# Miscellaneous scripts useful for analysis
from collections import OrderedDict
import math
import logging
import re

import numpy as np
import pandas as pd
from scipy.stats import chi2, norm
from pymatch.Matcher import Matcher

logger = logging.Logger('utils')

TABLES = OrderedDict(
    [
        ['cohort', 'vanco.cohort'],
        ['demographics', 'vanco.demographics'],
        ['aki', 'vanco.aki'],
        # drug usage
        ['vanco', 'vanco.vanco'],
        ['zosyn', 'vanco.zosyn'],
        ['cefepime', 'vanco.cefepime'],
        ['linezolid', 'vanco.linezolid'],
        ['meropenem', 'vanco.meropenem'],
        # confounders
        ['apache', 'vanco.apache'],
        ['sepsis_infection', 'vanco.sepsis_infection']
    ]
)


def frequency_once(frequency):
    if pd.isnull(frequency):
        return False
    # return an index of rows with frequency indicating a single administration
    if re.search('(once|one|pre-op)', frequency, re.IGNORECASE) is not None:
        return True
    return False


def extract_adm_and_wk(d, drugname='vanco', indefinite_orders=True):
    # create a dataframe with (1) abx on adm and (2) abx after 48 hr
    d_df = d[['patientunitstayid']].copy().drop_duplicates()
    d_df.set_index('patientunitstayid', inplace=True)
    d_df[drugname + '_adm'] = 0
    d_df[drugname + '_wk'] = 0

    # define abx on admission as any administration [-12, 12]
    idxKeep0 = (
        (d['drugstartoffset'] >=
         (-12 * 60)) & (d['drugstartoffset'] <= (12 * 60))
    )
    idxKeep1 = (
        (d['drugstopoffset'] >=
         (-12 * 60)) & (d['drugstopoffset'] <= (12 * 60))
    )
    idxKeep = idxKeep0 | idxKeep1
    logger.info(
        (
            f'{idxKeep.sum()} ({idxKeep.mean()*100.0:3.1f}%)'
            f' {drugname} administrations in [48, 168] hours.'
        )
    )
    d_on_adm = set(d.loc[idxKeep, 'patientunitstayid'].values)
    d_df.loc[d_on_adm, drugname + '_adm'] = 1

    if indefinite_orders:
        # add orders which start before -12, but have NULL drug stop offset
        idxKeep = ~d['frequency'].apply(frequency_once)
        idxKeep = idxKeep & d['drugstopoffset'].isnull()
        idxKeep = idxKeep & (d['drugstartoffset'] < (12 * 60))
        logger.info(
            (
                f'{idxKeep.sum()} ({idxKeep.mean()*100.0:3.1f}%)'
                f' {drugname} administrations < -12 hours with null drug stop.'
            )
        )
        d_on_adm = set(d.loc[idxKeep, 'patientunitstayid'].values)
        d_df.loc[d_on_adm, drugname + '_adm'] = 1

    # define "persistent" abx use using rules to try and capture continued administration

    # group 1: had an order which started or ended sometime between hours [48, 168]
    idxKeep0 = (
        (d['drugstartoffset'] >=
         (48 * 60)) & (d['drugstartoffset'] <= (168 * 60))
    )
    idxKeep1 = (
        (d['drugstopoffset'] >=
         (48 * 60)) & (d['drugstopoffset'] <= (168 * 60))
    )
    idxKeep = idxKeep0 | idxKeep1
    logger.info(
        (
            f'{idxKeep.sum()} ({idxKeep.mean()*100.0:3.1f}%)'
            f' {drugname} administrations in [48, 168] hours.'
        )
    )

    d_48hr = set(d.loc[idxKeep, 'patientunitstayid'].values)
    d_df.loc[d_48hr, drugname + '_wk'] = 1

    # group 2: had an order on admission that persisted after 48 hours
    # implicitly this is catching the group who had an order longer than 7 days
    # as those with orders < 7 days (168 hr) were caught in previous dataframe
    idxKeep0 = (
        (d['drugstartoffset'] >=
         (-12 * 60)) & (d['drugstartoffset'] <= (12 * 60))
    )
    idxKeep1 = (d['drugstopoffset'] >= (48 * 60))
    idxKeep = idxKeep0 & idxKeep1

    logger.info(
        (
            f'{idxKeep.sum()} ({idxKeep.mean()*100.0:3.1f}%)'
            f' {drugname} administration started in [-12, 12] and persisted >= 48 hours.'
        )
    )
    d_long_order = set(d.loc[idxKeep, 'patientunitstayid'].values)

    d_df.loc[d_long_order, drugname + '_wk'] = 1

    if indefinite_orders:
        # add orders which start before 48, but have NULL drug stop offset
        idxKeep = ~d['frequency'].apply(frequency_once)
        idxKeep = idxKeep & d['drugstopoffset'].isnull()
        idxKeep = idxKeep & (d['drugstartoffset'] < (48 * 60))
        idxKeep = idxKeep & (d['drugstartoffset'] >= (-12 * 60))
        logger.info(
            (
                f'{idxKeep.sum()} ({idxKeep.mean()*100.0:3.1f}%)'
                f' {drugname} administrations < 48 hours with null drug stop.'
            )
        )
        d_wk = set(d.loc[idxKeep, 'patientunitstayid'].values)
        d_df.loc[d_wk, drugname + '_wk'] = 1

    return d_df


def prepare_dataframe(co, dem, aki, apache, dx, drug_dfs=None):
    # drop exclusions
    idxKeep = co['patientunitstayid'].notnull()
    for c in co.columns:
        if c.startswith('exclude_'):
            idxKeep = idxKeep & (co[c] == 0)

    logger.info(
        (
            f'Retained {idxKeep.sum()} ({idxKeep.mean()*100.0:3.1f}%)'
            f' patients after exclusions.'
        )
    )
    # combine data into single dataframe
    df = co.loc[idxKeep, ['patientunitstayid']].merge(
        dem, how='inner', on='patientunitstayid'
    )

    aki_grp = aki.groupby('patientunitstayid')[[
        'creatinine', 'creatinine_baseline', 'aki_48h', 'aki_7d'
    ]].max()
    aki_grp.reset_index(inplace=True)
    df = df.merge(aki_grp, how='inner', on='patientunitstayid')

    df['aki'] = ((df['aki_48h'] == 1) | (df['aki_7d'] == 1)).astype(int)
    logger.info(
        (
            f'{df["aki"].sum()} ({df["aki"].mean()*100.0:3.1f}%)'
            f' patients have AKI.'
        )
    )

    # add in apache/diagnosis data
    apache_columns = ['patientunitstayid', 'apache_prob', 'immunocompromised']
    df = df.merge(apache[apache_columns], how='left', on='patientunitstayid')

    for c in apache_columns:
        if c != 'apache_prob':
            df[c].fillna(0, inplace=True)
            df[c] = df[c].astype(int)

    df = df.merge(dx, how='left', on='patientunitstayid')
    for c in dx.columns:
        df[c].fillna(0, inplace=True)
        df[c] = df[c].astype(int)

    df['sepsis'] = (df['infection'] == 1) & (df['organfailure'] == 1)
    df['sepsis'] = df['sepsis'] | (df['sepsis_explicit'] == 1)
    df['sepsis'] = df['sepsis'].astype(int)
    logger.info(
        (
            f'{df["sepsis"].sum()} ({df["sepsis"].mean()*100.0:3.1f}%)'
            f' patients have sepsis.'
        )
    )

    # convert binary vars to string so they are interpreted as categorical by pymatch
    for c in ['immunocompromised', 'sepsis', 'infection_skin_soft_tissue']:
        df[c] = df[c].map({0: 'no', 1: 'yes'})

    # avoid conflicts in column names with pymatch
    df.rename(
        columns={
            'weight': 'weight_kg',
            'height': 'height_cm'
        }, inplace=True
    )

    # ensure apache/age are continuous
    idx = df['age'] == '> 89'
    df.loc[idx, 'age'] = 90

    idx = df['age'] == ''
    df.loc[idx, 'age'] = np.nan
    df['age'] = pd.to_numeric(df['age'], errors='coerce')

    idx = df['apachescore'] == -1
    df.loc[idx, 'apachescore'] = np.nan
    df['apachescore'] = df['apachescore'].astype(float)

    idx = df['apache_group'] == '-1'
    df.loc[idx, 'apache_group'] = 'missing'

    # add GFR using baseline creatinine
    # eGFR = 175 x (SCr)^-1.154 x (age)^-0.203 x 0.742 [if female] x 1.212 [if Black]
    df['egfr'] = 175 * np.power(df['creatinine_baseline'],
                                -1.154) * np.power(df['age'], -0.203)
    idxFemale = df['gender'] == 'Female'
    df.loc[idxFemale, 'egfr'] = df.loc[idxFemale, 'egfr'] * 0.742
    idxBlack = df['ethnicity'] == 'African American'
    df.loc[idxBlack, 'egfr'] = df.loc[idxBlack, 'egfr'] * 1.212

    # finally, add the drug dataframes
    if drug_dfs is not None:
        for ddf in drug_dfs:
            # add drug administration, e.g. vanco, zosyn, cefepime
            df = df.merge(ddf, how='left', on='patientunitstayid')

            # if ptid missing in drug dataframe, then no drug was received
            # therefore impute 0
            for c in ddf.columns:
                df[c].fillna(0, inplace=True)
                df[c] = df[c].astype(int)

            # simplify one column as the logical AND of the two
            drug_cols = ddf.columns
            drug_name = [c.split('_')[0] for c in ddf.columns]
            assert drug_name[0] == drug_name[1]
            drug_name = drug_name[0]

            df[drug_name] = (df[drug_cols[0]] == 1) & (df[drug_cols[1]] == 1)
            df[drug_name] = df[drug_name].astype(int)
            df.drop(drug_cols, axis=1, inplace=True)

    # set patientunitstayid as index
    df.set_index('patientunitstayid', inplace=True)
    df.sort_index(inplace=True)

    return df


all_apache_groups = [
    '0-10', '11-20', '21-30', '31-40', '41-50', '51-60', '61-70', '71-80',
    '81-90', '91-100', '101-110', '111-120', '121-130', '131-140', '>140'
]


def determine_apache_distribution(treatmentgroup, controlgroup):
    # Determine distribution of severity in
    # treatment group vs control group based on APACHE score.
    print('Counts of Apache Scores for Control Group and Treatment Group\n')
    print(f'ApacheGroups\tControl\tTreatment\tControl (%)\tTreat (%)')

    for apache_group in all_apache_groups:
        n_control = (controlgroup["apache_group"] == apache_group).sum()
        n_treat = (treatmentgroup["apache_group"] == apache_group).sum()
        print(f'{apache_group}\t\t{n_control}\t{n_treat}', end='\t')
        n_control = n_control / controlgroup.shape[0] * 100.0
        n_treat = n_treat / treatmentgroup.shape[0] * 100.0
        print(f'{n_control:3.1f}\t{n_treat:3.1f}')

    control_mu = controlgroup['apachescore'].mean()
    treat_mu = treatmentgroup['apachescore'].mean()
    meandiff = control_mu - treat_mu
    print(f'\nAbsolute Mean Difference of APACHE Score: {meandiff}')


def get_matched_groups(treat_um, control_um, seed=None):
    # allow reproducibility by fixing seed
    # if no seed is input, this is randomly generated
    rng = np.random.RandomState(seed=seed)

    # Create an empty dataframe variables.
    df_treatment = pd.DataFrame()
    df_control = pd.DataFrame()

    # For each valid apache group, determine the count the number
    # of IDs in the treatment group
    # and sample that sample number from control group.
    for apache_group in all_apache_groups:
        treat_group = treat_um[treat_um["apache_group"] == apache_group]
        control_group = control_um[control_um["apache_group"] == apache_group]
        sample_num = len(
            treat_group
        ) if len(treat_group) < len(control_group) else len(control_group)

        if sample_num > 0:
            idx_sample = rng.permutation(sample_num)
            df_treatment = df_treatment.append(treat_group.iloc[idx_sample, :])

            idx_sample = rng.permutation(sample_num)
            df_control = df_control.append(control_group.iloc[idx_sample, :])

    print(f'Shape of treatment group: {df_treatment.shape}')
    print(f'Shape of control group: {df_control.shape}')

    return df_treatment, df_control


def get_odds_ratio(a, b, c, d):
    oddsr = (a / b) / (c / d)
    se_log_or = ((1 / a) + (1 / b) + (1 / c) + (1 / d))**.5
    ci_lower = math.exp(math.log(oddsr) - 1.96 * se_log_or)
    ci_upper = math.exp(math.log(oddsr) + 1.96 * se_log_or)

    print(f'Diseased + Exposed: {a}')
    print(f'Healthy + Exposed: {b}')
    print(f'Diseased + Nonexposed: {c}')
    print(f'Healthy + Nonexposed: {d}')
    print(f'Odds Ratio: {oddsr}')
    print(f'95% CI: ({ci_lower}, {ci_upper})')


# helper function to print odds ratio after matching
def match_and_print_or(exposure, control, seed=None):
    N = control.shape[0]
    print(f'{N} in control group.')

    N = exposure.shape[0]
    print(f'{N} in exposure group.')

    # Print out APACHE group distribution for each group
    print('\n=== APACHE distribution, unmatched data ===\n')
    determine_apache_distribution(exposure, control)

    # Match groups by APACHE group
    print('\n=== Match groups on APACHE ===\n')
    exposure_m, control_m = get_matched_groups(exposure, control, seed=seed)
    determine_apache_distribution(exposure_m, control_m)

    # Calculate Odds Ratio
    print('\n=== Odds ratio of exposure ===\n')
    diseased_exposed = len(exposure_m[exposure_m['aki'] == 1])
    healthy_exposed = len(exposure_m[exposure_m['aki'] == 0])
    diseased_nonexposed = len(control_m[control_m['aki'] == 1])
    healthy_nonexposed = len(control_m[control_m['aki'] == 0])

    get_odds_ratio(
        diseased_exposed, healthy_exposed, diseased_nonexposed,
        healthy_nonexposed
    )


def _mcnemar_test(n12, n21):
    z = np.power(n12 - n21, 2) / (n12 + n21)
    # two-sided test, so double the p-value
    return 2 * (1 - chi2.cdf(z, df=1))


def mcnemar_test(f):
    # two-sided test, so double the p-value
    return _mcnemar_test(n12=f[1, 0], n21=f[0, 1])


# n12 = f[1, 0]
# n21 = f[0, 1]


def cmh_test(
    x, alpha=0.05, exact=False, test_type='two-sided', continuity=True
):
    """Cochran Mantel Haenszel estimate of exposure adjusting for confounding.

    x should be a 2x2xK contingency table, where K is the number of strata for
    the confounding variable.
    """
    # x should be 2x2xK
    assert len(x.shape) == 3
    assert x.shape[0:2] == (2, 2)

    # total cases in each strata
    T = x.sum(axis=0).sum(axis=0)

    # need at least 1 sample in each stratum
    assert all(T > 0)

    I, J, K = x.shape

    # row/column totals used in the statistic
    n1i = x.sum(axis=1)[0, :]
    n2i = x.sum(axis=1)[1, :]
    m1i = x.sum(axis=0)[0, :]
    m2i = x.sum(axis=0)[1, :]

    # We test against a chi2 statistic with dof 1
    statistic = np.sum(x[0, 0, :] - (n1i * m1i / T))
    statistic_sign = np.sign(statistic)

    # Yates continuity correction
    if continuity & (np.abs(statistic) >= 0.5):
        statistic = np.abs(statistic) - 0.5

    statistic = statistic**2 / np.sum(
        n1i * n2i * m1i * m2i / (np.power(T, 2) * (T - 1))
    )

    if test_type != 'two-sided':
        # if one sided, take the square root and do z-test
        statistic = np.sqrt(statistic) * statistic_sign
        pval = norm.sf(statistic)
    else:
        # calculate the p-value for the statistic: 1 dof chi2
        pval = chi2.sf(statistic, df=1)

    # common odds-ratio (Mantel-Haenszel, 1959)
    main_diag_sum = np.sum(x[0, 0, :] * x[1, 1, :] / T)
    off_diag_sum = np.sum(x[0, 1, :] * x[1, 0, :] / T)
    R = main_diag_sum / off_diag_sum

    # Robins et al. (1986) estimate of the standard deviation of log CMH
    term1 = np.sum(
        (x[0, 0, :] + x[1, 1, :]) * x[0, 0, :] * x[1, 1, :] / np.power(T, 2)
    ) / (2 * np.power(main_diag_sum, 2))
    term2 = np.sum(
        (
            (x[0, 0, :] + x[1, 1, :]) * x[0, 1, :] * x[1, 0, :] +
            (x[0, 1, :] + x[1, 0, :]) * x[0, 0, :] * x[1, 1, :]
        ) / np.power(T, 2)
    ) / (2 * main_diag_sum * off_diag_sum)
    term3 = np.sum(
        (x[0, 1, :] + x[1, 0, :]) * x[0, 1, :] * x[1, 0, :] / np.power(T, 2)
    ) / (2 * np.power(off_diag_sum, 2))
    sigma = np.sqrt(term1 + term2 + term3)

    # un-log the estimate to get confidence intervals
    ci_lower = R * np.exp(1 * norm.ppf(alpha / 2) * sigma)
    ci_upper = R * np.exp(-1 * norm.ppf(alpha / 2) * sigma)

    return pval, R, (ci_lower, ci_upper)


def _proportion_confidence_interval(
    n12, n21, N, method='Bonett-Price', alpha=0.05
):
    if method == 'wald':
        p12 = n12 / N
        p21 = n21 / N
        v = np.sqrt((n12 + n21 - np.power(n12 - n21, 2) / N)) / N
    elif method == 'bonett-price':
        p12 = (n12 + 1) / (N + 2)
        p21 = (n21 + 1) / (N + 2)
        v = np.sqrt((p12 + p21 - np.power(p12 - p21, 2)) / (N + 2))
    else:
        raise ValueError(f'Unrecognized method {method}')

    theta = p12 - p21
    # two-sided, so divide alpha by 2
    z = norm.ppf(1 - (alpha / 2))
    ci = [theta - z * v, theta + z * v]

    return theta, ci


def proportion_confidence_interval(f, method='Bonett-Price', alpha=0.05):
    """Calculate confidence interval for paired sample.
    
    f should be a confusion matrix // cross-tabulation.
    """
    # f should be 2x2
    assert f.shape == (2, 2)

    method = method.lower()

    # phat should sum to 1, as it is a matrix of proportions for paired samples
    N = np.sum(f, axis=None)

    return _proportion_confidence_interval(
        n12=f[0, 1], n21=f[1, 0], N=N, method=method
    )


def _odds_ratio_confidence_interval(n12, n21, N, method='wald', alpha=0.05):
    # two-sided, so divide alpha by 2
    z = norm.ppf(1 - (alpha / 2))
    theta = n12 / n21

    if method in ('wald', 'wald_laplace'):
        if method == 'wald_laplace':
            # laplace smooth
            n12 = n12 + 1
            n21 = n21 + 1

        if (n12 == 0) | (n21 == 0):
            return np.nan, (np.nan, np.nan)

        v = np.exp(z * np.sqrt(1 / n12 + 1 / n21))
        ci = (theta / v, theta * v)
    elif method == 'wilson_score':
        v = z * np.sqrt(z**2 + 4 * n12 * (1 - n12 / (n12 + n21)))

        L = (2 * n12 + z**2 - v) / (2 * (n12 + n21 + z**2))
        U = (2 * n12 + z**2 + v) / (2 * (n12 + n21 + z**2))

        ci = (L / (1 - L), U / (1 - U))
    else:
        p12 = n12 / N
        p21 = n21 / N
        raise ValueError(f'Unrecognized method {method}')

    return theta, ci


def odds_ratio_confidence_interval(f, method='wald', alpha=0.05):
    """Calculate confidence interval for paired sample.
    
    f should be a confusion matrix // cross-tabulation.
    """
    # f should be 2x2
    assert f.shape == (2, 2)

    method = method.lower()

    # phat should sum to 1, as it is a matrix of proportions for paired samples
    N = np.sum(f, axis=None)

    return _odds_ratio_confidence_interval(
        n12=f[0, 1], n21=f[1, 0], N=N, method=method
    )


def propensity_match(
    exposure,
    control,
    covariates=[
        'age', 'apache_prob', 'sepsis', 'infection_skin_soft_tissue',
        'immunocompromised'
    ],
    outcome_var='aki',
    seed=389202
):

    np.random.seed(seed)

    exposure = exposure.copy()
    control = control.copy()

    # make sure we don't overwrite the legit column status
    if 'status' in exposure.columns:
        exposure['status_original'] = exposure['status']
        control['status_original'] = control['status']
    exposure_var = 'status'
    exposure.loc[:, exposure_var] = 1
    control.loc[:, exposure_var] = 0

    # vars we exclude
    cols_exclude, cols_include = [], []
    for c in exposure.columns:
        if c == exposure_var:
            continue
        if c not in covariates:
            cols_exclude.append(c)
        else:
            cols_include.append(c)

    if len(cols_include) == 0:
        raise ValueError(
            'None of the covariates appear in the exposure dataframe.'
        )
    logger.info((f'Columns included: {cols_include}'))

    # warn about missing data and missing columns
    for c in exposure.columns:
        if str(exposure[c].dtype) == 'object':
            mu = pd.concat([exposure[c], control[c]],
                           axis=0).value_counts().index[0]
        else:
            mu = pd.concat([exposure[c], control[c]], axis=0).mean()

        n = exposure[c].isnull().sum()
        if n > 0:
            logger.warning(
                f'Column {c} missing {n} observations in exposure dataframe.'
            )
            exposure[c].fillna(mu, inplace=True)

        if c not in control:
            logger.warning(f'Did not find column {c} in control dataframe.')
        else:
            n = control[c].isnull().sum()
            if n > 0:
                logger.warning(
                    f'Column {c} missing {n} observations in control dataframe.'
                )
                control[c].fillna(mu, inplace=True)

    # print('Dataframe being used:')
    # display(exposure[cols].head())
    m = Matcher(exposure, control, yvar=exposure_var, exclude=cols_exclude)

    # predict the y outcome balancing the classes
    # repeat 100 times to be sure we use a lot of majority class data
    m.fit_scores(balance=False)
    m.predict_scores()

    # m.plot_scores()

    # m.tune_threshold(method='random')
    m.match(method="min", nmatches=1, threshold=0.0005)
    # m.record_frequency()

    # no categorical variables -> this errors
    # cc = m.compare_continuous(return_table=True)
    # display(cc)
    return m


def get_contingency_tables(m, outcome_var='aki'):
    """Get 2x2xK contingency tables for matched pairs in propensity analysis.

    Contingency tables will be output in the following form:

    [
        Number exposed with outcome == 1, Number exposed with outcome == 0
        Number unexposed with outcome == 1, Number unexposed with outcome == 0
    ]

    The input match object must be populated with match using nmatches=1.
    """

    # in the matched object, m.yvar is the exposure variable
    df_matched = m.matched_data[['match_id', 'record_id', m.yvar, outcome_var]]

    # determine the minority group
    # this group will be matched to more than one case
    idxMinority = df_matched[m.yvar] == m.minority

    df_matched = df_matched.loc[idxMinority].merge(
        df_matched.loc[~idxMinority],
        how='inner',
        on='match_id',
        suffixes=('_minority', '_majority')
    )

    # drop the redundant yvar column
    df_matched.drop(
        [f'{m.yvar}_{s}' for s in ('minority', 'majority')],
        axis=1,
        inplace=True
    )

    # group them by the strata
    df_grouped = df_matched.groupby(
        ['record_id_minority', 'aki_minority', 'aki_majority']
    )[['match_id']].count()
    df_grouped = df_grouped.reset_index()

    K = df_grouped['record_id_minority'].nunique()
    cm = np.zeros([2, 2, K])

    # pivot the dataframe into a 2x2xK contingency table
    # we do this by creating the i/j/k indices, then inserting the count into a matrix of 0s

    # create an integer grouped by the strata
    df_grouped['k'] = df_grouped['record_id_minority'].rank(method='dense'
                                                           ).astype(int) - 1

    # below we guarantee the exposed cases are in the 0th row
    if m.minority == 1:
        # if minority are exposed, then majority should go in [1, :]
        i = np.ones(df_grouped.shape[0], dtype=int)
    else:
        # if minority are *not* exposed, then majority are exposed
        # therefore, place majority cases in [0, :]
        i = np.zeros(df_grouped.shape[0], dtype=int)
    j = 1 - df_grouped[f'{outcome_var}_majority']
    k = df_grouped['k']

    # insert the count of observations
    cm[i, j, k] = df_grouped['match_id']

    # now drop the non-minority rows, we have 1 match for each
    df_grouped.drop_duplicates(
        ['record_id_minority'], keep='first', inplace=True
    )
    # i is 1 if the minority class is the non-exposed class
    if m.minority == 1:
        # i is 0 if the minority class is the exposed class
        i = np.zeros(K, dtype=int)
    else:
        i = np.ones(K, dtype=int)

    # ensure that events occuring are placed in the 0th column
    # ensure that non-events are placed in the 1st column
    j = 1 - df_grouped[f'{outcome_var}_minority']
    k = df_grouped['k']
    cm[i, j, k] = 1

    return cm

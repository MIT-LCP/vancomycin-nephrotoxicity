# Miscellaneous scripts useful for analysis
import random
import math

import pandas as pd

      
def extract_adm_and_wk(d, drugname='vanco'):
    # define abx on admission as any administration [-12, 12]
    idxKeep0 = (d['drugstartoffset'] >= (-12*60)) & (d['drugstartoffset'] <= (12*60)) 
    idxKeep1 = (d['drugstopoffset'] >= (-12*60)) & (d['drugstopoffset'] <= (12*60))
    d_on_adm = set(d.loc[idxKeep0 | idxKeep1, 'patientunitstayid'].values)

    # define "persistent" abx use using rules to try and capture continued administration

    # group 1: had an order on admission, and had another one >48hr after admission
    idxKeep0 = (d['drugstartoffset'] >= (48*60)) & (d['drugstartoffset'] <= (168*60))
    idxKeep1 = (d['drugstopoffset'] >= (48*60)) & (d['drugstopoffset'] <= (168*60))
    d_48hr = set(d.loc[idxKeep0 | idxKeep1, 'patientunitstayid'].values)
    d_48hr = d_on_adm.intersection(d_48hr)

    # group 2: had an order on admission that persisted after 48 hours
    # implicitly this is catching the group who had an adm longer than 7 days
    # as those with orders >48 hr are also in group 1
    idxKeep0 = (d['drugstartoffset'] >= (-12*60)) & (d['drugstartoffset'] <= (12*60)) 
    idxKeep1 = (d['drugstopoffset'] >= (48*60))
    d_long_order = set(d.loc[idxKeep0 | idxKeep1, 'patientunitstayid'].values)

    # create a dataframe with (1) abx on adm and (2) abx after 48 hr
    d_df = d[['patientunitstayid']].copy().drop_duplicates()
    d_df.set_index('patientunitstayid', inplace=True)
    d_df[drugname + '_adm'] = 0
    d_df[drugname + '_wk'] = 0

    d_df.loc[d_on_adm, drugname + '_adm'] = 1
    d_df.loc[d_48hr, drugname + '_wk'] = 1
    d_df.loc[d_long_order, drugname + '_wk'] = 1

    N = ((d_df[drugname + '_adm'] == 1) & (d_df[drugname + '_wk'] == 0)).sum()
    
    return d_df

all_apache_groups = ['0-10', '11-20', '21-30', '31-40', '41-50', '51-60', '61-70', '71-80', '81-90', '91-100', '101-110', '111-120', '121-130', '131-140', '>140']

def determine_apache_distribution(treatmentgroup, controlgroup):
    # Determine distribution of severity in treatment group vs control group based on APACHE score. 
    print('Counts of Apache Scores for Control Group and Treatment Group\n')
    print(f'ApacheGroups\tControl\tTreatment')

    for apache_group in all_apache_groups:
        print(f'{apache_group}\t\t{len(controlgroup[controlgroup["apache_group"] == apache_group])}\t{len(treatmentgroup[treatmentgroup["apache_group"] == apache_group])}')
    
    meandiff = controlgroup['apachescore'].mean() - treatmentgroup['apachescore'].mean()
    print(f'\nAbsolute Mean Difference of APACHE Score: {meandiff}')
    
def get_matched_groups(treat_um, control_um, seed=830278):
    # ensure reproducibility by fixing seed
    random.seed(seed)
    
    # Create an empty dataframe variables. 
    df_treatment = pd.DataFrame()
    df_control = pd.DataFrame() 

    # For each valid apache group, determine the count the number of IDs in the treatment group 
    # and sample that sample number from control group.
    for apache_group in all_apache_groups:
        treat_group = treat_um[treat_um["apache_group"] == apache_group]
        control_group = control_um[control_um["apache_group"] == apache_group]
        sample_num = len(treat_group) if len(treat_group) < len(control_group) else len(control_group)

        if sample_num > 0:
            treat_sample = treat_group.sample( n=sample_num )
            df_treatment = df_treatment.append(treat_sample)

            control_sample = control_group.sample( n=sample_num )
            df_control = df_control.append(control_sample)

    print(f'Shape of treatment group: {df_treatment.shape}')  
    print(f'Shape of control group: {df_control.shape}')
    
    return df_treatment, df_control

def get_odds_ratio(a, b, c, d):
    oddsr = (a / b) / (c / d)
    se_log_or = ((1/a) + (1/b) + (1/c) + (1/d))**.5
    ci_lower = math.exp(math.log(oddsr) - 1.96*se_log_or)
    ci_upper = math.exp(math.log(oddsr) + 1.96*se_log_or)
    
    print(f'Diseased + Exposed: {a}')
    print(f'Healthy + Exposed: {b}')
    print(f'Diseased + Nonexposed: {c}')
    print(f'Healthy + Nonexposed: {d}')
    print(f'Odds Ratio: {oddsr}')
    print(f'95% CI: ({ci_lower}, {ci_upper})')


# helper function to print odds ratio after matching
def match_and_print_or(exposure, control):
    N = control.shape[0]
    print(f'{N} in control group.')

    N = exposure.shape[0]
    print(f'{N} in exposure group.')

    # Print out APACHE group distribution for each group
    print('\n=== APACHE distribution, unmatched data ===\n')
    determine_apache_distribution(exposure, control)

    # Match groups by APACHE group
    print('\n=== Match groups on APACHE ===\n')
    exposure_m, control_m = get_matched_groups(exposure, control)
    determine_apache_distribution(exposure_m, control_m)


    # Calculate Odds Ratio
    print('\n=== Odds ratio of exposure ===\n')
    diseased_exposed = len(exposure_m[exposure_m['aki'] == 1])
    healthy_exposed = len(exposure_m[exposure_m['aki'] == 0])
    diseased_nonexposed = len(control_m[control_m['aki'] == 1])
    healthy_nonexposed = len(control_m[control_m['aki'] == 0])

    get_odds_ratio(diseased_exposed, healthy_exposed, diseased_nonexposed, healthy_nonexposed)
# Miscellaneous scripts useful for analysis
from collections import OrderedDict
import math
import logging
import re

import numpy as np
import pandas as pd
from scipy.stats import chi2, norm
from pymatch.Matcher import Matcher

logger = logging.Logger('matching_utils')


def propensity_match(
    exposure,
    control,
    covariates=[
        'age', 'apache_prob', 'sepsis', 'infection_skin_soft_tissue',
        'immunocompromised'
    ],
    outcome_var='aki',
    seed=389202,
    balance=False,
    n_models=100,
    verbose=False
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
        if (n > 0) & (c not in cols_exclude):
            logger.warning(
                f'Column {c} missing {n} observations in exposure dataframe.'
            )
            exposure[c].fillna(mu, inplace=True)

        if c not in control:
            logger.warning(f'Did not find column {c} in control dataframe.')
        else:
            n = control[c].isnull().sum()
            if (n > 0) & (c not in cols_exclude):
                logger.warning(
                    f'Column {c} missing {n} observations in control dataframe.'
                )
                control[c].fillna(mu, inplace=True)

    # print('Dataframe being used:')
    # display(exposure[cols].head())
    m = Matcher(exposure, control, yvar=exposure_var, exclude=cols_exclude)

    # predict the y outcome balancing the classes
    # repeat 100 times to be sure we use a lot of majority class data
    if balance:
        m.fit_scores(balance=balance, nmodels=n_models)
    else:
        m.fit_scores(balance=False)

    m.predict_scores()

    if verbose:
        m.plot_scores()

    # m.tune_threshold(method='random')
    m.match(method="min", nmatches=1, threshold=0.0005) # finds the closest match for each minority record
    # m.record_frequency()

    # no categorical variables -> this errors
    if verbose:
        cc = m.compare_categorical(return_table=True)
        display(cc)
        cc = m.compare_continuous(return_table=True)
        display(cc)

    return m


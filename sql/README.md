# Data extraction

The SQL files in this folder perform all data extraction from eICU-CRD.
You can read more about [eICU-CRD at the documentation website](https://eicu-crd.mit.edu).


## Tables used

* apacheapsvar
* apachepatientresult
* careplangeneral
* diagnosis
* intakeoutput
* infusiondrug
* lab
* medication
* nursecharting
* patient
* pasthistory
* treatment

## GCP queries

eICU-CRD has been loaded into Google BigQuery and is available via the `physionet-data.eicu_crd` schema for those who have correct permissions.
Queries in the [../sql-gcp](../sql-gcp) folder use this bucket for extracting data.

For convenience, intermediate tables are created on a separate schema on Google BigQuery: the `lcp-internal.vanco` schema.
In order to run the code, the following tables must be generated, and we recommend generating them in this order:

* `physionet-data.eicu_crd_erived.pivoted_creatinine` - see eicu-code GitHub repository for information
* `lcp-internal.vanco.dialysis` - dialysis.sql
* `lcp-internal.vanco.cohort` - cohort.sql
* `lcp-internal.vanco.aki` - aki.sql
* `lcp-internal.vanco.vanco` - vanco.sql
* `lcp-internal.vanco.cefepime` - cefepime.sql
* `lcp-internal.vanco.zosyn` - zosyn.sql

## Propensity score variables

Additional variables extracted to perform propensity score:

presence of sepsis or septic shock
SIRS, lactate, elevated WBC, hypotension, fever
soft tissue infection/skin infections (?cellulitis, or APACHE admission diagnosis Sepsis:skin)
risk factors for community acquired MRSA
risk factors for MDR in general (hospitalization for more than 48 hours in the last 90 days, residence in a nursing home or extended care facility, home infusion therapy, chronic dialysis within one month, home wound care)
known colonization with MRSA
immunocompromized state even in the absence of shock (probably captured through the comorbidity fields)
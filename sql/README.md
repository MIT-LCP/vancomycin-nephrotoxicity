# Data extraction

The SQL files in this folder perform all data extraction from eICU-CRD.
You can read more about [eICU-CRD at the documentation website](https://eicu-crd.mit.edu).

eICU-CRD has been loaded into Google BigQuery and is available via the `physionet-data.eicu_crd` schema for those who have correct permissions.
All queries here use this bucket for extracting data.

For convenience, intermediate tables are created on a separate schema on Google BigQuery: the `lcp-internal.vanco` schema.
In order to run the code, the following tables must be generated, and we recommend generating them in this order:

* `physionet-data.eicu_crd_erived.pivoted_creatinine` - see eicu-code GitHub repository for information
* `lcp-internal.vanco.dialysis` - dialysis.sql
* `lcp-internal.vanco.cohort` - cohort.sql
* `lcp-internal.vanco.aki` - aki.sql
* `lcp-internal.vanco.vanco` - vanco.sql
* `lcp-internal.vanco.cefepime` - cefepime.sql
* `lcp-internal.vanco.zosyn` - zosyn.sql

-- generate cohort with base exclusions
-- requires eicu-code concepts, specifically:
--  pivoted_creatinine
-- assumes this is available on the "public" schema


-- decide which dataset to run queries on
--  eicu_crd - publicly available dataset
--  eicu_full_phi - internal larger dataset
-- SET SEARCH_PATH TO eicu_full_phi;

-- prepare vanco schema
DROP SCHEMA IF EXISTS vanco CASCADE;
CREATE SCHEMA vanco;

-- load in tables from file
\i dx_sepsis_infection.sql
\i medication_frequency_map.sql

-- get creatinines across ICU stays
\i pivoted_creatinine.sql

-- dialysis query required for cohort
\i dialysis.sql

-- generate a table listing all exclusions
\i cohort.sql

-- define AKI based upon pivoted_creatinine
\i aki.sql

-- extract vanco/cefepime/zosyn throughout ICU stay
\i vanco.sql
\i cefepime.sql
\i zosyn.sql

-- demographics
\i apache.sql
\i weight.sql
-- below requires the weight query
\i demographics.sql

-- additional covariates used for propensity score
\i nsaids.sql
\i loop_diuretics.sql
\i sepsis_infection.sql

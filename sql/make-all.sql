-- generate cohort with base exclusions
-- requires eicu-code concepts, specifically:
--  pivoted_creatinine


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

-- for abx comparison, we need above abx tables to be present
\i cohort_abx_comparison.sql

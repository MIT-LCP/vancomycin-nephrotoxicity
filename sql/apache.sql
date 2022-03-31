-- Determine baseline creatinine.
DROP TABLE IF EXISTS vanco.apache;
CREATE TABLE vanco.apache AS
SELECT
  pt.patientunitstayid
  , CASE
    WHEN CAST(apr.predictedhospitalmortality AS NUMERIC) = -1 THEN NULL
    ELSE CAST(apr.predictedhospitalmortality AS NUMERIC)
  END as apache_prob
  , CASE
    WHEN apv.aids = 1 OR apv.immunosuppression = 1 THEN 1
    ELSE 0
  END AS immunocompromised
  -- raw data for debugging
  , apr.acutephysiologyscore
  , apr.apachescore
  , CAST(apr.predictedhospitalmortality AS NUMERIC) AS predictedhospitalmortality
FROM patient pt
INNER JOIN apachepatientresult apr
  ON pt.patientunitstayid = apr.patientunitstayid
  AND apr.apacheversion = 'IVa'
INNER JOIN apachepredvar apv
  ON pt.patientunitstayid = apv.patientunitstayid
ORDER BY pt.patientunitstayid;

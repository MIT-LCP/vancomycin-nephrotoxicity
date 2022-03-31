DROP TABLE IF EXISTS vanco.dialysis;
CREATE TABLE vanco.dialysis AS
with tr as
(
    -- captures 7,985 stays
    SELECT 
      patientunitstayid, treatmentoffset as chartoffset
    FROM treatment t
    WHERE lower(treatmentstring) like '%dialysis%'
    OR lower(treatmentstring) like '%rrt%'
    OR lower(treatmentstring) like '%ihd%'
)
, cpl as
(
    -- captures 14,330 stays
    SELECT
      patientunitstayid, cplitemoffset as chartoffset
    FROM careplangeneral c
    WHERE c.cplgroup = 'Volume Status'
    AND c.cplitemvalue in (
          'Hypervolemic - actively diurese' -- 2987
        , 'Hypervolemic - dialyze/filter' -- 7496
        , 'Hypervolemic - gently diurese' -- 9202
    )
)
, ph as
(
    -- captures 7767 stays
    SELECT
      patientunitstayid, pasthistoryoffset as chartoffset
    FROM pasthistory
    -- it's not obvious how to escape ()s in bigquery strings
    -- so we use a wildcard, %, for the '(R)' in the string
    -- note using the SQL clause `IN ('str1', 'str2')` also had this issue
    WHERE pasthistorypath LIKE 'notes/Progress Notes/Past History/Organ Systems/Renal %/Renal Failure/renal failure - hemodialysis'
    OR pasthistorypath LIKE 'notes/Progress Notes/Past History/Organ Systems/Renal %/Renal Failure/renal failure - peritoneal dialysis'
    OR pasthistorypath LIKE 'notes/Progress Notes/Past History/Organ Systems/Renal %/s/p Renal Transplant/s/p renal transplant'
)
, apv as
(
    -- captures 6309 stays
    SELECT
      patientunitstayid
    FROM apacheapsvar
    WHERE dialysis = 1  
)
SELECT
  pt.patientunitstayid
  , MAX(
      CASE
        WHEN COALESCE(tr.patientunitstayid, cpl.patientunitstayid) IS NOT NULL
        THEN 1
        ELSE 0 END
    ) AS dialysis
  , MAX(
      CASE
        WHEN COALESCE(ph.patientunitstayid, apv.patientunitstayid) IS NOT NULL
        THEN 1
        ELSE 0 END
    ) AS chronic_dialysis
FROM patient pt
-- dialysis between -12h to 12h upon admission
LEFT JOIN tr
  ON pt.patientunitstayid = tr.patientunitstayid
  AND tr.chartoffset >= -12*60. and tr.chartoffset <= 12*60.
LEFT JOIN cpl
  ON pt.patientunitstayid = cpl.patientunitstayid
  AND cpl.chartoffset >= -12*60. and cpl.chartoffset <= 12*60.
-- documentation of chronic dialysis
-- we still check for this documentation from -12h to 12h, to prevent info leakage
LEFT JOIN ph
  ON pt.patientunitstayid = ph.patientunitstayid
  AND ph.chartoffset >= -12*60 and ph.chartoffset <= 12*60
-- apv only provides documentation on chronic dialysis, 1 row per pt
LEFT JOIN apv
  ON pt.patientunitstayid = apv.patientunitstayid
GROUP BY pt.patientunitstayid
ORDER BY pt.patientunitstayid

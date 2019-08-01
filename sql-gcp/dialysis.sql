with tr as
(
    -- captures 7,985 stays
    SELECT 
      patientunitstayid, treatmentoffset as chartoffset
    FROM `physionet-data.eicu_crd.treatment` t
    WHERE lower(treatmentstring) like '%dialysis%'
    OR lower(treatmentstring) like '%rrt%'
    OR lower(treatmentstring) like '%ihd%'
)
, cpl as
(
    -- captures 14,330 stays
    SELECT
      patientunitstayid, cplitemoffset as chartoffset
    FROM `physionet-data.eicu_crd.careplangeneral` c
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
    FROM `physionet-data.eicu_crd.pasthistory`
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
      patientunitstayid, 0 as chartoffset
    FROM `physionet-data.eicu_crd.apacheapsvar`
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
FROM `physionet-data.eicu_crd.patient` pt
LEFT JOIN tr
  ON pt.patientunitstayid = tr.patientunitstayid
  AND tr.chartoffset >= 0 and tr.chartoffset <= 10080
LEFT JOIN cpl
  ON pt.patientunitstayid = cpl.patientunitstayid
  AND cpl.chartoffset >= 0 and cpl.chartoffset <= 10080
LEFT JOIN ph
  ON pt.patientunitstayid = ph.patientunitstayid
  AND ph.chartoffset >= 0 and ph.chartoffset <= 10080
LEFT JOIN apv
  ON pt.patientunitstayid = apv.patientunitstayid
  AND apv.chartoffset >= 0 and apv.chartoffset <= 10080
GROUP BY pt.patientunitstayid
ORDER BY pt.patientunitstayid
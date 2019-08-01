-- Determine baseline creatinine.
WITH cr0_tb AS (
  SELECT
    patientunitstayid,
    MIN(creatinine) as creatinine_baseline
  FROM `physionet-data.eicu_crd_derived.pivoted_creatinine`
  WHERE chartoffset BETWEEN (-12*60) AND (12*60)
  AND creatinine IS NOT NULL
  GROUP BY patientunitstayid
)
-- Get lowest creatinine in the last 48 hours for *each* measurement
, cr_rel AS (
SELECT
    cr1.patientunitstayid,
    cr1.chartoffset,
    cr1.creatinine,
    -- lowest creatinine in the last 48 hours
    MIN(cr2.creatinine) as creatinine_reference
  FROM `physionet-data.eicu_crd_derived.pivoted_creatinine` cr1
  LEFT JOIN `physionet-data.eicu_crd_derived.pivoted_creatinine` cr2
    ON cr1.patientunitstayid = cr2.patientunitstayid
    AND cr1.chartoffset >= cr2.chartoffset
    AND cr1.chartoffset <= (cr2.chartoffset + 2880)
  WHERE cr1.chartoffset BETWEEN (-12*60) AND (24*60*7)
  GROUP BY cr1.patientunitstayid, cr1.chartoffset, cr1.creatinine
)
SELECT
  c.patientunitstayid
  , c.chartoffset
  , c.creatinine
  , creatinine_reference
  , creatinine_baseline
  -- AKI is defined by the sudden (in 48 h) increase in absolute SCr by at least 0.3 mg/dL
  , CASE WHEN (c.creatinine - creatinine_reference) >= 0.3 THEN 1 ELSE 0 END as aki_48h
  -- AKI also defined by a percentage increase in SCr ≥50% (1.5× baseline value)
  , CASE WHEN (c.creatinine / creatinine_baseline) >= 1.5 THEN 1 ELSE 0 END as aki_7d
FROM cr_rel c
LEFT JOIN cr0_tb
  on c.patientunitstayid = cr0_tb.patientunitstayid
ORDER BY c.patientunitstayid, c.chartoffset
-- Determine baseline creatinine.
DROP TABLE IF EXISTS vanco.aki;
CREATE TABLE vanco.aki AS
WITH cr0_tb AS (
  SELECT
    patientunitstayid,
    chartoffset as chartoffset_baseline,
    creatinine as creatinine_baseline,
    ROW_NUMBER() OVER (PARTITION BY patientunitstayid ORDER BY creatinine ASC, chartoffset ASC) as rn
  FROM vanco.pivoted_creatinine
  WHERE chartoffset BETWEEN (-12*60) AND (12*60)
  AND creatinine IS NOT NULL
)
-- Get lowest creatinine in the last 48 hours for *each* measurement
, cr_rel AS (
SELECT
    cr1.patientunitstayid,
    cr1.chartoffset,
    cr1.creatinine,
    -- lowest creatinine in the last 48 hours
    cr2.creatinine as creatinine_reference,
    cr2.chartoffset AS chartoffset_reference,
    ROW_NUMBER() OVER (
      PARTITION BY cr1.patientunitstayid, cr1.chartoffset, cr1.creatinine
      ORDER BY cr2.creatinine ASC, cr2.chartoffset ASC
    ) AS rn
  FROM vanco.pivoted_creatinine cr1
  LEFT JOIN vanco.pivoted_creatinine cr2
    ON cr1.patientunitstayid = cr2.patientunitstayid
    AND cr1.chartoffset >= cr2.chartoffset
    AND cr1.chartoffset <= (cr2.chartoffset + 2880)
  WHERE cr1.chartoffset BETWEEN (12*60) AND (24*60*7)
)
SELECT
  c.patientunitstayid
  , c.chartoffset
  , c.creatinine
  , c.creatinine_reference
  , c.chartoffset_reference
  , cr0_tb.chartoffset_baseline
  , cr0_tb.creatinine_baseline
  -- AKI is defined by the sudden (in 48 h) increase in absolute SCr by at least 0.3 mg/dL
  , CASE WHEN (c.creatinine - creatinine_reference) >= 0.3 THEN 1 ELSE 0 END as aki_48h
  -- AKI also defined by a percentage increase in SCr ≥50% (1.5× baseline value)
  , CASE WHEN (c.creatinine / creatinine_baseline) >= 1.5 THEN 1 ELSE 0 END as aki_7d
FROM (SELECT * FROM cr_rel WHERE rn = 1) c
LEFT JOIN cr0_tb
  on c.patientunitstayid = cr0_tb.patientunitstayid
  AND cr0_tb.rn = 1
ORDER BY c.patientunitstayid, c.chartoffset
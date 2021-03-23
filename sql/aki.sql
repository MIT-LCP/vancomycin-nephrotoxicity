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
    AND cr1.chartoffset <= (cr2.chartoffset + 2880) -- last 48 hours
  WHERE cr1.chartoffset BETWEEN (12*60) AND (24*60*7) -- only looks at Cr values from 12h - 7 days after admission
)
, dialysis as
(
    -- captures 7,985 stays
    -- Dialysis as defined in the treatment table
    SELECT 
      patientunitstayid, treatmentoffset as chartoffset
    FROM treatment t
    WHERE lower(treatmentstring) like '%dialysis%'
    OR lower(treatmentstring) like '%rrt%'
    OR lower(treatmentstring) like '%ihd%'

    UNION DISTINCT

    -- captures 14,330 stays
    -- Dialysis as defined in the care plan table
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
-- patients receiving dialysis after admission
, dialysis_all as 
( SELECT 
    patientunitstayid, MIN(chartoffset) AS rrt_offset
  FROM dialysis
  WHERE (chartoffset > 12*60.) AND (chartoffset <= 7*24*60.) -- after admission - 7days, where admission = (-12, 12h)
  GROUP BY patientunitstayid
) 
SELECT
  c.patientunitstayid
  , c.chartoffset
  , c.creatinine
  , c.creatinine_reference
  , c.chartoffset_reference
  , cr0_tb.chartoffset_baseline
  , cr0_tb.creatinine_baseline
  , d.rrt_offset
  , CASE 
      WHEN d.rrt_offset IS NULL THEN 0
      ELSE 1
    END AS rrt 
  -- AKI is defined by the sudden (in 48 h) increase in absolute SCr by at least 0.3 mg/dL
  , CASE WHEN (c.creatinine - creatinine_reference) >= 0.3 THEN 1 ELSE 0 END AS aki_48h
  -- AKI also defined by a percentage increase in SCr ≥50% (1.5× baseline value)
  , CASE WHEN (c.creatinine / creatinine_baseline) >= 1.5 THEN 1 ELSE 0 END AS aki_7d
  , CASE 
    WHEN (c.creatinine / creatinine_baseline) >= 3.0 THEN 3
    WHEN (c.creatinine >= 4.0) THEN 3 
    WHEN (d.rrt_offset IS NOT NULL) THEN 3
    WHEN ((c.creatinine / creatinine_baseline) >= 2.0) THEN 2 
    WHEN ((c.creatinine / creatinine_baseline) >= 1.5) THEN 1 
    WHEN ((c.creatinine - creatinine_reference) >= 0.3) THEN 1
    ELSE 0
  END AS stage 

FROM (SELECT * FROM cr_rel WHERE rn = 1) c
LEFT JOIN cr0_tb
  on c.patientunitstayid = cr0_tb.patientunitstayid
  AND cr0_tb.rn = 1
LEFT JOIN dialysis_all d
  on c.patientunitstayid = d.patientunitstayid
ORDER BY c.patientunitstayid, c.chartoffset

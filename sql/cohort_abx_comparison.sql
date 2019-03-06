-- Further exclusions from original cohort
--  

-- exclude patients who do not have vanco/cefepime/zosyn
-- exclude those with drug start offset of 0 for our medications of interest

(SELECT DISTINCT patientunitstayid FROM drugs_tb WHERE drugstartoffset = 0)

-- do not have one of our medications of interest
SELECT
    pt.patientunitstayid
    , CASE WHEN v.patientunitstayid IS NULL THEN 1 ELSE 0 END AS exclusion_invalid_stay
FROM `physionet-data.eicu_crd.patient` pt
LEFT JOIN valid_stay v
    ON pt.patientunitstayid = v.patientunitstayid
LEFT JOIN valid_stay v
    ON pt.patientunitstayid = v.patientunitstayid


drugs_tb AS (
    SELECT drugstartoffset, drugstopoffset, patientunitstayid, 'zosyn' AS drug
    FROM zosyn_pt
    UNION ALL
    SELECT drugstartoffset,  drugstopoffset, patientunitstayid, 'vanco' AS drug
    FROM vanco_pt
    UNION ALL
    SELECT drugstartoffset,  drugstopoffset, patientunitstayid, 'cefepime' AS drug
    FROM cefepime_pt
),

drugs_pivot_tb AS (
    SELECT 
      patientunitstayid,
      MAX(CASE WHEN drug = 'zosyn' AND drugstartoffset BETWEEN -720 AND 720 THEN 1 ELSE 0 END) AS zosyn_adm,
      MAX(CASE WHEN drug = 'vanco' AND drugstartoffset BETWEEN -720 AND 720 THEN 1 ELSE 0 END) AS vanco_adm,
      MAX(CASE WHEN drug = 'cefepime' AND drugstartoffset BETWEEN -720 AND 720 THEN 1 ELSE 0 END) AS cefepime_adm,
      MAX(CASE WHEN drug = 'zosyn' AND drugstartoffset BETWEEN -720 AND 10080 THEN 1 ELSE 0 END) AS zosyn_wk,
      MAX(CASE WHEN drug = 'vanco' AND drugstartoffset BETWEEN -720 AND 10080 THEN 1 ELSE 0 END) AS vanco_wk,
      MAX(CASE WHEN drug = 'cefepime' AND drugstartoffset BETWEEN -720 AND 10080 THEN 1 ELSE 0 END) AS cefepime_wk
    FROM drugs_tb 
    WHERE patientunitstayid NOT IN (SELECT DISTINCT patientunitstayid FROM drugs_tb WHERE drugstartoffset = 0)
    GROUP BY patientunitstayid
),

SELECT
  patientunitstayid
  , flags
FROM cohort

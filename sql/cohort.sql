DROP TABLE IF EXISTS vanco.cohort;
CREATE TABLE vanco.cohort AS
-- Define the cohort used for the vanco study
WITH 
-- define valid stays as at least 1 hour
-- filters out many administrative stays
valid_stay AS
(
    SELECT patientunitstayid, hospitalid
    , CASE WHEN unitdischargeoffset >= 60 THEN 0 ELSE 1 END AS exclude_short_stay
    , CASE WHEN unitstaytype = 'stepdown/other' THEN 1 ELSE 0 END AS exclude_sdu
    FROM patient
)
-- figure out which hospitals have at least 80% of patients with a prescription in medication
, med_tb AS (
    SELECT DISTINCT patientunitstayid
    FROM medication
)
, pat_tb AS (
  SELECT pt.hospitalid
    , pt.hospitaldischargeyear as yr
    , CAST(count(DISTINCT m.patientunitstayid) AS NUMERIC) as count_med
    , CAST(count(DISTINCT pt.patientunitstayid) AS NUMERIC) as count_all
  FROM patient pt
  LEFT JOIN med_tb m 
    ON pt.patientunitstayid = m.patientunitstayid
  GROUP BY pt.hospitalid, pt.hospitaldischargeyear
)
, hospitals_tb AS (
    SELECT p.hospitalid, p.yr
        , p.count_med AS patients_med
        , p.count_all AS patients_all
        , p.count_med/p.count_all AS coverage
        , CASE WHEN p.count_med/p.count_all >= 0.8 THEN 0 ELSE 1 END AS exclude_no_med_interface
    FROM pat_tb p
)
-- limit to patients admitted via the ED patients as we know they will not be long term vanco user
, ed AS (
    SELECT patientunitstayid, uniquepid
      , CASE WHEN age = '> 89' THEN 91
             WHEN age = '' THEN NULL
             ELSE CAST(age AS NUMERIC)
        END AS age
      , hospitaladmitoffset
      , hospitaldischargeyear
    FROM patient pt
    WHERE pt.unitAdmitSource IN
    (
        
        -- 'Direct Admit' -- around 5% are direct admits
        'Emergency Department'
    )
    AND pt.hospitaldischargeyear >= 2005
)
-- first stay for a given patient
-- orders patient by temporal identifiers
-- later a join on this filters secondary stays (rn > 1)
, first_stay AS (
  SELECT
    patientunitstayid
    -- orders stays by (1) order during hospitalization, (2) year, (3) age, (4) random identifier
    -- the last sort makes this deterministic, but we guess at the first stay
    , ROW_NUMBER() OVER W as rn
    , COUNT(patientunitstayid) OVER W as n_pt_id
  FROM ed
  WINDOW W AS
    (
      PARTITION BY uniquepid
      ORDER BY hospitaladmitoffset DESC, hospitaldischargeyear, age, patientunitstayid
    )
)
-- must have APACHE-IV score (equivalent to APACHE III score)
, ap AS (
  SELECT patientunitstayid
  FROM apachepatientresult
  WHERE apacheversion = 'IVa'
  AND predictedhospitalmortality IS NOT NULL
  AND predictedhospitalmortality != ''
  AND predictedhospitalmortality != '-1'
)
-- must have creatinine on baseline [-12, 12] and between [48,168]
, cr0 AS (
    SELECT DISTINCT patientunitstayid
    FROM vanco.pivoted_creatinine p1
    WHERE chartoffset >= (-12*60)
    AND chartoffset <= (12*60)
)
, cr7 AS (
    SELECT DISTINCT patientunitstayid
    FROM vanco.pivoted_creatinine p1
    WHERE chartoffset >= (48*60)
    AND chartoffset <= (168*60)
)
SELECT
  pt.patientunitstayid
  , CASE
      WHEN pt.hospitalid >= 1 AND pt.hospitalid <= 55 THEN 1 
      WHEN pt.hospitalid >= 228 AND pt.hospitalid <= 240 THEN 1
      WHEN pt.hospitalid >= 291 AND pt.hospitalid <= 299 THEN 1
      WHEN pt.hospitalid >= 366 AND pt.hospitalid <= 380 THEN 1
    ELSE 0 END AS exclude_corrupt_hospitals
  , CASE WHEN pt.hospitaldischargeyear < 2005 THEN 1 ELSE 0 END AS exclude_before_2005
  , vs.exclude_sdu
  , vs.exclude_short_stay
  , CASE WHEN ed.patientunitstayid IS NULL THEN 1 ELSE 0 END AS exclude_non_ed_admit
  , CASE WHEN fs.patientunitstayid IS NULL THEN 1 ELSE 0 END AS exclude_secondary_stay
  , CASE WHEN ap.patientunitstayid IS NULL THEN 1 ELSE 0 END AS exclude_missing_apache
  , ht.exclude_no_med_interface
  , CASE WHEN dt.chronic_dialysis = 1 THEN 1 ELSE 0 END AS exclude_dialysis_chronic
  , CASE WHEN dt.dialysis = 1 THEN 1 ELSE 0 END AS exclude_dialysis_on_admission
  , CASE WHEN cr0.patientunitstayid IS NULL THEN 1 ELSE 0 END AS exclude_cr_missing_baseline
  , CASE WHEN cr7.patientunitstayid IS NULL THEN 1 ELSE 0 END AS exclude_cr_missing_followup
FROM patient pt
LEFT JOIN vanco.dialysis dt
  ON pt.patientunitstayid = dt.patientunitstayid
LEFT JOIN valid_stay vs
  ON pt.patientunitstayid = vs.patientunitstayid
LEFT JOIN hospitals_tb ht
  ON pt.hospitalid = ht.hospitalid
  AND pt.hospitaldischargeyear = ht.yr
LEFT JOIN ed
  ON pt.patientunitstayid = ed.patientunitstayid
LEFT JOIN first_stay fs
  ON pt.patientunitstayid = fs.patientunitstayid
  AND fs.rn = 1
LEFT JOIN ap
  ON pt.patientunitstayid = ap.patientunitstayid
LEFT JOIN cr0
  ON pt.patientunitstayid = cr0.patientunitstayid
LEFT JOIN cr7
  ON pt.patientunitstayid = cr7.patientunitstayid;

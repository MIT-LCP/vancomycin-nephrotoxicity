-- This query extracts demographic information and apachescore from all e-ICU patient unitstayds.
DROP TABLE IF EXISTS vanco.demographics CASCADE;
CREATE TABLE vanco.demographics AS
WITH apache AS(
  SELECT 
    patientUnitStayID, 
    apacheScore,
    CASE
      WHEN apachescore IS NULL THEN NULL -- NULL indicates that the score was never calculated
      WHEN apachescore = -1 THEN '-1' -- -1 indicates that a score was not given; usually due to exclusions or missing data
      WHEN apachescore < 11 THEN '0-10'
      WHEN apachescore < 21 THEN '11-20'
      WHEN apachescore < 31 THEN '21-30'
      WHEN apachescore < 41 THEN '31-40'
      WHEN apachescore < 51 THEN '41-50'
      WHEN apachescore < 61 THEN '51-60'
      WHEN apachescore < 71 THEN '61-70'
      WHEN apachescore < 81 THEN '71-80'
      WHEN apachescore < 91 THEN '81-90'
      WHEN apachescore < 101 THEN '91-100'
      WHEN apachescore < 111 THEN '101-110'
      WHEN apachescore < 121 THEN '111-120'
      WHEN apachescore < 131 THEN '121-130'
      WHEN apachescore < 141 THEN '131-140'
      WHEN apachescore > 140 THEN '>140'
      ELSE NULL 
    END AS apache_group
  FROM apachepatientresult
  WHERE apacheversion = 'IVa'
),
demographics AS (
  SELECT 
    p.patientUnitStayID, 
    p.age, 
    p.gender,
    CASE WHEN p.ethnicity = '' THEN NULL ELSE p.ethnicity END AS ethnicity,
    w.weight_avg,
    (CASE 
        WHEN p.admissionHeight >90 AND p.admissionHeight <300 THEN p.admissionHeight
        ELSE NULL 
     END) AS height,
    ROUND(CASE 
        WHEN p.admissionHeight >90 AND p.admissionHeight < 300 THEN (10000*w.weight_avg/(p.admissionHeight*p.admissionHeight))
        ELSE NULL 
     END) AS BMI,
    p.unitDischargeOffset,
    apache.apacheScore,
    apache.apache_group
  FROM patient p
  LEFT JOIN vanco.weight w ON w.patientunitstayid = p.patientUnitStayID 
  LEFT JOIN apache ON p.patientUnitStayID = apache.patientUnitStayID
  ORDER BY p.patientUnitStayID  
)
-- categorize BMI values into categories
SELECT 
  patientunitstayid,
  unitdischargeoffset,
  age,
  gender,
  ethnicity,
  weight_avg AS weight,
  height,
  BMI,
  CASE 
    WHEN BMI < 18 THEN 'underweight' 
    WHEN BMI >= 18 AND BMI < 25 THEN 'normal'
    WHEN BMI >= 25 THEN 'overweight' 
    WHEN BMI >= 30 THEN 'obese'
    ELSE NULL 
  END AS BMI_group,
  apachescore,
  apache_group
FROM demographics;
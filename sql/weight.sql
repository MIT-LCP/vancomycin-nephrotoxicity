-- team_i/weight
-- This query extracts weights from four tables: nursecharting, intakeoutput, infusiongdrug, and patient and takes the average of them to improve accuracy of weight and decrease the number of null weights. 
DROP TABLE IF EXISTS vanco.weight CASCADE;
CREATE TABLE vanco.weight AS
with t1 as
(
  select
    patientunitstayid
    -- all of the below weights are measured in kg
    , cast(nursingchartvalue as NUMERIC) as weight
  from nursecharting
  where nursingchartcelltypecat = 'Other Vital Signs and Infusions'
  and nursingchartcelltypevallabel in
  ( 'Admission Weight'
  , 'Admit weight'
  , 'WEIGHT in Kg'
  )
  -- ensure that nursingchartvalue is numeric
  and nursingchartvalue ~ '^([0-9]+\\.?[0-9]*|\\.[0-9]+)$'
  and NURSINGCHARTOFFSET >= -60 and NURSINGCHARTOFFSET < 60*24
)
-- weight from intake/output table
, t2 as
(
  select
    patientunitstayid
    , case when CELLPATH = 'flowsheet|Flowsheet Cell Labels|I&O|Weight|Bodyweight (kg)'
        then CELLVALUENUMERIC
      else CELLVALUENUMERIC*0.453592
    end as weight
  from intakeoutput
  -- there are ~300 extra (lb) measurements, so we include both
  -- worth considering that this biases the median of all three tables towards these values..
  where CELLPATH in
  ( 'flowsheet|Flowsheet Cell Labels|I&O|Weight|Bodyweight (kg)'
  , 'flowsheet|Flowsheet Cell Labels|I&O|Weight|Bodyweight (lb)'
  )
  and INTAKEOUTPUTOFFSET >= -60 and INTAKEOUTPUTOFFSET < 60*24
)
-- weight from infusiondrug
, t3 as
(
  select
    patientunitstayid
    , cast(patientweight as NUMERIC) as weight
  from infusiondrug
  where patientweight is not null
  AND patientweight != ''
  and INFUSIONOFFSET >= -60 and INFUSIONOFFSET < 60*24
)
, unioned AS (
SELECT patientunitstayid, admissionweight AS weight
FROM patient pt
UNION ALL 
SELECT patientunitstayid, weight
FROM t1
UNION ALL
SELECT patientunitstayid, weight
FROM t2
UNION ALL
SELECT patientunitstayid, weight
FROM t3
)
select
  patientunitstayid
  , ROUND(AVG(weight), 2) as weight_avg
from unioned
WHERE weight >= 30 and weight <= 300
GROUP BY patientunitstayid
ORDER BY patientunitstayid

-- get all creatinines for a single patientunitstayid
DROP TABLE IF EXISTS vanco.creatinine_stg CASCADE;
CREATE TABLE vanco.creatinine_stg AS
select
  pt.patienthealthsystemstayid
  , pt.patientunitstayid
  , labresultoffset as chartoffset
  , labresult as creatinine
from 
-- get the last lab to be revised
(
  select
      lab.patientunitstayid
    , lab.labname
    , lab.labresultoffset
    , lab.labresultrevisedoffset
    , lab.labresult
    , ROW_NUMBER() OVER
        (
          PARTITION BY lab.patientunitstayid, lab.labname, lab.labresultoffset
          ORDER BY lab.labresultrevisedoffset DESC
        ) as rn
  from lab
  WHERE 
    (lab.labname = 'creatinine' and lab.labresult >= 0.1 and lab.labresult <= 28.28)
) vw1
INNER JOIN patient pt
  ON vw1.patientunitstayid = pt.patientunitstayid
where rn = 1
ORDER BY patienthealthsystemstayid, patientunitstayid, chartoffset;

-- copy lab measurements so that out of ICU labs occur for each patientunitstayid
-- e.g. if there are two ICU stays in one hosp, this makes sure creatinine data
-- across the entire hospitalization is stored with the patientunitstayid for both ICU stays
-- patienthealthsystemstayid == 86 is a good test case
DROP TABLE IF EXISTS vanco.pivoted_creatinine CASCADE;
CREATE TABLE vanco.pivoted_creatinine as
-- remove duplicate labs if they exist at the same time
SELECT
  pt_h.patienthealthsystemstayid
  , pt_h.patientunitstayid
  -- adjust chartoffset to match the current patient
  , cr.chartoffset + (pt.hospitaldischargeoffset - pt_h.hospitaldischargeoffset) as chartoffset
  , cr.creatinine
FROM vanco.creatinine_stg cr
-- get the patient's current hosp disch offset
INNER JOIN patient pt
  ON cr.patientunitstayid = pt.patientunitstayid
-- now associate all creatinine measurements with a given hospitalization  
INNER JOIN patient pt_h
  ON cr.patienthealthsystemstayid = pt_h.patienthealthsystemstayid
ORDER BY cr.patienthealthsystemstayid, cr.patientunitstayid, chartoffset;
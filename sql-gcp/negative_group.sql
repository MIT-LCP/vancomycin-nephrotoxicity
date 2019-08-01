SELECT patientunitstayid FROM `physionet-data.eicu_crd.intakeoutput`  
WHERE LOWER(celllabel) NOT LIKE '%vanco%'
AND LOWER(cellpath) NOT LIKE '%vanco%'
UNION DISTINCT
SELECT patientunitstayid FROM `physionet-data.eicu_crd.lab`  
WHERE LOWER(labname) NOT LIKE '%vanco%'
UNION DISTINCT
SELECT patientunitstayid FROM `physionet-data.eicu_crd.medication`   
WHERE LOWER(drugname) NOT LIKE '%vanco%'

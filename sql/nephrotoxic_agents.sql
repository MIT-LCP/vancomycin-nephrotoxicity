DROP TABLE IF EXISTS vanco.nephrotoxic_agents;
CREATE TABLE vanco.nephrotoxic_agents AS
WITH contrast AS (
	SELECT 
		patientunitstayid
		, MIN(treatmentoffset) AS contrastoffset
	FROM treatment trt
	WHERE treatmentstring IN (
	'pulmonary|radiologic procedures / bronchoscopy|CT scan|with contrast'
	, 'gastrointestinal|radiology, diagnostic and procedures|CT scan|with IV contrast'
	, 'neurologic|procedures / diagnostics|head CT scan|with contrast'
	, 'burns/trauma|trauma|CT scan|with contrast'
	, 'infectious diseases|procedures|CT scan|with contrast'
	, 'hematology|oncological issues|CT scan|with contrast'
	, 'endocrine|diagnostic studies|CT scan|with contrast')
	AND treatmentoffset BETWEEN (-12*60.) AND (7*24*60.)
	GROUP BY patientunitstayid
)
, nsaids AS (
	SELECT 
		patientunitstayid
		, MIN(drugstartoffset) AS nsaidoffset
	FROM medication med 
	WHERE (drughiclseqno IN (1820, 3723, 5175) 
    OR LOWER(drugname) LIKE '%aspirin%' 
    OR LOWER(drugname) LIKE '%ibuprofen%' 
    OR LOWER(drugname) LIKE '%ketorolac%'
    OR LOWER(drugname) LIKE '%ecotrin%'
    OR LOWER(drugname) LIKE '%motrin%'
    OR LOWER(drugname) LIKE '%toradol%')
    AND (drugstartoffset BETWEEN (-12*60.) AND (7*24*60.))
    GROUP BY patientunitstayid
)
-- calcineurin inhibitors (cyclosporine, tacrolimus)
, calci_inh AS ( 
	SELECT 
		patientunitstayid
		, MIN(drugstartoffset) AS calcioffset
	FROM medication med 
	WHERE (LOWER(drugname) LIKE '%tacrolimus%'
    OR drughiclseqno = 20974 
    OR drughiclseqno = 8974)
    AND (drugstartoffset BETWEEN (-12*60.) AND (7*24*60.))
    GROUP BY patientunitstayid
)
, pressors AS (
	SELECT 
		patientunitstayid
		, MIN(drugstartoffset) AS pressoroffset 
	FROM medication med 
	WHERE drughiclseqno IN (2050, 2051, 2059, 2060, 2087, 2839, 34361, 35517, 35587, 36346, 36437) 
    OR LOWER(drugname) LIKE '%norepinephrine%' 
    OR LOWER(drugname) LIKE '%epinephrine%'
    OR LOWER(drugname) LIKE '%dopamine%'
    OR LOWER(drugname) LIKE '%phenylephrine%'
    OR LOWER(drugname) LIKE '%vasopressin%'
    OR LOWER(drugname) LIKE '%levophed%'
    OR LOWER(drugname) LIKE '%synephrine%'
    OR LOWER(drugname) LIKE '%dobutamine%'
    AND (drugstartoffset BETWEEN (-12*60.) AND (7*24*60.))
    GROUP BY patientunitstayid
)

SELECT COALESCE(c.patientunitstayid, n.patientunitstayid, ci.patientunitstayid, p.patientunitstayid) AS patientunitstayid
	, c.contrastoffset
	, n.nsaidoffset
	, ci.calcioffset
	, p.pressoroffset
	, 1 AS nephrotoxic_exp
FROM contrast c 
FULL OUTER JOIN nsaids n ON c.patientunitstayid = n.patientunitstayid 
FULL OUTER JOIN calci_inh ci ON c.patientunitstayid = ci.patientunitstayid
FULL OUTER JOIN pressors p ON c.patientunitstayid = p.patientunitstayid

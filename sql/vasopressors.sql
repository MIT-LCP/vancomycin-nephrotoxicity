DROP TABLE IF EXISTS vanco.vasopressors;
CREATE TABLE vanco.vasopressors AS
SELECT 
  patientunitstayid,
  CASE 
      WHEN drugstopoffset = 0 THEN drugstartoffset
      WHEN drugstartoffset <= drugstopoffset THEN drugstartoffset
      WHEN drugstopoffset < drugstartoffset THEN drugstopoffset
  END AS drugstartoffset,
  CASE 
      WHEN drugstopoffset = 0 THEN NULL
      WHEN drugstartoffset <= drugstopoffset THEN drugstopoffset
      WHEN drugstopoffset < drugstartoffset THEN drugstartoffset
  END AS drugstopoffset,
  drugorderoffset,
  CASE
    WHEN drughiclseqno IN (37410, 36346, 2051) OR lower(drugname) LIKE '%norepinephrine%'
        THEN 'norepinephrine'
    WHEN drughiclseqno IN (37407, 39089, 36437, 34361, 2050) OR (lower(drugname) like '%epinephrine%' AND lower(drugname) NOT LIKE '%nor%epinephrine%')
        THEN 'epinephrine'
    WHEN drughiclseqno IN (2060, 2059) OR lower(drugname) LIKE '%dopamine%'
        THEN 'dopamine'
    WHEN drughiclseqno IN (37028, 35517, 35587, 2087) OR lower(drugname) LIKE '%phenylephrine%'
        THEN 'phenylephrine'
    WHEN drughiclseqno IN (38884, 38883, 2839) OR lower(drugname) LIKE '%vasopressin%'
        THEN 'vasopressin'
    WHEN drughiclseqno IN (9744) OR lower(drugname) LIKE '%milrinone%'
        THEN 'milrinone'
    WHEN drughiclseqno IN (8777, 40) OR lower(drugname) LIKE '%dobutamine%'
        THEN 'dobutamine'
    WHEN drughiclseqno = 2053 OR lower(drugname) LIKE '%isuprel%' OR lower(drugname) LIKE '%isoproterenol%'
        THEN 'isuprel'
  ELSE NULL END AS drug,
  m.frequency,
  map.classification,
  m.dosage
FROM medication m
INNER JOIN vanco.abx_route ro
  on m.routeadmin = ro.routeadmin
LEFT JOIN vanco.medication_frequency_map map
  on m.frequency = map.frequency
WHERE
-- vasopressors only
   drughiclseqno IN (37410, 36346, 2051) OR lower(drugname) LIKE '%norepinephrine%'
OR drughiclseqno IN (37407, 39089, 36437, 34361, 2050) OR (lower(drugname) like '%epinephrine%' AND lower(drugname) NOT LIKE '%nor%epinephrine%')
OR drughiclseqno IN (2060, 2059) OR lower(drugname) LIKE '%dopamine%'
OR drughiclseqno IN (37028, 35517, 35587, 2087) OR lower(drugname) LIKE '%phenylephrine%'
OR drughiclseqno IN (38884, 38883, 2839) OR lower(drugname) LIKE '%vasopressin%'
OR drughiclseqno IN (9744) OR lower(drugname) LIKE '%milrinone%'
OR drughiclseqno IN (8777, 40) OR lower(drugname) LIKE '%dobutamine%'
OR drughiclseqno = 2053 OR lower(drugname) LIKE '%isuprel%' OR lower(drugname) LIKE '%isoproterenol%'
-- other filters
AND drugordercancelled = 'No'
AND prn = 'No'
AND COALESCE(map.classification, '') NOT IN
(
  'TPN', 'dialysis', 'prophylactic', 'prn'
)
AND lower(m.frequency) NOT LIKE '%dialysis%'
AND lower(m.frequency) NOT LIKE '%prn%'
AND lower(m.frequency) NOT LIKE '%tpn%'
-- reasonably systemic administrations only
AND ro.code IN
(
  -- IV
  'IV', 'IVCC', 'IVCI', 'IVINJ', 'IVINJBOL', 'IVPB', 'IVPUSH'
)
ORDER BY patientunitstayid, drugstartoffset;
DROP TABLE IF EXISTS vanco.vanco;
CREATE TABLE vanco.vanco AS
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
  m.frequency,
  map.classification,
  dosage
FROM medication m
INNER JOIN vanco.abx_route ro
  on m.routeadmin = ro.routeadmin
LEFT JOIN vanco.medication_frequency_map map
  on m.frequency = map.frequency
WHERE 
  (drughiclseqno IN (4042, 10093, 8466, 37442) OR LOWER(drugname) LIKE '%vanco%')
-- only IV administrations
AND ro.code IN
(
  'IV', 'IVCC', 'IVCI', 'IVINJ', 'IVINJBOL', 'IVPB', 'IVPUSH'
)
AND drugordercancelled = 'No'
AND prn = 'No'
AND COALESCE(map.classification, '') NOT IN
(
  'TPN', 'dialysis', 'prophylactic', 'prn'
)
AND lower(m.frequency) NOT LIKE '%dialysis%'
AND lower(m.frequency) NOT LIKE '%prn%'
AND lower(m.frequency) NOT LIKE '%tpn%'
ORDER BY patientunitstayid, drugstartoffset;
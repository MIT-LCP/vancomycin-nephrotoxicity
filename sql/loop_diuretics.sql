DROP TABLE IF EXISTS vanco.loop_diuretics;
CREATE TABLE vanco.loop_diuretics AS
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
    WHEN
      (drughiclseqno = 3660 OR lower(drugname) like '%lasix%' OR lower(drugname) like '%furosemide%')
        THEN 'lasix'
    WHEN
      (drughiclseqno = 3664 OR lower(drugname) like '%bumex%' OR lower(drugname) like '%bumetanide%')
        THEN 'bumex'
  ELSE NULL END AS drug,
  m.frequency,
  map.classification,
  dosage
FROM medication m
LEFT JOIN vanco.medication_frequency_map map
  on m.frequency = map.frequency
WHERE 
  (drughiclseqno = 3660 OR lower(drugname) like '%lasix%' OR lower(drugname) like '%furosemide%')
OR
  (drughiclseqno = 3664 OR lower(drugname) like '%bumex%' OR lower(drugname) like '%bumetanide%')
AND drugordercancelled = 'No'
AND prn = 'No'
AND COALESCE(map.classification, '') NOT IN ('prn')
AND lower(m.frequency) NOT LIKE '%prn%'
ORDER BY patientunitstayid, drugstartoffset;
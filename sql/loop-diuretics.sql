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
        THEN 'aspirin'
    WHEN
      (drughiclseqno = 3664 OR lower(drugname) like '%bumex%' OR lower(drugname) like '%bumetanide%')
        THEN 'ibuprofen'
  ELSE NULL END AS drug,
  m.frequency,
  map.classification,
  dosage
FROM `physionet-data.eicu_crd.medication` m
LEFT JOIN `lcp-internal.vanco.medication_frequency_map` map
  on m.frequency = map.frequency
WHERE 
  (drughiclseqno = 3660 OR lower(drugname) like '%lasix%' OR lower(drugname) like '%furosemide%')
OR
  (drughiclseqno = 3664 OR lower(drugname) like '%bumex%' OR lower(drugname) like '%bumetanide%')
AND drugordercancelled = 'No'
AND prn = 'No'
ORDER BY patientunitstayid, drugstartoffset;
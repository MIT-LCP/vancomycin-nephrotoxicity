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
      (drughiclseqno = 1820 OR lower(drugname) like '%aspirin%' OR lower(drugname) like '%ecotrin%')
        THEN 'aspirin'
    WHEN
      (drughiclseqno = 3723 OR lower(drugname) like '%ibuprofen%' OR lower(drugname) like '%motrin%')
        THEN 'ibuprofen'
    WHEN
      (drughiclseqno = 5175 OR lower(drugname) like '%toradol%' OR lower(drugname) like '%ketorolac%')
        THEN 'toradol'
  ELSE NULL END AS drug,
  m.frequency,
  map.classification,
  dosage
FROM `physionet-data.eicu_crd.medication` m
LEFT JOIN `lcp-internal.vanco.medication_frequency_map` map
  on m.frequency = map.frequency
WHERE 
  -- aspirin
  (drughiclseqno = 1820 OR lower(drugname) like '%aspirin%' OR lower(drugname) like '%ecotrin%')
OR
  -- ibuprofen
  (drughiclseqno = 3723 OR lower(drugname) like '%ibuprofen%' OR lower(drugname) like '%motrin%')
OR
  -- toradol
  (drughiclseqno = 5175 OR lower(drugname) like '%toradol%' OR lower(drugname) like '%ketorolac%')
AND drugordercancelled = 'No'
AND prn = 'No'
ORDER BY patientunitstayid, drugstartoffset;
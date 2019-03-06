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
FROM `physionet-data.eicu_crd.medication` m
LEFT JOIN `lcp-internal.vanco.medication_frequency_map` map
  on m.frequency = map.frequency
WHERE 
  (drughiclseqno IN (8738, 32900, 33427) OR lower(drugname) like '%zosyn%' OR lower(drugname) like '%piperacillin%tazo%')
AND routeadmin IN (
  'IV', 
  'Intravenous', 
  'INTRAVENOU', 
  'INTRAVEN', 
  'IntraVENOUS', 
  'IV (intravenous)                                                                                    ', 
  'INTRAVENOUS',
  'IV - brief infusion (intravenous)                                                                   ',
  'PERIPH IV',
  'IV Push'
)
AND drugordercancelled = 'No'
AND prn = 'No'
AND map.classification NOT IN
(
  'TPN', 'dialysis', 'prophylactic'
)
ORDER BY patientunitstayid, drugstartoffset;
DROP TABLE IF EXISTS vanco.calcineurin_inhibitors;
CREATE TABLE vanco.calcineurin_inhibitors AS
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
      (drughiclseqno IN (4524, 10086) OR lower(drugname) like '%cyclosporine%' OR lower(drugname) like '%neoral%' OR LOWER(drugname) LIKE '%sandimmune%')
        THEN 'cyclosporine'
    WHEN
      (drughiclseqno IN (8974, 20974) OR lower(drugname) like '%tacrolimus%' OR lower(drugname) like '%prograf%')
        THEN 'tacrolimus'
    -- excluding 23167, pimecrolimus, as it is a cream
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
-- include all calcineurin inhibitors
(
   drughiclseqno IN (4524, 10086)
   OR lower(drugname) like '%cyclosporine%'
   OR lower(drugname) like '%neoral%'
   OR LOWER(drugname) LIKE '%sandimmune%'
   OR drughiclseqno IN (8974, 20974)
   OR lower(drugname) like '%tacrolimus%'
   OR lower(drugname) like '%prograf%'
)
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
AND LOWER(ro.routeadmin) NOT LIKE '%topical%'
AND ro.code IN
(
  -- IV
  'IV', 'IVCC', 'IVCI', 'IVINJ', 'IVINJBOL', 'IVPB', 'IVPUSH'
  -- oral
)
ORDER BY patientunitstayid, drugstartoffset;

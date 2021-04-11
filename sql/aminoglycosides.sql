DROP TABLE IF EXISTS vanco.aminoglycosides;
CREATE TABLE vanco.aminoglycosides AS
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
      (drughiclseqno IN (4035,35990) OR lower(drugname) like '%amikacin%' OR lower(drugname) like '%amikin%')
        THEN 'amikacin'
    WHEN
      (drughiclseqno IN (4030,4032,33290,34362) OR lower(drugname) like '%gentamicin%' OR lower(drugname) like '%garamycin%')
        THEN 'gentamicin'
    WHEN
      (drughiclseqno = 4027 OR lower(drugname) like '%streptomycin%')
        THEN 'streptomycin'
    WHEN
      (drughiclseqno IN (4029, 4258) OR lower(drugname) like '%neomycin%' OR lower(drugname) like '%fradin%')
        THEN 'neomycin'
    WHEN
      (drughiclseqno IN (3532,4034,5887,17765,39399) OR lower(drugname) like '%tobramycin%' OR lower(drugname) like '%tobrex%')
        THEN 'tobramycin'
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
-- include all aminoglycosides
(
    drughiclseqno IN (4035, 35990)
  OR LOWER(drugname) LIKE '%amikacin%'
  OR LOWER(drugname) LIKE '%amikin%'
  OR drughiclseqno IN (4030,4032,33290,34362)
  OR lower(drugname) like '%gentamicin%'
  OR lower(drugname) like '%garamycin%'
  OR drughiclseqno = 4027
  OR lower(drugname) like '%streptomycin%'
  OR drughiclseqno IN (4029, 4258)
  OR lower(drugname) like '%neomycin%'
  OR lower(drugname) like '%fradin%'
  OR drughiclseqno IN (3532,4034,5887,17765,39399)
  OR lower(drugname) like '%tobramycin%'
  OR lower(drugname) like '%tobrex%'
)
-- filter out topical treatments
AND LOWER(ro.routeadmin) NOT LIKE '%topical%'
AND m.drughiclseqno NOT IN (
    3363, 3383, 4258, 25197, -- neomycin, topical
    3368, -- neomycin, optic/aural
    3519, 3523, -- neomycin, optical ointment
    3530 -- gentamicin/prednisolone opth drops
)
AND LOWER(drugname) NOT LIKE '%neo-poly-baci%'
AND LOWER(drugname) NOT LIKE '%neosporin%'
AND LOWER(drugname) NOT LIKE '%neomycin%bacit%polym%'
AND LOWER(drugname) NOT IN ('TRIBIOTIC OINTMENT', 'TRIPLE ANTIBIOTIC (UD) OINT')
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
  -- oral
)
ORDER BY patientunitstayid, drugstartoffset;

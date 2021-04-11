DROP TABLE IF EXISTS vanco.nsaids;
CREATE TABLE vanco.nsaids AS
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
      (drughiclseqno IN (3733, 20420) OR lower(drugname) like '%diclofenac%' OR lower(drugname) like '%voltaren%')
        THEN 'diclofenac'
    WHEN
      (drughiclseqno IN (5175) OR lower(drugname) like '%ketorolac%' OR lower(drugname) like '%acular%' OR lower(drugname) like '%toradol%')
        THEN 'ketorolac'
    WHEN
      (drughiclseqno IN (18979) OR lower(drugname) like '%celecoxib%' OR lower(drugname) like '%celebrex%')
        THEN 'celecoxib'
    WHEN
      (drughiclseqno IN (3719) OR lower(drugname) like '%indomethacin%' OR lower(drugname) like '%indocin%')
        THEN 'indomethacin'
    WHEN
      (drughiclseqno IN (3727) OR lower(drugname) like '%naproxen%' OR lower(drugname) like '%naprosyn%')
        THEN 'naproxen'
    WHEN
      (drughiclseqno IN (12181) OR lower(drugname) like '%meloxicam%' OR lower(drugname) like '%mobic%')
        THEN 'meloxicam'
    WHEN
      (drughiclseqno IN (3732) OR lower(drugname) like '%piroxicam%' OR lower(drugname) like '%feldene%')
        THEN 'piroxicam'
  ELSE NULL END AS drug,
  m.frequency,
  map.classification,
  dosage
FROM medication m
LEFT JOIN vanco.medication_frequency_map map
  on m.frequency = map.frequency
WHERE -- aspirin
  (drughiclseqno = 1820 OR lower(drugname) like '%aspirin%' OR lower(drugname) like '%ecotrin%')
OR -- ibuprofen
  (drughiclseqno = 3723 OR lower(drugname) like '%ibuprofen%' OR lower(drugname) like '%motrin%')
OR -- toradol
  (drughiclseqno IN (5175) OR lower(drugname) like '%ketorolac%' OR lower(drugname) like '%acular%' OR lower(drugname) like '%toradol%')
OR -- diclofenac
  (drughiclseqno IN (3733, 20420) OR lower(drugname) like '%diclofenac%' OR lower(drugname) like '%voltaren%')
OR -- celecoxib
  (drughiclseqno IN (18979) OR lower(drugname) like '%celecoxib%' OR lower(drugname) like '%celebrex%')
OR -- indomethacin
  (drughiclseqno IN (3719) OR lower(drugname) like '%indomethacin%' OR lower(drugname) like '%indocin%')
OR -- naproxen
  (drughiclseqno IN (3727) OR lower(drugname) like '%naproxen%' OR lower(drugname) like '%naprosyn%')
OR -- meloxicam
  (drughiclseqno IN (12181) OR lower(drugname) like '%meloxicam%' OR lower(drugname) like '%mobic%')
OR -- piroxicam
  (drughiclseqno IN (3732) OR lower(drugname) like '%piroxicam%' OR lower(drugname) like '%feldene%')
AND drugordercancelled = 'No'
AND prn = 'No'
AND COALESCE(map.classification, '') NOT IN ('prn')
AND lower(m.frequency) NOT LIKE '%prn%'
ORDER BY patientunitstayid, drugstartoffset;
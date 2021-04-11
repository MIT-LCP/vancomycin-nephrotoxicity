DROP TABLE IF EXISTS vanco.antivirals;
CREATE TABLE vanco.antivirals AS
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
CASE
WHEN
    (drughiclseqno IN (4182, 4183, 10117) OR lower(drugname) like '%acyclovir%' OR lower(drugname) like '%zovirax%')
    THEN 'acyclovir'
WHEN
    (drughiclseqno IN (13221) OR lower(drugname) like '%foscarnet%' OR lower(drugname) like '%foscavir%')
    THEN 'foscarnet'
WHEN
    (drughiclseqno IN (22937, 26515, 33888, 37822) OR lower(drugname) like '%tenofovir%' OR lower(drugname) like '%viread%' OR lower(drugname) like '%atripla%' OR lower(drugname) LIKE '%truvada%')
    THEN 'tenofovir'
WHEN
    (drughiclseqno IN (10683) OR lower(drugname) like '%indinavir%' OR lower(drugname) like '%crixivan%')
    THEN 'indinavir'
ELSE NULL END AS drug,
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
    drughiclseqno IN (4182, 4183, 10117)
OR LOWER(drugname) LIKE '%acyclovir%'
OR LOWER(drugname) LIKE '%zovirax%'
OR drughiclseqno IN (13221)
OR lower(drugname) like '%foscarnet%'
OR lower(drugname) like '%foscavir%'
OR drughiclseqno IN (22937, 26515, 33888, 37822)
OR lower(drugname) like '%tenofovir%'
OR lower(drugname) like '%viread%'
OR lower(drugname) like '%atripla%'
OR lower(drugname) LIKE '%truvada%'
OR drughiclseqno IN (10683)
OR lower(drugname) like '%indinavir%'
OR lower(drugname) like '%crixivan%'
AND drugordercancelled = 'No'
AND prn = 'No'
AND COALESCE(map.classification, '') NOT IN
(
'TPN', 'dialysis', 'prophylactic', 'prn'
)
AND lower(m.frequency) NOT LIKE '%dialysis%'
AND lower(m.frequency) NOT LIKE '%prn%'
AND lower(m.frequency) NOT LIKE '%tpn%'
-- only IV administrations
AND ro.code IN
(
'IV', 'IVCC', 'IVCI', 'IVINJ', 'IVINJBOL', 'IVPB', 'IVPUSH'
);
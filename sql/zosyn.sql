
zosyn_pt AS (
  SELECT DISTINCT 
        CASE 
            WHEN drugstartoffset <= drugstopoffset THEN drugstartoffset
            WHEN drugstopoffset < drugstartoffset THEN drugstopoffset
        END AS drugstartoffset,
        CASE 
            WHEN drugstartoffset <= drugstopoffset THEN drugstopoffset
            WHEN drugstopoffset < drugstartoffset THEN drugstartoffset
        END AS drugstopoffset,
        patientunitstayid
  FROM `physionet-data.eicu_crd.medication` 
  WHERE (drughiclseqno IN (8738, 32900, 33427)
  OR lower(drugname) like '%zosyn%'
  OR lower(drugname) like '%piperacillin%tazo%')
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
  AND patientunitstayid IN (
      SELECT patientunitstayid FROM `physionet-data.eicu_crd.patient` 
      WHERE hospitalid IN (SELECT hospitalid FROM hospitals_tb)
    )
),
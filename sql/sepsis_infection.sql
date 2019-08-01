-- Extracts sepsis/infection/HIV status from first 24 hours of patient stay
DROP TABLE IF EXISTS vanco.sepsis_infection;
CREATE TABLE vanco.sepsis_infection AS
WITH dx AS
(
  select
    dx.patientunitstayid
    , max(case when category = 'sepsis' then 1 else 0 end) as sepsis
    , max(case when category = 'infection' then 1 else 0 end) as infection
    , max(case when category = 'organfailure' then 1 else 0 end) as organfailure
    -- soft tissue infection
    , MAX(
        CASE WHEN dx.diagnosisstring IN (
            'burns/trauma|dermatology|cellulitis',
            'burns/trauma|dermatology|rash, infectious',
            'burns/trauma|dermatology|rash, infectious|purulent dermatitis',
            'infectious diseases|GI infections|abscess of wound',
            'infectious diseases|head and neck infections|abscess - head and neck',
            'infectious diseases|head and neck infections|abscess - head and neck|ludwig''s angina',
            'infectious diseases|head and neck infections|abscess - head and neck|ludwig''s angina|with airway compromise',
            'infectious diseases|head and neck infections|abscess - head and neck|malignant otitis externa',
            'infectious diseases|head and neck infections|abscess - head and neck|orbital',
            'infectious diseases|head and neck infections|abscess - head and neck|orbital|with associated cellulitis',
            'infectious diseases|skin, bone and joint infections|cellulitis',
            'infectious diseases|skin, bone and joint infections|cellulitis|abdomen/pelvis',
            'infectious diseases|skin, bone and joint infections|cellulitis|chest',
            'infectious diseases|skin, bone and joint infections|cellulitis|extremity',
            'infectious diseases|skin, bone and joint infections|cellulitis|head and neck',
            'infectious diseases|skin, bone and joint infections|cellulitis|head and neck|periorbital',
            'infectious diseases|skin, bone and joint infections|diabetic foot infection',
            'infectious diseases|skin, bone and joint infections|diabetic foot infection|with gangrene',
            'infectious diseases|skin, bone and joint infections|diabetic foot infection|without gangrene',
            'infectious diseases|skin, bone and joint infections|infected pressure ulcer',
            'infectious diseases|skin, bone and joint infections|infectious dermatitis',
            'infectious diseases|skin, bone and joint infections|infectious dermatitis|candidal',
            'infectious diseases|skin, bone and joint infections|infectious dermatitis|pyogenic',
            'infectious diseases|skin, bone and joint infections|infectious organisms',
            'infectious diseases|skin, bone and joint infections|local skin infection',
            'infectious diseases|skin, bone and joint infections|lymphadenitis, acute',
            'infectious diseases|skin, bone and joint infections|necrotizing fasciitis',
            'infectious diseases|skin, bone and joint infections|necrotizing fasciitis|abdomen/pelvis',
            'infectious diseases|skin, bone and joint infections|necrotizing fasciitis|chest',
            'infectious diseases|skin, bone and joint infections|necrotizing fasciitis|extremity',
            'infectious diseases|skin, bone and joint infections|necrotizing fasciitis|head and neck',
            'infectious diseases|skin, bone and joint infections|necrotizing fasciitis|post-op',
            'infectious diseases|skin, bone and joint infections|necrotizing fasciitis|scrotal area',
            'infectious diseases|skin, bone and joint infections|necrotizing fasciitis|wound-associated',
            'infectious diseases|skin, bone and joint infections|wound infection',
            'infectious diseases|skin, bone and joint infections|wound infection|surgical wound',
            'infectious diseases|skin, bone and joint infections|wound infection|traumatic wound',
            'infectious diseases|systemic/other infections|bacteremia|skin or wound source',
            'infectious diseases|systemic/other infections|toxic shock syndrome',
            'infectious diseases|systemic/other infections|toxic shock syndrome|group A streptococcus',
            'infectious diseases|systemic/other infections|toxic shock syndrome|staphylococcus aureus',
            'surgery|cardiac surgery|sternotomy problems|localized wound infection',
            'surgery|infections|abscess of wound',
            'surgery|infections|cellulitis',
            'surgery|infections|cellulitis|abdomen/pelvis',
            'surgery|infections|cellulitis|chest',
            'surgery|infections|cellulitis|extremity',
            'surgery|infections|cellulitis|head and neck',
            'surgery|infections|necrotizing fasciitis',
            'surgery|infections|necrotizing fasciitis|abdomen/pelvis',
            'surgery|infections|necrotizing fasciitis|chest',
            'surgery|infections|necrotizing fasciitis|extremity',
            'surgery|infections|necrotizing fasciitis|head and neck',
            'surgery|infections|necrotizing fasciitis|post-op',
            'surgery|infections|necrotizing fasciitis|scrotal area',
            'surgery|infections|necrotizing fasciitis|wound-associated',
            'surgery|infections|wound infection',
            'surgery|infections|wound infection|surgical wound',
            'surgery|infections|wound infection|traumatic wound'
        ) THEN 1 ELSE 0
    END) AS isst
  from diagnosis dx
  left join vanco.dx_sepsis_infection dxlist
    on dx.diagnosisstring = dxlist.dx
  where diagnosisoffset >= -60 and diagnosisoffset < 60*24
  group by dx.patientunitstayid
)
, admit_dx AS
(
  select
    apv.patientunitstayid
    , max(case when apv.admitdiagnosis in
    (
         'SEPSISCUT' -- APACHE Disease: SEPSISCUT.   Description:  Sepsis, cutaneous/soft tissue
        ,'SEPSISGI' -- APACHE Disease: SEPSISGI.   Description:   Sepsis, GI
        ,'SEPSISGYN' -- APACHE Disease: SEPTICUT.   Description:   Sepsis, gynecologic
        ,'SEPSISOTH' -- APACHE Disease: SEPSISOTH.   Description:   Sepsis, other
        ,'SEPSISPULM' -- APACHE Disease: SEPSISPULM.   Description:   Sepsis, pulmonary
        ,'SEPSISUNK' -- APACHE Disease: SEPSISUNK.   Description:   Sepsis, unknown
        ,'SEPSISUTI' -- APACHE Disease: SEPTICUT.   Description:   Sepsis, renal/UTI (including bladder
    ) THEN 1 ELSE 0
    END) AS sepsis
    , max(case when apv.admitdiagnosis in
    (
         'PERICARDIT' -- APACHE Disease: CV-OTHER.   Description:  Pericarditis
        ,'SEPSISCUT' -- APACHE Disease: SEPSISCUT.   Description:  Sepsis, cutaneous/soft tissue
        ,'SEPSISGI' -- APACHE Disease: SEPSISGI.   Description:   Sepsis, GI
        ,'SEPSISGYN' -- APACHE Disease: SEPTICUT.   Description:   Sepsis, gynecologic
        ,'SEPSISOTH' -- APACHE Disease: SEPSISOTH.   Description:   Sepsis, other
        ,'SEPSISPULM' -- APACHE Disease: SEPSISPULM.   Description:   Sepsis, pulmonary
        ,'SEPSISUNK' -- APACHE Disease: SEPSISUNK.   Description:   Sepsis, unknown
        ,'SEPSISUTI' -- APACHE Disease: SEPTICUT.   Description:   Sepsis, renal/UTI (including bladder
        ,'S-APPENDIX' -- APACHE Disease: S-GIOTHER.   Description:   Appendectomy
        ,'PERITONIT' -- APACHE Disease: GI-INFLAM.   Description:   Peritonitis
        ,'S-GIABSCYS' -- APACHE Disease: S-GIABCES.   Description:  GI Abscess/cyst-primary, surgery for (for complications of GI surgery see below)
        ,'S-GICOMPL' -- APACHE Disease: S-GIOTHER.   Description:  Complications of previous GI surgery; surgery for (anastomotic leak, bleeding, abscess, infection, dehiscence, etc.)
        ,'S-GIFISTAB' -- APACHE Disease: S-GIABCES.   Description:  Fistula/abscess, surgery for (not inflammatory bowel disease)
        ,'GIABSCYST' -- APACHE Disease: GI-INFLAM.   Description:  GI Abscess/cyst
        ,'S-GIPERFOR' -- APACHE Disease: S-GIPERF.   Description:  GI Perforation/rupture, surgery for
        ,'S-PERITON' -- APACHE Disease: S-GIPERF.   Description:  Peritonitis, surgery for
        ,'S-GIABSCYS' -- APACHE Disease: S-GIABCES.   Description:  GI Abscess/cyst-primary, surgery for (for complications of GI surgery see below)
        ,'RENINFX' -- APACHE Disease:  REN-OTHER.   Description:  Renal infection/abscess
        ,'CELLULITIS' -- APACHE Disease: PVD.   Description:  Cellulitis and localized soft tissue infections
        ,'SEPARTHRIT' -- APACHE Disease: GEN-OTHER.   Description:  Arthritis, septic
        ,'S-CELLINFX' -- APACHE Disease: S-P/ISCHEM.   Description:  Cellulitis and localized soft tissue infections, surgery for
        ,'MENINGITIS' -- APACHE Disease: NEURO-INFX.   Description:  Meningitis
        ,'NEURABSCES' -- APACHE Disease: NEURO-INFX.   Description:  Abscess, neurologic
        ,'S-CRANINFX' -- APACHE Disease: S-NEUOTHER.   Description:  Abscess/infection-cranial, surgery for
        ,'PNEUMASPIR' -- APACHE Disease: ASP-PNEUM.   Description:  Pneumonia, aspiration
        ,'PNEUMBACT' -- APACHE Disease: BACPNEUM.   Description:  Pneumonia, bacterial
        ,'PNEUMFUNG' -- APACHE Disease: PARA-PNEUM.   Description:  Pneumonia, fungal
        ,'PNEUMOTHER' -- APACHE Disease: BACPNEUM.   Description:  Pneumonia, other
        ,'PNEUMPARAS' -- APACHE Disease: PARA-PNEUM.   Description:  Pneumonia, parasitic (i.e. Pneumocystis pneumonia)
        ,'PNEUMVIRAL' -- APACHE Disease: VIRALPNEUM.   Description:  Pneumonia, viral
        ,'S-OTHINFX' -- APACHE Disease: S-RESPINFX.   Description:  Infection/abscess, other surgery for
    ) THEN 1 ELSE 0
    END) AS infection
    , MAX(CASE WHEN apv.admitdiagnosis IN
    (
         'ACUHEPFAIL' -- 'Hepatic failure, acute' as comment UNION -- APACHE Disease: HEPAT-FAIL.
        ,'ARENFAIL' -- 'Renal failure, acute' as comment UNION -- APACHE Disease: REN-OTHER.
        ,'HEPRENSYN' -- 'Hepato-renal syndrome' as comment UNION -- APACHE Disease: HEPAT-FAIL.
        ,'COAGULOP' -- 'Coagulopathy' as comment UNION -- APACHE Disease: COAG/PENIA.
        ,'THROMBOCYT' -- 'Thrombocytopenia' as comment UNION -- APACHE Disease: COAG/PENIA.
        ,'PANCYTOPEN' -- 'Pancytopenia' as comment UNION -- APACHE Disease: COAG/PENIA.
        ,'COMA' -- 'Coma/change in level of consciousness (for hepatic see GI, for diabetic see Endocrine, if related to cardiac arrest, see CV)' as comment UNION -- APACHE Disease: COMA-M/UNK.
        ,'ENCEPHALOP' -- 'Encephalopathies (excluding hepatic)' as comment UNION -- APACHE Disease: COMA-M/UNK.
        ,'ARDS' -- 'ARDS-adult respiratory distress syndrome, non-cardiogenic pulmonary edema' as comment UNION -- APACHE Disease: PULEDEMA.
        ,'CARDSHOCK' -- 'Shock, cardiogenic' as comment UNION -- APACHE Disease: CARDISHOCK.
        ,'RESPARREST' -- 'Arrest, respiratory (without cardiac arrest)' as comment -- APACHE Disease: RESPARREST.
    ) THEN 1 ELSE 0
    END) AS organfailure
    , MAX(CASE WHEN apv.admitdiagnosis IN
        (
         'CELLULITIS' -- APACHE Disease: PVD.   Description:  Cellulitis and localized soft tissue infections
        ,'S-CELLINFX' -- APACHE Disease: S-P/ISCHEM.   Description:  Cellulitis and localized soft tissue infections, surgery for
        ,'SEPSISCUT' -- APACHE Disease: SEPSISCUT.   Description:  Sepsis, cutaneous/soft tissue
        ) THEN 1 ELSE 0 END) AS isst
  from apachepredvar apv
  group by apv.patientunitstayid
)
SELECT
  pt.patientunitstayid
  , COALESCE(GREATEST(dx.sepsis, adx.sepsis), 0) AS sepsis
  , COALESCE(GREATEST(dx.infection, dx.infection), 0) AS infection
  , COALESCE(GREATEST(dx.organfailure, dx.organfailure), 0) AS organfailure
  , COALESCE(GREATEST(dx.isst, dx.isst), 0) AS infection_skin_soft_tissue
FROM patient pt
LEFT JOIN dx
  ON pt.patientunitstayid = dx.patientunitstayid
LEFT JOIN admit_dx adx
  ON pt.patientunitstayid = adx.patientunitstayid
ORDER BY pt.patientunitstayid;
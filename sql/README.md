# Data extraction

The SQL files in this folder perform all data extraction from eICU-CRD.
You can read more about [eICU-CRD at the documentation website](https://eicu-crd.mit.edu).

eICU-CRD has been loaded into Google BigQuery and is available via the `physionet-data.eicu_crd` schema for those who have correct permissions.
All queries here use this bucket for extracting data.

For convenience, intermediate tables are created on a separate schema on Google BigQuery: the `lcp-internal.vanco` schema.
In order to run the code, the following tables must be generated, and we recommend generating them in this order:

* `physionet-data.eicu_crd_erived.pivoted_creatinine` - see eicu-code GitHub repository for information
* `lcp-internal.vanco.dialysis` - dialysis.sql
* `lcp-internal.vanco.cohort` - cohort.sql
* `lcp-internal.vanco.aki` - aki.sql
* `lcp-internal.vanco.vanco` - vanco.sql
* `lcp-internal.vanco.cefepime` - cefepime.sql
* `lcp-internal.vanco.zosyn` - zosyn.sql

## Propensity score variables

Additional variables extracted to perform propensity score:

presence of sepsis or septic shock
SIRS, lactate, elevated WBC, hypotension, fever
soft tissue infection/skin infections (?cellulitis, or APACHE admission diagnosis Sepsis:skin)
risk factors for community acquired MRSA
risk factors for MDR in general (hospitalization for more than 48 hours in the last 90 days, residence in a nursing home or extended care facility, home infusion therapy, chronic dialysis within one month, home wound care)
known colonization with MRSA
immunocompromized state even in the absence of shock (probably captured through the comorbidity fields)

sepsis
- sepsis documented flag
- soft tissue/skin infection documented flag

admission diagnosis|All Diagnosis|Non-operative|Diagnosis|Musculoskeletal/Skin|Arthritis, septic
admission diagnosis|All Diagnosis|Non-operative|Diagnosis|Musculoskeletal/Skin|Cellulitis and localized soft tissue infections
admission diagnosis|All Diagnosis|Operative|Diagnosis|Musculoskeletal/Skin|Cellulitis and localized soft tissue infections, surgery for


  select 'infection' as category, 'burns/trauma|dermatology|cellulitis' as dx UNION
  select 'infection' as category, 'burns/trauma|dermatology|rash, infectious' as dx UNION
  select 'infection' as category, 'burns/trauma|dermatology|rash, infectious|purulent dermatitis' as dx UNION
    select 'infection' as category, 'infectious diseases|GI infections|abscess of wound' as dx UNION

  select 'infection' as category, 'infectious diseases|head and neck infections|abscess - head and neck' as dx UNION
  select 'infection' as category, 'infectious diseases|head and neck infections|abscess - head and neck|ludwig''s angina' as dx UNION
  select 'infection' as category, 'infectious diseases|head and neck infections|abscess - head and neck|ludwig''s angina|with airway compromise' as dx UNION
  select 'infection' as category, 'infectious diseases|head and neck infections|abscess - head and neck|malignant otitis externa' as dx UNION
  select 'infection' as category, 'infectious diseases|head and neck infections|abscess - head and neck|orbital' as dx UNION
  select 'infection' as category, 'infectious diseases|head and neck infections|abscess - head and neck|orbital|with associated cellulitis' as dx UNION

  select 'infection' as category, 'infectious diseases|skin, bone and joint infections|cellulitis' as dx UNION
  select 'infection' as category, 'infectious diseases|skin, bone and joint infections|cellulitis|abdomen/pelvis' as dx UNION
  select 'infection' as category, 'infectious diseases|skin, bone and joint infections|cellulitis|chest' as dx UNION
  select 'infection' as category, 'infectious diseases|skin, bone and joint infections|cellulitis|extremity' as dx UNION
  select 'infection' as category, 'infectious diseases|skin, bone and joint infections|cellulitis|head and neck' as dx UNION
  select 'infection' as category, 'infectious diseases|skin, bone and joint infections|cellulitis|head and neck|periorbital' as dx UNION
  select 'infection' as category, 'infectious diseases|skin, bone and joint infections|diabetic foot infection' as dx UNION
  select 'infection' as category, 'infectious diseases|skin, bone and joint infections|diabetic foot infection|with gangrene' as dx UNION
  select 'infection' as category, 'infectious diseases|skin, bone and joint infections|diabetic foot infection|without gangrene' as dx UNION

  select 'infection' as category, 'infectious diseases|skin, bone and joint infections|infected pressure ulcer' as dx UNION
  select 'infection' as category, 'infectious diseases|skin, bone and joint infections|infectious dermatitis' as dx UNION
  select 'infection' as category, 'infectious diseases|skin, bone and joint infections|infectious dermatitis|candidal' as dx UNION
  select 'infection' as category, 'infectious diseases|skin, bone and joint infections|infectious dermatitis|pyogenic' as dx UNION
  select 'infection' as category, 'infectious diseases|skin, bone and joint infections|infectious organisms' as dx UNION
  select 'infection' as category, 'infectious diseases|skin, bone and joint infections|local skin infection' as dx UNION
  select 'infection' as category, 'infectious diseases|skin, bone and joint infections|lymphadenitis, acute' as dx UNION
  select 'infection' as category, 'infectious diseases|skin, bone and joint infections|necrotizing fasciitis' as dx UNION
  select 'infection' as category, 'infectious diseases|skin, bone and joint infections|necrotizing fasciitis|abdomen/pelvis' as dx UNION
  select 'infection' as category, 'infectious diseases|skin, bone and joint infections|necrotizing fasciitis|chest' as dx UNION
  select 'infection' as category, 'infectious diseases|skin, bone and joint infections|necrotizing fasciitis|extremity' as dx UNION
  select 'infection' as category, 'infectious diseases|skin, bone and joint infections|necrotizing fasciitis|head and neck' as dx UNION
  select 'infection' as category, 'infectious diseases|skin, bone and joint infections|necrotizing fasciitis|post-op' as dx UNION
  select 'infection' as category, 'infectious diseases|skin, bone and joint infections|necrotizing fasciitis|scrotal area' as dx UNION
  select 'infection' as category, 'infectious diseases|skin, bone and joint infections|necrotizing fasciitis|wound-associated' as dx UNION
  select 'infection' as category, 'infectious diseases|skin, bone and joint infections|wound infection' as dx UNION
  select 'infection' as category, 'infectious diseases|skin, bone and joint infections|wound infection|surgical wound' as dx UNION
  select 'infection' as category, 'infectious diseases|skin, bone and joint infections|wound infection|traumatic wound' as dx UNION
  select 'infection' as category, 'infectious diseases|systemic/other infections|bacteremia|skin or wound source' as dx UNION
  select 'infection' as category, 'infectious diseases|systemic/other infections|toxic shock syndrome' as dx UNION
  select 'infection' as category, 'infectious diseases|systemic/other infections|toxic shock syndrome|group A streptococcus' as dx UNION
  select 'infection' as category, 'infectious diseases|systemic/other infections|toxic shock syndrome|staphylococcus aureus' as dx UNION
  select 'infection' as category, 'surgery|cardiac surgery|sternotomy problems|localized wound infection' as dx UNION


  select 'infection' as category, 'surgery|infections|abscess of wound' as dx UNION
  select 'infection' as category, 'surgery|infections|cellulitis' as dx UNION
  select 'infection' as category, 'surgery|infections|cellulitis|abdomen/pelvis' as dx UNION
  select 'infection' as category, 'surgery|infections|cellulitis|chest' as dx UNION
  select 'infection' as category, 'surgery|infections|cellulitis|extremity' as dx UNION
  select 'infection' as category, 'surgery|infections|cellulitis|head and neck' as dx UNION
  select 'infection' as category, 'surgery|infections|necrotizing fasciitis' as dx UNION
  select 'infection' as category, 'surgery|infections|necrotizing fasciitis|abdomen/pelvis' as dx UNION
  select 'infection' as category, 'surgery|infections|necrotizing fasciitis|chest' as dx UNION
  select 'infection' as category, 'surgery|infections|necrotizing fasciitis|extremity' as dx UNION
  select 'infection' as category, 'surgery|infections|necrotizing fasciitis|head and neck' as dx UNION
  select 'infection' as category, 'surgery|infections|necrotizing fasciitis|post-op' as dx UNION
  select 'infection' as category, 'surgery|infections|necrotizing fasciitis|scrotal area' as dx UNION
  select 'infection' as category, 'surgery|infections|necrotizing fasciitis|wound-associated' as dx UNION  select 'infection' as category, 'surgery|infections|wound infection' as dx UNION
  select 'infection' as category, 'surgery|infections|wound infection|surgical wound' as dx UNION
  select 'infection' as category, 'surgery|infections|wound infection|traumatic wound' as dx UNION
  
- diagnosis table
- apache DX


recent hospitalization


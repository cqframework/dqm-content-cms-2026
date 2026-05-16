library TestRetrieve

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1'

codesystem RxNORM: 'http://www.nlm.nih.gov/research/umls/rxnorm'

code "0.005 ML dexAMETHasone 103.4 MG/ML Injection": 'TBD' from RxNORM

context Patient

define "Pulse Dexamethasone Administration During Hospitalization":
  ["MedicationAdministration": { "0.005 ML dexAMETHasone 103.4 MG/ML Injection" }] DexAdmin
    where DexAdmin.dosage.dose >= 50 'mg'
      and DexAdmin.dosage <= 200 'mg'
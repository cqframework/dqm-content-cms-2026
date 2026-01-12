/*
NOTE: For use by January 2026 Connectathon participants for internal use only. Not for use or distribution in commercial products.
*/
library AdvancedIllnessandFrailty version '2.0.000'

using QICore version '7.0.2'
using USCore version '7.0.0'
using FHIR version '4.0.1'

include hl7.fhir.uv.cql.FHIRHelpers version '4.0.1' called FHIRHelpers
include hl7.fhir.uv.cql.FHIRCommon version '2.0.0' called FHIRCommon
include hl7.fhir.us.cql.CumulativeMedicationDuration called CMD
include Status version '2.0.000' called Status

codesystem "LOINC": 'http://loinc.org'
codesystem "SNOMEDCT": 'http://snomed.info/sct'

valueset "Advanced Illness": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.464.1003.110.12.1082'
valueset "Dementia Medications": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.464.1003.196.12.1510'
valueset "Frailty Device": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.464.1003.118.12.1300'
valueset "Frailty Diagnosis": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.464.1003.113.12.1074'
valueset "Frailty Encounter": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.464.1003.101.12.1088'
valueset "Frailty Symptom": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.464.1003.113.12.1075'
 
code "Housing status": '71802-3' from "LOINC" display 'Housing status'
code "Lives in nursing home (finding)": '160734000' from "SNOMEDCT" display 'Lives in nursing home (finding)'
code "Medical equipment used": '98181-1' from "LOINC" display 'Medical equipment used'

parameter "Measurement Period" Interval<DateTime>

context Patient

define "Is Age 66 or Older with Advanced Illness and Frailty":
   AgeInYearsAt(date from end of "Measurement Period")>= 66
    and "Has Criteria Indicating Frailty"
    and ( "Has Advanced Illness in Year Before or During Measurement Period"
        or "Has Dementia Medications in Year Before or During Measurement Period"
    )

define "Is Age 66 to 80 with Advanced Illness and Frailty or Is Age 81 or Older with Frailty":
  ( AgeInYearsAt(date from end of "Measurement Period")in Interval[66, 80]
      and "Has Criteria Indicating Frailty"
      and ( "Has Advanced Illness in Year Before or During Measurement Period"
          or "Has Dementia Medications in Year Before or During Measurement Period"
      )
  )
    or ( AgeInYearsAt(date from end of "Measurement Period")>= 81
        and "Has Criteria Indicating Frailty"
    )

define "Has Criteria Indicating Frailty":
  exists ( (([QICore.DeviceRequest: "Frailty Device"]).isDeviceOrderPersonalUseDevices()) FrailtyDeviceOrder
      where FrailtyDeviceOrder.authoredOn.toInterval() during day of "Measurement Period"
  )
    // TODO: Shouldn't need to specify a code path here (see https://jira.hl7.org/browse/FHIR-53941)
    or exists ( (([ObservationScreeningAssessment: code ~ "Medical equipment used"]).isAssessmentPerformed()) EquipmentUsed
        where EquipmentUsed.value as CodeableConcept in "Frailty Device" 
        and EquipmentUsed.effective.toInterval() ends during day of "Measurement Period"
    )
    // TODO: Consider whether to keep this as the union of problems and encounter diagnoses
    or exists ( (([Condition: "Frailty Diagnosis"]).verified()) FrailtyDiagnosis
        where FrailtyDiagnosis.prevalenceInterval() overlaps day of "Measurement Period"
    )
    or exists ( (([QICore.Encounter: "Frailty Encounter"]).isEncounterPerformed()) FrailtyEncounter
        where FrailtyEncounter.period overlaps day of "Measurement Period"
    )
    // TODO: Shouldn't need to specify a code path here (see https://jira.hl7.org/browse/FHIR-53941)
    or exists ( (([SimpleObservation: code in "Frailty Symptom"]).isSymptom()) FrailtySymptom
        where FrailtySymptom.effective.toInterval() overlaps day of "Measurement Period"
    )

define "Has Advanced Illness in Year Before or During Measurement Period":
// TODO: Consider whether to keep this as the union of problems and encounter diagnoses
exists ((([Condition: "Advanced Illness"]).verified()) AdvancedIllnessDiagnosis
where AdvancedIllnessDiagnosis.prevalenceInterval() starts during day of Interval[start of "Measurement Period" - 1 year, end of "Measurement Period"])

define "Has Dementia Medications in Year Before or During Measurement Period":
  exists (( ([FHIR.MedicationRequest: "Dementia Medications"]).isMedicationActive()) DementiaMedication
      where DementiaMedication.medicationRequestPeriod() overlaps day of Interval[start of "Measurement Period" - 1 year, 
        end of "Measurement Period"]
  )

define "Is Age 66 or Older Living Long Term in a Nursing Home":
  AgeInYearsAt(date from 
     end of "Measurement Period"
  )>= 66
    // TODO: Shouldn't need to specify a code path here (see https://jira.hl7.org/browse/FHIR-53941)
    and ( ( Last( (([ObservationScreeningAssessment: code ~ "Housing status"]).isAssessmentPerformed()) HousingStatus    
          where HousingStatus.effective.toInterval() ends on or before 
          day of end of "Measurement Period"
          sort by 
          end of effective.toInterval() asc
      )) LastHousingStatus
        where LastHousingStatus.value ~ "Lives in nursing home (finding)"
    ) is not null

/*
TODO: This is moving to the US Common library (see https://jira.hl7.org/browse/FHIR-53940)
*/
define fluent function medicationRequestPeriod(medicationRequest FHIR.MedicationRequest):
  CMD.MedicationRequestPeriod(medicationRequest)
/*
NOTE: Proposed shared library content refactored to use USQualityCore 0.5.0
*/
library VTE version '9.2.000'

using USQualityCore version '0.5.0'
using USCore version '6.1.0-derived'
using FHIR version '4.0.1'

include hl7.fhir.uv.cql.FHIRHelpers version '4.0.1' called FHIRHelpers
include hl7.fhir.uv.cql.FHIRCommon version '2.0.0' called FHIRCommon
include hl7.fhir.us.cql.USCoreCommon version '2.0.0' called USCoreCommon
include hl7.fhir.us.cql.USCoreElements version '2.0.0' called USCoreElements
include fhir.onc."us-quality-core".USQualityCoreCommon version '0.5.0' called USQualityCoreCommon

include CQMCommon version '5.2.000' called CQMCommon
include ClaimCommon version '0.4.000-draft' called ClaimCommon
include ClaimElements version '0.4.000-draft' called ClaimElements

valueset "Obstetrical or Pregnancy Related Conditions": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.117.1.7.1.263' 
valueset "Obstetrics VTE": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.117.1.7.1.264'
valueset "Venous Thromboembolism": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.117.1.7.1.279' 

parameter "Measurement Period" Interval<DateTime>
  default Interval[@2026-01-01T00:00:00.000Z, @2027-01-01T00:00:00.000Z)

context Patient
  
define "Initial Population":
  "Encounter With Age Range And Without VTE Diagnosis Or Obstetrical Conditions"

define fluent function isRelatedTo(condition FHIR.Condition, encounter FHIR.Encounter):
  encounter.reasonReference.references(condition)
    or condition.encounter.references(encounter)

define "Admission Without VTE Or Obstetrical Conditions":
  CQMCommon."Inpatient Encounter" InpatientEncounter
    where not (
      InpatientEncounter.reasonCode in "Obstetrical or Pregnancy Related Conditions"
        or InpatientEncounter.reasonCode in "Venous Thromboembolism"
        or InpatientEncounter.reasonCode in "Obstetrics VTE"
    )
      and not exists (
        (
          [USQualityCore.ConditionEncounterDiagnosis: "Obstetrical or Pregnancy Related Conditions"]
            union [USQualityCore.ConditionEncounterDiagnosis: "Venous Thromboembolism"]
            union [USQualityCore.ConditionEncounterDiagnosis: "Obstetrics VTE"]
        ) EncounterDiagnosis
          where EncounterDiagnosis.isRelatedTo(InpatientEncounter)
      )


define "Encounter With Age Range And Without VTE Diagnosis Or Obstetrical Conditions":
 "Admission Without VTE Or Obstetrical Conditions" EncounterWithoutConditions
     where AgeInYearsAt(date from start of EncounterWithoutConditions.period) >= 18
    
    
define fluent function fromDayOfStartOfHospitalizationToDayAfterAdmission(TheEncounter Encounter):
	Interval[ date from (start of TheEncounter.hospitalizationWithObservation()), date from (start of TheEncounter.period) + 1 days]
	
/*
Refactored to use Condition.isRelatedTo(Encounter)	
define fluent function hasEncDiagnosisOf(TheEncounter Encounter, DiagnosisValueSet System.ValueSet):
   TheEncounter E
     return (E.encounterDiagnosis()).code in DiagnosisValueSet
       or E.reasonCode in DiagnosisValueSet
       

Refactored to use Claim Item Procedure       
define fluent function hasPrincipalProcedureOf(TheEncounter Encounter, DiagnosisValueSet System.ValueSet):
   TheEncounter E
   let
        PPx: E.principalProcedure(),
        CPx: singleton from ([Procedure] P where PPx.procedure.references(P.id))
     return PPx.procedure in DiagnosisValueSet
       or CPx.code in DiagnosisValueSet
*/
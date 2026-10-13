library JCCommon version '8.34.000'

using USQualityCore version '0.5.0'
using USCore version '6.1.0-derived'
using FHIR version '4.0.1'

include hl7.fhir.uv.cql.FHIRHelpers version '4.0.1' called FHIRHelpers
include hl7.fhir.uv.cql.FHIRCommon version '2.0.0' called FHIRCommon
include hl7.fhir.us.cql.USCoreCommon version '2.0.0' called USCoreCommon
include hl7.fhir.us.cql.USCoreElements version '2.0.0' called USCoreElements

include CQMCommon version '5.2.000' called CQMCommon
include fhir.onc."us-quality-core".USQualityCoreCommon version '0.5.0' called USQualityCoreCommon
include ClaimElements version '0.3.000' called ClaimElements
include ClaimCommon version '0.3.000' called ClaimCommon

valueset "Comfort Measures": 'http://cts.nlm.nih.gov/fhir/ValueSet/1.3.6.1.4.1.33895.1.3.0.45'
valueset "Discharge To Acute Care Facility": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.117.1.7.1.87'
valueset "Discharged to Health Care Facility for Hospice Care": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.117.1.7.1.207'
valueset "Discharged to Home for Hospice Care": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.117.1.7.1.209'
valueset "Ischemic Stroke": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.117.1.7.1.247'
valueset "Left Against Medical Advice": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.117.1.7.1.308'
valueset "Nonelective Inpatient Encounter": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.117.1.7.1.424'
valueset "Patient Expired": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.117.1.7.1.309'

parameter "Measurement Period" Interval<DateTime>

context Patient

define "Non Elective Inpatient Encounter With Age":
  ["USQualityCore.Encounter": "Nonelective Inpatient Encounter"] NonElectiveEncounter
        where AgeInYearsAt(date from start of NonElectiveEncounter.period ) >= 18
         and NonElectiveEncounter.period ends during day of "Measurement Period"

define "Ischemic Stroke Encounter":
  "Non Elective Inpatient Encounter With Age" NonElectiveEncounterWithAge
  // where NonElectiveEncounterWithAge.isPrincipalDiagnosis ("Ischemic Stroke")
        with ClaimElements."Claim Item Diagnosis" ClaimDiagnosis
      such that ClaimDiagnosis.serviced during NonElectiveEncounterWithAge.period
        and ClaimDiagnosis.diagnosisType.isPrincipalDiagnosis()
        and  ClaimDiagnosis.diagnosis in "Ischemic Stroke"
        

define "Ischemic Stroke Encounters With Selected Discharge Disposition":
  "Ischemic Stroke Encounter" IschemicStrokeEncounter
  let DischDisp: IschemicStrokeEncounter.hospitalization.dischargeDisposition
  	where  DischDisp in "Discharge To Acute Care Facility"
		or DischDisp in "Left Against Medical Advice"
		or DischDisp in "Patient Expired"
		or DischDisp in "Discharged to Home for Hospice Care"
		or DischDisp in "Discharged to Health Care Facility for Hospice Care"			

define "Encounter With Comfort Measures During Hospitalization":
  "Ischemic Stroke Encounter" IschemicStrokeEncounter
    with "Intervention Comfort Measures" ComfortMeasure
     such that Coalesce(start of ComfortMeasure.performed.toInterval(), ComfortMeasure.authoredOn) during IschemicStrokeEncounter.hospitalizationWithObservation()

define "Intervention Comfort Measures":
  ( ["ServiceRequest": "Comfort Measures"] ComfortCare
    where ComfortCare.status in { 'active', 'completed', 'on-hold' }
      and ComfortCare.intent in { 'order', 'original-order', 'reflex-order', 'filler-order', 'instance-order' }
  )  
  union ( ["Procedure": "Comfort Measures"] ComfortCarePerformed
        where ComfortCarePerformed.status in { 'completed', 'in-progress' }
  )
  
define fluent function calendarDayOfOrDayAfter(StartValue DateTime):
  Interval [date from (StartValue), date from (StartValue) + 1 day]
  
 define function "Has Selected Discharge Disposition"(encounterdis Encounter):
  encounterdis.hospitalization.dischargeDisposition in "Discharge To Acute Care Facility"
    or encounterdis.hospitalization.dischargeDisposition in "Left Against Medical Advice"
    or encounterdis.hospitalization.dischargeDisposition in "Patient Expired"
    or encounterdis.hospitalization.dischargeDisposition in "Discharged to Home for Hospice Care"
    or encounterdis.hospitalization.dischargeDisposition in "Discharged to Health Care Facility for Hospice Care"
    
define fluent function fromDayOfStartOfHospitalizationToDayAfterAdmission(TheEncounter Encounter):
	Interval[ date from (start of TheEncounter.hospitalizationWithObservation()), date from (start of TheEncounter.period) + 1 days]
	
	
define fluent function fromDayOfStartOfHospitalizationToDayAfterAdmission(TheEncounter Encounter):
	Interval[ date from (start of TheEncounter.hospitalizationWithObservation()), date from (start of TheEncounter.period) + 1 days]
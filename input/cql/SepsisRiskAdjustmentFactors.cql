library SepsisRiskAdjustmentFactors

using USQualityCore version '0.5.0'
using USCore version '6.1.0-derived'
using FHIR version '4.0.1'

include hl7.fhir.uv.cql.FHIRHelpers version '4.0.1' called FHIRHelpers
include hl7.fhir.uv.cql.FHIRCommon version '2.0.0' called FHIRCommon
include hl7.fhir.us.cql.USCoreCommon version '2.0.0' called USCoreCommon
include hl7.fhir.us.cql.USCoreElements version '2.0.0' called USCoreElements
include fhir.onc."us-quality-core".USQualityCoreCommon version '0.5.0' called USQCommon

valueset "Discharge To Acute Care Facility": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.117.1.7.1.87'
valueset "Discharged to Health Care Facility for Hospice Care": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.117.1.7.1.207'
valueset "Discharged to Home for Hospice Care": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.117.1.7.1.209'
valueset "Left Against Medical Advice": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.117.1.7.1.308'
valueset "Patient Expired": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.117.1.7.1.309'

include ClaimCommon version '0.2.000'
include ClaimElements version '0.2.000'
include Status version '2.2.000'

parameter "Measurement Period" Interval<DateTime>
  default Interval[@2026-01-01T00:00:00.000Z, @2027-01-01T00:00:00.000Z)

context Patient

define "Completed Encounter":
  ( [USQualityCore.Encounter] )//.isEncounterPerformed ( )

define "Qualifying Encounter":
  "Completed Encounter" E
    where E.period ends during "Measurement Period"

// Conditions Present On Admission
define "Encounter With Diagnosis Present On Admission":
  [USQualityCore.Encounter] E
    with ClaimElements."Claim Item Diagnosis" D
      such that D.serviced during day of E.period
        and D.onAdmission in ClaimCommon."Present on Admission or Clinically Undetermined"

// Principal Diagnosis
define "Encounter With Principal Diagnosis":
  [USQualityCore.Encounter] E
    with ClaimElements."Claim Item Diagnosis" ClaimDiagnosis
      such that ClaimDiagnosis.serviced during day of E.period
        and ClaimDiagnosis.diagnosisType.isPrincipalDiagnosis() // short-hand for .includesCode("Prinicipal Diagnosis")

// Discharge Disposition
// Terminology mismatch...
define "Encounter With Allowable Discharge Disposition":
  "Qualifying Encounter" Encounter
    with [FHIR.Claim] Claim
      such that Claim.billablePeriod includes Encounter.period
        and (
          Claim.dischargeStatus() in "Discharge To Acute Care Facility"
            or Claim.dischargeStatus() in "Left Against Medical Advice"
            or Claim.dischargeStatus() in "Patient Expired"
            or Claim.dischargeStatus() in "Discharged to Home for Hospice Care"
            or Claim.dischargeStatus() in "Discharged to Health Care Facility for Hospice Care"
        )
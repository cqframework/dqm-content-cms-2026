library StratificationPatientExample

using FHIR version '4.0.1'

include hl7.fhir.uv.cql.FHIRHelpers version '4.0.1'
include hl7.fhir.uv.cql.FHIRCommon version '2.0.0'

include PatientCommon

parameter "Measurement Period" Interval<DateTime>
  default Interval[@2026-01-01T00:00:00.000Z, @2027-01-01T00:00:00.000Z)

context Patient

define "Well-Visit Encounter":
  [Encounter] E
    where E.status = 'finished'
      and E.period ends during day of "Measurement Period"

define "Initial Population":
  true

define "Denominator":
  Patient.active is true

define "Numerator":
  exists ("Well-Visit Encounter")

/* Criteria-based Stratifiers */

define "Stratifier P0Y--P21Y":
  Patient.ageInYearsAt(end of "Measurement Period") between 0 and 20

define "Stratifier P21Y--P41Y":
  Patient.ageInYearsAt(end of "Measurement Period") between 21 and 40

define "Stratifier P41Y--P9999Y":
  Patient.ageInYearsAt(end of "Measurement Period") >= 41

/* Value-based Stratifiers */

define "Gender Stratifier":
  Patient.gender

define "Age Range Stratifier":
  case
    when Patient.ageInYearsAt(end of "Measurement Period") between 0 and 20 then 'P0Y--P21Y'
    when Patient.ageInYearsAt(end of "Measurement Period") between 21 and 40 then 'P21Y--P41Y'
    when Patient.ageInYearsAt(end of "Measurement Period") >= 41 then 'P41Y--P9999Y'
    else null
  end


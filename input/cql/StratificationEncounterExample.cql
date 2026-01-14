library StratificationEncounterExample

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

define "Blood Pressure Observation":
  [Observation] O
    where O.status in { 'final', 'amended', 'corrected' }
      and O.issued during day of "Measurement Period"

define "Initial Population":
  "Well-Visit Encounter"

define "Denominator":
  "Well-Visit Encounter"

define "Numerator":
  "Well-Visit Encounter" E
    with "Blood Pressure Observation" O
      such that O.issued during E.period

/* Criteria-based Stratification */

define "Stratifier P0Y--P21Y":
  "Well-Visit Encounter" E
    where Patient.ageInYearsAt(end of E.period) between 0 and 20

define "Stratifier P21Y--P41Y":
  "Well-Visit Encounter" E
    where Patient.ageInYearsAt(end of E.period) between 21 and 40

define "Stratifier P41Y--P9999Y":
  "Well-Visit Encounter" E
    where Patient.ageInYearsAt(end of E.period) >= 41

/* Value-based Stratification */

define function "Gender Stratifier"(encounter Encounter):
  Patient.gender

define function "Age Range Stratifier"(encounter Encounter):
  case
    when Patient.ageInYearsAt(start of encounter.period) between 0 and 20 then 'P0Y--P21Y'
    when Patient.ageInYearsAt(start of encounter.period) between 21 and 40 then 'P21Y--P41Y'
    when Patient.ageInYearsAt(start of encounter.period) >= 41 then 'P41Y--P9999Y'
    else null
  end

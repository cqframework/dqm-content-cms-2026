/*
@description: Demonstrates a measure that is calculated with a predicted denominator, rather than from data in the source
@comment: Observed (O) HAIs / Predicted (P) HAIs. Note that this is still a work in progress and is known not to compile correctly at this point.
@seealso: https://github.com/cqframework/CQL-Formatting-and-Usage-Wiki/blob/master/Source/Cooking%20With%20CQL/93/CAUTI.md
*/
library CAUTI

using FHIR version '4.0.1'

include hl7.fhir.uv.cql.FHIRHelpers version '4.0.1' called FHIRHelpers
include hl7.fhir.uv.cql.FHIRCommon version '2.0.0' called FHIRCommon

valueset "Catheter Inserted": 'http://example.org/ValueSet/catheter-inserted'
valueset "Catheter Removed": 'http://example.org/ValueSet/catheter-removed'
valueset "Urine Culture": 'http://example.org/ValueSet/urine-culture'
valueset "Bacterium Presence": 'http://example.org/ValueSet/bacterium-presence'
valueset "Microbiologic Blood Tests": 'http://example.org/ValueSet/bacterium-presence'

parameter "Measurement Period" Interval<DateTime> 
  default Interval[@2026-01-01T00:00:00, @2026-12-31T23:59:59]

context Patient

define "Catheter Inserted Procedure":
  [Procedure: "Catheter Inserted"] P
    where P.status = 'completed'

define "Catheter Removed Procedure":
  [Procedure: "Catheter Removed"] P
    where P.status = 'completed'

define "Catheter Usage":
  "Catheter Inserted Procedure" I
    let catheterRemoved: 
      First(
        "Catheter Removed Procedure" R
          where R.performed.toInterval() starts after I.performed.toInterval()
          sort by start of performed.toInterval()
      )
    return Interval[
      date from start of I.performed.toInterval(), 
      date from start of catheterRemoved.performed.toInterval()
    ]

define "Catheter Usage During Measurement Period":
  collapse (
    "Catheter Usage" Usage
        where Usage overlaps "Measurement Period"
        return Interval[
            Max({start of Usage, start of "Measurement Period"}),
            Min({end of Usage, end of "Measurement Period"})
        ]
  )

/*
define function "Denominator Observation"():
  Sum(
    "Catheter Usage During Measurement Period" Usage
      return all duration in days of Usage
  )
*/

define "Urine Culture With Bacterium":
  [Observation: "Urine Culture"] O
    where O.status = 'final'
      and exists (
        O.component C
          where C.code in "Bacterium Presence"
            and C.value >= 10000 '[CFU]/mL'
      )

define "UTI":
  "Urine Culture With Bacterium" U
    let 
      DOE: date from start of U.effective.toInterval(),
      IWP: Interval[DOE - 3 days, DOE + 3 days]
    where start of U.effective.toInterval() during "Measurement Period"
    return {
      urineCultureResult: U,
      dateOfEvent: DOE,
      infectionWindowPeriod: IWP
    }

define "Catheter-Associated UTI":
  "UTI" U
    where exists (
        "Catheter Usage" Usage
          where start of Usage before U.dateOfEvent
            and end of Usage on or after U.dateOfEvent - 1 day
            and duration in days of Usage > 2
    )

define "Symptomatic UTI":
  "UTI" U
    where exists ("Symptoms Not Attributable To Catheter" S 
      where S.prevalencePeriod() starts during U.infectionWindowPeriod
    )
      or exists (
        "Symptoms Attributable to Catheter" S
          where S.prevalencePeriod() starts during U.infectionWindowPeriod
            and not exists (
              "Catheter Usage" Usage
                where S.prevalencePeriod() starts during Usage
            )
      )

define "Symptoms Not Attributable To Catheter":
  [Condition] C where false
/*
  "Fever Over 38"
    union "Suprapubic Tenderness"
    union "Costovertebral Angle Pain"
    union "Hypothermia Under 36 In Infants"
    union "Apnea In Infants"
    union "Bradycardia In Infants"
    union "Lethargy In Infants"
    union "Vomiting In Infants"
*/

define "Microbiologic Blood Test Result":
  [Observation: "Microbiologic Blood Tests"] T
    where T.status = 'final'
      and exists (
        T.component C
          where C.code in "Bacterium Presence"
            and C.value >= 10000 '[CFU]/ml'
      )

define "Bacteremic UTI":
  "UTI" U
    where exists (
      "Microbiologic Blood Test Result" B
        where B.effective.toInterval() during U.infectionWindowPeriod
          and exists (
            B.component.code intersect U.component.code
          )
    )

define "Numerator Observation":
  Count("Catheter-Associated UTI")

// TODO: Update to the 2022 Baseline parameters:
// [NHSN SIR Guide](https://www.cdc.gov/nhsn/2022rebaseline/sir-guide.pdf)
// As HTML: https://www.cdc.gov/nhsn/2022rebaseline/sir-risk-factors.html
// CAUTI ACH Factors https://www.cdc.gov/nhsn/2022rebaseline/tables/table-6.html
define "Acute Care Hospital Parameters": {
    { code: "Intercept", estimate: -10.2667, standardError: 0.1618, pValue: Quantity { value: 0.001, comparator: '<' } },
    { code: "Burn Critical Care", estimate: 3.3318, standardError: 0.1580, pValue: Quantity { value: 0.001, comparator: '<' } }
}

define function "Location Parameters"(location Location):
  {
    "Intercept",
    location.type.toCDCLocationCode(),
    location.medicalSchoolAffiliation(),
    location.facilityBedSize(),
    location.facilityType()
  }

define function "Denominator Observation"(location Location):
  Sum(
    from "Location Parameters"(location) P, "Acute Care Hospital Parameters" H
      where P ~ H.code
      return all H.estimate
  ) * "Patient Days"(location)


define "Encounter During Measurement Period":
  [Encounter] E
    where E.period during "Measurement Period"

define function "Patient Days"(location Location):
  Sum(
    "Encounter During Measurement Period" E
      where E.location.references(location)
      return all duration in days of E.period
  )

define "Denominator Initial Population":
  [Location] L
    with "Encounter During Measurement Period" E
     such that E.location.references(L)

define "Denominator":
  "Denominator Initial Population"

define function "Numerator Observation"():
  Count(CAUTIRate."Catheter-Associated UTI")

define "Numerator Initial Population":
  exists ("Encounter During Measurement Period")

define "Numerator":
  "Numerator Initial Population"
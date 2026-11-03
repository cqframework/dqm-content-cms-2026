/*
Draft CQL representation of Hospital Onset Bacteremia and Fungemia Surveillance Measure
*/
library HOB

using USQualityCore version '0.5.0'
using USCore version '6.1.0-derived'
using FHIR version '4.0.1'

include hl7.fhir.uv.cql.FHIRHelpers version '4.0.1' called FHIRHelpers
include hl7.fhir.uv.cql.FHIRCommon version '2.0.0' called FHIRCommon

include CQMConcepts version '0.5.000' called CQMConcepts
include CQMElements version '0.5.000' called CQMElements
include HOBOrganismTaxonomy

valueset "Bacteria and Fungi - HOB Specific": 'https://example.org/fhir/ValueSet/bacteria-and-fungi-hob-specific'
valueset "Bacterial Skin Commensals": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.114222.24.7.281' version '20240918' // Was 20241003, verify
valueset "Community-associated Organisms - HOB Specific": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.114222.24.7.1170' version '20250930'
valueset "Bacterial and Fungal Blood Culture Tests": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1190.63' version '20220721'
valueset "Enteral Medication Route": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1190.74' version '20240618'
valueset "Intravenous Medication Route": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1190.75' version '20240618'
valueset "Specimen Type - Blood": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.114222.24.7.315' version '20250929'
valueset "Absolute Neutrophils": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.114222.24.7.1173' version '20250913'
valueset "Antimicrobial Medications - I.V Antibacterials": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.114222.24.7.1220' version '20260122'
valueset "Antimicrobial Medications - Oral Antibacterials": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.114222.24.7.1220' version '20250813'
valueset "Antimicrobials for Bacteremia and Fungemia Surveillance Module": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.114222.24.7.1220' version '20260205'

parameter "Measurement Period" Interval<DateTime> 
  default Interval[@2026-01-01T00:00:00.0, @2026-01-31T23:59:59.999]

context Patient

define "Bacterial and Fungal Blood Culture Test Results":
  [USQualityCore.LaboratoryResultObservation: "Bacterial and Fungal Blood Culture Tests"] O
    where O.isResulted()

define "Blood Specimen":
  [USCore.SpecimenProfile: "Specimen Type - Blood"] S
    where S.status = 'available'

define "Bacteremia or Fungemia Result":
  "Bacterial and Fungal Blood Culture Test Results" R
    where ((R.value as CodeableConcept) in "Bacteria and Fungi - HOB Specific")
      and not ((R.value as CodeableConcept) in "Bacterial Skin Commensals")

define "Bacteremia or Fungemia Result With Specimen":
  "Bacteremia or Fungemia Result" R
    let specimen: singleton from ("Blood Specimen" S where R.specimen.references(S))
    return {
      result: R,
      specimen: specimen
    }

/*
@description: Returns the specimen collection time if available, falling back to the effective time
@comment: Note that specimen collection time is not a USCI+Qualtiy or USCDI element
*/
define fluent function collectionTime(
  resultWithSpecimen Tuple { 
    result USQualityCore.LaboratoryResultObservation, 
    specimen USCore.SpecimenProfile
  }
):
  Coalesce(
    resultWithSpecimen.specimen.collection.collected.toInterval(), 
    resultWithSpecimen.result.effective.toInterval()
  )

// TODO: Consider this IP:
// https://measures-ci.nhsnlink.org/Library-NHSNAcuteCareHospitalMonthlyInitialPopulation.html

// TODO: Consider "Outpatient Surgery Encounter"?
define "Hospital Stays":
  CQMElements."Hospitalization Encounters"(
    CQMElements."Inpatient Encounter"
      union CQMElements."Emergency Department Encounter"
      union CQMElements."Observation Encounter"
  )

define "Inpatient Encounter":
  "Hospital Stays" Stay
    where Stay.type in CQMConcepts."Encounter Inpatient"

define "Outpatient Encounter":
  "Hospital Stays"
    except "Inpatient Encounter"

/*
An O-COB event occurs when a patient has a bacterial or fungal organism identified 
from a blood culture performed on a blood specimen collected during an ED/Observation-only 
Hospital Stay that does not include an inpatient admission.
*/
define "O-COB Event":
  "Outpatient Encounter" E
    let results: (
      "Bacteremia or Fungemia Result With Specimen" RS 
        where RS.collectionTime() during E.hospitalization()
    )
    where exists (results)
    return {
      encounter: E,
      indexDate: Min(results R return start of R.collectionTime()),
      organisms: results R return R.result.value as CodeableConcept
    }

/*
@description: Returns the community onset window, hospital days 1 to 3
*/
define fluent function communityOnsetWindow(encounter USQualityCore.Encounter):
  encounter.hospitalization().hospitalDays(1, 3)

/*
A COB event occurs when a patient has a bacterial or fungal organism identified from a blood 
culture performed on a blood specimen collected on Hospital Stay days 1 through 3 of a Hospital 
Stay that includes an inpatient admission.
*/
define "COB Event":
  "Inpatient Encounter" E
    let results: (
      "Bacteremia or Fungemia Result With Specimen" RS
        where RS.collectionTime() during E.hospitalization().hospitalDays(1, 3)
    )
    where exists (results)
    return {
      encounter: E,
      indexDate: Min(results R return start of R.collectionTime()),
      organisms: results R return R.result.value as CodeableConcept
    }

/*
@description: Returns the hospital onset window, hospital day 4 to the end of the hospitalization
*/
define fluent function hospitalOnsetWindow(encounter USQualityCore.Encounter):
  (encounter.hospitalization()) H
    let day4Start: DateTimeWithSamePrecision(date from start of H + 3 days, start of H)
    return if day4Start <= H.high then Interval[start of H.hospitalDay(4), H.high] else null
  
/*
An HOB event occurs when a patient has a bacterial or fungal organism identified from a blood
culture performed on a blood specimen collected on Hospital Stay day 4 or later of a Hospital 
Stay that includes an inpatient admission.
*/
define "HOB Event":
  "Inpatient Encounter" E
    let 
      COB: singleton from ("COB Event" COBEvent where E.id = COBEvent.encounter.id),
      results: (
        "Bacteremia or Fungemia Result With Specimen" RS
          where RS.collectionTime() during E.hospitalOnsetWindow()
            and not exists (
              COB.organisms O
                where O.organismMatches(RS.result.value as CodeableConcept)
            )
    )
    where exists (results)
    return {
      encounter: E,
      indexDate: Min(results R return start of R.collectionTime()),
      organisms: results R return R.result.value as CodeableConcept
    }

/*
Metric: O-COB Prevalence Rate
Scoring: Proportion
Numerator: Number of outpatient O-COB events occurring within the measurement period
Denominator: Number of outpatient (ED/OBS) encounters occurring within the measurement period
*/

define "Outpatient Encounter During Measurement Period":
  "Outpatient Encounter" O
    where O.hospitalization() overlaps "Measurement Period"

define "O-COB Prevalence Rate Initial Population":
  "Outpatient Encounter During Measurement Period"

define "O-COB Prevalence Rate Denominator":
  "Outpatient Encounter During Measurement Period"

define "O-COB Prevlanece Rate Numerator":
  "O-COB Event" OCOBEvent
    where OCOBEvent.indexDate during "Measurement Period"
    return OCOBEvent.encounter

/*
Metric: Inpatient COB Prevalence Rate
Scoring: Proportion
Numerator: Number of inpatient COB events occurring within the measurement period
Denominator: Number of inpatient stays where at least one of the first three inpatient calendar days falls within the measurement period
*/

define "Community Eligible Inpatient Encounter During Measurement Period":
  "Inpatient Encounter" I
    where I.communityOnsetWindow() overlaps "Measurement Period"

define "COB Prevalence Rate Initial Population":
  "Community Eligible Inpatient Encounter During Measurement Period"

define "COB Prevalence Rate Denominator":
  "Community Eligible Inpatient Encounter During Measurement Period"

define "COB Prevalence Rate Numerator":
  "COB Event" COBEvent
    where COBEvent.indexDate during "Measurement Period"
    return COBEvent.encounter

/*
Metric: HOB Crude Risk
Scoring: Proportion
Numerator: Number of inpatient stays with at least one HOB event occurring within the measurement period
Denominator: Number of inpatient stays where there are any inpatient days eligible for a hosptial-onset event during the measurement period
Notes: The denominator for HOB admission risk will include only those inpatient stays who were eligible for an HOB event in the measurement period:  
  1. Stays where day 4 (or later) of their admission occurred during the measurement period.  
  2. If an event occurs, then a stay will not be included in the denominator of subsequent measurement periods.
*/

define "Hospital Eligible Inpatient Encounter During Measurement Period":
  "Inpatient Encounter" I
    where I.hospitalOnsetWindow() overlaps "Measurement Period"
      and not exists (
        "HOB Event" HOBEvent
          where HOBEvent.encounter.id = I.id
            and HOBEvent.indexDate before start of "Measurement Period"
      )

define "HOB Crude Risk Initial Population":
  "Hospital Eligible Inpatient Encounter During Measurement Period"

define "HOB Crude Risk Denominator":
  "Hospital Eligible Inpatient Encounter During Measurement Period"

define "HOB Crude Risk Numerator":
  "HOB Event" HOBEvent
    where HOBEvent.indexDate during "Measurement Period"
    return HOBEvent.encounter

/*
Metric: HOB Incidence Density
Scoring: Ratio /100.d
Numerator: Number of HOB events
Denominator: Number of inpatient days eligible for a hospital-onset event during the measurement period
Notes: Eligible patient days are defined as: Inpatient day 4 until discharge or index HOB event date
*/

define "HOB Incidence Density Initial Population":
  "Hospital Eligible Inpatient Encounter During Measurement Period"

define "HOB Incidence Density Denominator":
  "Hospital Eligible Inpatient Encounter During Measurement Period"

define function "HOB Incidence Density Denominator Observation"(encounter USQualityCore.Encounter):
  days between start of encounter.hospitalOnsetWindow()
    and Min({
      ("HOB Event" HOBEvent where HOBEvent.encounter.id = encounter.id).single().indexDate,
      end of encounter.period
    })

define "HOB Incidence Density Numerator":
  "HOB Event" HOBEvent
    where HOBEvent.indexDate during "Measurement Period"
    return HOBEvent.encounter

// Just counting, so return 1
define function "HOB Incidence Density Numerator Observation"(encounter USQualityCore.Encounter):
  1

/*
@description: Returns a DateTime constructed with the same precision as
the given date time. This is effectively a ToDateTime operation but setting
the time components to 0 (i.e. starting at midnight on the given date)
@comment: Proposed for inclusion in CQMConcepts
*/
define function DateTimeWithSamePrecision(_date Date, _dateTime DateTime):
  DateTime(
    year from _date,
    month from _date,
    day from _date,
    if hour from _dateTime is not null then 0 else null,
    if minute from _dateTime is not null then 0 else null,
    if second from _dateTime is not null then 0 else null
  )

/*
@description: Returns the interval of time covering the given hospital day
@comment: The interval will be a full day unless it is the first or last day
of the hospital stay, in which case it will start or end with the hospitalization
start or end.

NOTE: Proposed for inclusion in CQMConcepts
*/
define fluent function hospitalDay(hospitalization Interval<DateTime>, dayNumber Integer):
  hospitalization H
    let 
      hospitalDate: date from start of H + ((dayNumber - 1) * 1 day),
      hospitalDateTime: DateTimeWithSamePrecision(hospitalDate, start of H)
    return Interval[
      Max({ start of H, hospitalDateTime }),
      Min({ hospitalDateTime + 1 day, H.high })
    )

/*
@description: Returns the interval of time covering the given hospital days
@comment: The interval will start at midnight on the starting day, unless it is
the first day, in which case it will start with the hospitalization start. The
interval will end just before midnight on the ending day, unless it is the last
day or later, in which case it will end with the hospitalization end.

NOTE: Proposed for inclusion in CQMConcepts
*/
define fluent function hospitalDays(hospitalization Interval<DateTime>, startDayNumber Integer, endDayNumber Integer):
  hospitalization H
    let 
      hospitalDate: date from start of H + ((startDayNumber - 1) * 1 day),
      hospitalDateTime: DateTimeWithSamePrecision(hospitalDate, start of H),
      numberOfDays: (endDayNumber - startDayNumber) + 1
    return Interval[
      Max({ start of H, hospitalDateTime }),
      Min({ hospitalDateTime + (numberOfDays * 1 day), H.high })
    )
    

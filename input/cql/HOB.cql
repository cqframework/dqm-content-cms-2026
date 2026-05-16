/*
Draft CQL representation of Hospital Onset Bacteremia and Fungemia Surveillance Measure
*/
library HOB

using FHIR version '4.0.1'

include hl7.fhir.uv.cql.FHIRHelpers version '4.0.1' called FHIRHelpers
include hl7.fhir.uv.cql.FHIRCommon version '2.0.0' called FHIRCommon

include CQMCommon version '5.1.000' called CQMCommon
include HOBOrganismTaxonomy

valueset "Bacteria and Fungi - HOB Specific": 'TBD'
valueset "Bacterial Skin Commensals": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.114222.24.7.281' version '20241003'
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

/*
ED/OBS encounter: Any patient visit to an emergency department (ED) or observation (OBS) location. One patient visit equals one encounter. ED/OBS are considered outpatient locations.
Hospital Stay: NHSN defines a hospital stay to be inclusive of any: (a) ED/OBS encounters, (b) inpatient admissions, or (c) ED/OBS encounters that lead to inpatient admissions (within 1 hour of ED/OBS encounters).
Inpatient admission: For NHSN reporting purposes, the ‘date admitted to the facility’ is hospital day (HD) 1. NHSN defines an inpatient as any patient cared for or housed on an inpatient location. Local status may differ from NHSN definition; all days spent in an inpatient unit, regardless of local admission status and/or billing status are included in the counts of admissions and inpatient days. For NHSN reporting purposes, the date admitted to the facility is the calendar date that the patient physically locates to an inpatient location.
Measurement Period: Time period selected for report generation/metric calculation
Adult: Patients who are ≥18 years old on the calendar day of the start of the Hospital Stay
Pediatric: Patients who are < 18 years old on the calendar day of the start of the Hospital Stay
NICU: Patients who are housed in a NICU location at the time of index blood culture collection
Oncology/Neutropenia: Patient either 1) located in an Oncology ward, or 2) with neutropenia define an absolute neutrophil count (ANC) <1000 cell/microL observed for ≥2 days in a +/- 7-day window period around the index blood culture
O-COB: Outpatient Community-onset Bacteremia & Fungemia Event
COB: Community-onset Bacteremia & Fungemia Event
HOB: Hospital-onset Bacteremia & Fungemia Event
*/

/*
|Onset |Metric |Numerator |Denominator |Multiplier |Notes 
|Outpatient Community Onset |O-COB Prevalence Rate |Number of outpatient O-COB events occurring within the measurement period |Number of outpatient (ED/OBS) encounters occurring within the measurement period |x 100 | |
|Inpatient Community Onset |Inpatient COB Prevalence Rate |Number of inpatient COB events occurring within the measurement period |Number of inpatient stays where at least one of the first three inpatient calendar days falls within the measurement period |x 100 | |
|Hospital Onset |HOB Crude Risk |Number of inpatient stays with at least one HOB event occurring within the measurement period |Number of inpatient stays where there are any inpatient days eligible for a hospital-onset event during the measurement period |x 100 |The denominator for HOB admission risk will include only those inpatient stays who were eligible for an HOB event in the measurement period: 1. Stays where day 4 (or later) of their admission occurred during the measurement period. 2. If an event occurs, then a stay will not be included in the denominator of subsequent measurement periods. |
|^ |HOB Incidence Density |Number of HOB events |Number of inpatient days eligible for a hospital-onset event during the measurement period |x 10,000 |Eligible patient days are defined as: 1. Inpatient day 4 until discharge or index HOB event date. |
*/

/*
Metric: O-COB Prevalence Rate
Numerator: Number of outpatient O-COB events occurring within the measurement period
Denominator: Number of outpatient (ED/OBS) encounters occurring within the measurement period
*/

//define function "Denominator Observation"():
//  Count("Outpatient Encounter During Measurement Period")

//define function "Numerator Observation"():
//  Count("O-COB Event During Measurement Period")

define "Bacterial and Fungal Blood Culture Test Results":
  [Observation: "Bacterial and Fungal Blood Culture Tests"] O
    where O.isLaboratory()
      and O.isResulted()

define "Bacteremia or Fungemia Result":
  "Bacterial and Fungal Blood Culture Test Results" R
    where (R.value in "Bacteria and Fungi - HOB Specific")
      and not (R.value in "Bacterial Skin Commensals")

define "Bacteremia or Fungemia Result With Specimen":
  from
    "Bacteremia or Fungemia Result" R,
    [Specimen: "Specimen Type - Blood"] S
    where R.specimen.references(S)
    return {
      result: R,
      specimen: S
    }

// TODO: Needs to account for Outpatient (i.e. never admitted)
define "Encounter With ED and Observation":
  [Encounter: CQMCommon."Encounter Inpatient"] E
    let observationVisit: Last(
      [Encounter: CQMCommon."Observation Services"] O
        where O.period ends 1 hour or less on or before start of E.period
        sort by end of period
    ),
    visitStart: Coalesce(start of observationVisit.period, start of E.period),
    edVisit: Last(
      [Encounter: CQMCommon."Emergency Department Visit"] ED
        where ED.period ends 1 hour or less on or before start of E.period
        sort by end of period
    ),
    edOrObservationPeriod: 
      if edVisit is null and observationVisit is null then 
        null 
      else
        Interval[Coalesce(start of edVisit.period, start of observationVisit.period), start of E.period],
    inpatientStay: E.period
  return {
    encounter: E,
    observationVisit: observationVisit,
    edVisit: edVisit,
    edOrObservationPeriod: edOrObservationPeriod,
    inpatientStay: inpatientStay
  }

// TODO: USCDI+ Quality/USCDI Gap (Specimen Collection Time)
define "Encounter With O-COB Result":
  "Encounter With ED and Observation" E
    let results: (
      "Bacteremia or Fungemia Result With Specimen" RS 
        where RS.specimen.collection.collected.toInterval()
          during E.edOrObservationPeriod
    )
    return {
      encounter: E.encounter,
      observationVisit: E.observationVisit,
      edVisit: E.edVisit,
      edOrObservationPeriod: E.edOrObservationPeriod,
      inpatientStay: E.inpatientStay,
      indexDate: Min(results R return start of R.specimen.collection.collected.toInterval()),
      organisms: results R return R.result.value as CodeableConcept
    }

define "Encounter With COB Result":
  "Encounter With O-COB Result" E
    let results: (
      "Bacteremia or Fungemia Result With Specimen" RS
        where RS.specimen.collection.collected.toInterval()
          during day of Interval[start of E.inpatientStay, start of E.inpatientStay + 3 days]
          and not exists (
            E.organisms O
              where O.organismMatches(RS.result.value as CodeableConcept)
          )
    )
    return {
      encounter: E.encounter,
      observationVisit: E.observationVisit,
      edVisit: E.edVisit,
      edOrObservationPeriod: E.edOrObservationPeriod,
      inpatientStay: E.inpatientStay,
      ocobIndexDate: E.indexDate,
      ocobOrganisms: E.organisms,
      indexDate: Min(results R return start of R.specimen.collection.collected.toInterval()),
      organisms: results R return R.result.value as CodeableConcept
    }

// TODO: Check that inpatientStay is more than 4 days
define "Encounter with HOB Result":
  "Encounter With COB Result" E
    let results: (
      "Bacteremia or Fungemia Result With Specimen" RS
        where RS.specimen.collection.collected.toInterval()
          during day of Interval[start of E.inpatientStay + 4 days, end of E.inpatientStay]
          and not exists (
            E.organisms O
              where O.organismMatches(RS.result.value as CodeableConcept)
          )
          and not exists (
            E.ocobOrganisms O
              where O.organismMatches(RS.result.value as CodeableConcept)
          )
    )
    return {
      encounter: E.encounter,
      observationVisit: E.observationVisit,
      edVisit: E.edVisit,
      edOrObservationPeriod: E.edOrObservationPeriod,
      inpatientStay: E.inpatientStay,
      ocobIndexDate: E.ocobIndexDate,
      ocobOrganisms: E.ocobOrganisms,
      cobIndexDate: E.indexDate,
      cobOrganisms: E.organisms,
      indexDate: Min(results R return start of R.specimen.collection.collected.toInterval()),
      organisms: results R return R.result.value as CodeableConcept
    }



/*
Draft CQL representation of Hospital Onset Bacteremia and Fungemia Surveillance Measure
NOTE: Direct copy of HOB to support testing the NHSN test cases
*/
library HOBNHSN

using FHIR version '4.0.1'

include hl7.fhir.uv.cql.FHIRHelpers version '4.0.1' called FHIRHelpers
include hl7.fhir.uv.cql.FHIRCommon version '2.0.0' called FHIRCommon

include CQMCommon version '5.1.000' called CQMCommon
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

parameter "Measurement Period" Interval<DateTime> default Interval[@2025-01-01T00:00:00.0, @2025-01-31T23:59:59.999]

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

define "Bacterial and Fungal Blood Culture Test Results":
  [Observation: "Bacterial and Fungal Blood Culture Tests"] O
    where O.isLaboratory()
      and O.isResulted()

define "Bacteremia or Fungemia Result":
  "Bacterial and Fungal Blood Culture Test Results" R
    where ((R.value as CodeableConcept) in "Bacteria and Fungi - HOB Specific")
      and not ((R.value as CodeableConcept) in "Bacterial Skin Commensals")

define "Bacteremia or Fungemia Result With Specimen":
  from
    "Bacteremia or Fungemia Result" R,
    [Specimen: "Specimen Type - Blood"] S
    where R.specimen.references(S)
    return {
      result: R,
      specimen: S
    }

// Assertion is that there is never more than one ED/Observation preceding an inpatient stay
// i.e. ED -> ED -> Inpatient, ED -> Observation -> ED -> Inpatient, Observation -> Inpatient are all combinations that will never appear
// TODO: This does not currently hold for real-world data, need to build encounter normalization logic
// Note also that Encounter.classHistory is not defined, so Encounter.hospitalization.location will have a more accurate representation of class over time
define "Outpatient Encounter":
  [Encounter: CQMCommon."Emergency Department Visit"] ED
    let observationEncounter: First(
      [Encounter: CQMCommon."Observation Services"] O
        where O.period starts 1 hour or less on or after end of ED.period
        sort by start of period
    ),
    endOfStay: Coalesce(end of observationEncounter.period, end of ED.period),
    inpatientEncounter: First(
      [Encounter: CQMCommon."Encounter Inpatient"] E
        where E.period starts 1 hour or less on or after endOfStay
    )
  return {
    edEncounter: ED,
    observationEncounter: observationEncounter,
    inpatientEncounter: inpatientEncounter,
    outpatientStay: Interval[start of ED.period, Coalesce(start of inpatientEncounter.period, endOfStay)],
    inpatientStay: inpatientEncounter.period
  }

define "Inpatient Encounter":
  [Encounter: CQMCommon."Encounter Inpatient"] E
    let observationEncounter: Last(
      [Encounter: CQMCommon."Observation Services"] O
        where O.period ends 1 hour or less on or before start of E.period
        sort by end of period
    ),
    visitStart: Coalesce(start of observationEncounter.period, start of E.period),
    edEncounter: Last(
      [Encounter: CQMCommon."Emergency Department Visit"] ED
        where ED.period ends 1 hour or less on or before visitStart
        sort by end of period
    ),
    outpatientStay:
      if observationEncounter is null and edEncounter is null then
        null
      else
        Interval[Coalesce(start of edEncounter.period, start of observationEncounter.period), start of E.period]
    return {
      edEncounter: edEncounter,
      observationEncounter: observationEncounter,
      inpatientEncounter: E,
      outpatientStay: outpatientStay,
      inpatientStay: E.period
    }

// TODO: USCDI+ Quality/USCDI Gap (Specimen Collection Time)
// NOTE: Can we use effectiveTime here rather than Specimen Collection Time
define "Encounter With O-COB Result":
  "Outpatient Encounter" E
    let results: (
      "Bacteremia or Fungemia Result With Specimen" RS 
        where RS.specimen.collection.collected.toInterval()
          during E.outpatientStay
    )
    where exists (results)
    return {
      edEncounter: E.edEncounter,
      observationEncounter: E.observationEncounter,
      inpatientEncounter: E.inpatientEncounter,
      outpatientStay: E.outpatientStay,
      inpatientStay: E.inpatientStay,
      indexDate: Min(results R return start of R.specimen.collection.collected.toInterval()),
      organisms: results R return R.result.value as CodeableConcept
    }

define "Encounter With COB Result":
  "Inpatient Encounter" E
    let 
      oCOB: "Encounter With O-COB Result" oCOBEncounter where E.inpatientEncounter.id = oCOBEncounter.inpatientEncounter.id,
      results: (
        "Bacteremia or Fungemia Result With Specimen" RS
          where RS.specimen.collection.collected.toInterval()
            during Interval[start of E.inpatientStay, start of E.inpatientStay + 3 days]
            and not exists (
              oCOB.organisms O
                where O.organismMatches(RS.result.value as CodeableConcept)
            )
    )
    where exists (results)
    return {
      edEncounter: E.edEncounter,
      observationEncounter: E.observationEncounter,
      inpatientEncounter: E.inpatientEncounter,
      outpatientStay: E.outpatientStay,
      outpatientStayStart: start of E.outpatientStay,
      outpatientStayEnd: end of E.outpatientStay,
      inpatientStay: E.inpatientStay,
      inpatientStayStart: start of E.inpatientStay,
      inpatientEligibleTo: start of E.inpatientStay + 3 days,
      inpatientStayEnd: end of E.inpatientStay,
      indexDate: Min(results R return start of R.specimen.collection.collected.toInterval()),
      organisms: results R return R.result.value as CodeableConcept
    }

define "Encounter With HOB Result":
  "Inpatient Encounter" E
    let 
      oCOB: "Encounter With O-COB Result" oCOBEncounter where E.inpatientEncounter.id = oCOBEncounter.inpatientEncounter.id,
      COB: "Encounter With COB Result" COBEncounter where E.inpatientEncounter.id = COBEncounter.inpatientEncounter.id,
      // Guard the interval: for stays of 3 days or fewer, start + 3 days is after the
      // stay end, which would construct an inverted (invalid) interval and error.
      hospitalOnsetWindow:
        if duration in days of E.inpatientStay > 3
          then Interval[start of E.inpatientStay + 3 days, end of E.inpatientStay]
          else null as Interval<DateTime>,
      results: (
        "Bacteremia or Fungemia Result With Specimen" RS
          where RS.specimen.collection.collected.toInterval()
            during hospitalOnsetWindow
            and not exists (
              oCOB.organisms O
                where O.organismMatches(RS.result.value as CodeableConcept)
            )
            and not exists (
              COB.organisms O
                where O.organismMatches(RS.result.value as CodeableConcept)
            )
    )
    where duration in days of E.inpatientStay > 3
      and exists (results)
    return {
      edEncounter: E.edEncounter,
      observationEncounter: E.observationEncounter,
      inpatientEncounter: E.inpatientEncounter,
      outpatientStay: E.outpatientStay,
      inpatientStay: E.inpatientStay,
      indexDate: Min(results R return start of R.specimen.collection.collected.toInterval()),
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
    where O.outpatientStay overlaps "Measurement Period"

define "O-COB Prevalence Rate Initial Population":
  "Outpatient Encounter During Measurement Period" O
    return O.edEncounter

define "O-COB Prevalence Rate Denominator":
  "Outpatient Encounter During Measurement Period" O
    return O.edEncounter

define "O-COB Prevlanece Rate Numerator":
  "Encounter With O-COB Result" OCOBEvent
    where OCOBEvent.indexDate during "Measurement Period"
    return OCOBEvent.edEncounter

/*
Metric: Inpatient COB Prevalence Rate
Scoring: Proportion
Numerator: Number of inpatient COB events occurring within the measurement period
Denominator: Number of inpatient stays where at least one of the first three inpatient calendar days falls within the measurement period
*/

define "Community Eligible Inpatient Encounter During Measurement Period":
  "Inpatient Encounter" I
    let communityEligible: Interval[start of I.inpatientStay, Min({ start of I.inpatientStay + 3 days, end of I.inpatientStay })]
    where communityEligible overlaps "Measurement Period"

define "COB Prevalence Rate Initial Population":
  "Community Eligible Inpatient Encounter During Measurement Period" I
    return I.inpatientEncounter // Tricky... encounter normalization will address this

define "COB Prevalence Rate Denominator":
  "Community Eligible Inpatient Encounter During Measurement Period" I
    return I.inpatientEncounter // Tricky... encounter normalization will address this

define "COB Prevalence Rate Numerator":
  "Encounter With COB Result" COBEvent
    where COBEvent.indexDate during "Measurement Period"
    return COBEvent.inpatientEncounter  

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
    // Guard the interval: for stays of 3 days or fewer, start + 4 days is after the
    // stay end, which would construct an inverted (invalid) interval and error. The
    // conditional also subsumes the duration > 3 eligibility check.
    let hospitalEligible:
      if duration in days of I.inpatientStay > 3
        then Interval[start of I.inpatientStay + 4 days, end of I.inpatientStay]
        else null as Interval<DateTime>
    where hospitalEligible overlaps "Measurement Period"
      and not exists (
        "Encounter With HOB Result" HOBEvent
          where HOBEvent.inpatientEncounter ~ I.inpatientEncounter
            and HOBEvent.indexDate before start of "Measurement Period"
      )

define "HOB Crude Risk Initial Population":
  "Hospital Eligible Inpatient Encounter During Measurement Period" I
    return I.inpatientEncounter

define "HOB Crude Risk Denominator":
  "Hospital Eligible Inpatient Encounter During Measurement Period" I
    return I.inpatientEncounter

define "HOB Crude Risk Numerator":
  "Encounter With HOB Result" HOBEvent
    where HOBEvent.indexDate during "Measurement Period"
    return HOBEvent.inpatientEncounter

/*
Metric: HOB Incidence Density
Scoring: Ratio /100.d
Numerator: Number of HOB events
Denominator: Number of inpatient days eligible for a hospital-onset event during the measurement period
Notes: Eligible patient days are defined as: Inpatient day 4 until discharge or index HOB event date
*/

define "HOB Incidence Density Initial Population":
  "Hospital Eligible Inpatient Encounter During Measurement Period" I
    return I.inpatientEncounter

define "HOB Incidence Density Denominator":
  "Hospital Eligible Inpatient Encounter During Measurement Period" I
    return I.inpatientEncounter

define function "HOB Incidence Density Denominator Observation"(encounter Encounter):
  days between start of encounter.period + 4 days
    and Min({
      ("Encounter With HOB Result" HOBEvent where HOBEvent.inpatientEncounter ~ encounter).single().indexDate,
      end of encounter.period
    })

define "HOB Incidence Density Numerator":
  "Encounter With HOB Result" I
    return I.inpatientEncounter

// Just counting, so return 1
define function "HOB Incidence Density Numerator Observation"(encounter Encounter):
  1


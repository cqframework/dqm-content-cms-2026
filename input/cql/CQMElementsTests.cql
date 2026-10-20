/*
@description: Tests for the CQMElements library
@comment: Each test expression is named `Test...` and evaluates to `true` when the test passes.

The test data is in `input/tests/CQMElementsTests/<case>/`, one folder per patient, with the patient id
equal to the folder name. See the README there for what each case contains. Every expression is
evaluated once per case, so:
* Case tests list the expected result for each case they cover, and are `true` for any other case.
* Invariant tests (marked as such) must hold for every case.

So every test must be `true` on every case: `false` or `null` is a failure. A `null` on a case a test
covers means the assertion couldn't be evaluated, e.g. because an element it reads came back null.
Because a case a test doesn't cover passes, a misspelled case name in a `when` clause would pass
silently; `.claude/skills/cql/check_results.py` checks the names against the case folders.

The retrieves and the visit functions need the CQMConcepts value set expansions, and the test data uses
codes that are members of them.
*/
library CQMElementsTests version '0.3.000-draft'

using USQualityCore version '0.5.0'
using USCore version '6.1.0-derived'
using FHIR version '4.0.1'

include hl7.fhir.uv.cql.FHIRHelpers version '4.0.1'
include hl7.fhir.uv.cql.FHIRCommon version '2.0.0'

include CQMConcepts version '0.3.000-draft'
include CQMElements version '0.3.000-draft'

codesystem "HSLOC": 'https://www.cdc.gov/nhsn/cdaportal/terminology/codesystem/hsloc.html'

code "Medical Critical Care": '1027-2' from "HSLOC" display 'Medical Critical Care'

context Patient

/*
 * Helpers
 */

// The case is the patient id, which is also the name of the test case folder
define "Case": FHIRHelpers.ToString(Patient.id)

define function "Ids"(resources List<FHIR.Resource>):
  resources R
    return R.id.value

// True if the resources have exactly the given ids, in any order
define function "Has Ids"(resources List<FHIR.Resource>, ids List<String>):
  Count(resources) = Count(ids)
    and "Ids"(resources) includes ids

define function "Find"(encounters List<USQualityCore.Encounter>, id String):
  singleton from (encounters E where E.id = id)

/*
 * Data
 */

define "Encounters": [USQualityCore.Encounter]

define "Locations": [USQualityCore.Location]

define "Hospitalizations": CQMElements."Hospitalization Encounters"("Encounters")

define "Normalized": CQMElements."Normalize Encounters"("Encounters")

// The hospitalization each case is mostly about: the one ending with the case's inpatient encounter
define "Inpatient Hospitalization":
  case "Case"
    when '01-ED-Observation-Inpatient' then "Find"("Hospitalizations", 'inp-01')
    when '02-ED-Inpatient-Gap-Over-Hour' then "Find"("Hospitalizations", 'inp-02')
    when '03-Surgery-Inpatient' then "Find"("Hospitalizations", 'inp-03')
    when '04-Cancelled-ED-Inpatient' then "Find"("Hospitalizations", 'inp-04')
    when '05-Gap-Exactly-One-Hour' then "Find"("Hospitalizations", 'inp-05')
    when '06-Gap-One-Hour-One-Minute' then "Find"("Hospitalizations", 'inp-06')
    when '07-Inpatient-Two-ICU-Stays' then "Find"("Hospitalizations", 'inp-07')
    else null
  end

/*
 * Retrieves
 */

define TestInpatientEncounter:
  case "Case"
    when '01-ED-Observation-Inpatient' then "Has Ids"(CQMElements."Inpatient Encounter", { 'inp-01' })
    when '03-Surgery-Inpatient' then "Has Ids"(CQMElements."Inpatient Encounter", { 'inp-03' })
    when '08-No-Encounters' then not exists CQMElements."Inpatient Encounter"
    else true
  end

define TestEmergencyDepartmentEncounter:
  case "Case"
    when '01-ED-Observation-Inpatient' then "Has Ids"(CQMElements."Emergency Department Encounter", { 'ed-01' })
    when '02-ED-Inpatient-Gap-Over-Hour' then "Has Ids"(CQMElements."Emergency Department Encounter", { 'ed-02' })
    // A cancelled visit is excluded
    when '04-Cancelled-ED-Inpatient' then not exists CQMElements."Emergency Department Encounter"
    else true
  end

define TestObservationEncounter:
  case "Case"
    when '01-ED-Observation-Inpatient' then "Has Ids"(CQMElements."Observation Encounter", { 'obs-01' })
    when '02-ED-Inpatient-Gap-Over-Hour' then not exists CQMElements."Observation Encounter"
    else true
  end

define TestOutpatientSurgeryEncounter:
  case "Case"
    when '03-Surgery-Inpatient' then "Has Ids"(CQMElements."Outpatient Surgery Encounter", { 'surg-03' })
    when '01-ED-Observation-Inpatient' then not exists CQMElements."Outpatient Surgery Encounter"
    else true
  end

// Invariant
define TestRetrievedEncountersFinished:
  AllTrue(CQMElements."Inpatient Encounter" E return E.status = 'finished')
    and AllTrue(CQMElements."Emergency Department Encounter" E return E.status = 'finished')
    and AllTrue(CQMElements."Observation Encounter" E return E.status = 'finished')
    and AllTrue(CQMElements."Outpatient Surgery Encounter" E return E.status = 'finished')

/*
 * Hospitalization Encounters
 */

define TestHospitalizationEncounters:
  case "Case"
    when '01-ED-Observation-Inpatient' then "Has Ids"("Hospitalizations", { 'inp-01' })
    // A gap of more than an hour separates the hospitalizations
    when '02-ED-Inpatient-Gap-Over-Hour' then "Has Ids"("Hospitalizations", { 'ed-02', 'inp-02' })
    when '03-Surgery-Inpatient' then "Has Ids"("Hospitalizations", { 'inp-03' })
    when '04-Cancelled-ED-Inpatient' then "Has Ids"("Hospitalizations", { 'inp-04' })
    // A gap of exactly one hour does not
    when '05-Gap-Exactly-One-Hour' then "Has Ids"("Hospitalizations", { 'inp-05' })
    when '06-Gap-One-Hour-One-Minute' then "Has Ids"("Hospitalizations", { 'ed-06', 'inp-06' })
    when '07-Inpatient-Two-ICU-Stays' then "Has Ids"("Hospitalizations", { 'inp-07' })
    when '08-No-Encounters' then not exists "Hospitalizations"
    else true
  end

define TestHospitalizationEncountersContainedInOrder:
  case "Case"
    when '01-ED-Observation-Inpatient' then "Ids"("Inpatient Hospitalization".contained) = { 'ed-01', 'obs-01', 'inp-01' }
    when '02-ED-Inpatient-Gap-Over-Hour' then "Ids"("Inpatient Hospitalization".contained) = { 'inp-02' }
    when '03-Surgery-Inpatient' then "Ids"("Inpatient Hospitalization".contained) = { 'surg-03', 'inp-03' }
    // The function does not filter by status, so a cancelled encounter in the input is included
    when '04-Cancelled-ED-Inpatient' then "Ids"("Inpatient Hospitalization".contained) = { 'ed-04', 'inp-04' }
    when '05-Gap-Exactly-One-Hour' then "Ids"("Inpatient Hospitalization".contained) = { 'ed-05', 'inp-05' }
    else true
  end

// Callers are expected to pass only the encounters that should form hospitalizations, such as the
// finished encounters from the CQMElements retrieves
define TestHospitalizationEncountersFilteredInput:
  case "Case"
    when '04-Cancelled-ED-Inpatient' then
      "Ids"(
        "Find"(
          CQMElements."Hospitalization Encounters"(CQMElements."Inpatient Encounter" union CQMElements."Emergency Department Encounter"),
          'inp-04'
        ).contained
      ) = { 'inp-04' }
    else true
  end

define TestHospitalizationEncountersIncludedEncounterExtensions:
  case "Case"
    when '01-ED-Observation-Inpatient' then
      ("Inpatient Hospitalization".extension E return all E.url.value)
        = List<String>{
          'http://cql.hl7.org/transient/StructureDefinition/includedEncounter',
          'http://cql.hl7.org/transient/StructureDefinition/includedEncounter',
          'http://cql.hl7.org/transient/StructureDefinition/includedEncounter'
        }
    else true
  end

define TestHospitalizationEncountersKeepsLastEncounterElements:
  case "Case"
    when '01-ED-Observation-Inpatient' then
      "Inpatient Hospitalization".period ~ "Find"("Encounters", 'inp-01').period
        and "Inpatient Hospitalization".status = 'finished'
        and "Inpatient Hospitalization".type ~ "Find"("Encounters", 'inp-01').type
        and "Inpatient Hospitalization".subject.reference = 'Patient/01-ED-Observation-Inpatient'
        and "Inpatient Hospitalization".location ~ "Find"("Encounters", 'inp-01').location
    else true
  end

// Invariant
define TestHospitalizationEncountersEmptyInput:
  not exists CQMElements."Hospitalization Encounters"(List<USQualityCore.Encounter>{})

// Invariant: every retrieved encounter is included in exactly one hospitalization
define TestHospitalizationEncountersIncludeEveryEncounter:
  Count(flatten ("Hospitalizations" H return H.includedEncounters())) = Count("Encounters")

/*
 * Normalize Encounters
 */

define TestNormalizeEncounters:
  case "Case"
    when '01-ED-Observation-Inpatient' then "Has Ids"("Normalized", { 'inp-01-primary' })
    when '02-ED-Inpatient-Gap-Over-Hour' then "Has Ids"("Normalized", { 'ed-02-primary', 'inp-02-primary' })
    when '08-No-Encounters' then not exists "Normalized"
    else true
  end

define TestNormalizeEncountersPeriodSpansEpisode:
  case "Case"
    when '01-ED-Observation-Inpatient' then
      start of "Find"("Normalized", 'inp-01-primary').period = @2024-03-01T08:00:00.000Z
        and end of "Find"("Normalized", 'inp-01-primary').period = @2024-03-05T10:00:00.000Z
    else true
  end

define TestNormalizeEncountersKeepsLastEncounterElements:
  case "Case"
    when '01-ED-Observation-Inpatient' then
      "Find"("Normalized", 'inp-01-primary').status = 'finished'
        and "Find"("Normalized", 'inp-01-primary').type ~ "Find"("Encounters", 'inp-01').type
        and "Find"("Normalized", 'inp-01-primary').subject.reference = 'Patient/01-ED-Observation-Inpatient'
    else true
  end

define TestNormalizeEncountersFlattensLocations:
  case "Case"
    when '01-ED-Observation-Inpatient' then
      (("Find"("Normalized", 'inp-01-primary').location) L return all L.location.reference.value)
        = { 'Location/er-01', 'Location/obs-unit-01', 'Location/ward-01', 'Location/icu-01', 'Location/ward-01' }
    else true
  end

define TestNormalizeEncountersIncludedEncounters:
  case "Case"
    when '01-ED-Observation-Inpatient' then
      "Ids"("Find"("Normalized", 'inp-01-primary').contained) = { 'ed-01', 'obs-01', 'inp-01' }
        and "Ids"("Find"("Normalized", 'inp-01-primary').includedEncounters()) = { 'ed-01', 'obs-01', 'inp-01' }
    else true
  end

/*
 * includedEncounters
 */

define TestIncludedEncounters:
  case "Case"
    when '01-ED-Observation-Inpatient' then "Ids"("Inpatient Hospitalization".includedEncounters()) = { 'ed-01', 'obs-01', 'inp-01' }
    when '02-ED-Inpatient-Gap-Over-Hour' then "Ids"("Inpatient Hospitalization".includedEncounters()) = { 'inp-02' }
    else true
  end

// Invariant: a retrieved encounter, not built by Hospitalization Encounters, has no included encounters
define TestIncludedEncountersNoneOnRetrievedEncounter:
  AllTrue("Encounters" E return not exists E.includedEncounters())

/*
 * Encounter location entries and locations
 */

define TestEncounterLocationEntries:
  case "Case"
    when '01-ED-Observation-Inpatient' then
      Count(CQMElements."Encounter Location Entries"("Hospitalizations")) = 5
        and AllTrue((CQMElements."Encounter Location Entries"("Hospitalizations")) E return E.encounterId = 'inp-01')
    when '02-ED-Inpatient-Gap-Over-Hour' then
      Count((CQMElements."Encounter Location Entries"("Hospitalizations")) E where E.encounterId = 'ed-02') = 1
        and Count((CQMElements."Encounter Location Entries"("Hospitalizations")) E where E.encounterId = 'inp-02') = 1
    // The surgery has no locations, so only the inpatient location is listed
    when '03-Surgery-Inpatient' then Count(CQMElements."Encounter Location Entries"("Hospitalizations")) = 1
    else true
  end

define TestEncounterLocationEntriesElements:
  case "Case"
    when '01-ED-Observation-Inpatient' then
      exists (
        (CQMElements."Encounter Location Entries"("Hospitalizations")) E
          where E.location.reference = 'Location/icu-01'
            and E.status = 'completed'
            and start of E.period = @2024-03-02T08:00:00.000Z
            and end of E.period = @2024-03-04T08:00:00.000Z
      )
    else true
  end

// Invariant
define TestEncounterLocationEntriesEmptyInput:
  not exists CQMElements."Encounter Location Entries"(List<USQualityCore.Encounter>{})

// Invariant: every location on every retrieved encounter is represented by an entry
define TestAllEncounterLocationEntries:
  Count(CQMElements."All Encounter Location Entries")
    = Count(flatten ("Encounters" E return E.location))

define TestEncounterLocations:
  case "Case"
    when '01-ED-Observation-Inpatient' then
      Count(CQMElements."Encounter Locations"("Hospitalizations", "Locations")) = 5
        and exists (
          (CQMElements."Encounter Locations"("Hospitalizations", "Locations")) L
            where L.location.id = 'icu-01'
              and L.location.type.includesCode("Medical Critical Care")
              and start of L.period = @2024-03-02T08:00:00.000Z
        )
    else true
  end

define TestEncounterLocationsDropsUnresolvedReferences:
  case "Case"
    when '01-ED-Observation-Inpatient' then
      "Has Ids"(
        (CQMElements."Encounter Locations"("Hospitalizations", "Locations" L where L.id in { 'er-01', 'icu-01' })) EL
          return EL.location,
        { 'er-01', 'icu-01' }
      )
    else true
  end

// Invariant: every resolved location is one of the retrieved locations
define TestAllEncounterLocationsReferenceRetrievedLocations:
  AllTrue(
    CQMElements."All Encounter Locations" L
      return L.location.id in "Ids"("Locations")
  )

define TestEmergencyDepartmentLocations:
  case "Case"
    when '01-ED-Observation-Inpatient' then
      "Has Ids"((CQMElements."Emergency Department Locations"("Hospitalizations", "Locations")) EL return EL.location, { 'er-01' })
    // An emergency trauma unit is an emergency department location
    when '02-ED-Inpatient-Gap-Over-Hour' then
      "Has Ids"((CQMElements."Emergency Department Locations"("Hospitalizations", "Locations")) EL return EL.location, { 'etu-02' })
    when '03-Surgery-Inpatient' then
      not exists CQMElements."Emergency Department Locations"("Hospitalizations", "Locations")
    else true
  end

/*
 * Hospitalization timing functions
 */

define TestHospitalization:
  case "Case"
    when '01-ED-Observation-Inpatient' then
      "Inpatient Hospitalization".hospitalization() = Interval[@2024-03-01T08:00:00.000Z, @2024-03-05T10:00:00.000Z]
    when '02-ED-Inpatient-Gap-Over-Hour' then
      "Inpatient Hospitalization".hospitalization() = Interval[@2024-06-01T09:00:00.000Z, @2024-06-03T09:00:00.000Z]
    when '03-Surgery-Inpatient' then
      "Inpatient Hospitalization".hospitalization() = Interval[@2024-08-01T06:00:00.000Z, @2024-08-03T10:00:00.000Z]
    when '05-Gap-Exactly-One-Hour' then
      "Inpatient Hospitalization".hospitalization() = Interval[@2024-10-01T08:00:00.000Z, @2024-10-02T10:00:00.000Z]
    else true
  end

define TestHospitalizationLocations:
  case "Case"
    when '01-ED-Observation-Inpatient' then
      (("Inpatient Hospitalization".hospitalizationLocations()) L return all L.location.reference.value)
        = { 'Location/er-01', 'Location/obs-unit-01', 'Location/ward-01', 'Location/icu-01', 'Location/ward-01' }
    when '03-Surgery-Inpatient' then
      (("Inpatient Hospitalization".hospitalizationLocations()) L return L.location.reference.value)
        = { 'Location/ward-03' }
    else true
  end

define TestHospitalizationLengthOfStay:
  case "Case"
    when '01-ED-Observation-Inpatient' then "Inpatient Hospitalization".hospitalizationLengthOfStay() = 4
    when '02-ED-Inpatient-Gap-Over-Hour' then "Inpatient Hospitalization".hospitalizationLengthOfStay() = 2
    // Same-day ED visit
    when '06-Gap-One-Hour-One-Minute' then "Find"("Hospitalizations", 'ed-06').hospitalizationLengthOfStay() = 0
    else true
  end

define TestHospitalAdmissionTime:
  case "Case"
    when '01-ED-Observation-Inpatient' then "Inpatient Hospitalization".hospitalAdmissionTime() = @2024-03-01T08:00:00.000Z
    when '02-ED-Inpatient-Gap-Over-Hour' then "Inpatient Hospitalization".hospitalAdmissionTime() = @2024-06-01T09:00:00.000Z
    when '03-Surgery-Inpatient' then "Inpatient Hospitalization".hospitalAdmissionTime() = @2024-08-01T06:00:00.000Z
    else true
  end

define TestHospitalDischargeTime:
  case "Case"
    when '01-ED-Observation-Inpatient' then
      "Inpatient Hospitalization".hospitalDischargeTime() = @2024-03-05T10:00:00.000Z
        // The discharge time doesn't depend on the included encounters
        and "Find"("Encounters", 'inp-01').hospitalDischargeTime() = @2024-03-05T10:00:00.000Z
    else true
  end

define TestHospitalArrivalTime:
  case "Case"
    when '01-ED-Observation-Inpatient' then "Inpatient Hospitalization".hospitalArrivalTime() = @2024-03-01T08:00:00.000Z
    // Arrival is read from locations, and the surgery has none, so arrival is the start of the inpatient
    // location, later than the admission time
    when '03-Surgery-Inpatient' then "Inpatient Hospitalization".hospitalArrivalTime() = @2024-08-01T10:30:00.000Z
    else true
  end

define TestHospitalDepartureTime:
  case "Case"
    when '01-ED-Observation-Inpatient' then "Inpatient Hospitalization".hospitalDepartureTime() = @2024-03-05T10:00:00.000Z
    when '02-ED-Inpatient-Gap-Over-Hour' then "Inpatient Hospitalization".hospitalDepartureTime() = @2024-06-03T09:00:00.000Z
    else true
  end

define TestEmergencyDepartmentArrivalTime:
  case "Case"
    when '01-ED-Observation-Inpatient' then
      "Inpatient Hospitalization".emergencyDepartmentArrivalTime() = @2024-03-01T08:00:00.000Z
    when '02-ED-Inpatient-Gap-Over-Hour' then
      "Find"("Hospitalizations", 'ed-02').emergencyDepartmentArrivalTime() = @2024-06-01T03:00:00.000Z
        and "Inpatient Hospitalization".emergencyDepartmentArrivalTime() is null
    when '03-Surgery-Inpatient' then
      "Inpatient Hospitalization".emergencyDepartmentArrivalTime() is null
    else true
  end

// Invariant
define TestEmergencyDepartmentArrivalTimeDuringHospitalization:
  AllTrue(
    "Hospitalizations" H
      let arrival: H.emergencyDepartmentArrivalTime()
      where arrival is not null
      return arrival during H.hospitalization()
        and arrival on or after H.hospitalArrivalTime()
  )

define TestFirstInpatientIntensiveCareUnit:
  case "Case"
    when '01-ED-Observation-Inpatient' then
      "Find"("Encounters", 'inp-01').firstInpatientIntensiveCareUnit().location.reference = 'Location/icu-01'
        and start of "Find"("Encounters", 'inp-01').firstInpatientIntensiveCareUnit().period = @2024-03-02T08:00:00.000Z
        and end of "Find"("Encounters", 'inp-01').firstInpatientIntensiveCareUnit().period = @2024-03-04T08:00:00.000Z
    // The earliest ICU stay during the encounter, regardless of the order the locations are listed in,
    // and ignoring an ICU entry outside the encounter period
    when '07-Inpatient-Two-ICU-Stays' then
      "Find"("Encounters", 'inp-07').firstInpatientIntensiveCareUnit().location.reference = 'Location/icu-a-07'
    when '02-ED-Inpatient-Gap-Over-Hour' then
      "Find"("Encounters", 'inp-02').firstInpatientIntensiveCareUnit() is null
    else true
  end

/*
 * Visit functions
 */

define TestEdVisit:
  case "Case"
    when '01-ED-Observation-Inpatient' then "Inpatient Hospitalization".edVisit().id = 'ed-01'
    when '02-ED-Inpatient-Gap-Over-Hour' then "Inpatient Hospitalization".edVisit() is null
    // A cancelled ED visit is not an ED visit, even though it is an included encounter
    when '04-Cancelled-ED-Inpatient' then "Inpatient Hospitalization".edVisit() is null
    when '05-Gap-Exactly-One-Hour' then "Inpatient Hospitalization".edVisit().id = 'ed-05'
    when '06-Gap-One-Hour-One-Minute' then "Inpatient Hospitalization".edVisit() is null
    else true
  end

define TestObservationVisit:
  case "Case"
    when '01-ED-Observation-Inpatient' then "Inpatient Hospitalization".observationVisit().id = 'obs-01'
    when '03-Surgery-Inpatient' then "Inpatient Hospitalization".observationVisit() is null
    else true
  end

define TestOutpatientSurgeryVisit:
  case "Case"
    when '03-Surgery-Inpatient' then "Inpatient Hospitalization".outpatientSurgeryVisit().id = 'surg-03'
    when '01-ED-Observation-Inpatient' then "Inpatient Hospitalization".outpatientSurgeryVisit() is null
    else true
  end

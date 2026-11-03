/*
@description: Tests for the CQMElements library
@comment: Each test expression is named `Test...` and evaluates to `true` when the test passes.

The test data is in `input/tests/CQMElementsTests/<patient id>/`, one folder per patient. Patient ids
are GUIDs, as MADiE expects, so each case is identified by its label, the patient's given name (e.g.
`01-ED-Observation-Inpatient`). See the README there for what each case contains. Every expression is
evaluated once per case, so:
* Case tests list the expected result for each case they cover, and are `true` for any other case.
* Invariant tests (marked as such) must hold for every case.

So every test must be `true` on every case: `false` or `null` is a failure. A `null` on a case a test
covers means the assertion couldn't be evaluated, e.g. because an element it reads came back null.
Because a case a test doesn't cover passes, a misspelled case name in a `when` clause would pass
silently; `.claude/skills/cql/check_results.py` checks the names against the case labels.

MADiE also replaces resource ids that aren't GUIDs with new GUIDs on import, so the tests don't use
resource ids. Each resource has a readable key (e.g. `inp-01`) in an identifier with the system
`http://example.org/fhir/identifiers`, and the tests find resources, and check which resources a
result holds, by that key (`"EncounterKey"`, `"LocationKey"`, `"Find"`).

The retrieves and the visit functions need the CQMConcepts value set expansions, and the test data uses
codes that are members of them.

NOTE: This library is developed in the dqm-content-cms-2026 repository:
https://github.com/cqframework/dqm-content-cms-2026/blob/main/input/cql/CQMElementsTests.cql

NOTE: This is in the process of being established as the measure CQMConceptsTests in MADiE:
https://madie.cms.gov/measures/6ad7eeae1fbcbfc8d7e0c8de/edit/details/
*/
library CQMElementsTests version '0.5.000'

using USQualityCore version '0.5.0'
using USCore version '6.1.0-derived'
using FHIR version '4.0.1'

include hl7.fhir.uv.cql.FHIRHelpers version '4.0.1'
include hl7.fhir.uv.cql.FHIRCommon version '2.0.0'

include CQMConcepts version '0.5.000'
include CQMElements version '0.5.000'

codesystem "HSLOC": 'https://www.cdc.gov/nhsn/cdaportal/terminology/codesystem/hsloc.html'

code "Medical Critical Care": '1027-2' from "HSLOC" display 'Medical Critical Care'

context Patient

/*
 * Helpers
 */

// The case is the test case label, which is the patient's given name. The patient id (and the name of
// the test case folder) is a GUID, as MADiE expects, so it doesn't say which case this is.
define "Case": FHIRHelpers.ToString(First(Patient.name.given))

define "Patient Reference": 'Patient/' + FHIRHelpers.ToString(Patient.id)

// Resources are identified by a readable key (e.g. `inp-01`) in an identifier with this system, not by
// their ids: MADiE replaces resource ids that aren't GUIDs with new GUIDs on import
define "Key System": 'http://example.org/fhir/identifiers'

// The key functions are separate for each resource type, rather than one function over FHIR.Resource
// with `is` / `as`, and are not overloads of one name: the MADiE engine resolves neither `is` nor
// overloads like these correctly at runtime.
define function "EncounterKey"(encounter FHIR.Encounter):
  singleton from (
    encounter.identifier I
      where I.system = "Key System"
      return I.value.value
  )

define function "LocationKey"(location FHIR.Location):
  singleton from (
    location.identifier I
      where I.system = "Key System"
      return I.value.value
  )

// The key of the retrieved location a reference points to
define function "ResolveKey"(reference FHIR.Reference):
  "LocationKey"(singleton from ("Locations" L where reference.references(L)))

define function "EncounterKeys"(encounters List<FHIR.Encounter>):
  encounters E
    return all "EncounterKey"(E)

define function "LocationKeys"(locations List<FHIR.Location>):
  locations L
    return all "LocationKey"(L)

// The keys of contained encounters. Contained resources are typed FHIR.Resource, which has no
// identifier, and reading it would need `as`, so each is matched by id to the retrieved encounter it
// is a copy of.
define function "ContainedKeys"(resources List<FHIR.Resource>):
  resources R
    return all "EncounterKey"(singleton from ("Encounters" E where E.id.value = R.id.value))

// True if the encounters (or the locations) have exactly the given keys, in any order
define function "HasEncounterKeys"(encounters List<FHIR.Encounter>, keys List<String>):
  Count(encounters) = Count(keys)
    and "EncounterKeys"(encounters) includes keys

define function "HasLocationKeys"(locations List<FHIR.Location>, keys List<String>):
  Count(locations) = Count(keys)
    and "LocationKeys"(locations) includes keys

define function "Find"(encounters List<USQualityCore.Encounter>, key String):
  singleton from (encounters E where "EncounterKey"(E) = key)

// A normalized encounter has no identifier; its id is the id of its last included encounter plus
// `-primary`
define function "Find Normalized"(key String):
  singleton from ("Normalized" N where N.id = "Find"("Encounters", key).id + '-primary')

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
    when '01-ED-Observation-Inpatient' then "HasEncounterKeys"(CQMElements."Inpatient Encounter", { 'inp-01' })
    when '03-Surgery-Inpatient' then "HasEncounterKeys"(CQMElements."Inpatient Encounter", { 'inp-03' })
    when '08-No-Encounters' then not exists CQMElements."Inpatient Encounter"
    else true
  end

define TestEmergencyDepartmentEncounter:
  case "Case"
    when '01-ED-Observation-Inpatient' then "HasEncounterKeys"(CQMElements."Emergency Department Encounter", { 'ed-01' })
    when '02-ED-Inpatient-Gap-Over-Hour' then "HasEncounterKeys"(CQMElements."Emergency Department Encounter", { 'ed-02' })
    // A cancelled visit is excluded
    when '04-Cancelled-ED-Inpatient' then not exists CQMElements."Emergency Department Encounter"
    else true
  end

define TestObservationEncounter:
  case "Case"
    when '01-ED-Observation-Inpatient' then "HasEncounterKeys"(CQMElements."Observation Encounter", { 'obs-01' })
    when '02-ED-Inpatient-Gap-Over-Hour' then not exists CQMElements."Observation Encounter"
    else true
  end

define TestOutpatientSurgeryEncounter:
  case "Case"
    when '03-Surgery-Inpatient' then "HasEncounterKeys"(CQMElements."Outpatient Surgery Encounter", { 'surg-03' })
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
    when '01-ED-Observation-Inpatient' then "HasEncounterKeys"("Hospitalizations", { 'inp-01' })
    // A gap of more than an hour separates the hospitalizations
    when '02-ED-Inpatient-Gap-Over-Hour' then "HasEncounterKeys"("Hospitalizations", { 'ed-02', 'inp-02' })
    when '03-Surgery-Inpatient' then "HasEncounterKeys"("Hospitalizations", { 'inp-03' })
    when '04-Cancelled-ED-Inpatient' then "HasEncounterKeys"("Hospitalizations", { 'inp-04' })
    // A gap of exactly one hour does not
    when '05-Gap-Exactly-One-Hour' then "HasEncounterKeys"("Hospitalizations", { 'inp-05' })
    when '06-Gap-One-Hour-One-Minute' then "HasEncounterKeys"("Hospitalizations", { 'ed-06', 'inp-06' })
    when '07-Inpatient-Two-ICU-Stays' then "HasEncounterKeys"("Hospitalizations", { 'inp-07' })
    when '08-No-Encounters' then not exists "Hospitalizations"
    else true
  end

define TestHospitalizationEncountersContainedInOrder:
  case "Case"
    when '01-ED-Observation-Inpatient' then "ContainedKeys"("Inpatient Hospitalization".contained) = { 'ed-01', 'obs-01', 'inp-01' }
    when '02-ED-Inpatient-Gap-Over-Hour' then "ContainedKeys"("Inpatient Hospitalization".contained) = { 'inp-02' }
    when '03-Surgery-Inpatient' then "ContainedKeys"("Inpatient Hospitalization".contained) = { 'surg-03', 'inp-03' }
    // The function does not filter by status, so a cancelled encounter in the input is included
    when '04-Cancelled-ED-Inpatient' then "ContainedKeys"("Inpatient Hospitalization".contained) = { 'ed-04', 'inp-04' }
    when '05-Gap-Exactly-One-Hour' then "ContainedKeys"("Inpatient Hospitalization".contained) = { 'ed-05', 'inp-05' }
    else true
  end

// Callers are expected to pass only the encounters that should form hospitalizations, such as the
// finished encounters from the CQMElements retrieves
define TestHospitalizationEncountersFilteredInput:
  case "Case"
    when '04-Cancelled-ED-Inpatient' then
      "ContainedKeys"(
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
        and "Inpatient Hospitalization".subject.reference = "Patient Reference"
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
    when '01-ED-Observation-Inpatient' then
      Count("Normalized") = 1
        and "Find Normalized"('inp-01') is not null
    when '02-ED-Inpatient-Gap-Over-Hour' then
      Count("Normalized") = 2
        and "Find Normalized"('ed-02') is not null
        and "Find Normalized"('inp-02') is not null
    when '08-No-Encounters' then not exists "Normalized"
    else true
  end

define TestNormalizeEncountersPeriodSpansEpisode:
  case "Case"
    when '01-ED-Observation-Inpatient' then
      start of "Find Normalized"('inp-01').period = @2024-03-01T08:00:00.000Z
        and end of "Find Normalized"('inp-01').period = @2024-03-05T10:00:00.000Z
    else true
  end

define TestNormalizeEncountersKeepsLastEncounterElements:
  case "Case"
    when '01-ED-Observation-Inpatient' then
      "Find Normalized"('inp-01').status = 'finished'
        and "Find Normalized"('inp-01').type ~ "Find"("Encounters", 'inp-01').type
        and "Find Normalized"('inp-01').subject.reference = "Patient Reference"
    else true
  end

define TestNormalizeEncountersFlattensLocations:
  case "Case"
    when '01-ED-Observation-Inpatient' then
      (("Find Normalized"('inp-01').location) L return all "ResolveKey"(L.location))
        = { 'er-01', 'obs-unit-01', 'ward-01', 'icu-01', 'ward-01' }
    else true
  end

define TestNormalizeEncountersIncludedEncounters:
  case "Case"
    when '01-ED-Observation-Inpatient' then
      "ContainedKeys"("Find Normalized"('inp-01').contained) = { 'ed-01', 'obs-01', 'inp-01' }
        and "EncounterKeys"("Find Normalized"('inp-01').includedEncounters()) = { 'ed-01', 'obs-01', 'inp-01' }
    else true
  end

/*
 * includedEncounters
 */

define TestIncludedEncounters:
  case "Case"
    when '01-ED-Observation-Inpatient' then "EncounterKeys"("Inpatient Hospitalization".includedEncounters()) = { 'ed-01', 'obs-01', 'inp-01' }
    when '02-ED-Inpatient-Gap-Over-Hour' then "EncounterKeys"("Inpatient Hospitalization".includedEncounters()) = { 'inp-02' }
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
        and AllTrue((CQMElements."Encounter Location Entries"("Hospitalizations")) E return E.encounterId.value = "Find"("Encounters", 'inp-01').id.value)
    when '02-ED-Inpatient-Gap-Over-Hour' then
      Count((CQMElements."Encounter Location Entries"("Hospitalizations")) E where E.encounterId.value = "Find"("Encounters", 'ed-02').id.value) = 1
        and Count((CQMElements."Encounter Location Entries"("Hospitalizations")) E where E.encounterId.value = "Find"("Encounters", 'inp-02').id.value) = 1
    // The surgery has no locations, so only the inpatient location is listed
    when '03-Surgery-Inpatient' then Count(CQMElements."Encounter Location Entries"("Hospitalizations")) = 1
    else true
  end

define TestEncounterLocationEntriesElements:
  case "Case"
    when '01-ED-Observation-Inpatient' then
      exists (
        (CQMElements."Encounter Location Entries"("Hospitalizations")) E
          where "ResolveKey"(E.location) = 'icu-01'
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
            where "LocationKey"(L.location) = 'icu-01'
              and L.location.type.includesCode("Medical Critical Care")
              and start of L.period = @2024-03-02T08:00:00.000Z
        )
    else true
  end

define TestEncounterLocationsDropsUnresolvedReferences:
  case "Case"
    when '01-ED-Observation-Inpatient' then
      "HasLocationKeys"(
        (CQMElements."Encounter Locations"("Hospitalizations", "Locations" L where "LocationKey"(L) in { 'er-01', 'icu-01' })) EL
          return EL.location,
        { 'er-01', 'icu-01' }
      )
    else true
  end

// Invariant: every resolved location is one of the retrieved locations
define TestAllEncounterLocationsReferenceRetrievedLocations:
  AllTrue(
    CQMElements."All Encounter Locations" L
      return "LocationKey"(L.location) in "LocationKeys"("Locations")
  )

define TestEmergencyDepartmentLocations:
  case "Case"
    when '01-ED-Observation-Inpatient' then
      "HasLocationKeys"((CQMElements."Emergency Department Locations"("Hospitalizations", "Locations")) EL return EL.location, { 'er-01' })
    // An emergency trauma unit is an emergency department location
    when '02-ED-Inpatient-Gap-Over-Hour' then
      "HasLocationKeys"((CQMElements."Emergency Department Locations"("Hospitalizations", "Locations")) EL return EL.location, { 'etu-02' })
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
      (("Inpatient Hospitalization".hospitalizationLocations()) L return all "ResolveKey"(L.location))
        = { 'er-01', 'obs-unit-01', 'ward-01', 'icu-01', 'ward-01' }
    when '03-Surgery-Inpatient' then
      (("Inpatient Hospitalization".hospitalizationLocations()) L return "ResolveKey"(L.location))
        = { 'ward-03' }
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
      "ResolveKey"("Find"("Encounters", 'inp-01').firstInpatientIntensiveCareUnit().location) = 'icu-01'
        and start of "Find"("Encounters", 'inp-01').firstInpatientIntensiveCareUnit().period = @2024-03-02T08:00:00.000Z
        and end of "Find"("Encounters", 'inp-01').firstInpatientIntensiveCareUnit().period = @2024-03-04T08:00:00.000Z
    // The earliest ICU stay during the encounter, regardless of the order the locations are listed in,
    // and ignoring an ICU entry outside the encounter period
    when '07-Inpatient-Two-ICU-Stays' then
      "ResolveKey"("Find"("Encounters", 'inp-07').firstInpatientIntensiveCareUnit().location) = 'icu-a-07'
    when '02-ED-Inpatient-Gap-Over-Hour' then
      "Find"("Encounters", 'inp-02').firstInpatientIntensiveCareUnit() is null
    else true
  end

/*
 * Visit functions
 */

define TestEdVisit:
  case "Case"
    when '01-ED-Observation-Inpatient' then "EncounterKey"("Inpatient Hospitalization".edVisit()) = 'ed-01'
    when '02-ED-Inpatient-Gap-Over-Hour' then "Inpatient Hospitalization".edVisit() is null
    // A cancelled ED visit is not an ED visit, even though it is an included encounter
    when '04-Cancelled-ED-Inpatient' then "Inpatient Hospitalization".edVisit() is null
    when '05-Gap-Exactly-One-Hour' then "EncounterKey"("Inpatient Hospitalization".edVisit()) = 'ed-05'
    when '06-Gap-One-Hour-One-Minute' then "Inpatient Hospitalization".edVisit() is null
    else true
  end

define TestObservationVisit:
  case "Case"
    when '01-ED-Observation-Inpatient' then "EncounterKey"("Inpatient Hospitalization".observationVisit()) = 'obs-01'
    when '03-Surgery-Inpatient' then "Inpatient Hospitalization".observationVisit() is null
    else true
  end

define TestOutpatientSurgeryVisit:
  case "Case"
    when '03-Surgery-Inpatient' then "EncounterKey"("Inpatient Hospitalization".outpatientSurgeryVisit()) = 'surg-03'
    when '01-ED-Observation-Inpatient' then "Inpatient Hospitalization".outpatientSurgeryVisit() is null
    else true
  end

/*
 * Combined result
 */

// True only if every test in this library is true, for use as the population criteria of a Cohort
// measure. It uses `and` rather than AllTrue(), which ignores nulls, so that a null test fails it.
// It must list each Test define; .claude/skills/cql/check_results.py checks this.
define _Passed:
  TestInpatientEncounter
    and TestEmergencyDepartmentEncounter
    and TestObservationEncounter
    and TestOutpatientSurgeryEncounter
    and TestRetrievedEncountersFinished
    and TestHospitalizationEncounters
    and TestHospitalizationEncountersContainedInOrder
    and TestHospitalizationEncountersFilteredInput
    and TestHospitalizationEncountersIncludedEncounterExtensions
    and TestHospitalizationEncountersKeepsLastEncounterElements
    and TestHospitalizationEncountersEmptyInput
    and TestHospitalizationEncountersIncludeEveryEncounter
    and TestNormalizeEncounters
    and TestNormalizeEncountersPeriodSpansEpisode
    and TestNormalizeEncountersKeepsLastEncounterElements
    and TestNormalizeEncountersFlattensLocations
    and TestNormalizeEncountersIncludedEncounters
    and TestIncludedEncounters
    and TestIncludedEncountersNoneOnRetrievedEncounter
    and TestEncounterLocationEntries
    and TestEncounterLocationEntriesElements
    and TestEncounterLocationEntriesEmptyInput
    and TestAllEncounterLocationEntries
    and TestEncounterLocations
    and TestEncounterLocationsDropsUnresolvedReferences
    and TestAllEncounterLocationsReferenceRetrievedLocations
    and TestEmergencyDepartmentLocations
    and TestHospitalization
    and TestHospitalizationLocations
    and TestHospitalizationLengthOfStay
    and TestHospitalAdmissionTime
    and TestHospitalDischargeTime
    and TestHospitalArrivalTime
    and TestHospitalDepartureTime
    and TestEmergencyDepartmentArrivalTime
    and TestEmergencyDepartmentArrivalTimeDuringHospitalization
    and TestFirstInpatientIntensiveCareUnit
    and TestEdVisit
    and TestObservationVisit
    and TestOutpatientSurgeryVisit

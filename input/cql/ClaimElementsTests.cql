/*
@description: Tests for the ClaimElements library
@comment: Each test expression is named `Test...` and evaluates to `true` when the test passes.

The ClaimElements expressions are retrieves, so the test data is in
`input/tests/ClaimElementsTests/<patient id>/`, one folder per patient. Patient ids are GUIDs, as MADiE
expects, so each case is identified by its label, the patient's given name (e.g. `01-Inpatient-Claim`).
See the README there for what each case contains. Every expression is evaluated once per case, so:
* Case tests list the expected result for each case they cover, and are `true` for any other case.
* Invariant tests (marked as such) must hold for every case.

So every test must be `true` on every case: `false` or `null` is a failure. A `null` on a case a test
covers means the assertion couldn't be evaluated, e.g. because an element it reads came back null.
Because a case a test doesn't cover passes, a misspelled case name in a `when` clause would pass
silently; `.claude/skills/cql/check_results.py` checks the names against the case labels.

MADiE replaces resource ids that aren't GUIDs with new GUIDs on import, so the tests don't use
resource ids. Each claim and encounter has a readable key (e.g. `clm-01`) in an identifier with the
system `http://example.org/fhir/identifiers`, and the tests find resources by that key (`"ClaimKey"`, `"EncounterKey"`).

Rows of the flattened expressions are identified by a key built from the claim's key and the sequence
numbers, e.g. `clm-01:1` for item 1 of claim clm-01, and `clm-01:1:2` for diagnosis 2 of that item.

No terminology is needed: the tests compare codes directly, not by value set membership.

NOTE: This is in the process of being established as the measure ClaimElementsTests in MADiE:
https://madie.cms.gov/measures/6ad8ccb11fbcbfc8d7e0c9b5/edit/details/
*/
library ClaimElementsTests version '0.5.000'

using USQualityCore version '0.5.0'
using USCore version '6.1.0-derived'
using FHIR version '4.0.1'

include hl7.fhir.uv.cql.FHIRHelpers version '4.0.1'
include hl7.fhir.uv.cql.FHIRCommon version '2.0.0'

include ClaimCommon version '0.5.000'
include ClaimElements version '0.5.000'

codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'
codesystem "ICD10PCS": 'http://www.cms.gov/Medicare/Coding/ICD10'
codesystem "CPT": 'http://www.ama-assn.org/go/cpt'
codesystem "POA": 'https://www.cms.gov/Medicare/Medicare-Fee-for-Service-Payment/HospitalAcqCond/Coding'

context Patient

/*
 * Helpers
 */

// The case is the test case label, which is the patient's given name. The patient id (and the name of
// the test case folder) is a GUID, as MADiE expects, so it doesn't say which case this is.
define "Case": FHIRHelpers.ToString(First(Patient.name.given))

define function "Key"(prefix String, sequence Integer):
  prefix + ':' + ToString(sequence)

// True if the keys are exactly the expected keys, in any order, with no duplicates
define function "Has Keys"(keys List<String>, expected List<String>):
  Count(keys) = Count(expected)
    and keys includes expected

// Resources are identified by a readable key (e.g. `clm-01`) in an identifier with this system, not by
// their ids: MADiE replaces resource ids that aren't GUIDs with new GUIDs on import
define "Key System": 'http://example.org/fhir/identifiers'

// The key functions are separate for each resource type, rather than one function over FHIR.Resource
// with `is` / `as`, and are not overloads of one name: the MADiE engine resolves neither `is` nor
// overloads like these correctly at runtime.
define function "ClaimKey"(claim FHIR.Claim):
  singleton from (
    claim.identifier I
      where I.system = "Key System"
      return I.value.value
  )

define function "EncounterKey"(encounter FHIR.Encounter):
  singleton from (
    encounter.identifier I
      where I.system = "Key System"
      return I.value.value
  )

// The key of the retrieved encounter that a reference points to
define function "ResolveKey"(reference FHIR.Reference):
  "EncounterKey"(singleton from ([USQualityCore.Encounter] E where reference.references(E)))

// The key of the claim with the given id (the claimId of a row element)
define function "ClaimIdKey"(claimId String):
  "ClaimKey"(singleton from ([USQualityCore.Claim] C where C.id = claimId))

define function "Encounter"(key String):
  singleton from ([USQualityCore.Encounter] E where "EncounterKey"(E) = key)

define function "As Concept"(value Choice<FHIR.CodeableConcept, FHIR.Reference>):
  FHIRHelpers.ToConcept(value as FHIR.CodeableConcept)

/*
 * Data
 */

define "Item Keys":
  ClaimElements."Claim Item" I
    return all "Key"("ClaimIdKey"(I.claimId), I.sequence)

define "Encounter Item Keys":
  ClaimElements."Claim Encounter Item" I
    return all "Key"("ClaimIdKey"(I.claimId), I.sequence) + ':' + "ResolveKey"(I.encounter)

define "Diagnosis Keys":
  ClaimElements."Claim Diagnosis" D
    return all "Key"("ClaimIdKey"(D.claimId), D.sequence)

define "Item Diagnosis Keys":
  ClaimElements."Claim Item Diagnosis" D
    return all "Key"("Key"("ClaimIdKey"(D.claimId), D.itemSequence), D.diagnosisSequence)

define "Procedure Keys":
  ClaimElements."Claim Procedure" P
    return all "Key"("ClaimIdKey"(P.claimId), P.sequence)

define "Item Procedure Keys":
  ClaimElements."Claim Item Procedure" P
    return all "Key"("Key"("ClaimIdKey"(P.claimId), P.itemSequence), P.procedureSequence)

define function "Item"(key String):
  singleton from (ClaimElements."Claim Item" I where "Key"("ClaimIdKey"(I.claimId), I.sequence) = key)

define function "Item Diagnosis"(key String):
  singleton from (
    ClaimElements."Claim Item Diagnosis" D
      where "Key"("Key"("ClaimIdKey"(D.claimId), D.itemSequence), D.diagnosisSequence) = key
  )

define function "Item Procedure"(key String):
  singleton from (
    ClaimElements."Claim Item Procedure" P
      where "Key"("Key"("ClaimIdKey"(P.claimId), P.itemSequence), P.procedureSequence) = key
  )

/*
 * Claim Item
 */

define TestClaimItem:
  case "Case"
    when '01-Inpatient-Claim' then "Has Keys"("Item Keys", { 'clm-01:1', 'clm-01:2' })
    // An item with no encounter is still an item
    when '02-Two-Items-Two-Encounters' then "Has Keys"("Item Keys", { 'clm-02:1', 'clm-02:2', 'clm-02:3' })
    // Only the active claim with a use of claim
    when '03-Status-And-Use' then "Has Keys"("Item Keys", { 'clm-03-active:1' })
    when '05-No-Claims' then not exists ClaimElements."Claim Item"
    else true
  end

define TestClaimItemElements:
  case "Case"
    when '01-Inpatient-Claim' then
      "ClaimKey"("Item"('clm-01:1').claim) = 'clm-01'
        and FHIRHelpers.ToConcept("Item"('clm-01:1').productOrService) ~ Code '99223' from "CPT"
        and (("Item"('clm-01:1').diagnosisSequence) S return all S.value) = { 1, 2 }
        and (("Item"('clm-01:1').procedureSequence) S return all S.value) = { 1 }
        and "Item"('clm-01:1').encounter.references("Encounter"('enc-01'))
    else true
  end

define TestClaimItemServicedPeriod:
  case "Case"
    when '01-Inpatient-Claim' then
      "Item"('clm-01:1').serviced = Interval[@2024-03-01T08:00:00.000Z, @2024-03-05T10:00:00.000Z]
    else true
  end

// A serviced date is a day-precision interval
define TestClaimItemServicedDate:
  case "Case"
    when '01-Inpatient-Claim' then
      "Item"('clm-01:2').serviced = Interval[ToDateTime(@2024-03-02), ToDateTime(@2024-03-02)]
    else true
  end

define TestClaimItemNoServiced:
  case "Case"
    when '02-Two-Items-Two-Encounters' then "Item"('clm-02:1').serviced is null
    else true
  end

// Invariant: every item belongs to an active claim with a use of claim
define TestClaimItemActiveClaims:
  AllTrue(
    ClaimElements."Claim Item" I
      return I.claim.isActive() and I.claim.isClaim() and I.claim.id = I.claimId
  )

// Invariant: every item of every active claim with a use of claim is included
define TestClaimItemIncludesEveryItem:
  Count(ClaimElements."Claim Item")
    = Count(flatten ([USQualityCore.Claim] C where C.isActive() and C.isClaim() return all C.item))

/*
 * Claim Encounter Item
 */

// Each item is paired with each of the encounters it references, and items with no encounter are left
// out. Case 02 is the regression test for pairing every item with every encounter on the claim, which
// gave six rows (three items by two encounters) rather than two. Case 01 can't catch that: both its items
// reference the same encounter, so the duplicate rows are removed by the query's distinct.
define TestClaimEncounterItem:
  case "Case"
    when '01-Inpatient-Claim' then
      "Has Keys"("Encounter Item Keys", { 'clm-01:1:enc-01', 'clm-01:2:enc-01' })
    when '02-Two-Items-Two-Encounters' then
      "Has Keys"("Encounter Item Keys", { 'clm-02:1:enc-02a', 'clm-02:2:enc-02b' })
    when '03-Status-And-Use' then not exists ClaimElements."Claim Encounter Item"
    when '04-Related-By-Date' then not exists ClaimElements."Claim Encounter Item"
    when '05-No-Claims' then not exists ClaimElements."Claim Encounter Item"
    else true
  end

// Invariant: every encounter item is for an item that references its encounter
define TestClaimEncounterItemReferencesEncounter:
  AllTrue(
    ClaimElements."Claim Encounter Item" EI
      return exists (
        ClaimElements."Claim Item" I
          where I.claimId = EI.claimId
            and I.sequence = EI.sequence
            and exists (I.encounter E where E.reference = EI.encounter.reference)
      )
  )

/*
 * Claim Diagnosis
 */

define TestClaimDiagnosis:
  case "Case"
    when '01-Inpatient-Claim' then "Has Keys"("Diagnosis Keys", { 'clm-01:1', 'clm-01:2' })
    when '02-Two-Items-Two-Encounters' then "Has Keys"("Diagnosis Keys", { 'clm-02:1' })
    when '03-Status-And-Use' then "Has Keys"("Diagnosis Keys", { 'clm-03-active:1' })
    when '05-No-Claims' then not exists ClaimElements."Claim Diagnosis"
    else true
  end

define TestClaimDiagnosisElements:
  case "Case"
    when '01-Inpatient-Claim' then
      exists (
        ClaimElements."Claim Diagnosis" D
          where "ClaimIdKey"(D.claimId) = 'clm-01'
            and D.sequence = 1
            and "As Concept"(D.diagnosis) ~ Code 'I21.4' from "ICD10CM"
            and D.type.isPrincipalDiagnosis()
            and FHIRHelpers.ToConcept(D.onAdmission) ~ Code 'Y' from "POA"
      )
    else true
  end

/*
 * Claim Item Diagnosis
 */

define TestClaimItemDiagnosis:
  case "Case"
    when '01-Inpatient-Claim' then
      "Has Keys"("Item Diagnosis Keys", { 'clm-01:1:1', 'clm-01:1:2', 'clm-01:2:1' })
    // Item 2 lists a diagnosis sequence (9) that the claim doesn't have; it is still a row
    when '02-Two-Items-Two-Encounters' then
      "Has Keys"("Item Diagnosis Keys", { 'clm-02:1:1', 'clm-02:2:1', 'clm-02:2:9', 'clm-02:3:1' })
    when '03-Status-And-Use' then "Has Keys"("Item Diagnosis Keys", { 'clm-03-active:1:1' })
    when '05-No-Claims' then not exists ClaimElements."Claim Item Diagnosis"
    else true
  end

define TestClaimItemDiagnosisElements:
  case "Case"
    when '01-Inpatient-Claim' then
      "As Concept"("Item Diagnosis"('clm-01:1:1').diagnosis) ~ Code 'I21.4' from "ICD10CM"
        and "Item Diagnosis"('clm-01:1:1').diagnosisType.isPrincipalDiagnosis()
        and FHIRHelpers.ToConcept("Item Diagnosis"('clm-01:1:1').onAdmission) ~ Code 'Y' from "POA"
        and "As Concept"("Item Diagnosis"('clm-01:1:2').diagnosis) ~ Code 'E11.9' from "ICD10CM"
        and "Item Diagnosis"('clm-01:1:2').diagnosisType.isAdmittingDiagnosis()
        and not "Item Diagnosis"('clm-01:1:2').diagnosisType.isPrincipalDiagnosis()
        and FHIRHelpers.ToConcept("Item Diagnosis"('clm-01:1:2').onAdmission) ~ Code 'N' from "POA"
        and "As Concept"("Item Diagnosis"('clm-01:2:1').diagnosis) ~ Code 'I21.4' from "ICD10CM"
    else true
  end

// The item elements are carried onto each of its diagnoses
define TestClaimItemDiagnosisItemElements:
  case "Case"
    when '01-Inpatient-Claim' then
      "ClaimKey"("Item Diagnosis"('clm-01:2:1').claim) = 'clm-01'
        and FHIRHelpers.ToConcept("Item Diagnosis"('clm-01:2:1').productOrService) ~ Code '93458' from "CPT"
        and "Item Diagnosis"('clm-01:2:1').serviced = Interval[ToDateTime(@2024-03-02), ToDateTime(@2024-03-02)]
        and "Item Diagnosis"('clm-01:2:1').encounter.references("Encounter"('enc-01'))
    else true
  end

define TestClaimItemDiagnosisUnmatchedSequence:
  case "Case"
    when '02-Two-Items-Two-Encounters' then
      "Item Diagnosis"('clm-02:2:9').diagnosis is null
        and "Item Diagnosis"('clm-02:2:9').diagnosisType is null
        and "Item Diagnosis"('clm-02:2:9').onAdmission is null
    else true
  end

// Invariant: every item diagnosis with a diagnosis matches a claim diagnosis
define TestClaimItemDiagnosisMatchesClaimDiagnosis:
  AllTrue(
    ClaimElements."Claim Item Diagnosis" ID
      where ID.diagnosis is not null
      return exists (
        ClaimElements."Claim Diagnosis" D
          where D.claimId = ID.claimId
            and D.sequence = ID.diagnosisSequence
            and "As Concept"(D.diagnosis) ~ "As Concept"(ID.diagnosis)
      )
  )

/*
 * isRelatedTo
 */

define TestIsRelatedToByReference:
  case "Case"
    when '01-Inpatient-Claim' then
      AllTrue(ClaimElements."Claim Item Diagnosis" D return D.isRelatedTo("Encounter"('enc-01')))
    when '02-Two-Items-Two-Encounters' then
      "Item Diagnosis"('clm-02:1:1').isRelatedTo("Encounter"('enc-02a'))
        and "Item Diagnosis"('clm-02:2:1').isRelatedTo("Encounter"('enc-02b'))
    else true
  end

// Neither the reference, the serviced period, nor the billable period relates the item to the encounter
define TestIsRelatedToUnrelated:
  case "Case"
    when '02-Two-Items-Two-Encounters' then
      not "Item Diagnosis"('clm-02:2:1').isRelatedTo("Encounter"('enc-02a'))
    when '04-Related-By-Date' then
      not "Item Diagnosis"('clm-04c:1:1').isRelatedTo("Encounter"('enc-04'))
    else true
  end

define TestIsRelatedToByServicedPeriod:
  case "Case"
    when '04-Related-By-Date' then "Item Diagnosis"('clm-04b:1:1').isRelatedTo("Encounter"('enc-04'))
    else true
  end

define TestIsRelatedToByServicedDate:
  case "Case"
    when '04-Related-By-Date' then "Item Diagnosis"('clm-04e:1:1').isRelatedTo("Encounter"('enc-04'))
    else true
  end

define TestIsRelatedToByBillablePeriod:
  case "Case"
    when '04-Related-By-Date' then "Item Diagnosis"('clm-04a:1:1').isRelatedTo("Encounter"('enc-04'))
    else true
  end

// A serviced date on the day the encounter starts is day precision, compared with an encounter start
// with a time, so whether it is during the encounter is unknown, and so is the result.
// See the README (observation 2).
define TestIsRelatedToServicedDateOnStartDay:
  case "Case"
    when '04-Related-By-Date' then "Item Diagnosis"('clm-04d:1:1').isRelatedTo("Encounter"('enc-04')) is null
    else true
  end

// When the relationship can't be established, the result is null rather than false. See the README
// (observation 3).

// An item with no serviced element that neither references the encounter nor has a billable period during
// it
define TestIsRelatedToNoServiced:
  case "Case"
    when '02-Two-Items-Two-Encounters' then
      "Item Diagnosis"('clm-02:3:1').isRelatedTo("Encounter"('enc-02a')) is null
        and "Item Diagnosis"('clm-02:1:1').isRelatedTo("Encounter"('enc-02b')) is null
    else true
  end

// A claim with no billable period, and an item that neither references the encounter nor is serviced
// during it
define TestIsRelatedToNoBillablePeriod:
  case "Case"
    when '04-Related-By-Date' then "Item Diagnosis"('clm-04f:1:1').isRelatedTo("Encounter"('enc-04')) is null
    else true
  end

// An unknown part doesn't make the result unknown when another part is true
define TestIsRelatedToNoBillablePeriodServicedDuring:
  case "Case"
    when '04-Related-By-Date' then "Item Diagnosis"('clm-04g:1:1').isRelatedTo("Encounter"('enc-04'))
    else true
  end

/*
 * Claim Procedure
 */

define TestClaimProcedure:
  case "Case"
    when '01-Inpatient-Claim' then "Has Keys"("Procedure Keys", { 'clm-01:1', 'clm-01:2' })
    when '02-Two-Items-Two-Encounters' then not exists ClaimElements."Claim Procedure"
    when '03-Status-And-Use' then "Has Keys"("Procedure Keys", { 'clm-03-active:1' })
    when '05-No-Claims' then not exists ClaimElements."Claim Procedure"
    else true
  end

define TestClaimProcedureElements:
  case "Case"
    when '01-Inpatient-Claim' then
      exists (
        ClaimElements."Claim Procedure" P
          where "ClaimIdKey"(P.claimId) = 'clm-01'
            and P.sequence = 1
            and "As Concept"(P.procedure) ~ Code '02703ZZ' from "ICD10PCS"
            and P.type.isPrimaryProcedure()
            and P.date = @2024-03-02T10:00:00.000Z
      )
    else true
  end

/*
 * Claim Item Procedure
 */

define TestClaimItemProcedure:
  case "Case"
    when '01-Inpatient-Claim' then "Has Keys"("Item Procedure Keys", { 'clm-01:1:1', 'clm-01:2:2' })
    when '02-Two-Items-Two-Encounters' then not exists ClaimElements."Claim Item Procedure"
    when '03-Status-And-Use' then "Has Keys"("Item Procedure Keys", { 'clm-03-active:1:1' })
    when '05-No-Claims' then not exists ClaimElements."Claim Item Procedure"
    else true
  end

define TestClaimItemProcedureElements:
  case "Case"
    when '01-Inpatient-Claim' then
      "As Concept"("Item Procedure"('clm-01:1:1').procedure) ~ Code '02703ZZ' from "ICD10PCS"
        and "Item Procedure"('clm-01:1:1').procedureType.isPrimaryProcedure()
        and "Item Procedure"('clm-01:1:1').procedureDate = @2024-03-02T10:00:00.000Z
        and "As Concept"("Item Procedure"('clm-01:2:2').procedure) ~ Code 'B2111ZZ' from "ICD10PCS"
        and "Item Procedure"('clm-01:2:2').procedureType.isSecondaryProcedure()
        and "Item Procedure"('clm-01:2:2').procedureDate = @2024-03-02T09:00:00.000Z
        and FHIRHelpers.ToConcept("Item Procedure"('clm-01:2:2').productOrService) ~ Code '93458' from "CPT"
    else true
  end

/*
 * Combined result
 */

// True only if every test in this library is true, for use as the population criteria of a Cohort
// measure. It uses `and` rather than AllTrue(), which ignores nulls, so that a null test fails it.
// It must list each Test define; .claude/skills/cql/check_results.py checks this.
define _Passed:
  TestClaimItem
    and TestClaimItemElements
    and TestClaimItemServicedPeriod
    and TestClaimItemServicedDate
    and TestClaimItemNoServiced
    and TestClaimItemActiveClaims
    and TestClaimItemIncludesEveryItem
    and TestClaimEncounterItem
    and TestClaimEncounterItemReferencesEncounter
    and TestClaimDiagnosis
    and TestClaimDiagnosisElements
    and TestClaimItemDiagnosis
    and TestClaimItemDiagnosisElements
    and TestClaimItemDiagnosisItemElements
    and TestClaimItemDiagnosisUnmatchedSequence
    and TestClaimItemDiagnosisMatchesClaimDiagnosis
    and TestIsRelatedToByReference
    and TestIsRelatedToUnrelated
    and TestIsRelatedToByServicedPeriod
    and TestIsRelatedToByServicedDate
    and TestIsRelatedToByBillablePeriod
    and TestIsRelatedToServicedDateOnStartDay
    and TestIsRelatedToNoServiced
    and TestIsRelatedToNoBillablePeriod
    and TestIsRelatedToNoBillablePeriodServicedDuring
    and TestClaimProcedure
    and TestClaimProcedureElements
    and TestClaimItemProcedure
    and TestClaimItemProcedureElements

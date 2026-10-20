/*
@description: Tests for the ClaimElements library
@comment: Each test expression is named `Test...` and evaluates to `true` when the test passes.

The ClaimElements expressions are retrieves, so the test data is in `input/tests/ClaimElementsTests/<case>/`,
one folder per patient, with the patient id equal to the folder name. See the README there for what
each case contains. Every expression is evaluated once per case, so:
* Case tests list the expected result for each case they cover, and are `true` for any other case.
* Invariant tests (marked as such) must hold for every case.

So every test must be `true` on every case: `false` or `null` is a failure. A `null` on a case a test
covers means the assertion couldn't be evaluated, e.g. because an element it reads came back null.
Because a case a test doesn't cover passes, a misspelled case name in a `when` clause would pass
silently; `.claude/skills/cql/check_results.py` checks the names against the case folders.

Rows of the flattened expressions are identified by a key built from the claim id and the sequence
numbers, e.g. `clm-01:1` for item 1 of claim clm-01, and `clm-01:1:2` for diagnosis 2 of that item.

No terminology is needed: the tests compare codes directly, not by value set membership.
*/
library ClaimElementsTests version '0.4.000-draft'

using USQualityCore version '0.5.0'
using USCore version '6.1.0-derived'
using FHIR version '4.0.1'

include hl7.fhir.uv.cql.FHIRHelpers version '4.0.1'
include hl7.fhir.uv.cql.FHIRCommon version '2.0.0'

include ClaimCommon version '0.4.000-draft'
include ClaimElements version '0.4.000-draft'

codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'
codesystem "ICD10PCS": 'http://www.cms.gov/Medicare/Coding/ICD10'
codesystem "CPT": 'http://www.ama-assn.org/go/cpt'
codesystem "POA": 'https://www.cms.gov/Medicare/Medicare-Fee-for-Service-Payment/HospitalAcqCond/Coding'

context Patient

/*
 * Helpers
 */

// The case is the patient id, which is also the name of the test case folder
define "Case": FHIRHelpers.ToString(Patient.id)

define function "Key"(prefix String, sequence Integer):
  prefix + ':' + ToString(sequence)

// True if the keys are exactly the expected keys, in any order, with no duplicates
define function "Has Keys"(keys List<String>, expected List<String>):
  Count(keys) = Count(expected)
    and keys includes expected

define function "Encounter"(id String):
  singleton from ([USQualityCore.Encounter] E where E.id = id)

define function "As Concept"(value Choice<FHIR.CodeableConcept, FHIR.Reference>):
  FHIRHelpers.ToConcept(value as FHIR.CodeableConcept)

/*
 * Data
 */

define "Item Keys":
  ClaimElements."Claim Item" I
    return all "Key"(I.claimId, I.sequence)

define "Encounter Item Keys":
  ClaimElements."Claim Encounter Item" I
    return all "Key"(I.claimId, I.sequence) + ':' + I.encounter.reference.value

define "Diagnosis Keys":
  ClaimElements."Claim Diagnosis" D
    return all "Key"(D.claimId, D.sequence)

define "Item Diagnosis Keys":
  ClaimElements."Claim Item Diagnosis" D
    return all "Key"("Key"(D.claimId, D.itemSequence), D.diagnosisSequence)

define "Procedure Keys":
  ClaimElements."Claim Procedure" P
    return all "Key"(P.claimId, P.sequence)

define "Item Procedure Keys":
  ClaimElements."Claim Item Procedure" P
    return all "Key"("Key"(P.claimId, P.itemSequence), P.procedureSequence)

define function "Item"(key String):
  singleton from (ClaimElements."Claim Item" I where "Key"(I.claimId, I.sequence) = key)

define function "Item Diagnosis"(key String):
  singleton from (
    ClaimElements."Claim Item Diagnosis" D
      where "Key"("Key"(D.claimId, D.itemSequence), D.diagnosisSequence) = key
  )

define function "Item Procedure"(key String):
  singleton from (
    ClaimElements."Claim Item Procedure" P
      where "Key"("Key"(P.claimId, P.itemSequence), P.procedureSequence) = key
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
      "Item"('clm-01:1').claim.id = 'clm-01'
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
      "Has Keys"("Encounter Item Keys", { 'clm-01:1:Encounter/enc-01', 'clm-01:2:Encounter/enc-01' })
    when '02-Two-Items-Two-Encounters' then
      "Has Keys"("Encounter Item Keys", { 'clm-02:1:Encounter/enc-02a', 'clm-02:2:Encounter/enc-02b' })
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
          where D.claimId = 'clm-01'
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
      "Item Diagnosis"('clm-01:2:1').claim.id = 'clm-01'
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
          where P.claimId = 'clm-01'
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

/*
@description: Tests for the MedicationCommon library
@comment: Each test expression is named `Test...` and evaluates to `true` when the test passes.

The test data is in `input/tests/MedicationCommonTests/<patient id>/`, one folder per patient. Patient
ids are GUIDs, as MADiE expects, so each case is identified by its label, the patient's given name (e.g.
`01-Request-Status`). See the README there for what each case contains. Every expression is evaluated
once per case, so case tests list the expected result for each case they cover, and are `true` for any
other case. So every test must be `true` on every case: `false` or `null` is a failure. Because a case a
test doesn't cover passes, a misspelled case name in a `when` clause would pass silently;
`.claude/skills/cql/check_results.py` checks the names against the case labels.

The resources are retrieved as US Quality Core profiles, so every test also checks that the FHIR-typed
MedicationCommon functions resolve and run for the profiled types measure logic uses. The negation
profiles (MedicationNotRequested, MedicationAdministrationNotDone, MedicationDispenseDeclined) have their
own case.

MADiE replaces resource ids that aren't GUIDs with new GUIDs on import, so the tests don't use resource
ids. Each resource has a readable key (e.g. `mr-01-active`) in an identifier with the system
`http://example.org/fhir/identifiers`, and the tests find resources, and compare the results of the
list functions, by key.

The status and intent functions compare only the code value of the element. The category functions
compare codings, so the category tests pass codes declared in this library rather than the
MedicationCommon code declarations, and the case data codes its categories independently. The code
declarations are tested separately against independently declared codes, so that a wrong system or
code in MedicationCommon makes a test fail.

The case data is valid, conformant FHIR (MADiE rejects invalid resources), so a missing status or
intent is not tested: both elements are required.

NOTE: This is in the process of being established as the measure MedicationCommonTests in MADiE:
https://madie.cms.gov/measures/6ad8cdd11fbcbfc8d7e0c9bd/edit/details/
*/
library MedicationCommonTests version '0.2.000'

using USQualityCore version '0.5.0'
using USCore version '6.1.0-derived'
using FHIR version '4.0.1'

include hl7.fhir.uv.cql.FHIRHelpers version '4.0.1'
include MedicationCommon version '0.2.000'

codesystem "MedicationRequestStatus": 'http://hl7.org/fhir/CodeSystem/medicationrequest-status'
codesystem "MedicationRequestIntent": 'http://hl7.org/fhir/CodeSystem/medicationrequest-intent'
codesystem "MedicationAdministrationStatus": 'http://terminology.hl7.org/CodeSystem/medication-admin-status'
codesystem "MedicationDispenseStatus": 'http://terminology.hl7.org/CodeSystem/medicationdispense-status'
codesystem "MedicationRequestCategory": 'http://terminology.hl7.org/CodeSystem/medicationrequest-category'
codesystem "MedicationAdministrationCategory": 'http://terminology.hl7.org/CodeSystem/medication-admin-category'

context Patient

/*
 * Helpers
 */

// The case is the test case label, which is the patient's given name. The patient id (and the name of
// the test case folder) is a GUID, as MADiE expects, so it doesn't say which case this is.
define "Case": FHIRHelpers.ToString(First(Patient.name.given))

// Resources are identified by a readable key (e.g. `mr-01-active`) in an identifier with this system,
// not by their ids: MADiE replaces resource ids that aren't GUIDs with new GUIDs on import
define "Key System": 'http://example.org/fhir/identifiers'

// The key functions are separate for each resource type, rather than one function over FHIR.Resource
// with `is` / `as`, and are not overloads of one name: the MADiE engine resolves neither `is` nor
// overloads like these correctly at runtime.
define function "MedicationRequestKey"(request FHIR.MedicationRequest):
  singleton from (
    request.identifier I
      where I.system = "Key System"
      return I.value.value
  )

define function "MedicationAdministrationKey"(administration FHIR.MedicationAdministration):
  singleton from (
    administration.identifier I
      where I.system = "Key System"
      return I.value.value
  )

define function "MedicationDispenseKey"(dispense FHIR.MedicationDispense):
  singleton from (
    dispense.identifier I
      where I.system = "Key System"
      return I.value.value
  )

define function "Request Keys"(requests List<FHIR.MedicationRequest>):
  requests R
    return all "MedicationRequestKey"(R)

define function "Administration Keys"(administrations List<FHIR.MedicationAdministration>):
  administrations A
    return all "MedicationAdministrationKey"(A)

define function "Dispense Keys"(dispenses List<FHIR.MedicationDispense>):
  dispenses D
    return all "MedicationDispenseKey"(D)

// True if the keys are exactly the expected keys, in any order
define function "SameKeys"(keys List<String>, expected List<String>):
  Count(keys) = Count(expected)
    and keys includes expected

define "Requests": [USQualityCore.MedicationRequest]
define "Administrations": [USQualityCore.MedicationAdministration]
define "Dispenses": [USQualityCore.MedicationDispense]

// The retrieved resource with the given key. A key that isn't in the case gives null, so an assertion
// on it is null and fails.
define function "Request"(key String):
  singleton from ("Requests" R where "MedicationRequestKey"(R) = key)

define function "Administration"(key String):
  singleton from ("Administrations" A where "MedicationAdministrationKey"(A) = key)

define function "Dispense"(key String):
  singleton from ("Dispenses" D where "MedicationDispenseKey"(D) = key)

// Category codes to test for, declared independently of the MedicationCommon code declarations
define "Request Inpatient": Code 'inpatient' from "MedicationRequestCategory"
define "Request Outpatient": Code 'outpatient' from "MedicationRequestCategory"
define "Request Community": Code 'community' from "MedicationRequestCategory"
define "Request Discharge": Code 'discharge' from "MedicationRequestCategory"
define "Administration Inpatient": Code 'inpatient' from "MedicationAdministrationCategory"
define "Administration Community": Code 'community' from "MedicationAdministrationCategory"

/*
 * Code declarations
 */

define TestMedicationRequestStatusDeclarations:
  MedicationCommon."medicationrequest-active" ~ Code 'active' from "MedicationRequestStatus"
    and MedicationCommon."medicationrequest-on-hold" ~ Code 'on-hold' from "MedicationRequestStatus"
    and MedicationCommon."medicationrequest-cancelled" ~ Code 'cancelled' from "MedicationRequestStatus"
    and MedicationCommon."medicationrequest-completed" ~ Code 'completed' from "MedicationRequestStatus"
    and MedicationCommon."medicationrequest-entered-in-error" ~ Code 'entered-in-error' from "MedicationRequestStatus"
    and MedicationCommon."medicationrequest-stopped" ~ Code 'stopped' from "MedicationRequestStatus"
    and MedicationCommon."medicationrequest-draft" ~ Code 'draft' from "MedicationRequestStatus"
    and MedicationCommon."medicationrequest-unknown" ~ Code 'unknown' from "MedicationRequestStatus"

define TestMedicationRequestIntentDeclarations:
  MedicationCommon."medicationrequest-proposal" ~ Code 'proposal' from "MedicationRequestIntent"
    and MedicationCommon."medicationrequest-plan" ~ Code 'plan' from "MedicationRequestIntent"
    and MedicationCommon."medicationrequest-order" ~ Code 'order' from "MedicationRequestIntent"
    and MedicationCommon."medicationrequest-original-order" ~ Code 'original-order' from "MedicationRequestIntent"
    and MedicationCommon."medicationrequest-reflex-order" ~ Code 'reflex-order' from "MedicationRequestIntent"
    and MedicationCommon."medicationrequest-filler-order" ~ Code 'filler-order' from "MedicationRequestIntent"
    and MedicationCommon."medicationrequest-instance-order" ~ Code 'instance-order' from "MedicationRequestIntent"
    and MedicationCommon."medicationrequest-option" ~ Code 'option' from "MedicationRequestIntent"

define TestMedicationRequestCategoryDeclarations:
  MedicationCommon."medicationrequest-inpatient" ~ Code 'inpatient' from "MedicationRequestCategory"
    and MedicationCommon."medicationrequest-outpatient" ~ Code 'outpatient' from "MedicationRequestCategory"
    and MedicationCommon."medicationrequest-community" ~ Code 'community' from "MedicationRequestCategory"
    and MedicationCommon."medicationrequest-discharge" ~ Code 'discharge' from "MedicationRequestCategory"

define TestMedicationAdministrationCategoryDeclarations:
  MedicationCommon."medicationadministration-inpatient" ~ Code 'inpatient' from "MedicationAdministrationCategory"
    and MedicationCommon."medicationadministration-outpatient" ~ Code 'outpatient' from "MedicationAdministrationCategory"
    and MedicationCommon."medicationadministration-community" ~ Code 'community' from "MedicationAdministrationCategory"

define TestMedicationAdministrationStatusDeclarations:
  MedicationCommon."medicationadministration-in-progress" ~ Code 'in-progress' from "MedicationAdministrationStatus"
    and MedicationCommon."medicationadministration-not-done" ~ Code 'not-done' from "MedicationAdministrationStatus"
    and MedicationCommon."medicationadministration-on-hold" ~ Code 'on-hold' from "MedicationAdministrationStatus"
    and MedicationCommon."medicationadministration-completed" ~ Code 'completed' from "MedicationAdministrationStatus"
    and MedicationCommon."medicationadministration-entered-in-error" ~ Code 'entered-in-error' from "MedicationAdministrationStatus"
    and MedicationCommon."medicationadministration-stopped" ~ Code 'stopped' from "MedicationAdministrationStatus"
    and MedicationCommon."medicationadministration-unknown" ~ Code 'unknown' from "MedicationAdministrationStatus"

define TestMedicationDispenseStatusDeclarations:
  MedicationCommon."medicationdispense-preparation" ~ Code 'preparation' from "MedicationDispenseStatus"
    and MedicationCommon."medicationdispense-in-progress" ~ Code 'in-progress' from "MedicationDispenseStatus"
    and MedicationCommon."medicationdispense-cancelled" ~ Code 'cancelled' from "MedicationDispenseStatus"
    and MedicationCommon."medicationdispense-on-hold" ~ Code 'on-hold' from "MedicationDispenseStatus"
    and MedicationCommon."medicationdispense-completed" ~ Code 'completed' from "MedicationDispenseStatus"
    and MedicationCommon."medicationdispense-entered-in-error" ~ Code 'entered-in-error' from "MedicationDispenseStatus"
    and MedicationCommon."medicationdispense-stopped" ~ Code 'stopped' from "MedicationDispenseStatus"
    and MedicationCommon."medicationdispense-declined" ~ Code 'declined' from "MedicationDispenseStatus"
    and MedicationCommon."medicationdispense-unknown" ~ Code 'unknown' from "MedicationDispenseStatus"

/*
 * MedicationRequest status
 */

define TestMedicationRequestIsActive:
  case "Case"
    when '01-Request-Status' then
      "Request"('mr-01-active').isActive()
        and not "Request"('mr-01-completed').isActive()
        and not "Request"('mr-01-on-hold').isActive()
    else true
  end

define TestMedicationRequestActive:
  case "Case"
    when '01-Request-Status' then "SameKeys"("Request Keys"("Requests".active()), { 'mr-01-active' })
    when '09-No-Medications' then not exists "Requests".active()
    else true
  end

define TestMedicationRequestIsOnHold:
  case "Case"
    when '01-Request-Status' then
      "Request"('mr-01-on-hold').isOnHold()
        and not "Request"('mr-01-active').isOnHold()
    else true
  end

define TestMedicationRequestOnHold:
  case "Case"
    when '01-Request-Status' then "SameKeys"("Request Keys"("Requests".onHold()), { 'mr-01-on-hold' })
    when '09-No-Medications' then not exists "Requests".onHold()
    else true
  end

define TestMedicationRequestIsCompleted:
  case "Case"
    when '01-Request-Status' then
      "Request"('mr-01-completed').isCompleted()
        and not "Request"('mr-01-active').isCompleted()
    else true
  end

define TestMedicationRequestCompleted:
  case "Case"
    when '01-Request-Status' then "SameKeys"("Request Keys"("Requests".completed()), { 'mr-01-completed' })
    when '09-No-Medications' then not exists "Requests".completed()
    else true
  end

// The composition the library header recommends in place of an aggregate helper
define TestMedicationRequestActiveOrCompleted:
  case "Case"
    when '01-Request-Status' then
      "SameKeys"(
        "Request Keys"("Requests" MR where MR.isActive() or MR.isCompleted()),
        { 'mr-01-active', 'mr-01-completed' }
      )
    else true
  end

define TestMedicationRequestIsCancelled:
  case "Case"
    when '01-Request-Status' then
      "Request"('mr-01-cancelled').isCancelled()
        and not "Request"('mr-01-stopped').isCancelled()
    else true
  end

define TestMedicationRequestIsStopped:
  case "Case"
    when '01-Request-Status' then
      "Request"('mr-01-stopped').isStopped()
        and not "Request"('mr-01-cancelled').isStopped()
    else true
  end

define TestMedicationRequestIsDraft:
  case "Case"
    when '01-Request-Status' then
      "Request"('mr-01-draft').isDraft()
        and not "Request"('mr-01-active').isDraft()
    else true
  end

define TestMedicationRequestIsEnteredInError:
  case "Case"
    when '01-Request-Status' then
      "Request"('mr-01-entered-in-error').isEnteredInError()
        and not "Request"('mr-01-active').isEnteredInError()
    else true
  end

// Each status predicate holds for exactly the request with that status
define TestMedicationRequestStatusPredicatesExclusive:
  case "Case"
    when '01-Request-Status' then
      "SameKeys"("Request Keys"("Requests" MR where MR.isActive()), { 'mr-01-active' })
        and "SameKeys"("Request Keys"("Requests" MR where MR.isOnHold()), { 'mr-01-on-hold' })
        and "SameKeys"("Request Keys"("Requests" MR where MR.isCompleted()), { 'mr-01-completed' })
        and "SameKeys"("Request Keys"("Requests" MR where MR.isCancelled()), { 'mr-01-cancelled' })
        and "SameKeys"("Request Keys"("Requests" MR where MR.isStopped()), { 'mr-01-stopped' })
        and "SameKeys"("Request Keys"("Requests" MR where MR.isDraft()), { 'mr-01-draft' })
        and "SameKeys"("Request Keys"("Requests" MR where MR.isEnteredInError()), { 'mr-01-entered-in-error' })
    else true
  end

/*
 * MedicationRequest intent
 */

define TestMedicationRequestIsOrder:
  case "Case"
    when '02-Request-Intent' then
      "Request"('mr-02-order').isOrder()
        // Only the order intent, not the other order intents
        and not "Request"('mr-02-original-order').isOrder()
        and not "Request"('mr-02-plan').isOrder()
    else true
  end

define TestMedicationRequestIsPlan:
  case "Case"
    when '02-Request-Intent' then
      "Request"('mr-02-plan').isPlan()
        and not "Request"('mr-02-order').isPlan()
    else true
  end

define TestMedicationRequestIsProposal:
  case "Case"
    when '02-Request-Intent' then
      "Request"('mr-02-proposal').isProposal()
        and not "Request"('mr-02-order').isProposal()
    else true
  end

define TestMedicationRequestIsOrderIntent:
  case "Case"
    when '02-Request-Intent' then
      "Request"('mr-02-order').isOrderIntent()
        and "Request"('mr-02-original-order').isOrderIntent()
        and "Request"('mr-02-reflex-order').isOrderIntent()
        and "Request"('mr-02-filler-order').isOrderIntent()
        and "Request"('mr-02-instance-order').isOrderIntent()
        and not "Request"('mr-02-proposal').isOrderIntent()
        and not "Request"('mr-02-plan').isOrderIntent()
        and not "Request"('mr-02-option').isOrderIntent()
    else true
  end

define TestMedicationRequestOrderIntent:
  case "Case"
    when '02-Request-Intent' then
      "SameKeys"(
        "Request Keys"("Requests".orderIntent()),
        { 'mr-02-order', 'mr-02-original-order', 'mr-02-reflex-order', 'mr-02-filler-order', 'mr-02-instance-order' }
      )
    when '09-No-Medications' then not exists "Requests".orderIntent()
    else true
  end

/*
 * MedicationRequest category
 */

define TestMedicationRequestHasCategory:
  case "Case"
    when '03-Request-Category' then
      "Request"('mr-03-community').hasCategory("Request Community")
        and not "Request"('mr-03-community').hasCategory("Request Discharge")
    else true
  end

define TestMedicationRequestHasCategoryAmongSeveral:
  case "Case"
    when '03-Request-Category' then
      "Request"('mr-03-community-discharge').hasCategory("Request Community")
        and "Request"('mr-03-community-discharge').hasCategory("Request Discharge")
    else true
  end

// A category is matched by any of its codings
define TestMedicationRequestHasCategoryMatchesAnyCoding:
  case "Case"
    when '03-Request-Category' then "Request"('mr-03-discharge-among-codings').hasCategory("Request Discharge")
    else true
  end

// The same code in another code system doesn't match, including the MedicationAdministration category
// code system, which has the same codes
define TestMedicationRequestHasCategoryWrongSystem:
  case "Case"
    when '03-Request-Category' then
      not "Request"('mr-03-wrong-system').hasCategory("Request Community")
        and not "Request"('mr-03-administration-category').hasCategory("Request Community")
    else true
  end

define TestMedicationRequestHasCategoryNoCategories:
  case "Case"
    when '03-Request-Category' then not "Request"('mr-03-uncategorized').hasCategory("Request Community")
    else true
  end

define TestMedicationRequestHasCategoryNullCategory:
  case "Case"
    when '03-Request-Category' then not "Request"('mr-03-community').hasCategory(null as Code)
    else true
  end

define TestMedicationRequestIsInpatient:
  case "Case"
    when '03-Request-Category' then
      "Request"('mr-03-inpatient').isInpatient()
        and not "Request"('mr-03-outpatient').isInpatient()
        and not "Request"('mr-03-uncategorized').isInpatient()
    else true
  end

define TestMedicationRequestInpatient:
  case "Case"
    when '03-Request-Category' then "SameKeys"("Request Keys"("Requests".inpatient()), { 'mr-03-inpatient' })
    when '09-No-Medications' then not exists "Requests".inpatient()
    else true
  end

define TestMedicationRequestIsOutpatient:
  case "Case"
    when '03-Request-Category' then
      "Request"('mr-03-outpatient').isOutpatient()
        and not "Request"('mr-03-inpatient').isOutpatient()
        and not "Request"('mr-03-uncategorized').isOutpatient()
    else true
  end

define TestMedicationRequestOutpatient:
  case "Case"
    when '03-Request-Category' then "SameKeys"("Request Keys"("Requests".outpatient()), { 'mr-03-outpatient' })
    when '09-No-Medications' then not exists "Requests".outpatient()
    else true
  end

define TestMedicationRequestIsCommunity:
  case "Case"
    when '03-Request-Category' then
      "Request"('mr-03-community').isCommunity()
        and "Request"('mr-03-community-discharge').isCommunity()
        and not "Request"('mr-03-discharge').isCommunity()
        and not "Request"('mr-03-uncategorized').isCommunity()
        and not "Request"('mr-03-wrong-system').isCommunity()
        and not "Request"('mr-03-administration-category').isCommunity()
    else true
  end

define TestMedicationRequestCommunity:
  case "Case"
    when '03-Request-Category' then
      "SameKeys"("Request Keys"("Requests".community()), { 'mr-03-community', 'mr-03-community-discharge' })
    when '09-No-Medications' then not exists "Requests".community()
    else true
  end

define TestMedicationRequestIsDischarge:
  case "Case"
    when '03-Request-Category' then
      "Request"('mr-03-discharge').isDischarge()
        and "Request"('mr-03-community-discharge').isDischarge()
        and "Request"('mr-03-discharge-among-codings').isDischarge()
        and not "Request"('mr-03-community').isDischarge()
        and not "Request"('mr-03-uncategorized').isDischarge()
    else true
  end

define TestMedicationRequestDischarge:
  case "Case"
    when '03-Request-Category' then
      "SameKeys"(
        "Request Keys"("Requests".discharge()),
        { 'mr-03-discharge', 'mr-03-community-discharge', 'mr-03-discharge-among-codings' }
      )
    when '09-No-Medications' then not exists "Requests".discharge()
    else true
  end

// The composition used for discharge medications in CMS measure logic
define TestMedicationRequestCommunityOrDischarge:
  case "Case"
    when '03-Request-Category' then
      "SameKeys"(
        "Request Keys"("Requests" MR where MR.isCommunity() or MR.isDischarge()),
        { 'mr-03-community', 'mr-03-discharge', 'mr-03-community-discharge', 'mr-03-discharge-among-codings' }
      )
    else true
  end

/*
 * MedicationRequest selection
 */

define TestMedicationRequestMostRecent:
  case "Case"
    // The time of day is taken into account, not just the date, and a request with no authoredOn is
    // not the most recent
    when '04-Request-Most-Recent' then "MedicationRequestKey"("Requests".mostRecent()) = 'mr-04-march-5-later'
    else true
  end

// The order of the input doesn't matter
define TestMedicationRequestMostRecentOrder:
  case "Case"
    when '04-Request-Most-Recent' then
      "MedicationRequestKey"(({ "Request"('mr-04-march-5'), "Request"('mr-04-march-1') }).mostRecent()) = 'mr-04-march-5'
        and "MedicationRequestKey"(({ "Request"('mr-04-march-1'), "Request"('mr-04-march-5') }).mostRecent()) = 'mr-04-march-5'
    else true
  end

// Nulls sort first, so a request with no authoredOn is not the most recent, whatever the input order
define TestMedicationRequestMostRecentIgnoresNotAuthored:
  case "Case"
    when '04-Request-Most-Recent' then
      "MedicationRequestKey"(({ "Request"('mr-04-march-1'), "Request"('mr-04-not-authored') }).mostRecent()) = 'mr-04-march-1'
        and "MedicationRequestKey"(({ "Request"('mr-04-not-authored'), "Request"('mr-04-march-1') }).mostRecent()) = 'mr-04-march-1'
    else true
  end

define TestMedicationRequestMostRecentOnlyNotAuthored:
  case "Case"
    when '04-Request-Most-Recent' then
      "MedicationRequestKey"(({ "Request"('mr-04-not-authored') }).mostRecent()) = 'mr-04-not-authored'
    else true
  end

define TestMedicationRequestMostRecentEmpty:
  case "Case"
    when '09-No-Medications' then "Requests".mostRecent() is null
    else true
  end

/*
 * MedicationAdministration status
 */

define TestMedicationAdministrationIsCompleted:
  case "Case"
    when '05-Administration-Status' then
      "Administration"('ma-05-completed').isCompleted()
        and not "Administration"('ma-05-in-progress').isCompleted()
    else true
  end

define TestMedicationAdministrationCompleted:
  case "Case"
    when '05-Administration-Status' then
      "SameKeys"("Administration Keys"("Administrations".completed()), { 'ma-05-completed' })
    when '09-No-Medications' then not exists "Administrations".completed()
    else true
  end

define TestMedicationAdministrationIsInProgress:
  case "Case"
    when '05-Administration-Status' then
      "Administration"('ma-05-in-progress').isInProgress()
        and not "Administration"('ma-05-completed').isInProgress()
    else true
  end

define TestMedicationAdministrationIsOnHold:
  case "Case"
    when '05-Administration-Status' then
      "Administration"('ma-05-on-hold').isOnHold()
        and not "Administration"('ma-05-in-progress').isOnHold()
    else true
  end

define TestMedicationAdministrationIsStopped:
  case "Case"
    when '05-Administration-Status' then
      "Administration"('ma-05-stopped').isStopped()
        and not "Administration"('ma-05-completed').isStopped()
    else true
  end

define TestMedicationAdministrationIsNotDone:
  case "Case"
    when '05-Administration-Status' then
      "Administration"('ma-05-not-done').isNotDone()
        and not "Administration"('ma-05-completed').isNotDone()
    else true
  end

define TestMedicationAdministrationIsEnteredInError:
  case "Case"
    when '05-Administration-Status' then
      "Administration"('ma-05-entered-in-error').isEnteredInError()
        and not "Administration"('ma-05-completed').isEnteredInError()
    else true
  end

// Each status predicate holds for exactly the administration with that status
define TestMedicationAdministrationStatusPredicatesExclusive:
  case "Case"
    when '05-Administration-Status' then
      "SameKeys"("Administration Keys"("Administrations" MA where MA.isCompleted()), { 'ma-05-completed' })
        and "SameKeys"("Administration Keys"("Administrations" MA where MA.isInProgress()), { 'ma-05-in-progress' })
        and "SameKeys"("Administration Keys"("Administrations" MA where MA.isOnHold()), { 'ma-05-on-hold' })
        and "SameKeys"("Administration Keys"("Administrations" MA where MA.isStopped()), { 'ma-05-stopped' })
        and "SameKeys"("Administration Keys"("Administrations" MA where MA.isNotDone()), { 'ma-05-not-done' })
        and "SameKeys"("Administration Keys"("Administrations" MA where MA.isEnteredInError()), { 'ma-05-entered-in-error' })
    else true
  end

/*
 * MedicationAdministration category
 */

define TestMedicationAdministrationHasCategory:
  case "Case"
    when '06-Administration-Category' then
      "Administration"('ma-06-community').hasCategory("Administration Community")
        and not "Administration"('ma-06-community').hasCategory("Administration Inpatient")
    else true
  end

// A category is matched by any of its codings
define TestMedicationAdministrationHasCategoryMatchesAnyCoding:
  case "Case"
    when '06-Administration-Category' then
      "Administration"('ma-06-community-among-codings').hasCategory("Administration Community")
    else true
  end

// The same code in another code system doesn't match, including the MedicationRequest category code
// system, which has the same codes
define TestMedicationAdministrationHasCategoryWrongSystem:
  case "Case"
    when '06-Administration-Category' then
      not "Administration"('ma-06-wrong-system').hasCategory("Administration Community")
        and not "Administration"('ma-06-request-category').hasCategory("Administration Inpatient")
    else true
  end

define TestMedicationAdministrationHasCategoryNoCategory:
  case "Case"
    when '06-Administration-Category' then
      not "Administration"('ma-06-uncategorized').hasCategory("Administration Community")
    else true
  end

define TestMedicationAdministrationHasCategoryNullCategory:
  case "Case"
    when '06-Administration-Category' then not "Administration"('ma-06-community').hasCategory(null as Code)
    else true
  end

define TestMedicationAdministrationIsInpatient:
  case "Case"
    when '06-Administration-Category' then
      "Administration"('ma-06-inpatient').isInpatient()
        and not "Administration"('ma-06-outpatient').isInpatient()
        and not "Administration"('ma-06-uncategorized').isInpatient()
        and not "Administration"('ma-06-request-category').isInpatient()
    else true
  end

define TestMedicationAdministrationInpatient:
  case "Case"
    when '06-Administration-Category' then
      "SameKeys"("Administration Keys"("Administrations".inpatient()), { 'ma-06-inpatient' })
    when '09-No-Medications' then not exists "Administrations".inpatient()
    else true
  end

define TestMedicationAdministrationIsOutpatient:
  case "Case"
    when '06-Administration-Category' then
      "Administration"('ma-06-outpatient').isOutpatient()
        and not "Administration"('ma-06-inpatient').isOutpatient()
        and not "Administration"('ma-06-uncategorized').isOutpatient()
    else true
  end

define TestMedicationAdministrationOutpatient:
  case "Case"
    when '06-Administration-Category' then
      "SameKeys"("Administration Keys"("Administrations".outpatient()), { 'ma-06-outpatient' })
    when '09-No-Medications' then not exists "Administrations".outpatient()
    else true
  end

define TestMedicationAdministrationIsCommunity:
  case "Case"
    when '06-Administration-Category' then
      "Administration"('ma-06-community').isCommunity()
        and "Administration"('ma-06-community-among-codings').isCommunity()
        and not "Administration"('ma-06-inpatient').isCommunity()
        and not "Administration"('ma-06-uncategorized').isCommunity()
        and not "Administration"('ma-06-wrong-system').isCommunity()
    else true
  end

define TestMedicationAdministrationCommunity:
  case "Case"
    when '06-Administration-Category' then
      "SameKeys"("Administration Keys"("Administrations".community()), { 'ma-06-community', 'ma-06-community-among-codings' })
    when '09-No-Medications' then not exists "Administrations".community()
    else true
  end

/*
 * MedicationDispense status
 */

define TestMedicationDispenseIsCompleted:
  case "Case"
    when '07-Dispense-Status' then
      "Dispense"('md-07-completed').isCompleted()
        and not "Dispense"('md-07-in-progress').isCompleted()
    else true
  end

define TestMedicationDispenseCompleted:
  case "Case"
    when '07-Dispense-Status' then "SameKeys"("Dispense Keys"("Dispenses".completed()), { 'md-07-completed' })
    when '09-No-Medications' then not exists "Dispenses".completed()
    else true
  end

define TestMedicationDispenseIsInProgress:
  case "Case"
    when '07-Dispense-Status' then
      "Dispense"('md-07-in-progress').isInProgress()
        and not "Dispense"('md-07-preparation').isInProgress()
    else true
  end

define TestMedicationDispenseIsPreparation:
  case "Case"
    when '07-Dispense-Status' then
      "Dispense"('md-07-preparation').isPreparation()
        and not "Dispense"('md-07-in-progress').isPreparation()
    else true
  end

define TestMedicationDispenseIsOnHold:
  case "Case"
    when '07-Dispense-Status' then
      "Dispense"('md-07-on-hold').isOnHold()
        and not "Dispense"('md-07-in-progress').isOnHold()
    else true
  end

define TestMedicationDispenseIsCancelled:
  case "Case"
    when '07-Dispense-Status' then
      "Dispense"('md-07-cancelled').isCancelled()
        and not "Dispense"('md-07-stopped').isCancelled()
    else true
  end

define TestMedicationDispenseIsStopped:
  case "Case"
    when '07-Dispense-Status' then
      "Dispense"('md-07-stopped').isStopped()
        and not "Dispense"('md-07-cancelled').isStopped()
    else true
  end

define TestMedicationDispenseIsDeclined:
  case "Case"
    when '07-Dispense-Status' then
      "Dispense"('md-07-declined').isDeclined()
        and not "Dispense"('md-07-cancelled').isDeclined()
    else true
  end

define TestMedicationDispenseIsEnteredInError:
  case "Case"
    when '07-Dispense-Status' then
      "Dispense"('md-07-entered-in-error').isEnteredInError()
        and not "Dispense"('md-07-completed').isEnteredInError()
    else true
  end

// The composition the library header gives for a positive dispensing event
define TestMedicationDispensePositiveEvent:
  case "Case"
    when '07-Dispense-Status' then
      "SameKeys"(
        "Dispense Keys"("Dispenses" MD where MD.isInProgress() or MD.isCompleted() or MD.isOnHold()),
        { 'md-07-in-progress', 'md-07-completed', 'md-07-on-hold' }
      )
    else true
  end

// Each status predicate holds for exactly the dispense with that status
define TestMedicationDispenseStatusPredicatesExclusive:
  case "Case"
    when '07-Dispense-Status' then
      "SameKeys"("Dispense Keys"("Dispenses" MD where MD.isCompleted()), { 'md-07-completed' })
        and "SameKeys"("Dispense Keys"("Dispenses" MD where MD.isInProgress()), { 'md-07-in-progress' })
        and "SameKeys"("Dispense Keys"("Dispenses" MD where MD.isPreparation()), { 'md-07-preparation' })
        and "SameKeys"("Dispense Keys"("Dispenses" MD where MD.isOnHold()), { 'md-07-on-hold' })
        and "SameKeys"("Dispense Keys"("Dispenses" MD where MD.isCancelled()), { 'md-07-cancelled' })
        and "SameKeys"("Dispense Keys"("Dispenses" MD where MD.isStopped()), { 'md-07-stopped' })
        and "SameKeys"("Dispense Keys"("Dispenses" MD where MD.isDeclined()), { 'md-07-declined' })
        and "SameKeys"("Dispense Keys"("Dispenses" MD where MD.isEnteredInError()), { 'md-07-entered-in-error' })
    else true
  end

/*
 * Negation profiles
 *
 * The functions also resolve and run for the negation profiles, which fix the element the predicate
 * tests (MedicationNotRequested fixes doNotPerform, the other two fix the status).
 */

define TestProfileMedicationNotRequested:
  case "Case"
    when '08-Negation-Profiles' then
      "SameKeys"("Request Keys"([USQualityCore.MedicationNotRequested]), { 'mr-08-not-requested' })
        and "SameKeys"("Request Keys"(([USQualityCore.MedicationNotRequested]).completed()), { 'mr-08-not-requested' })
        and not exists ([USQualityCore.MedicationNotRequested]).active()
    when '09-No-Medications' then not exists [USQualityCore.MedicationNotRequested]
    else true
  end

define TestProfileMedicationAdministrationNotDone:
  case "Case"
    when '08-Negation-Profiles' then
      "SameKeys"("Administration Keys"([USQualityCore.MedicationAdministrationNotDone] MA where MA.isNotDone()), { 'ma-08-not-done' })
        and not exists ([USQualityCore.MedicationAdministrationNotDone]).completed()
    when '09-No-Medications' then not exists [USQualityCore.MedicationAdministrationNotDone]
    else true
  end

define TestProfileMedicationDispenseDeclined:
  case "Case"
    when '08-Negation-Profiles' then
      "SameKeys"("Dispense Keys"([USQualityCore.MedicationDispenseDeclined] MD where MD.isDeclined()), { 'md-08-declined' })
        and not exists ([USQualityCore.MedicationDispenseDeclined]).completed()
    when '09-No-Medications' then not exists [USQualityCore.MedicationDispenseDeclined]
    else true
  end

/*
 * Combined result
 */

// True only if every test in this library is true, for use as the population criteria of a Cohort
// measure. It uses `and` rather than AllTrue(), which ignores nulls, so that a null test fails it.
// It must list each Test define; .claude/skills/cql/check_results.py checks this.
define _Passed:
  TestMedicationRequestStatusDeclarations
    and TestMedicationRequestIntentDeclarations
    and TestMedicationRequestCategoryDeclarations
    and TestMedicationAdministrationCategoryDeclarations
    and TestMedicationAdministrationStatusDeclarations
    and TestMedicationDispenseStatusDeclarations
    and TestMedicationRequestIsActive
    and TestMedicationRequestActive
    and TestMedicationRequestIsOnHold
    and TestMedicationRequestOnHold
    and TestMedicationRequestIsCompleted
    and TestMedicationRequestCompleted
    and TestMedicationRequestActiveOrCompleted
    and TestMedicationRequestIsCancelled
    and TestMedicationRequestIsStopped
    and TestMedicationRequestIsDraft
    and TestMedicationRequestIsEnteredInError
    and TestMedicationRequestStatusPredicatesExclusive
    and TestMedicationRequestIsOrder
    and TestMedicationRequestIsPlan
    and TestMedicationRequestIsProposal
    and TestMedicationRequestIsOrderIntent
    and TestMedicationRequestOrderIntent
    and TestMedicationRequestHasCategory
    and TestMedicationRequestHasCategoryAmongSeveral
    and TestMedicationRequestHasCategoryMatchesAnyCoding
    and TestMedicationRequestHasCategoryWrongSystem
    and TestMedicationRequestHasCategoryNoCategories
    and TestMedicationRequestHasCategoryNullCategory
    and TestMedicationRequestIsInpatient
    and TestMedicationRequestInpatient
    and TestMedicationRequestIsOutpatient
    and TestMedicationRequestOutpatient
    and TestMedicationRequestIsCommunity
    and TestMedicationRequestCommunity
    and TestMedicationRequestIsDischarge
    and TestMedicationRequestDischarge
    and TestMedicationRequestCommunityOrDischarge
    and TestMedicationRequestMostRecent
    and TestMedicationRequestMostRecentOrder
    and TestMedicationRequestMostRecentIgnoresNotAuthored
    and TestMedicationRequestMostRecentOnlyNotAuthored
    and TestMedicationRequestMostRecentEmpty
    and TestMedicationAdministrationIsCompleted
    and TestMedicationAdministrationCompleted
    and TestMedicationAdministrationIsInProgress
    and TestMedicationAdministrationIsOnHold
    and TestMedicationAdministrationIsStopped
    and TestMedicationAdministrationIsNotDone
    and TestMedicationAdministrationIsEnteredInError
    and TestMedicationAdministrationStatusPredicatesExclusive
    and TestMedicationAdministrationHasCategory
    and TestMedicationAdministrationHasCategoryMatchesAnyCoding
    and TestMedicationAdministrationHasCategoryWrongSystem
    and TestMedicationAdministrationHasCategoryNoCategory
    and TestMedicationAdministrationHasCategoryNullCategory
    and TestMedicationAdministrationIsInpatient
    and TestMedicationAdministrationInpatient
    and TestMedicationAdministrationIsOutpatient
    and TestMedicationAdministrationOutpatient
    and TestMedicationAdministrationIsCommunity
    and TestMedicationAdministrationCommunity
    and TestMedicationDispenseIsCompleted
    and TestMedicationDispenseCompleted
    and TestMedicationDispenseIsInProgress
    and TestMedicationDispenseIsPreparation
    and TestMedicationDispenseIsOnHold
    and TestMedicationDispenseIsCancelled
    and TestMedicationDispenseIsStopped
    and TestMedicationDispenseIsDeclined
    and TestMedicationDispenseIsEnteredInError
    and TestMedicationDispensePositiveEvent
    and TestMedicationDispenseStatusPredicatesExclusive
    and TestProfileMedicationNotRequested
    and TestProfileMedicationAdministrationNotDone
    and TestProfileMedicationDispenseDeclined

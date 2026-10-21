/*
@description: Tests for the MedicationCommon library
@comment: Each test expression is named `Test...` and evaluates to `true` when the test passes.

The fixtures build their resources inline with FHIRBuilders, so most tests need neither patient data
nor terminology. The status and intent functions compare only the code value of the status or intent
element, so the fixtures set those elements directly. The category functions compare codings, so the
category fixtures are built from code systems and codes declared in this library rather than from the
MedicationCommon code declarations. The code declarations are tested separately against independently
declared codes, so that a wrong system or code in MedicationCommon makes a test fail.

The profile tests run the functions over retrieved US Quality Core medication resources. They check that
the FHIR-typed overloads resolve for profiled inputs, and are invariants that must hold for whatever
data is loaded. With no data loaded they are vacuously true.

NOTE: This is in the process of being established as the measure MedicationCommonTests in MADiE:
https://madie.cms.gov/measures/6ad8cdd11fbcbfc8d7e0c9bd/edit/details/
*/
library MedicationCommonTests version '0.2.000'

using USQualityCore version '0.5.0'
using USCore version '6.1.0-derived'
using FHIR version '4.0.1'

include hl7.fhir.uv.cql.FHIRHelpers version '4.0.1'

include MedicationCommon version '0.2.000'
include FHIRBuilders version '0.1.000' called Build

codesystem "RXNORM": 'http://www.nlm.nih.gov/research/umls/rxnorm'
codesystem "MedicationRequestStatus": 'http://hl7.org/fhir/CodeSystem/medicationrequest-status'
codesystem "MedicationRequestIntent": 'http://hl7.org/fhir/CodeSystem/medicationrequest-intent'
codesystem "MedicationAdministrationStatus": 'http://terminology.hl7.org/CodeSystem/medication-admin-status'
codesystem "MedicationDispenseStatus": 'http://terminology.hl7.org/CodeSystem/medicationdispense-status'
codesystem "MedicationRequestCategory": 'http://terminology.hl7.org/CodeSystem/medicationrequest-category'
codesystem "MedicationAdministrationCategory": 'http://terminology.hl7.org/CodeSystem/medication-admin-category'

// A code system that is deliberately not one the MedicationCommon terminology uses
codesystem "Example Codes": 'http://example.org/codes'

context Patient

/*
 * Fixture builders
 */

define function "Test MedicationRequest"(status String, intent String):
  FHIR.MedicationRequest {
    id: Build.id(Coalesce(status, 'no-status') + '-' + Coalesce(intent, 'no-intent')),
    status: FHIR.MedicationRequestStatus { value: status },
    intent: FHIR.MedicationRequestIntent { value: intent },
    medication: "Aspirin",
    subject: Build.Reference('Patient/test-patient')
  }

define function "Test MedicationAdministration"(status String):
  FHIR.MedicationAdministration {
    id: Build.id(Coalesce(status, 'no-status')),
    status: FHIR.MedicationAdministrationStatus { value: status },
    medication: "Aspirin",
    subject: Build.Reference('Patient/test-patient'),
    effective: Build.dateTime(@2024-03-01T08:00:00.000Z)
  }

define function "Test MedicationDispense"(status String):
  FHIR.MedicationDispense {
    id: Build.id(Coalesce(status, 'no-status')),
    status: FHIR.MedicationDispenseStatus { value: status },
    medication: "Aspirin",
    subject: Build.Reference('Patient/test-patient')
  }

define function "Categorized MedicationRequest"(id String, categories List<FHIR.CodeableConcept>):
  FHIR.MedicationRequest {
    id: Build.id(id),
    status: FHIR.MedicationRequestStatus { value: 'active' },
    intent: FHIR.MedicationRequestIntent { value: 'order' },
    category: categories,
    medication: "Aspirin",
    subject: Build.Reference('Patient/test-patient')
  }

define function "Categorized MedicationAdministration"(id String, category FHIR.CodeableConcept):
  FHIR.MedicationAdministration {
    id: Build.id(id),
    status: FHIR.MedicationAdministrationStatus { value: 'completed' },
    category: category,
    medication: "Aspirin",
    subject: Build.Reference('Patient/test-patient'),
    effective: Build.dateTime(@2024-03-01T08:00:00.000Z)
  }

define function "Ids"(resources List<FHIR.Resource>):
  resources R
    return R.id.value

// True if the resources have exactly the given ids, in any order
define function "Has Ids"(resources List<FHIR.Resource>, ids List<String>):
  Count(resources) = Count(ids)
    and "Ids"(resources) includes ids

/*
 * Fixtures
 */

define "Aspirin":
  Build.CodeableConcept(Code '243670' from "RXNORM" display 'aspirin 81 MG Oral Tablet')

// One request for each status, all with an intent of order
define "Requests By Status":
  ({ 'active', 'on-hold', 'cancelled', 'completed', 'entered-in-error', 'stopped', 'draft', 'unknown' }) S
    return "Test MedicationRequest"(S, 'order')

// One request for each intent, all with a status of active
define "Requests By Intent":
  ({ 'proposal', 'plan', 'order', 'original-order', 'reflex-order', 'filler-order', 'instance-order', 'option' }) I
    return "Test MedicationRequest"('active', I)

define "Request Without Status Or Intent": "Test MedicationRequest"(null, null)

define "Administrations":
  ({ 'in-progress', 'not-done', 'on-hold', 'completed', 'entered-in-error', 'stopped', 'unknown' }) S
    return "Test MedicationAdministration"(S)

define "Administration Without Status": "Test MedicationAdministration"(null)

define "Dispenses":
  ({ 'preparation', 'in-progress', 'cancelled', 'on-hold', 'completed', 'entered-in-error', 'stopped', 'declined', 'unknown' }) S
    return "Test MedicationDispense"(S)

define "Dispense Without Status": "Test MedicationDispense"(null)

define function "Request"(status String): "Test MedicationRequest"(status, 'order')
define function "Order"(intent String): "Test MedicationRequest"('active', intent)
define function "Administration"(status String): "Test MedicationAdministration"(status)
define function "Dispense"(status String): "Test MedicationDispense"(status)

define "Request Inpatient": Code 'inpatient' from "MedicationRequestCategory"
define "Request Outpatient": Code 'outpatient' from "MedicationRequestCategory"
define "Request Community": Code 'community' from "MedicationRequestCategory"
define "Request Discharge": Code 'discharge' from "MedicationRequestCategory"
define "Administration Inpatient": Code 'inpatient' from "MedicationAdministrationCategory"
define "Administration Outpatient": Code 'outpatient' from "MedicationAdministrationCategory"
define "Administration Community": Code 'community' from "MedicationAdministrationCategory"

define "Inpatient Request": "Categorized MedicationRequest"('inpatient', { Build.CodeableConcept("Request Inpatient") })
define "Outpatient Request": "Categorized MedicationRequest"('outpatient', { Build.CodeableConcept("Request Outpatient") })
define "Community Request": "Categorized MedicationRequest"('community', { Build.CodeableConcept("Request Community") })
define "Discharge Request": "Categorized MedicationRequest"('discharge', { Build.CodeableConcept("Request Discharge") })
define "Community And Discharge Request":
  "Categorized MedicationRequest"('community-discharge', {
    Build.CodeableConcept("Request Community"),
    Build.CodeableConcept("Request Discharge")
  })
// A category is matched by any of its codings
define "Discharge Among Codings Request":
  "Categorized MedicationRequest"('discharge-among-codings', {
    Build.CodeableConcept(Concept { Code 'discharge-meds' from "Example Codes", Code 'discharge' from "MedicationRequestCategory" })
  })
define "Uncategorized Request": "Categorized MedicationRequest"('uncategorized', List<FHIR.CodeableConcept>{})
define "Wrong System Request": "Categorized MedicationRequest"('wrong-system', { Build.CodeableConcept(Code 'community' from "Example Codes") })
// The MedicationAdministration category code system has the same codes, but is a different code system
define "Administration Category Request":
  "Categorized MedicationRequest"('administration-category', { Build.CodeableConcept("Administration Community") })

define function "Authored MedicationRequest"(id String, authoredOn DateTime):
  FHIR.MedicationRequest {
    id: Build.id(id),
    status: FHIR.MedicationRequestStatus { value: 'active' },
    intent: FHIR.MedicationRequestIntent { value: 'order' },
    medication: "Aspirin",
    subject: Build.Reference('Patient/test-patient'),
    authoredOn: Build.dateTime(authoredOn)
  }

define "Authored March 1": "Authored MedicationRequest"('march-1', @2024-03-01T08:00:00.000Z)
define "Authored March 5": "Authored MedicationRequest"('march-5', @2024-03-05T08:00:00.000Z)
define "Authored March 5 Later": "Authored MedicationRequest"('march-5-later', @2024-03-05T09:00:00.000Z)
define "Not Authored": "Authored MedicationRequest"('not-authored', null)

define "Categorized Requests":
  {
    "Inpatient Request",
    "Outpatient Request",
    "Community Request",
    "Discharge Request",
    "Community And Discharge Request",
    "Discharge Among Codings Request",
    "Uncategorized Request",
    "Wrong System Request",
    "Administration Category Request"
  }

define "Inpatient Administration": "Categorized MedicationAdministration"('inpatient', Build.CodeableConcept("Administration Inpatient"))
define "Outpatient Administration": "Categorized MedicationAdministration"('outpatient', Build.CodeableConcept("Administration Outpatient"))
define "Community Administration": "Categorized MedicationAdministration"('community', Build.CodeableConcept("Administration Community"))
define "Community Among Codings Administration":
  "Categorized MedicationAdministration"('community-among-codings',
    Build.CodeableConcept(Concept { Code 'home' from "Example Codes", Code 'community' from "MedicationAdministrationCategory" })
  )
define "Uncategorized Administration": "Categorized MedicationAdministration"('uncategorized', null)
define "Wrong System Administration": "Categorized MedicationAdministration"('wrong-system', Build.CodeableConcept(Code 'community' from "Example Codes"))
// The MedicationRequest category code system has the same codes, but is a different code system
define "Request Category Administration":
  "Categorized MedicationAdministration"('request-category', Build.CodeableConcept("Request Inpatient"))

define "Categorized Administrations":
  {
    "Inpatient Administration",
    "Outpatient Administration",
    "Community Administration",
    "Community Among Codings Administration",
    "Uncategorized Administration",
    "Wrong System Administration",
    "Request Category Administration"
  }

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
  "Request"('active').isActive()
    and not "Request"('completed').isActive()
    and not "Request"('on-hold').isActive()
    and not "Request Without Status Or Intent".isActive()

define TestMedicationRequestActive:
  "Has Ids"("Requests By Status".active(), { 'active-order' })

define TestMedicationRequestActiveEmpty:
  not exists (List<FHIR.MedicationRequest>{}).active()

define TestMedicationRequestIsOnHold:
  "Request"('on-hold').isOnHold()
    and not "Request"('active').isOnHold()
    and not "Request Without Status Or Intent".isOnHold()

define TestMedicationRequestOnHold:
  "Has Ids"("Requests By Status".onHold(), { 'on-hold-order' })

define TestMedicationRequestIsCompleted:
  "Request"('completed').isCompleted()
    and not "Request"('active').isCompleted()
    and not "Request Without Status Or Intent".isCompleted()

define TestMedicationRequestCompleted:
  "Has Ids"("Requests By Status".completed(), { 'completed-order' })

// The composition the library header recommends in place of an aggregate helper
define TestMedicationRequestActiveOrCompleted:
  "Has Ids"(
    "Requests By Status" MR where MR.isActive() or MR.isCompleted(),
    { 'active-order', 'completed-order' }
  )

define TestMedicationRequestIsCancelled:
  "Request"('cancelled').isCancelled()
    and not "Request"('stopped').isCancelled()
    and not "Request Without Status Or Intent".isCancelled()

define TestMedicationRequestIsStopped:
  "Request"('stopped').isStopped()
    and not "Request"('cancelled').isStopped()
    and not "Request Without Status Or Intent".isStopped()

define TestMedicationRequestIsDraft:
  "Request"('draft').isDraft()
    and not "Request"('active').isDraft()
    and not "Request Without Status Or Intent".isDraft()

define TestMedicationRequestIsEnteredInError:
  "Request"('entered-in-error').isEnteredInError()
    and not "Request"('active').isEnteredInError()
    and not "Request Without Status Or Intent".isEnteredInError()

// Invariant: each status predicate holds for exactly one status
define TestMedicationRequestStatusPredicatesExclusive:
  Count("Requests By Status" MR where MR.isActive()) = 1
    and Count("Requests By Status" MR where MR.isOnHold()) = 1
    and Count("Requests By Status" MR where MR.isCompleted()) = 1
    and Count("Requests By Status" MR where MR.isCancelled()) = 1
    and Count("Requests By Status" MR where MR.isStopped()) = 1
    and Count("Requests By Status" MR where MR.isDraft()) = 1
    and Count("Requests By Status" MR where MR.isEnteredInError()) = 1

/*
 * MedicationRequest intent
 */

define TestMedicationRequestIsOrder:
  "Order"('order').isOrder()
    // Only the order intent, not the other order intents
    and not "Order"('original-order').isOrder()
    and not "Order"('plan').isOrder()
    and not "Request Without Status Or Intent".isOrder()

define TestMedicationRequestIsPlan:
  "Order"('plan').isPlan()
    and not "Order"('order').isPlan()
    and not "Request Without Status Or Intent".isPlan()

define TestMedicationRequestIsProposal:
  "Order"('proposal').isProposal()
    and not "Order"('order').isProposal()
    and not "Request Without Status Or Intent".isProposal()

define TestMedicationRequestIsOrderIntent:
  "Order"('order').isOrderIntent()
    and "Order"('original-order').isOrderIntent()
    and "Order"('reflex-order').isOrderIntent()
    and "Order"('filler-order').isOrderIntent()
    and "Order"('instance-order').isOrderIntent()
    and not "Order"('proposal').isOrderIntent()
    and not "Order"('plan').isOrderIntent()
    and not "Order"('option').isOrderIntent()
    and not "Request Without Status Or Intent".isOrderIntent()

define TestMedicationRequestOrderIntent:
  "Has Ids"(
    "Requests By Intent".orderIntent(),
    { 'active-order', 'active-original-order', 'active-reflex-order', 'active-filler-order', 'active-instance-order' }
  )

define TestMedicationRequestOrderIntentEmpty:
  not exists (List<FHIR.MedicationRequest>{}).orderIntent()

/*
 * MedicationRequest category
 */

define TestMedicationRequestHasCategory:
  "Community Request".hasCategory("Request Community")
    and not "Community Request".hasCategory("Request Discharge")

define TestMedicationRequestHasCategoryAmongSeveral:
  "Community And Discharge Request".hasCategory("Request Community")
    and "Community And Discharge Request".hasCategory("Request Discharge")

define TestMedicationRequestHasCategoryMatchesAnyCoding:
  "Discharge Among Codings Request".hasCategory("Request Discharge")

define TestMedicationRequestHasCategoryWrongSystem:
  not "Wrong System Request".hasCategory("Request Community")
    and not "Administration Category Request".hasCategory("Request Community")

define TestMedicationRequestHasCategoryNoCategories:
  not "Uncategorized Request".hasCategory("Request Community")

define TestMedicationRequestHasCategoryNullCategory:
  not "Community Request".hasCategory(null as Code)

define TestMedicationRequestIsInpatient:
  "Inpatient Request".isInpatient()
    and not "Outpatient Request".isInpatient()
    and not "Uncategorized Request".isInpatient()

define TestMedicationRequestInpatient:
  "Has Ids"("Categorized Requests".inpatient(), { 'inpatient' })

define TestMedicationRequestIsOutpatient:
  "Outpatient Request".isOutpatient()
    and not "Inpatient Request".isOutpatient()
    and not "Uncategorized Request".isOutpatient()

define TestMedicationRequestOutpatient:
  "Has Ids"("Categorized Requests".outpatient(), { 'outpatient' })

define TestMedicationRequestIsCommunity:
  "Community Request".isCommunity()
    and "Community And Discharge Request".isCommunity()
    and not "Discharge Request".isCommunity()
    and not "Uncategorized Request".isCommunity()
    and not "Wrong System Request".isCommunity()
    and not "Administration Category Request".isCommunity()

define TestMedicationRequestCommunity:
  "Has Ids"("Categorized Requests".community(), { 'community', 'community-discharge' })

define TestMedicationRequestIsDischarge:
  "Discharge Request".isDischarge()
    and "Community And Discharge Request".isDischarge()
    and "Discharge Among Codings Request".isDischarge()
    and not "Community Request".isDischarge()
    and not "Uncategorized Request".isDischarge()

define TestMedicationRequestDischarge:
  "Has Ids"("Categorized Requests".discharge(), { 'discharge', 'community-discharge', 'discharge-among-codings' })

// The composition used for discharge medications in CMS measure logic
define TestMedicationRequestCommunityOrDischarge:
  "Has Ids"(
    "Categorized Requests" MR where MR.isCommunity() or MR.isDischarge(),
    { 'community', 'discharge', 'community-discharge', 'discharge-among-codings' }
  )

define TestMedicationRequestCategoryEmpty:
  not exists (List<FHIR.MedicationRequest>{}).community()

/*
 * MedicationRequest selection
 */

// The order of the input doesn't matter
define TestMedicationRequestMostRecent:
  ({ "Authored March 5", "Authored March 1" }).mostRecent().id = 'march-5'
    and ({ "Authored March 1", "Authored March 5" }).mostRecent().id = 'march-5'

// The time of day is taken into account, not just the date
define TestMedicationRequestMostRecentSameDay:
  ({ "Authored March 5 Later", "Authored March 5", "Authored March 1" }).mostRecent().id = 'march-5-later'

// Nulls sort first, so a request with no authoredOn is not the most recent
define TestMedicationRequestMostRecentIgnoresNotAuthored:
  ({ "Authored March 1", "Not Authored" }).mostRecent().id = 'march-1'
    and ({ "Not Authored", "Authored March 1" }).mostRecent().id = 'march-1'

define TestMedicationRequestMostRecentOnlyNotAuthored:
  ({ "Not Authored" }).mostRecent().id = 'not-authored'

define TestMedicationRequestMostRecentSingle:
  ({ "Authored March 1" }).mostRecent().id = 'march-1'

define TestMedicationRequestMostRecentEmpty:
  (List<FHIR.MedicationRequest>{}).mostRecent() is null

/*
 * MedicationAdministration status
 */

define TestMedicationAdministrationIsCompleted:
  "Administration"('completed').isCompleted()
    and not "Administration"('in-progress').isCompleted()
    and not "Administration Without Status".isCompleted()

define TestMedicationAdministrationCompleted:
  "Has Ids"("Administrations".completed(), { 'completed' })

define TestMedicationAdministrationCompletedEmpty:
  not exists (List<FHIR.MedicationAdministration>{}).completed()

define TestMedicationAdministrationIsInProgress:
  "Administration"('in-progress').isInProgress()
    and not "Administration"('completed').isInProgress()
    and not "Administration Without Status".isInProgress()

define TestMedicationAdministrationIsOnHold:
  "Administration"('on-hold').isOnHold()
    and not "Administration"('in-progress').isOnHold()
    and not "Administration Without Status".isOnHold()

define TestMedicationAdministrationIsStopped:
  "Administration"('stopped').isStopped()
    and not "Administration"('completed').isStopped()
    and not "Administration Without Status".isStopped()

define TestMedicationAdministrationIsNotDone:
  "Administration"('not-done').isNotDone()
    and not "Administration"('completed').isNotDone()
    and not "Administration Without Status".isNotDone()

define TestMedicationAdministrationIsEnteredInError:
  "Administration"('entered-in-error').isEnteredInError()
    and not "Administration"('completed').isEnteredInError()
    and not "Administration Without Status".isEnteredInError()

// Invariant: each status predicate holds for exactly one status
define TestMedicationAdministrationStatusPredicatesExclusive:
  Count("Administrations" MA where MA.isCompleted()) = 1
    and Count("Administrations" MA where MA.isInProgress()) = 1
    and Count("Administrations" MA where MA.isOnHold()) = 1
    and Count("Administrations" MA where MA.isStopped()) = 1
    and Count("Administrations" MA where MA.isNotDone()) = 1
    and Count("Administrations" MA where MA.isEnteredInError()) = 1

/*
 * MedicationAdministration category
 */

define TestMedicationAdministrationHasCategory:
  "Community Administration".hasCategory("Administration Community")
    and not "Community Administration".hasCategory("Administration Inpatient")

define TestMedicationAdministrationHasCategoryMatchesAnyCoding:
  "Community Among Codings Administration".hasCategory("Administration Community")

define TestMedicationAdministrationHasCategoryWrongSystem:
  not "Wrong System Administration".hasCategory("Administration Community")
    and not "Request Category Administration".hasCategory("Administration Inpatient")

define TestMedicationAdministrationHasCategoryNoCategory:
  not "Uncategorized Administration".hasCategory("Administration Community")

define TestMedicationAdministrationHasCategoryNullCategory:
  not "Community Administration".hasCategory(null as Code)

define TestMedicationAdministrationIsInpatient:
  "Inpatient Administration".isInpatient()
    and not "Outpatient Administration".isInpatient()
    and not "Uncategorized Administration".isInpatient()
    and not "Request Category Administration".isInpatient()

define TestMedicationAdministrationInpatient:
  "Has Ids"("Categorized Administrations".inpatient(), { 'inpatient' })

define TestMedicationAdministrationIsOutpatient:
  "Outpatient Administration".isOutpatient()
    and not "Inpatient Administration".isOutpatient()
    and not "Uncategorized Administration".isOutpatient()

define TestMedicationAdministrationOutpatient:
  "Has Ids"("Categorized Administrations".outpatient(), { 'outpatient' })

define TestMedicationAdministrationIsCommunity:
  "Community Administration".isCommunity()
    and "Community Among Codings Administration".isCommunity()
    and not "Inpatient Administration".isCommunity()
    and not "Uncategorized Administration".isCommunity()
    and not "Wrong System Administration".isCommunity()

define TestMedicationAdministrationCommunity:
  "Has Ids"("Categorized Administrations".community(), { 'community', 'community-among-codings' })

define TestMedicationAdministrationCategoryEmpty:
  not exists (List<FHIR.MedicationAdministration>{}).inpatient()

/*
 * MedicationDispense status
 */

define TestMedicationDispenseIsCompleted:
  "Dispense"('completed').isCompleted()
    and not "Dispense"('in-progress').isCompleted()
    and not "Dispense Without Status".isCompleted()

define TestMedicationDispenseCompleted:
  "Has Ids"("Dispenses".completed(), { 'completed' })

define TestMedicationDispenseCompletedEmpty:
  not exists (List<FHIR.MedicationDispense>{}).completed()

define TestMedicationDispenseIsInProgress:
  "Dispense"('in-progress').isInProgress()
    and not "Dispense"('preparation').isInProgress()
    and not "Dispense Without Status".isInProgress()

define TestMedicationDispenseIsPreparation:
  "Dispense"('preparation').isPreparation()
    and not "Dispense"('in-progress').isPreparation()
    and not "Dispense Without Status".isPreparation()

define TestMedicationDispenseIsOnHold:
  "Dispense"('on-hold').isOnHold()
    and not "Dispense"('in-progress').isOnHold()
    and not "Dispense Without Status".isOnHold()

define TestMedicationDispenseIsCancelled:
  "Dispense"('cancelled').isCancelled()
    and not "Dispense"('stopped').isCancelled()
    and not "Dispense Without Status".isCancelled()

define TestMedicationDispenseIsStopped:
  "Dispense"('stopped').isStopped()
    and not "Dispense"('cancelled').isStopped()
    and not "Dispense Without Status".isStopped()

define TestMedicationDispenseIsDeclined:
  "Dispense"('declined').isDeclined()
    and not "Dispense"('cancelled').isDeclined()
    and not "Dispense Without Status".isDeclined()

define TestMedicationDispenseIsEnteredInError:
  "Dispense"('entered-in-error').isEnteredInError()
    and not "Dispense"('completed').isEnteredInError()
    and not "Dispense Without Status".isEnteredInError()

// The composition the library header gives for a positive dispensing event
define TestMedicationDispensePositiveEvent:
  "Has Ids"(
    "Dispenses" MD where MD.isInProgress() or MD.isCompleted() or MD.isOnHold(),
    { 'in-progress', 'completed', 'on-hold' }
  )

// Invariant: each status predicate holds for exactly one status
define TestMedicationDispenseStatusPredicatesExclusive:
  Count("Dispenses" MD where MD.isCompleted()) = 1
    and Count("Dispenses" MD where MD.isInProgress()) = 1
    and Count("Dispenses" MD where MD.isPreparation()) = 1
    and Count("Dispenses" MD where MD.isOnHold()) = 1
    and Count("Dispenses" MD where MD.isCancelled()) = 1
    and Count("Dispenses" MD where MD.isStopped()) = 1
    and Count("Dispenses" MD where MD.isDeclined()) = 1
    and Count("Dispenses" MD where MD.isEnteredInError()) = 1

/*
 * Profiles
 *
 * Invariants: the FHIR-typed functions resolve for US Quality Core medication resources, and agree with
 * the elements they test.
 */

define TestProfileMedicationRequest:
  AllTrue([USQualityCore.MedicationRequest] MR return MR.isActive() implies MR.status = 'active')
    and AllTrue([USQualityCore.MedicationRequest] MR return MR.isOrderIntent() implies MR.intent in { 'order', 'original-order', 'reflex-order', 'filler-order', 'instance-order' })
    and Count(([USQualityCore.MedicationRequest]).active()) = Count([USQualityCore.MedicationRequest] MR where MR.status = 'active')

define TestProfileMedicationRequestCategory:
  AllTrue(
    [USQualityCore.MedicationRequest] MR
      return (MR.isCommunity() implies exists (MR.category C where C ~ Code 'community' from "MedicationRequestCategory"))
        and (MR.isDischarge() implies exists (MR.category C where C ~ Code 'discharge' from "MedicationRequestCategory"))
  )
    and Count(([USQualityCore.MedicationRequest]).inpatient())
      = Count([USQualityCore.MedicationRequest] MR where MR.hasCategory(Code 'inpatient' from "MedicationRequestCategory"))

define TestProfileMedicationAdministrationCategory:
  AllTrue(
    [USQualityCore.MedicationAdministration] MA
      return MA.isInpatient() implies MA.category ~ Code 'inpatient' from "MedicationAdministrationCategory"
  )
    and Count(([USQualityCore.MedicationAdministration]).community())
      = Count([USQualityCore.MedicationAdministration] MA where MA.hasCategory(Code 'community' from "MedicationAdministrationCategory"))

// No retrieved request was authored after the most recent one
define TestProfileMedicationRequestMostRecent:
  AllTrue(
    [USQualityCore.MedicationRequest] MR
      return not (MR.authoredOn after ([USQualityCore.MedicationRequest]).mostRecent().authoredOn)
  )

define TestProfileMedicationNotRequested:
  AllTrue([USQualityCore.MedicationNotRequested] MR return MR.isCompleted() implies MR.status = 'completed')

define TestProfileMedicationAdministration:
  AllTrue([USQualityCore.MedicationAdministration] MA return MA.isCompleted() implies MA.status = 'completed')
    and Count(([USQualityCore.MedicationAdministration]).completed()) = Count([USQualityCore.MedicationAdministration] MA where MA.status = 'completed')

define TestProfileMedicationAdministrationNotDone:
  AllTrue([USQualityCore.MedicationAdministrationNotDone] MA return MA.isNotDone() implies MA.status = 'not-done')

define TestProfileMedicationDispense:
  AllTrue([USQualityCore.MedicationDispense] MD return MD.isCompleted() implies MD.status = 'completed')
    and Count(([USQualityCore.MedicationDispense]).completed()) = Count([USQualityCore.MedicationDispense] MD where MD.status = 'completed')

define TestProfileMedicationDispenseDeclined:
  AllTrue([USQualityCore.MedicationDispenseDeclined] MD return MD.isDeclined() implies MD.status = 'declined')

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
    and TestMedicationRequestActiveEmpty
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
    and TestMedicationRequestOrderIntentEmpty
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
    and TestMedicationRequestCategoryEmpty
    and TestMedicationRequestMostRecent
    and TestMedicationRequestMostRecentSameDay
    and TestMedicationRequestMostRecentIgnoresNotAuthored
    and TestMedicationRequestMostRecentOnlyNotAuthored
    and TestMedicationRequestMostRecentSingle
    and TestMedicationRequestMostRecentEmpty
    and TestMedicationAdministrationIsCompleted
    and TestMedicationAdministrationCompleted
    and TestMedicationAdministrationCompletedEmpty
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
    and TestMedicationAdministrationCategoryEmpty
    and TestMedicationDispenseIsCompleted
    and TestMedicationDispenseCompleted
    and TestMedicationDispenseCompletedEmpty
    and TestMedicationDispenseIsInProgress
    and TestMedicationDispenseIsPreparation
    and TestMedicationDispenseIsOnHold
    and TestMedicationDispenseIsCancelled
    and TestMedicationDispenseIsStopped
    and TestMedicationDispenseIsDeclined
    and TestMedicationDispenseIsEnteredInError
    and TestMedicationDispensePositiveEvent
    and TestMedicationDispenseStatusPredicatesExclusive
    and TestProfileMedicationRequest
    and TestProfileMedicationRequestCategory
    and TestProfileMedicationAdministrationCategory
    and TestProfileMedicationRequestMostRecent
    and TestProfileMedicationNotRequested
    and TestProfileMedicationAdministration
    and TestProfileMedicationAdministrationNotDone
    and TestProfileMedicationDispense
    and TestProfileMedicationDispenseDeclined

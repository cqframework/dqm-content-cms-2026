/*
@description: Tests for the MedicationElements library
@comment: Each test expression is named `Test...` and evaluates to `true` when the test passes.

The test data is in `input/tests/MedicationElementsTests/<patient id>/`, one folder per patient. Patient
ids are GUIDs, as MADiE expects, so each case is identified by its label, the patient's given name (e.g.
`01-Request-Medication-Forms`). See the README there for what each case contains. Every expression is
evaluated once per case, so:
* Case tests list the expected result for each case they cover, and are `true` for any other case.
* Invariant tests (marked as such) must hold for every case.

So every test must be `true` on every case: `false` or `null` is a failure. A `null` on a case a test
covers means the assertion couldn't be evaluated, e.g. because an element it reads came back null.
Because a case a test doesn't cover passes, a misspelled case name in a `when` clause would pass
silently; `.claude/skills/cql/check_results.py` checks the names against the case labels.

MADiE also replaces resource ids that aren't GUIDs with new GUIDs on import, so the tests don't use
resource ids. Each retrieved resource has a readable key (e.g. `mr-01-code`) in an identifier with the
system `http://example.org/fhir/identifiers`. MedicationElements copies `identifier`, so each element is
found by the same key as the resource it was built from (`"Request Element"`, ...).

Each element definition is tested for:
* one element per retrieved resource (invariant),
* the medication: an inline code is kept, a reference is replaced by the referenced Medication's code
  (a Medication in the data, or one contained in the resource), and a reference to a Medication that
  isn't loaded gives a null medication. The normalized medication is compared as a whole concept, with
  the declared RxNorm code and with the source concept (the inline code or the Medication's code),
* downstream use: one predicate on the normalized medication (`~` an RxNorm code) selects every
  resource for that drug, whichever way the source identified it, and none of the others,
* the elements it copies, compared with the retrieved resource. `null ~ null` is true, so each copied
  element is also checked to be present on the retrieved resource,
* the subject being the patient (invariant).

The medication codes are RxNorm codes, declared here, so the tests need no value sets.

NOTE: This library is developed in the dqm-content-cms-2026 repository:
https://github.com/cqframework/dqm-content-cms-2026/blob/main/input/cql/MedicationElementsTests.cql
*/
library MedicationElementsTests version '0.2.000'

using USQualityCore version '0.5.0'
using USCore version '6.1.0-derived'
using FHIR version '4.0.1'

include hl7.fhir.uv.cql.FHIRHelpers version '4.0.1'

include MedicationElements version '0.2.000'

codesystem "RXNORM": 'http://www.nlm.nih.gov/research/umls/rxnorm'

code "Amlodipine 5 MG Oral Tablet": '197361' from "RXNORM" display 'amlodipine 5 MG Oral Tablet'
code "Lisinopril 10 MG Oral Tablet": '314076' from "RXNORM" display 'lisinopril 10 MG Oral Tablet'
code "Ibuprofen 200 MG Oral Tablet": '310965' from "RXNORM" display 'ibuprofen 200 MG Oral Tablet'

context Patient

/*
 * Helpers
 */

// The case is the test case label, which is the patient's given name. The patient id (and the name of
// the test case folder) is a GUID, as MADiE expects, so it doesn't say which case this is.
define "Case": FHIRHelpers.ToString(First(Patient.name.given))

define "Patient Reference": 'Patient/' + FHIRHelpers.ToString(Patient.id)

// Resources are identified by a readable key (e.g. `mr-01-code`) in an identifier with this system, not by
// their ids: MADiE replaces resource ids that aren't GUIDs with new GUIDs on import
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

define function "MedicationDispenseKey"(dispense FHIR.MedicationDispense):
  singleton from (
    dispense.identifier I
      where I.system = "Key System"
      return I.value.value
  )

define function "MedicationAdministrationKey"(administration FHIR.MedicationAdministration):
  singleton from (
    administration.identifier I
      where I.system = "Key System"
      return I.value.value
  )

define function "MedicationKey"(medication FHIR.Medication):
  singleton from (
    medication.identifier I
      where I.system = "Key System"
      return I.value.value
  )

// True if the keys are exactly the expected keys, in any order
define function "SameKeys"(keys List<String>, expected List<String>):
  Count(keys) = Count(expected)
    and keys includes expected

// The Medication (not contained) with the given key
define function "Medication"(key String):
  singleton from ([USQualityCore.Medication] M where "MedicationKey"(M) = key)

// The retrieved resource with the given key, and the MedicationElements element built from it
define function "Request"(key String):
  singleton from ([USQualityCore.MedicationRequest] R where "MedicationRequestKey"(R) = key)

define function "Request Element"(key String):
  singleton from (MedicationElements.MedicationRequest E where "MedicationRequestKey"(E) = key)

define function "Dispense"(key String):
  singleton from ([USQualityCore.MedicationDispense] D where "MedicationDispenseKey"(D) = key)

define function "Dispense Element"(key String):
  singleton from (MedicationElements.MedicationDispense E where "MedicationDispenseKey"(E) = key)

define function "Administration"(key String):
  singleton from ([USQualityCore.MedicationAdministration] A where "MedicationAdministrationKey"(A) = key)

define function "Administration Element"(key String):
  singleton from (MedicationElements.MedicationAdministration E where "MedicationAdministrationKey"(E) = key)

// The normalized medication of an element. It must be a CodeableConcept: an element still holding a
// Reference casts to null, and the assertions on it then fail.
define function "Request Medication"(key String):
  "Request Element"(key).medication as FHIR.CodeableConcept

define function "Dispense Medication"(key String):
  "Dispense Element"(key).medication as FHIR.CodeableConcept

define function "Administration Medication"(key String):
  "Administration Element"(key).medication as FHIR.CodeableConcept

/*
 * MedicationRequest
 */

// Invariant: one element for each retrieved request, with the same ids
define TestMedicationRequestOnePerRetrieved:
  Count(MedicationElements.MedicationRequest) = Count([USQualityCore.MedicationRequest])
    and (MedicationElements.MedicationRequest E return all E.id.value)
      includes ([USQualityCore.MedicationRequest] R return all R.id.value)

define TestMedicationRequestMedication:
  case "Case"
    // An inline code is kept
    when '01-Request-Medication-Forms' then
      "Request Medication"('mr-01-code') ~ "Lisinopril 10 MG Oral Tablet"
        and "Request Medication"('mr-01-code') ~ ("Request"('mr-01-code').medication as FHIR.CodeableConcept)
        // A reference is replaced by the referenced Medication's code
        and "Request Medication"('mr-01-ref') ~ "Amlodipine 5 MG Oral Tablet"
        and "Request Medication"('mr-01-ref') ~ "Medication"('med-01').code
        // A reference to a contained Medication is replaced by its code
        and "Request Medication"('mr-01-contained') ~ "Ibuprofen 200 MG Oral Tablet"
        // A reference to a Medication that isn't loaded gives no medication
        and "Request Element"('mr-01-missing') is not null
        and "Request Element"('mr-01-missing').medication is null
    when '04-Shared-Medications' then "Request Medication"('mr-04') ~ "Medication"('med-04-a').code
    else true
  end

define TestMedicationRequestCopiesElements:
  case "Case"
    when '01-Request-Medication-Forms' then
      "Request Element"('mr-01-code').status = 'active'
        and "Request Element"('mr-01-code').intent = 'order'
        and "Request Element"('mr-01-code').authoredOn = @2026-03-01T12:00:00.000Z
        and "Request Element"('mr-01-code').doNotPerform = false
        and "Request Element"('mr-01-code').subject.reference = "Patient Reference"
        and "Request Element"('mr-01-code').meta ~ "Request"('mr-01-code').meta
        and "Request Element"('mr-01-code').identifier ~ "Request"('mr-01-code').identifier
        and exists "Request"('mr-01-code').category
        and "Request Element"('mr-01-code').category ~ "Request"('mr-01-code').category
        and "Request"('mr-01-code').reported is not null
        and "Request Element"('mr-01-code').reported ~ "Request"('mr-01-code').reported
        and "Request"('mr-01-code').encounter is not null
        and "Request Element"('mr-01-code').encounter ~ "Request"('mr-01-code').encounter
        and "Request"('mr-01-code').requester is not null
        and "Request Element"('mr-01-code').requester ~ "Request"('mr-01-code').requester
        and exists "Request"('mr-01-code').reasonCode
        and "Request Element"('mr-01-code').reasonCode ~ "Request"('mr-01-code').reasonCode
        and exists "Request"('mr-01-code').dosageInstruction
        and "Request Element"('mr-01-code').dosageInstruction ~ "Request"('mr-01-code').dosageInstruction
        and "Request"('mr-01-code').dispenseRequest is not null
        and "Request Element"('mr-01-code').dispenseRequest ~ "Request"('mr-01-code').dispenseRequest
    else true
  end

// Invariant
define TestMedicationRequestSubject:
  AllTrue(MedicationElements.MedicationRequest E return E.subject.reference = "Patient Reference")

/*
 * MedicationDispense
 */

// Invariant: one element for each retrieved dispense, with the same ids
define TestMedicationDispenseOnePerRetrieved:
  Count(MedicationElements.MedicationDispense) = Count([USQualityCore.MedicationDispense])
    and (MedicationElements.MedicationDispense E return all E.id.value)
      includes ([USQualityCore.MedicationDispense] D return all D.id.value)

define TestMedicationDispenseMedication:
  case "Case"
    when '02-Dispense-Medication-Forms' then
      "Dispense Medication"('md-02-code') ~ "Lisinopril 10 MG Oral Tablet"
        and "Dispense Medication"('md-02-code') ~ ("Dispense"('md-02-code').medication as FHIR.CodeableConcept)
        and "Dispense Medication"('md-02-ref') ~ "Ibuprofen 200 MG Oral Tablet"
        and "Dispense Medication"('md-02-ref') ~ "Medication"('med-02').code
        and "Dispense Medication"('md-02-contained') ~ "Amlodipine 5 MG Oral Tablet"
        and "Dispense Element"('md-02-missing') is not null
        and "Dispense Element"('md-02-missing').medication is null
    when '04-Shared-Medications' then
      "Dispense Medication"('md-04') ~ "Medication"('med-04-a').code
        and "Dispense Medication"('md-04-other') ~ "Medication"('med-04-b').code
    else true
  end

define TestMedicationDispenseCopiesElements:
  case "Case"
    when '02-Dispense-Medication-Forms' then
      "Dispense Element"('md-02-code').status = 'completed'
        and "Dispense Element"('md-02-code').whenPrepared = @2026-03-02T10:00:00.000Z
        and "Dispense Element"('md-02-code').whenHandedOver = @2026-03-02T12:00:00.000Z
        and "Dispense Element"('md-02-code').subject.reference = "Patient Reference"
        and "Dispense Element"('md-02-code').meta ~ "Dispense"('md-02-code').meta
        and "Dispense Element"('md-02-code').identifier ~ "Dispense"('md-02-code').identifier
        and exists "Dispense"('md-02-code').performer
        and "Dispense Element"('md-02-code').performer ~ "Dispense"('md-02-code').performer
        and exists "Dispense"('md-02-code').authorizingPrescription
        and "Dispense Element"('md-02-code').authorizingPrescription ~ "Dispense"('md-02-code').authorizingPrescription
        and "Dispense"('md-02-code').type is not null
        and "Dispense Element"('md-02-code').type ~ "Dispense"('md-02-code').type
        and "Dispense Element"('md-02-code').quantity = 30 '{tbl}'
        and "Dispense Element"('md-02-code').daysSupply = 30 'd'
        and exists "Dispense"('md-02-code').dosageInstruction
        and "Dispense Element"('md-02-code').dosageInstruction ~ "Dispense"('md-02-code').dosageInstruction
    else true
  end

// Invariant
define TestMedicationDispenseSubject:
  AllTrue(MedicationElements.MedicationDispense E return E.subject.reference = "Patient Reference")

/*
 * MedicationAdministration
 */

// Invariant: one element for each retrieved administration, with the same ids
define TestMedicationAdministrationOnePerRetrieved:
  Count(MedicationElements.MedicationAdministration) = Count([USQualityCore.MedicationAdministration])
    and (MedicationElements.MedicationAdministration E return all E.id.value)
      includes ([USQualityCore.MedicationAdministration] A return all A.id.value)

define TestMedicationAdministrationMedication:
  case "Case"
    when '03-Administration-Medication-Forms' then
      "Administration Medication"('ma-03-code') ~ "Lisinopril 10 MG Oral Tablet"
        and "Administration Medication"('ma-03-code') ~ ("Administration"('ma-03-code').medication as FHIR.CodeableConcept)
        and "Administration Medication"('ma-03-ref') ~ "Amlodipine 5 MG Oral Tablet"
        and "Administration Medication"('ma-03-ref') ~ "Medication"('med-03').code
        and "Administration Medication"('ma-03-contained') ~ "Ibuprofen 200 MG Oral Tablet"
        and "Administration Element"('ma-03-missing') is not null
        and "Administration Element"('ma-03-missing').medication is null
    when '04-Shared-Medications' then "Administration Medication"('ma-04') ~ "Medication"('med-04-b').code
    else true
  end

define TestMedicationAdministrationCopiesElements:
  case "Case"
    when '03-Administration-Medication-Forms' then
      "Administration Element"('ma-03-code').status = 'completed'
        and "Administration Element"('ma-03-code').subject.reference = "Patient Reference"
        and "Administration Element"('ma-03-code').meta ~ "Administration"('ma-03-code').meta
        and "Administration Element"('ma-03-code').identifier ~ "Administration"('ma-03-code').identifier
        and "Administration"('ma-03-code').category is not null
        and "Administration Element"('ma-03-code').category ~ "Administration"('ma-03-code').category
        and "Administration"('ma-03-code').context is not null
        and "Administration Element"('ma-03-code').context ~ "Administration"('ma-03-code').context
        and "Administration"('ma-03-code').request is not null
        and "Administration Element"('ma-03-code').request ~ "Administration"('ma-03-code').request
        and "Administration"('ma-03-code').dosage is not null
        and "Administration Element"('ma-03-code').dosage ~ "Administration"('ma-03-code').dosage
        // An effective dateTime (`~` is ambiguous on the effective choice, so compare with the values)
        and ("Administration Element"('ma-03-code').effective as FHIR.dateTime) = @2026-03-03T12:00:00.000Z
        // A not-done administration, with a status reason and an effective period
        and "Administration Element"('ma-03-ref').status = 'not-done'
        and exists "Administration"('ma-03-ref').statusReason
        and "Administration Element"('ma-03-ref').statusReason ~ "Administration"('ma-03-ref').statusReason
        and ("Administration Element"('ma-03-ref').effective as FHIR.Period)
          = Interval[@2026-03-03T12:00:00.000Z, @2026-03-03T12:30:00.000Z]
    else true
  end

// Invariant
define TestMedicationAdministrationSubject:
  AllTrue(MedicationElements.MedicationAdministration E return E.subject.reference = "Patient Reference")

/*
 * Downstream use: one predicate on the normalized medication selects every resource for a drug,
 * whether the source identified it inline, by reference, or by a contained Medication
 */

define "Amlodipine Requests":
  MedicationElements.MedicationRequest E
    where E.medication ~ "Amlodipine 5 MG Oral Tablet"
    return all "MedicationRequestKey"(E)

define "Amlodipine Dispenses":
  MedicationElements.MedicationDispense E
    where E.medication ~ "Amlodipine 5 MG Oral Tablet"
    return all "MedicationDispenseKey"(E)

define "Amlodipine Administrations":
  MedicationElements.MedicationAdministration E
    where E.medication ~ "Amlodipine 5 MG Oral Tablet"
    return all "MedicationAdministrationKey"(E)

define TestMedicationSelectionIndependentOfForm:
  case "Case"
    // Inline, by reference, and contained; not the inline lisinopril or the referenced ibuprofen
    when '04-Shared-Medications' then
      "SameKeys"("Amlodipine Requests", { 'mr-04', 'mr-04-inline', 'mr-04-contained' })
        and "SameKeys"("Amlodipine Dispenses", { 'md-04', 'md-04-inline' })
        and "SameKeys"("Amlodipine Administrations", { 'ma-04-inline', 'ma-04-contained' })
    when '01-Request-Medication-Forms' then "SameKeys"("Amlodipine Requests", { 'mr-01-ref' })
    when '05-No-Medications' then not exists "Amlodipine Requests"
    else true
  end

/*
 * No medication resources
 */

define TestNoMedications:
  case "Case"
    when '05-No-Medications' then
      not exists MedicationElements.MedicationRequest
        and not exists MedicationElements.MedicationDispense
        and not exists MedicationElements.MedicationAdministration
    else true
  end

define _Passed:
  TestMedicationRequestOnePerRetrieved
    and TestMedicationRequestMedication
    and TestMedicationRequestCopiesElements
    and TestMedicationRequestSubject
    and TestMedicationDispenseOnePerRetrieved
    and TestMedicationDispenseMedication
    and TestMedicationDispenseCopiesElements
    and TestMedicationDispenseSubject
    and TestMedicationAdministrationOnePerRetrieved
    and TestMedicationAdministrationMedication
    and TestMedicationAdministrationCopiesElements
    and TestMedicationAdministrationSubject
    and TestMedicationSelectionIndependentOfForm
    and TestNoMedications

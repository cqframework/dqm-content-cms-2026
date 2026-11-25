/*
@description: Medication data elements for use with clinical quality measures, with the medication
normalized to a code
@comment: In FHIR, the medication of a MedicationRequest, MedicationDispense, or MedicationAdministration
is either a CodeableConcept (`medicationCodeableConcept`) or a reference to a Medication resource
(`medicationReference`), which may be a separate resource or one contained in the referencing
resource. Each definition in this library returns the retrieved resources with the medication always
given as a CodeableConcept: the inline code if there is one, otherwise the `code` of the referenced
Medication. Logic that uses these definitions can then test the medication the same way whichever form
the source data used, e.g.

  MedicationElements.MedicationRequest R
    where R.medication in "Some Medications"

Each definition returns one resource for every resource retrieved, with the same id and identifier, so
results can be related back to the source data. The definitions don't filter: callers apply status,
intent, category, and timing criteria. Only the elements listed for each definition are copied; any
other element (including extensions and contained resources) is not present in the result.

A reference that can't be resolved (the Medication is not in the data) gives a null medication.

NOTE: This library is developed in the dqm-content-cms-2026 repository:
https://github.com/cqframework/dqm-content-cms-2026/blob/main/input/cql/MedicationElements.cql
*/
library MedicationElements version '0.2.000'

using USQualityCore version '0.5.0'
using USCore version '6.1.0-derived'
using FHIR version '4.0.1'

include hl7.fhir.uv.cql.FHIRHelpers version '4.0.1'
include hl7.fhir.uv.cql.FHIRCommon version '2.0.0'

context Patient

/*
@description: Returns the patient's medication requests, with the medication given as a CodeableConcept
@comment: The medication is the request's `medicationCodeableConcept` if it has one, otherwise the `code`
of the Medication its `medicationReference` refers to (a Medication resource, or one contained in the
request), or null if that Medication is not in the data.

Copies id, meta, identifier, status, intent, category, doNotPerform, reported, subject, encounter,
authoredOn, requester, reasonCode, reasonReference, dosageInstruction, and dispenseRequest. Other
elements, e.g. statusReason, priority, performer, recorder, basedOn, courseOfTherapyType,
substitution, and note, are not copied.
*/
// NOTE: Contained resource references should be handled in FHIRCommon upstream: https://jira.hl7.org/browse/FHIR-59965
// TODO: Add support for including the contained resource as an includedMedication, similar to hospitalization encounters
define MedicationRequest:
  [USQualityCore.MedicationRequest] MR
    let M: 
      singleton from (
        case 
          when MR.medication.reference.startsWith('#') 
            then MR.contained C where '#' + C.id = MR.medication.reference return C as USQualityCore.Medication
          else [USQualityCore.Medication] M where MR.medication.references(M)
        end
      )
    return USQualityCore.MedicationRequest {
      id: MR.id,
      meta: MR.meta,
      identifier: MR.identifier,
      status: MR.status,
      intent: MR.intent,
      category: MR.category,
      doNotPerform: MR.doNotPerform,
      reported: MR.reported,
      medication: Coalesce(MR.medication as FHIR.CodeableConcept, M.code),
      subject: MR.subject,
      encounter: MR.encounter,
      authoredOn: MR.authoredOn,
      requester: MR.requester,
      reasonCode: MR.reasonCode,
      reasonReference: MR.reasonReference,
      dosageInstruction: MR.dosageInstruction,
      dispenseRequest: MR.dispenseRequest
    }

/*
@description: Returns the patient's medication dispenses, with the medication given as a CodeableConcept
@comment: The medication is the dispense's `medicationCodeableConcept` if it has one, otherwise the `code`
of the Medication its `medicationReference` refers to (a Medication resource, or one contained in the
dispense), or null if that Medication is not in the data.

Copies id, meta, identifier, status, subject, performer, authorizingPrescription, type, quantity,
daysSupply, whenPrepared, whenHandedOver, and dosageInstruction. Other elements, e.g. statusReason,
category, context, location, receiver, substitution, and note, are not copied.
*/
// NOTE: Contained resource references should be handled in FHIRCommon upstream: https://jira.hl7.org/browse/FHIR-59965
// TODO: Add support for including the contained resource as an includedMedication, similar to hospitalization encounters
define MedicationDispense:
  [USQualityCore.MedicationDispense] MR
    let M: 
      singleton from (
        case 
          when MR.medication.reference.startsWith('#') 
            then MR.contained C where '#' + C.id = MR.medication.reference return C as USQualityCore.Medication
          else [USQualityCore.Medication] M where MR.medication.references(M)
        end
      )
    return USQualityCore.MedicationDispense {
      id: MR.id,
      meta: MR.meta,
      identifier: MR.identifier,
      status: MR.status,
      medication: Coalesce(MR.medication as FHIR.CodeableConcept, M.code),
      subject: MR.subject,
      performer: MR.performer,
      authorizingPrescription: MR.authorizingPrescription,
      type: MR.type,
      quantity: MR.quantity,
      daysSupply: MR.daysSupply,
      whenPrepared: MR.whenPrepared,
      whenHandedOver: MR.whenHandedOver,
      dosageInstruction: MR.dosageInstruction
    }

/*
@description: Returns the patient's medication administrations, with the medication given as a
CodeableConcept
@comment: The medication is the administration's `medicationCodeableConcept` if it has one, otherwise the
`code` of the Medication its `medicationReference` refers to (a Medication resource, or one contained in
the administration), or null if that Medication is not in the data.

Copies id, meta, identifier, status, statusReason, category, subject, context, effective, request, and
dosage. Other elements, e.g. performer, reasonCode, reasonReference, partOf, device, and note, are not
copied.
*/
// NOTE: Contained resource references should be handled in FHIRCommon upstream: https://jira.hl7.org/browse/FHIR-59965
// TODO: Add support for including the contained resource as an includedMedication, similar to hospitalization encounters
define MedicationAdministration:
  [USQualityCore.MedicationAdministration] MR
    let M: 
      singleton from (
        case 
          when MR.medication.reference.startsWith('#') 
            then MR.contained C where '#' + C.id = MR.medication.reference return C as USQualityCore.Medication
          else [USQualityCore.Medication] M where MR.medication.references(M)
        end
      )
    return USQualityCore.MedicationAdministration {
      id: MR.id,
      identifier: MR.identifier,
      meta: MR.meta,
      status: MR.status,
      statusReason: MR.statusReason,
      category: MR.category,
      medication: Coalesce(MR.medication as FHIR.CodeableConcept, M.code),
      subject: MR.subject,
      context: MR.context,
      effective: MR.effective,
      request: MR.request,
      dosage: MR.dosage
    }

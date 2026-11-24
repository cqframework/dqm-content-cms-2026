# MedicationCommonTests test cases

Test data for the `MedicationCommonTests` CQL library, evaluated by the CQL VS Code extension
(`CQL: Execute`). Each subfolder is one patient context (**`Patient.id` must equal the folder
name**); results are written to
[../results/MedicationCommonTests.txt](../results/MedicationCommonTests.txt).

MADiE expects patient ids to be GUIDs, so each case is identified by its **label**, kept in the
Patient's given name. Every resource, the Patient included, has a readable **key** in an identifier
with the system `http://example.org/fhir/identifiers` (the label for the Patient, the resource's id
otherwise), because MADiE replaces ids that aren't GUIDs on import. The tests find resources, and
compare the results of the list functions, by key. Each case also has a test case `MeasureReport`
with its description and the Cohort group (`Group_1` / `InitialPopulation_1`, count 1).

The resources are retrieved as US Quality Core profiles (`meta.profile` set accordingly), so every
test runs the FHIR-typed MedicationCommon functions on profiled data. All medications are inline
RxNorm `243670` (aspirin 81 MG Oral Tablet).

To check a run:

```
python .claude/skills/cql/check_results.py MedicationCommonTests
```

[MedicationCommonTests.zip](MedicationCommonTests.zip) packages these cases for import into MADiE.
Rebuild it after changing the data:

```
python scripts/make_test_case_zip.py input/tests/MedicationCommonTests
```

## Conformance

MADiE rejects invalid resources, so every resource must conform to its profile, including elements
the tests don't read: e.g. the `us-quality-core-recorded` extension the MedicationAdministrationNotDone
and MedicationDispenseDeclined profiles require, and the negation reason on all three negation
resources. A missing status or intent (both required) is therefore not tested.

## Cases

| # | Case | Folder (patient id) | Data | Point being tested |
|---|------|---------------------|------|--------------------|
| 01 | Request-Status | `9294f0b2-0626-41fd-84b3-39f59ac85304` | `mr-01-<status>` for each MedicationRequest status (intent order) | MedicationRequest status predicates and list functions; each predicate holds for exactly one status |
| 02 | Request-Intent | `8adc9a27-2c9c-47ae-8999-ffab80a7d591` | `mr-02-<intent>` for each intent (status active) | Intent predicates; `isOrderIntent` / `orderIntent` cover the five order intents only |
| 03 | Request-Category | `1f1ce5cf-3110-454e-973c-6dd0bf9e8e47` | `mr-03-inpatient`, `-outpatient`, `-community`, `-discharge`, `-community-discharge` (two categories), `-discharge-among-codings` (example code + discharge in one concept), `-uncategorized`; near-misses `-wrong-system` (`community` in `http://example.org/codes`), `-administration-category` (`community` from the admin category system) | `hasCategory` and the category predicates and list functions |
| 04 | Request-Most-Recent | `cba06702-46a6-4cc0-9d03-2bda23229a96` | `mr-04-march-1`, `mr-04-march-5` (12:00Z), `mr-04-march-5-later` (13:00Z), `mr-04-not-authored` | `mostRecent`: time of day counts, input order doesn't, a request with no authoredOn is only chosen alone |
| 05 | Administration-Status | `40cdcb61-ef2f-4a7c-91c5-633ec79c2fea` | `ma-05-<status>` for each MedicationAdministration status | Administration status predicates and `completed` |
| 06 | Administration-Category | `13f360fc-0f4e-4aeb-b4a2-f203114d0ca3` | `ma-06-inpatient`, `-outpatient`, `-community`, `-community-among-codings`, `-uncategorized`; near-misses `-wrong-system`, `-request-category` (`inpatient` from the request category system) | Administration `hasCategory` and the category predicates and list functions |
| 07 | Dispense-Status | `b06e66e8-f1c4-4a5d-8f16-a954f808908c` | `md-07-<status>` for each MedicationDispense status | Dispense status predicates, `completed`, and the positive-event composition |
| 08 | Negation-Profiles | `f710f472-4961-4c25-9e14-e706af5e2fe9` | `mr-08-not-requested` (MedicationNotRequested, completed), `ma-08-not-done` (MedicationAdministrationNotDone), `md-08-declined` (MedicationDispenseDeclined) | The functions resolve and run for the negation profile types |
| 09 | No-Medications | `f03b022c-d1ac-4916-af3e-cda72e39dc02` | None | The list functions return empty lists and `mostRecent` null on empty retrieves |

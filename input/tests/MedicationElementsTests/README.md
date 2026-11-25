# MedicationElementsTests test cases

Test data for the `MedicationElementsTests` CQL library, evaluated by the CQL VS Code extension
(`CQL: Execute`). Each subfolder is one patient context (**`Patient.id` must equal the folder
name**); results are written to
[../results/MedicationElementsTests.txt](../results/MedicationElementsTests.txt).

MADiE expects patient ids to be GUIDs, so each case is identified by its **label**, kept in the
Patient's given name. Every resource, the Patient included, has a readable **key** in an identifier
with the system `http://example.org/fhir/identifiers` (the label for the Patient, the resource's id
otherwise), because MADiE replaces ids that aren't GUIDs on import. MedicationElements copies
`identifier`, so the tests find each element by the key of the resource it was built from.
Each case also has a test case `MeasureReport` with its description and the Cohort group
(`Group_1` / `InitialPopulation_1`, count 1).

To check a run:

```
python .claude/skills/cql/check_results.py MedicationElementsTests
```

[MedicationElementsTests.zip](MedicationElementsTests.zip) packages these cases for import into MADiE.
Rebuild it after changing the data:

```
python scripts/make_test_case_zip.py input/tests/MedicationElementsTests
```

## Coding

Medications are RxNorm codes: `197361` amlodipine 5 MG Oral Tablet, `314076` lisinopril 10 MG Oral
Tablet, `310965` ibuprofen 200 MG Oral Tablet. References to resources that aren't in the case
(`Encounter/enc-01`, `Practitioner/prac-01`, `MedicationRequest/mr-elsewhere`, `Medication/med-missing`)
are deliberate; the zip script's warnings about them are expected.

## Cases

| # | Case | Folder (patient id) | Data | Point being tested |
|---|------|---------------------|------|--------------------|
| 01 | Request-Medication-Forms | `cefac7d4-207f-4bc4-9d90-07eb4adbb2b1` | `med-01` (197361); `mr-01-code` (inline 314076, every copied element populated), `mr-01-ref` (→ `med-01`), `mr-01-contained` (→ contained 310965), `mr-01-missing` (→ a Medication not in the case) | MedicationRequest: the four medication forms; copied elements |
| 02 | Dispense-Medication-Forms | `29c6dee9-b918-4f79-8146-8bcd971559e7` | `med-02` (310965); `md-02-code`, `md-02-ref`, `md-02-contained` (→ contained 197361), `md-02-missing` | MedicationDispense: the same |
| 03 | Administration-Medication-Forms | `586c4166-8b7b-4063-8f29-cbe7259b762a` | `med-03` (197361); `ma-03-code` (effective dateTime), `ma-03-ref` (not done, status reason, effective period), `ma-03-contained` (→ contained 310965), `ma-03-missing` | MedicationAdministration: the same, both effective types |
| 04 | Shared-Medications | `52a9747a-63de-4745-a59f-6ddf0a904345` | `med-04-a` (amlodipine 197361), `med-04-b` (ibuprofen 310965). Amlodipine: `mr-04`, `md-04` → `med-04-a`; `mr-04-inline`, `md-04-inline`, `ma-04-inline` inline; `mr-04-contained`, `ma-04-contained` contained. Near-misses: `mr-04-other` (inline lisinopril), `md-04-other`, `ma-04` → `med-04-b` | Each resource resolves its own Medication when several are loaded; one amlodipine predicate selects every amlodipine resource, whatever the form, and no others |
| 05 | No-Medications | `e79e6f21-5465-4608-9154-cc46f4db51df` | None | Everything empty |

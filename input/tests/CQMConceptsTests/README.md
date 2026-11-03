# CQMConceptsTests test cases

Patient data for [CQMConceptsTests](../../cql/CQMConceptsTests.cql). Most of CQMConceptsTests builds its
fixtures inline and needs no data; these cases are for the tests of the `TESTING SUPPORT:` retrieves in
CQMConcepts, which retrieve encounters by each CQMConcepts encounter value set. Run the library with the
CQL extension's **Execute CQL** command; results are written to
[../results/CQMConceptsTests.txt](../results/CQMConceptsTests.txt).

MADiE expects patient ids to be GUIDs, so the patient ids (and folder names) are GUIDs, and each case
is identified by its **label**, kept in the Patient's given name (e.g. `01-Value-Set-Encounters`).
The library's `Case` define reads the label from there. Each case also has a test case `MeasureReport`
(`isTestCase`), whose `cqfm-testCaseDescription` extension holds the case's description, and whose
group (`Group_1` / `InitialPopulation_1`, count 1) is the expected result in MADiE.

MADiE also replaces resource ids that aren't GUIDs with new GUIDs on import, so the tests don't rely
on resource ids. Every resource has a readable **key** in an identifier with the system
`http://example.org/fhir/identifiers`: the label for the Patient, and the resource's id (e.g. `ed-01`)
otherwise. The tests find resources by that key.

To add a case, run `python .claude/skills/cql/new_test_case.py CQMConceptsTests <label> "<description>"`
from the repo root, add its resources with `subject` references to `Patient/<guid>` and a key identifier
each, and rebuild the zip with `python scripts/make_test_case_zip.py input/tests/CQMConceptsTests`.

## Cases

| # | Case | Folder (patient id) | Data | Point being tested |
|---|---|---|---|---|
| 01 | `01-Value-Set-Encounters` | `8a611c20-2ff6-4c60-9a61-98420dafe057` | Finished encounters `ed-01` (SNOMED `4525004`), `inp-01` (`32485007`), `icu-01` (HSLOC `1027-2`), `obs-01` (`448951000124107`), `surg-01` (`110468005`), and `checkup-01` (`185349003`, Encounter for check up) | Each `TESTING SUPPORT:` retrieve returns exactly the encounter typed with its value set's member code; `checkup-01` is in none of the value sets and returned by none of the retrieves |
| 02 | `02-No-Encounters` | `fc1cccc7-2133-4ab6-a58a-0df6ce5d4fd6` | A patient only | Every retrieve is empty |

The member codes are the ones the inline value set tests use (`TestEmergencyDepartmentVisitValueSet`,
...), confirmed against the expansions in `input/vocabulary/valueset/external/`.

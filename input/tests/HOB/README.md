# HOB test cases

Test data for the `HOB` measure library, evaluated by the CQL VS Code extension (`CQL: Execute`).
Each subfolder is one patient context (**`Patient.id` must equal the folder name**); results are
written to [../results/HOB.txt](../results/HOB.txt).

MADiE expects patient ids to be GUIDs, so the patient ids (and folder names) are GUIDs, and each case
is identified by its **label**, kept in the Patient's given name (e.g. `04-ED-OBS-O-COB`). MADiE also
replaces resource ids that aren't GUIDs on import, so every resource, the Patient included, has a
readable **key** in an identifier with the system `http://example.org/fhir/identifiers`: the label for
the Patient, and the resource's id (e.g. `ip-05`) otherwise. Locally the ids are unchanged, so the
results show them (`Encounter(id=ip-05)`). A hospital stay has the id of its last encounter.

Each case has a test case `MeasureReport` (`isTestCase`) with the case's description (in
`cqfm-testCaseDescription`) and its **expected populations**: one group per HOB metric, in the
measure's group order, each with the expected initial population, denominator, and numerator counts
(the number of hospital stays, since the measure is episode-based). The group and population ids are
the ones MADiE gives a measure's groups (`Group_1`, `InitialPopulation_1`, `Denominator_1`,
`Numerator_1`, ..., `Group_4`, `Numerator_4`).

| Group | Metric | Populations (defines) |
|-------|--------|-----------------------|
| 1 | O-COB Prevalence Rate | `O-COB Prevalence Rate Initial Population` / `Denominator` / `O-COB Prevlanece Rate Numerator` |
| 2 | COB Prevalence Rate | `COB Prevalence Rate Initial Population` / `Denominator` / `Numerator` |
| 3 | HOB Crude Risk | `HOB Crude Risk Initial Population` / `Denominator` / `Numerator` |
| 4 | HOB Incidence Density | `HOB Incidence Density Initial Population` / `Denominator` / `Numerator` |

[populations.json](populations.json) maps each group's population codes to these defines. To check a
run against the expected counts:

```
python .claude/skills/cql/check_measure_results.py HOB input/tests/HOB/populations.json
```

[HOB.zip](HOB.zip) packages these cases for import into MADiE. Rebuild it after changing the data:

```
python scripts/make_test_case_zip.py input/tests/HOB
```

To add a case, run `python .claude/skills/cql/new_test_case.py HOB <label> "<description>"` from the
repo root, which creates the folder, Patient and MeasureReport. Replace the MeasureReport's `group`
with the four groups and the case's expected counts, then add the case's resources with `subject`
references to `Patient/<guid>` and a key identifier each.

## Conventions

- **Measurement period:** HOB's default, January 2026. Everything meant to be in the measurement
  period is in January 2026, and everything meant to be outside it is in 2025, so the expected
  populations are the same with a calendar 2026 measurement period (the MeasureReport period). The
  end of the measurement period is therefore not tested.
- **Times** are UTC, between 12:00Z and 20:00Z. Hospital days start at midnight in the evaluation's
  timezone, and these times fall on the same date in UTC and in any US timezone.
- **Hospital day 1** is the date the hospital stay starts, including any ED or observation visit
  within an hour before the admission.
- **Blood cultures** (`bc-*`) are `Observation`s (US Quality Core lab profile, `status` final,
  category laboratory, LOINC `600-7`, organism in `valueCodeableConcept`). Each references a blood
  `Specimen` (`sp-*`, `status` available, SNOMED `119297000`) with the same collection time, unless
  noted otherwise.
- **The standard stay** (cases 12–17 and 19–21): inpatient `2026-01-05 14:00 → 2026-01-16 15:00`, so
  day 1 = 01-05, day 3 = 01-07, and day 4 = 01-08.

| Kind | `Encounter.type` (SNOMED) | `Encounter.class` |
|------|---------------------------|-------------------|
| ED (`ed-*`) | `4525004` | `EMER` |
| Observation (`obs-*`) | `448951000124107` | `OBSENC` |
| Inpatient (`ip-*`) | `32485007` | `IMP` |

| Organism | SNOMED | Notes |
|----------|--------|-------|
| A | `113714003` Abiotrophia defectiva | |
| B | `396950003` Acetobacter aceti | A different genus from A |
| L1, L2 | `266186009`, `154315008` Legionella | Same genus, no species |
| C | `103494005` Staphylococcus lugdunensis | Skin commensal (not in the HOB-specific value set either) |

## Cases

Expected populations are initial population / denominator / numerator, per group; `–` is 0/0/0.
Group 4 (HOB Incidence Density) has the same counts as group 3 in every case. The last column is the
expected HOB Incidence Density denominator observation (eligible days, from the start of day 4 to
discharge or the HOB index date), for reference; it isn't in the MeasureReports.

| # | Case | Folder (patient id) | Data | O-COB | COB | HOB | Days | Point being tested |
|---|------|---------------------|------|:-----:|:---:|:---:|:----:|--------------------|
| 01 | ED-Only | `e69774f5-3cec-43d4-8a1f-06724d9836fa` | ED 01-10 12:00→18:00 | 1/1/0 | – | – | | ED with no admission is an outpatient stay |
| 02 | ED-Outside-MP | `f47dd828-63b0-499a-8e4b-571c60ea34d6` | ED 2025-12-15 | – | – | – | | Outpatient stay outside the MP |
| 03 | OBS-Only | `5ad284c0-90fa-4953-9650-4fc4324c7e0f` | OBS 01-12 12:00→01-13 18:00 | 1/1/0 | – | – | | Observation with no admission is an outpatient stay |
| 04 | ED-OBS-O-COB | `a78d7577-d2cf-4741-9464-e5480af48f8a` | ED 01-14 12:00→16:00, OBS 16:30→01-15 14:00; culture A 01-15 12:00 | 1/1/1 | – | – | | One outpatient stay (`obs-04`); O-COB event |
| 05 | OBS-Inpatient | `89bd67c0-37dd-48a7-a222-4cc86ad358fa` | OBS 01-06 12:00→20:00, IP 20:30→01-11 15:00 | – | 1/1/0 | 1/1/0 | 2 | OBS leading to admission is part of the inpatient stay |
| 06 | ED-Inpatient-Culture-In-ED | `e24d9924-bf2a-4348-8024-25c890e95568` | ED 01-04 12:00→15:00, IP 15:30→01-12 15:00; culture A 01-04 13:00 | – | 1/1/1 | 1/1/0 | 5 | Culture in an ED visit leading to admission is COB (day 1), not O-COB |
| 07 | ED-Inpatient-Gap-Over-Hour | `19c0c6e3-766f-4f72-8519-9b6a3c55db5d` | ED 01-06 12:00→14:00, IP 16:00→01-11 16:00; culture A 01-06 13:00 | 1/1/1 | 1/1/0 | 1/1/0 | 2 | Two stays; the ED culture is O-COB, not COB |
| 08 | Discharged-Day-3 | `64eab3ff-d208-4eab-a28d-528e2b68907c` | IP 01-15 12:00→01-17 20:00; culture B 01-16 13:00 | – | 1/1/1 | – | | COB event; never reaches day 4, so not in the HOB populations |
| 09 | Discharged-Day-4 | `97322a7c-8ef2-49d1-a863-bf96626f1996` | IP 01-10 12:00→01-13 20:00; culture A 01-13 14:00 | – | 1/1/0 | 1/1/1 | 0 | Reaches day 4 in under four 24-hour days: HOB event |
| 10 | Culture-After-Discharge | `d29ac01e-09dc-4b39-9404-6ac61ec66e0e` | IP 01-05 12:00→01-20 12:00; culture A 01-25 | – | 1/1/0 | 1/1/0 | 12 | A culture outside the stay is no event |
| 11 | COB-Window-Before-MP | `608a829f-3237-476e-affa-bc8a85f83e9d` | IP 2025-12-28 12:00→01-10 12:00 | – | – | 1/1/0 | 10 | Days 1–3 before the MP, day 4 on in it |
| 12 | HOB-Day-6 | `0bb111d7-a019-44ff-b000-9b8a1ead100f` | Standard stay; culture A day 6 | – | 1/1/0 | 1/1/1 | 2 | HOB event |
| 13 | COB-Day-2 | `98a2bca8-4fa8-41a8-bb93-98c872e4c155` | Standard stay; culture B day 2 | – | 1/1/1 | 1/1/0 | 8 | COB event |
| 14 | Day-3-COB-Day-4-HOB | `56050d88-794a-4c23-8564-bab422172805` | Standard stay; culture A day 3, B day 4 | – | 1/1/1 | 1/1/1 | 0 | The day 3 / day 4 boundary |
| 15 | HOB-Excluded-Matching-COB | `eec30a27-3635-4cd9-abab-62f2fe47ef46` | Standard stay; culture A day 2 and day 6 | – | 1/1/1 | 1/1/0 | 8 | Same organism as the COB event: no HOB event |
| 16 | HOB-Non-Matching-COB | `42932e7a-46e8-4134-8852-327a2fe42216` | Standard stay; culture A day 2, B day 6 | – | 1/1/1 | 1/1/1 | 2 | Different organism: COB and HOB events |
| 17 | HOB-Excluded-Genus-Match | `f2b6ce03-5652-4bb9-a50b-762c201549c1` | Standard stay; culture L1 day 2, L2 day 6 | – | 1/1/1 | 1/1/0 | 8 | Genus match (no species): no HOB event |
| 18 | Day-Count-From-ED-Arrival | `6a2768ee-b9d5-4a84-9a28-0aafc39a1703` | ED 01-04 18:00→01-05 13:00, IP 13:30→01-12 15:00; culture A 01-07 14:00 | – | 1/1/0 | 1/1/1 | 0 | Day 1 is the ED arrival date, so the culture is day 4: HOB, not COB |
| 19 | Excluded-Results | `c3c71a9a-f6dd-4efd-adf8-0417ad5ba727` | Standard stay; day 6: culture C, a preliminary culture A, a urine culture A (LOINC `630-4`, no specimen); an unavailable specimen | – | 1/1/0 | 1/1/0 | 8 | Not bacteremia or fungemia results: no events |
| 20 | Specimen-Collection-Time | `fca52ba3-d56d-4e38-a9fc-2cab1a726b9d` | Standard stay; culture A collected day 3, resulted day 5 | – | 1/1/1 | 1/1/0 | 8 | Collection time is used: COB, not HOB |
| 21 | No-Specimen | `745c7428-d787-493c-8652-5af34a811f97` | Standard stay; culture A day 2, no specimen | – | 1/1/1 | 1/1/0 | 8 | With no specimen, the result time is used |
| 22 | Prior-HOB-Before-MP | `e0dcc8d7-cc79-4a51-b516-6630ff02574d` | IP 2025-12-20 12:00→01-15 12:00; culture A 2025-12-27 | – | – | – | | HOB event before the MP: the stay is not in the HOB populations |
| 23 | No-Encounters | `d11a20b3-f05f-4cd3-abd2-e10c8eccaafc` | None | – | – | – | | Everything empty |

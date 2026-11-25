---
name: cql
description: How CQL is validated, run and tested in the dqm-content-cms-2026 repository - running test libraries with cql-mcp and checking them, checking measures, its test-case scripts and MADiE zips, and its test-library conventions. Use alongside the cqf-skills plugins whenever writing, editing or validating .cql files in input/cql, writing <Library>Tests libraries or their patient test cases in input/tests, testing a measure such as HOB, or building MADiE test case zips here.
---

# CQL in this repository

This skill covers only what is specific to this repository. The general guidance is in the
cqf-skills plugins enabled in `.claude/settings.json`:

| Topic | Skill |
| --- | --- |
| The language, its pitfalls, and the test-library method (`resources/testing.md`) | `cql` (plugin) |
| FHIRHelpers, FHIRCommon (including `references()` and contained resources) | `cql-ig` |
| CMS measure patterns, CQMCommon / CQMConcepts / CQMElements / ClaimCommon, known issues | `cms-qmd` |
| US Quality Core profiles and model info | `usqualitycore` |
| The VS Code CQL extension, `input/tests/config.jsonc`, Execute CQL | `vscode-cql` |
| MADiE test cases, zips, import rules, its engine's differences, missing code systems | `madie` |

Read those first. When something learned here is true in general, contribute it to
cqframework/cqf-skills rather than adding it below.

## Validating and running

Use the `cql-mcp` tools (enabled in `.claude/settings.json`; see the `cql-mcp` skill). They run the
same language server as the VS Code CQL extension 1.0.0 (translator and engine 5.5.0).

- **Validate** every library you change, and the libraries that include a changed shared library
  (such as its `*Tests.cql`): `cql_validate` with `cqlFile`. Pass `timeoutMs: 30000` on the first
  call of a session, while the language server starts. Don't report a CQL change as done until it
  is clean.
- **Run a test library:** `cql_test_run_suite` with `cqlFile` (`input/cql/<Library>Tests.cql`),
  `suiteRoot` (`input/tests`) and `suiteName` (`<Library>Tests`); a run takes a couple of minutes.
  Its per-case `status` only says whether the run errored, so then check the results with
  `python .claude/skills/cql/check_results.py --mcp <Library>Tests`, which runs the `cql` skill's
  `check_test_library.py` with this repo's paths. It reports a run error, every `Test…` that isn't
  `true` on a case, a `_Passed` that doesn't list each test exactly once, and case labels in `when`
  clauses that don't exist. A test commented out of `_Passed` (`// and TestX`, with the reason) is
  reported as a known failure.
- **Run and check a measure:** `cql_test_run_suite` the same way (`suiteName` `<Measure>`); with large
  measures, don't read the run's output, go straight to the checker:
  `python scripts/cqf_skill.py madie check_results input/tests/<Measure> .cql-debug/test-runs/latest-<Measure>.json --populations input/tests/<Measure>/populations.json`.
  It compares each case with its MeasureReport the way MADiE does, applying the population rules.
- Execute CQL results (`input/tests/results/<Library>.txt`, written when the user runs it) are
  checked the same way: `check_results.py` without `--mcp`, or the results file in place of the run.
  Read results with the checkers, never by eye.

Run history is kept in `.cql-debug/test-runs/` (git-ignored); `cql_test_diff` compares two runs. A
run-time error in a define stops that case's results (`Error=...`): find the expression, take it out
with a comment saying why, and run again.

Without cql-mcp, fall back to the editor's diagnostics (`mcp__claude-vscode__getDiagnostics`, a
deferred tool). They go stale after edits made outside the editor (from a shell, or a new file from
Write): only trust a result whose `linesInFile` matches the file, and make a real Edit to force
re-analysis.

## Test cases

Test libraries (`<Library>Tests.cql`, `define Test…` plus `_Passed`, run in MADiE as a Cohort
measure) are only for **shared** libraries. A **measure** (e.g. HOB) has no test library: its cases
go in `input/tests/<Measure>/`, and each MeasureReport holds the expected count for every group
(`Group_1`…`Group_N`, populations `InitialPopulation_<n>`, `Denominator_<n>`, `Numerator_<n>`),
with `populations.json` mapping them to the defines in the `madie` skill's `--populations` format
(see `input/tests/HOB/`). Don't change measure logic to make it testable; report defects to the user.

- **Create a case** with `python .claude/skills/cql/new_test_case.py <Library>Tests <NN-Label> "<description>"`,
  which runs the `madie` skill's `new_test_case.py` with this repo's 2026 measurement period. It
  writes the Patient (GUID id = folder name, the label in `name.given` and as its key) and the test
  case MeasureReport in MADiE's export form (Cohort group, count 1), and prints the GUID. `--list`
  lists the cases. For a measure, add `--populations input/tests/<Measure>/populations.json`, which
  writes the measure's groups without counts, then fill in each expected count.
- **Add resources** as `<ResourceType>-<id>.json`, with `subject` / `patient` set to
  `Patient/<guid>`, `meta.profile` set to the US Quality Core profile the logic retrieves, and a key
  identifier with the system `http://example.org/fhir/identifiers` (usually the id, e.g. `mr-01-active`).
  Keys are unique across the library's cases. Reference only resources that are in the case: MADiE
  drops a resource whose reference doesn't resolve.
- **Labels** are `NN-Short-Description`, numbered in order, and never changed once tests use them.
- **In the test library:** `define "Case": FHIRHelpers.ToString(First(Patient.name.given))`, one key
  function per resource type (`"MedicationRequestKey"(FHIR.MedicationRequest)`; not overloads, and no
  `is` / `as`), and tests written as `case "Case" when '<label>' then … else true end`.
- **README:** each test folder has a README listing the cases (folder, label, data, point tested);
  keep its descriptions and the MeasureReports' the same.
- **Zip for MADiE:** `python scripts/make_test_case_zip.py input/tests/<Library>Tests` after any
  change. It runs the `madie` skill's `vscode_to_madie.py`, writes the zip next to the README, and
  checks it against MADiE's import rules. Its warnings about unresolved references are real (MADiE
  leaves those resources out). `python scripts/cqf_skill.py <skill> <script> …` runs any of the
  cqf-skills scripts directly.

Worked examples: MedicationCommonTests and MedicationElementsTests (resources from case data),
CQMElementsTests and ClaimElementsTests (keys, contained resources), CQMConceptsTests (inline
fixtures for element-level functions), and `input/tests/HOB/` (a measure).

## Repository specifics

- **FHIRBuilders** (`include FHIRBuilders version '0.1.000' called Build`) builds FHIR values for
  inline fixtures: `Build.id`, `Build.string`, `Build.uri`, `Build.code`, `Build.Period`,
  `Build.Quantity`, `Build.Coding`, `Build.CodeableConcept`, `Build.Identifier`, `Build.Reference`,
  and fluent `toFHIR…` forms (`'x'.toFHIRString()`). Use it rather than redefining builders, and
  name new fluent builders `toFHIR…` (a FHIRPath name such as `toString` would resolve to the system
  operator).
- **Value sets** for Execute CQL are in `input/vocabulary/valueset/external/`
  (`ValueSet-<oid>-<date>.json`, with expansions); confirm a code is a member there before using it
  in test data. The top-level `input/vocabulary/valueset` folder is published by the IG, so ask
  before adding ValueSets there.

---
name: cql
description: How CQL is checked, run and tested in the dqm-content-cms-2026 repository - its folders, its checker and test-case scripts, the run loop with the VS Code CQL extension, and its test-library conventions. Use alongside the cqf-skills plugins whenever writing, editing or validating .cql files in input/cql, writing <Library>Tests libraries or their patient test cases in input/tests, testing a measure such as HOB, or building MADiE test case zips here.
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

## Checking for errors

Prefer `cql_validate` (see [Running and checking](#running-and-checking)). The VS Code extension's
diagnostics give the same answer and are the fallback when cql-mcp isn't available. Both resolve the
model infos and dependencies from `~/.fhir/packages`. To use the editor's diagnostics:

1. Load the deferred tool: `ToolSearch` with `select:mcp__claude-vscode__getDiagnostics`.
2. Call it with the file's `file:///` URI. Treat `Error` as blocking and read the `Warning`s.
3. Don't report a CQL change as done until every file you touched, and the libraries that include
   a changed shared library (such as its `*Tests.cql`), come back without errors.

The diagnostics can be wrong in both directions:
- After an edit from a shell (sed, Python, heredoc), or to a file just created with Write, the
  results are stale or missing: no `linesInFile`, ranges past the end of the file, or errors in code
  that is gone. Make a real Edit (change a word; whitespace-only edits are rejected) and query again.
  Only trust an empty list that comes with a `linesInFile` matching the file.
- A library that includes a changed library keeps its old errors until it is edited itself.
- They have missed a syntax error entirely: a new library with no diagnostics failed to load at run
  time ("Syntax error at H") because of an unparenthesized function call used as a query source.
  Check new files by eye against the `cql` skill's pitfalls.
- If the tool isn't available (not running in VS Code), ask the user what the Problems panel shows,
  naming each file.

## Running and checking

The `cql-mcp` plugin (enabled in `.claude/settings.json`) lets Claude validate and run CQL itself,
with the same language server (5.0.0, translator and engine 5.5.0) as the VS Code extension 1.0.0.
See the `cql-mcp` skill for its tools. In this repo:

- **Validate:** `cql_validate` with `cqlFile`. Pass `timeoutMs: 30000` on the first call of a
  session, while the language server starts. Check a deliberate mistake once if a clean result
  seems too quick. This is the same check as the editor's diagnostics, without the staleness.
- **Run a test library:** `cql_test_run_suite` with `cqlFile` (`input/cql/<Library>Tests.cql`),
  `suiteRoot` (`input/tests`) and `suiteName` (`<Library>Tests`). Its `status` per case only says
  whether the run errored, not whether the tests passed, so then run
  `py -3 .claude/skills/cql/check_results.py --mcp <Library>Tests`. A run takes a couple of minutes.
- Run history is kept in `.cql-debug/test-runs/` (git-ignored); `cql_test_diff` compares two runs.

The user can also run **Execute CQL**, which writes `input/tests/results/<Library>.txt`; check it
with the same script without `--mcp`. Read results with the checkers, from the repo root, never by eye:

- Test library: `check_results.py [--mcp] <Library>Tests`. It reports a run error (`Error=`), every
  `Test…` that isn't `true` on a case, a `_Passed` that doesn't list each test exactly once, and
  case labels in `when` clauses that don't exist. A test commented out of `_Passed`
  (`// and TestX`, with the reason) is reported as a known failure.
- Measure: `py -3 .claude/skills/cql/check_measure_results.py <Measure> input/tests/<Measure>/populations.json`,
  which compares each population define's count with the MeasureReport's expected counts in the
  Execute CQL results file.

A run-time error in a define stops that case's results (`Error=...`). Find the expression, take it
out with a comment saying why, and run again.

Use `py -3` for the scripts: the `python` on PATH here may be another program's bundled interpreter.

## Test cases

Test libraries (`<Library>Tests.cql`, `define Test…` plus `_Passed`, run in MADiE as a Cohort
measure) are only for **shared** libraries. A **measure** (e.g. HOB) has no test library: its cases
go in `input/tests/<Measure>/`, and each MeasureReport holds the expected count for every group
(`Group_1`…`Group_N`, populations `InitialPopulation_<n>`, `Denominator_<n>`, `Numerator_<n>`),
with `populations.json` mapping them to the defines. Don't change measure logic to make it testable;
report defects to the user.

- **Create a case** with `python .claude/skills/cql/new_test_case.py <Library>Tests <NN-Label> "<description>"`.
  It writes the Patient (GUID id = folder name, the label in `name.given` and as its key) and the
  test case MeasureReport (Cohort group, count 1), and prints the GUID. `--list` lists the cases. For
  a measure, replace the MeasureReport's group with the measure's groups.
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
  change. Then check it with the `madie` skill's `check_test_cases.py`; its warnings about
  unresolved references are real (MADiE leaves those resources out).

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
- **USQualityCore type names** are in the model info at
  `~/.fhir/packages/fhir.onc.us-quality-core#0.5.0/package/Library-USQualityCore-ModelInfo.json`
  (base64 content).
- `cql-options.json` changes aren't picked up until the language server restarts.

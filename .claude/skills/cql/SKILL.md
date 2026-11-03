---
name: cql
description: How to validate, run, and test CQL in this repo using the VS Code CQL extension. Use whenever writing, editing, reviewing, or validating .cql files (input/cql) or CQL snippets in narrative pages; when writing <Library>Tests libraries, their patient test cases (input/tests), or MADiE test case zips; and before claiming any CQL compiles.
---

# CQL validation and execution in FHIR Content IGs

CQL in this repo is validated by the VS Code CQL extension (`cqframework.cql`), which already resolves
the model infos (`USQualityCore 0.5.0`, `USCore 6.1.0-derived`, `FHIR 4.0.1`) and the library
dependencies in `~/.fhir/packages`. Always use it. **Never build or run a standalone CQL translator**
(from `~/.m2` jars, the extension's `cql-ls-server-*.jar`, or anything else); that path has failed
repeatedly on classpath and model info resolution.

## Checking for errors

1. Load the diagnostics tool. It is deferred, so fetch its schema first:
   `ToolSearch` with query `select:mcp__claude-vscode__getDiagnostics`.
2. Call `mcp__claude-vscode__getDiagnostics` with the file's URI, e.g.
   `file:///c:/Users/Bryn/Documents/Src/CQF/dqm-content-cms-2026/input/cql/CQMElements.cql`.
   Omit `uri` to get every file the editor currently has diagnostics for.
3. Treat `Error` severity as blocking. Read `Warning`s too; they often flag real mistakes.
4. Do not report a CQL change as done, or as compiling, until diagnostics for every file you touched
   come back with no errors.

Notes:
- Edits made with the **Edit** tool trigger re-analysis, and their diagnostics are often attached to
  the tool result automatically.
- After edits made from a shell (sed, Python, heredocs) the diagnostics can be **stale**: the giveaway
  is ranges on lines past `linesInFile`, or errors in code that no longer exists. Make any small edit
  with the Edit tool to force re-analysis, then query again.
- Diagnostics can also lag an Edit: the first query after a fix may still report the old error. If an
  error points at code you have just changed, query again before changing anything else.
- Errors cascade. A type error in a fixture builder shows up as "Internal error: could not determine
  result type" on every expression that calls it. Fix the first real error and query again before
  working on the rest.
- The extension does **not** flag a function defined twice with the same signature (CQMConcepts had
  duplicate `toDateInterval` and `lengthInDays` definitions that compiled cleanly). Look for duplicates
  yourself when reviewing a library.
- A file you have just created with Write is often not analysed yet: the result has no `linesInFile`
  and an empty `diagnostics` list. That is not a clean result. Make a real (non-identical) Edit to the
  file and query again; only trust an empty list that comes with a `linesInFile` matching the file.
  The Edit tool rejects a change that only adds or removes whitespace (e.g. a trailing space) as a
  no-op, so to force re-analysis change a word, e.g. in a comment.
- An empty list for a file the editor has not analysed does not mean it is clean. If a file is missing
  from the results, ask the user to open it.
- A change to a library can break the libraries that include it. After editing a shared library
  (`CQMConcepts`, `CQMElements`, `CQMCommon`, `FHIRBuilders`, ...), also check the libraries that
  include it, such as the matching `*Tests.cql` library.

### Fallback

If `mcp__claude-vscode__getDiagnostics` is not available (the session is not running inside the VS
Code extension), ask the user what the Problems panel shows, naming each file exactly. Do not guess,
and do not fall back to a standalone translator.

## Running CQL

Claude cannot evaluate CQL in this repo. The user runs the extension's **Execute CQL** command; results
are written to `input/tests/results/<Library>.txt`, one `<define>=<value>` line per expression. Read
that file after the user says they have run it.

- A runtime error in any one expression aborts the whole run: the results file then holds only a
  single `Error=...` line and no per-expression results. Find the expression responsible, take it out
  (with a comment saying why), and ask the user to run again.
- Compiling cleanly doesn't mean an expression will run. Building a non-null `FHIR.xhtml` compiles but
  fails at runtime with "Could not resolve data provider for package 'org.hl7.fhir.utilities.xhtml'".
- Patient test data: `input/tests/<Library>/<patient-id>/` (FHIR resource JSON).
- Terminology: the extension reads value sets from `input/vocabulary/valueset` and its sub-directories,
  and code systems from `input/vocabulary/codesystem`. VSAC value sets (with expansions) live in
  `input/vocabulary/valueset/external/`, named `ValueSet-<oid>-<date>.json`. Look there to confirm a
  code is a member of a value set before using it in test fixtures. The top-level `valueset` folder is
  an IG publisher `path-resource`, so anything placed directly in it gets published; check with the
  user before adding ValueSet resources there.
- Test libraries are named `<Library>Tests.cql` and use `define Test...: <Boolean>` expressions that
  evaluate to `true` when they pass. End each test library with a combined result,
  `define _Passed: TestA and TestB and ...`, listing every `Test...` define, for use as the
  population criteria of a Cohort measure in MADiE. Use `and`, not `AllTrue({ ... })`: `AllTrue`
  ignores nulls, so a null test would pass it. Add each new test to `_Passed`; the checker below
  verifies that `_Passed` lists every test exactly once. The only exception is a test that fails
  because of an engine issue rather than a defect in the library: comment it out in `_Passed` on a
  line of its own (`// and TestX`), with a comment saying why and to restore it once the engine is
  fixed (see `TestDiagnosticReportHasCategoryCodeCase` in CQMConceptsTests). The checker then reports
  it as a known failure, and says when it starts passing.
- Libraries with retrieves are tested with patient data rather than inline fixtures. See
  [Patient test data](#patient-test-data-for-madie) below.
- Check every results file with the checker, from the repo root:
  `python .claude/skills/cql/check_results.py <Library>Tests`. It reports:
  - an aborted run (`Error=`),
  - any `Test...` define that is missing from a case's results or isn't `true` there,
  - a `_Passed` that doesn't list every test exactly once.

  For patient data, it also checks that every case name in a `when '<case>' then` clause is a case
  label. With `else true`, a misspelled case name would otherwise pass silently. Tests inside
  `/* ... */` block comments are ignored, as are their commented-out `// and TestX` lines in
  `_Passed`. Don't read results files by eye.

## Patient test data (for MADiE)

Every library with patient data follows the same layout (`input/tests/CQMElementsTests/` and
`input/tests/ClaimElementsTests/` are the worked examples).

**Shared libraries vs measures.** A `<Library>Tests` library, with `Test...` defines and `_Passed`
as a Cohort measure in MADiE, is only for testing *shared* libraries (CQMConcepts, CQMElements,
ClaimCommon, ...). A *measure* library (e.g. HOB) is tested directly: its cases go in
`input/tests/<Measure>/`, with no test library, and each case's MeasureReport holds the expected
population counts for every group of the measure instead of the Cohort group. See
`input/tests/HOB/` (its README describes the groups):
- Groups are `Group_1` ... `Group_N` in the measure's group order, with populations
  `InitialPopulation_<n>`, `Denominator_<n>`, `Numerator_<n>` (counts of episodes, e.g. hospital
  stays, for an episode-based measure). `new_test_case.py` writes the Cohort group, so replace it.
- Everything else below applies unchanged: GUID patient ids, labels, keys, the README, and the zip.
- Check a run with `python .claude/skills/cql/check_measure_results.py <Measure> input/tests/<Measure>/populations.json`.
  `populations.json` maps each group's population codes to the defines, in group order. It compares
  the number of resources each population define returns with the expected counts.
- Don't change the measure logic to make it testable. Report defects to the user instead.

- **One folder per case:** `input/tests/<Library>Tests/<guid>/`, where `Patient.id` equals the folder
  name. MADiE requires GUID patient ids, so the informative case label (e.g. `03-Status-And-Use`)
  goes in the Patient's `name.given`.
- **Description and expected result:** each case's folder has a test case MeasureReport, in the form
  MADiE exports (compare a MADiE export of one case when in doubt):
  - `cqfm-isTestCase`, and the description in its `cqfm-testCaseDescription` extension;
  - the input parameters extension URL `http://hl7.org/fhir/StructureDefinition/cqf-inputParameters`
    (not `cqfm-inputParameters`), and a 2026 date `period`;
  - a `group` with the ids MADiE gives a Cohort measure's first group, `Group_1`, and its population,
    `InitialPopulation_1` (code `initial-population`), with `count: 1`, because `_Passed` is true on
    every case when the tests pass. Without the group, MADiE imports the case but can't wire up its
    expected values.
- **Keys, not ids:** MADiE replaces every resource id that isn't a GUID with a new GUID on import,
  and rewrites the references to match. So tests must never identify a resource by its id, or by a
  `'Location/x'` reference string. Every resource has a readable **key** in an identifier with the
  system `http://example.org/fhir/identifiers`: the case label for the Patient (MADiE also requires
  a Patient identifier), and otherwise the resource's readable id (`inp-03`). The test library reads
  it with one function per resource type (`"EncounterKey"(FHIR.Encounter)`,
  `"LocationKey"(FHIR.Location)`, `"ClaimKey"(FHIR.Claim)`), and resolves a reference to a key with
  `"ResolveKey"(reference)`, which uses FHIRCommon's `references()`. The MADiE engine has two runtime
  problems that don't show up locally, so:
  - Don't overload these functions under one name. MADiE resolved `"Key"(FHIR.Resource)` and
    `"Key"(FHIR.Reference)` wrongly at runtime.
  - Don't write one function over `FHIR.Resource` that branches with `is` / `as`, because MADiE
    can't evaluate `is` at runtime.

  Contained resources are typed `FHIR.Resource`, which has no `identifier`. To get their keys,
  match each one by id to the retrieved resource it copies (`"ContainedKeys"` in CQMElementsTests),
  rather than casting it. See CQMElementsTests and
  ClaimElementsTests. Comparing one resource's id with another's (e.g.
  `I.claim.id = I.claimId`) is fine. Constructed resources that don't copy `identifier` (CQMElements'
  normalized encounters, with id `<id>-primary`) are found from the key of their source resource.
- **Creating a case:** don't hand-write the Patient or the MeasureReport. Create them with
  `python .claude/skills/cql/new_test_case.py <Library>Tests <label> "<description>"`, which prints
  the new guid. Then add the case's other resources to the folder, with their subject or patient
  references set to `Patient/<guid>`, and a key identifier each. Name each file
  `<ResourceType>-<id>.json`, keep the ids (and keys) short and readable (`Encounter-inp-03.json`),
  and make them unique across the library's cases.
- **Labels:** labels are `NN-Short-Description`. Number them in order, so that the results blocks and
  the `when` clauses read in sequence. Never change a label once tests refer to it.
- **The "Case" define:** in the test library, write
  `define "Case": FHIRHelpers.ToString(First(Patient.name.given))`. When an assertion needs the
  patient reference, use `define "Patient Reference": 'Patient/' + FHIRHelpers.ToString(Patient.id)`.
  Don't hard-code guids in the CQL. (MADiE keeps a patient id that is already a GUID.)
- **README:** list the cases in the README with their folder, label, and what each covers.
  `new_test_case.py <Library>Tests --list` prints the folders, labels, and descriptions. Keep the
  README's description and the MeasureReport's description the same.
- **MADiE zip:** after any change to the cases, rebuild the import zip with
  `python scripts/make_test_case_zip.py input/tests/<Library>Tests`. It reads the titles and
  descriptions from the Patient and the MeasureReport. Its testCaseIds are hashed from the labels,
  so they stay stable across rebuilds. Its warnings about references to resources that are not in
  the case are expected for references to Coverage or Organization that aren't retrieved.
- **Which resources go in a case:** add only the resources the tests need, plus one deliberate
  near-miss of each kind, to show that a filter excludes it (wrong status, outside the period, an
  unrelated encounter). Also include a case with none of the resources the library retrieves (e.g.
  `05-No-Claims`), so the invariants are checked on empty input.
- **Non-compartment resources:** resources such as Location can go in the case folder, and
  `[USQualityCore.Location]` in Patient context returns them.
- **Profiles:** use `meta.profile` URLs from the model's IG, e.g.
  `http://fhir.org/guides/onc/us-quality-core/StructureDefinition/us-quality-core-encounter`.

How the results are laid out:
- Every expression is evaluated once per case.
- In the results file, each case's results are a block separated from the next by a blank line,
  sorted by expression name. `Patient=Patient(id=...)` is therefore *not* a header: it falls among
  the P's.
- Identify the case by the `Case=` line anywhere in the block.

How to write case tests:
- Write them as `case "Case" when '<label>' then <assertion> ... else true end`.
- Mark tests that must hold for every case as invariants.
- Every test must then be `true` on every case, and `false` or `null` is always a failure.
- Don't use `else null` for "not applicable". A `null` from an assertion that couldn't be evaluated
  (e.g. a serviced date that came back null) is then indistinguishable from "doesn't apply", which
  hid a real bug in ClaimElements.
- Don't use `Coalesce(..., true)` either, for the same reason.
- To assert that a value is null, write `X is null`.
- Helper defines (not `Test...`) can still use `else null`.

## Covering new or changed functions

When a library gains functions (or a function changes), use this workflow to keep the coverage
consistent. CQMConceptsTests' `prevalencePeriod` / `relevantDate` / `relevantPeriod` tests are a
worked example.

1. **List every branch.** Read each new function and the functions it calls in the included
   libraries (FHIRCommon, USCoreCommon, CQMCommon), down to the element level. Write the branches
   down:
   - each type in a choice element (`dateTime` vs `Period` onset),
   - an element present vs absent,
   - every `if` / `case` arm and `Coalesce` fallback,
   - each status value that changes the result, including a missing status,
   - an open vs closed null boundary.

   Pay particular attention to how a dependency treats null: FHIRCommon's `isActive()` uses `~`, so
   a missing clinicalStatus gives false, not null.
2. **Write one fixture builder that takes every varying element as a parameter.** Pass null for
   elements the fixture should not have, e.g. `"Test Condition"(clinicalStatus, onset, abatement,
   assertedDate, recordedDate)`. Then each test reads as one line of arguments, and the next agent
   adds cases by changing arguments, not by copying resource selectors. Keep named fixture values
   (`"Onset Date"`, `"Abatement Period"`) as defines, so the expected values in assertions refer to
   the same values.
3. **Write one test per branch.** Name it `Test<Resource><Function><Branch>`, e.g.
   `TestConditionPrevalencePeriodActiveNoAbatement`. Group the tests under a block comment naming the
   function, in the same order as the library under test.
4. **Assert the whole result, not just one part of it.** For an interval, check the start, the end
   and the closedness. Reusable predicates such as `"Is Ongoing From"(period, start)` (closed null
   end, so `end of` is `maximum DateTime`) and `"Has Unknown End From"` (open null end, so `end of`
   is null) make that one call.
5. **Add a profiled-type test.** Add one invariant over a retrieve of each profiled type, so the
   call is checked against the profile types measure logic uses. For example, see
   `TestProfiledConditionPeriods`:
   `AllTrue([USQualityCore.ConditionProblemsHealthConcerns] C return C.relevantPeriod() is not null)`.
   Condition has two profiles, so cover both.
6. **Update `_Passed`, then compile-check** both the library and the test library (see above).
7. **Run and check.** Ask the user to run the test library, then run `check_results.py`. When a test
   fails, decide whether the defect is in the library or in the test's expected value before changing
   either. Report library defects to the user rather than silently fitting the test to them.
8. **Report what isn't covered.** At the end, tell the user which functions are still untested, and
   why.

### Terminology available in MADiE

MADiE doesn't have every code system. A test library that declares a code system MADiE lacks can't be
imported, even when it compiles and runs locally. The known gaps are:
- v2-0074 (`DiagnosticServiceSectionCodes`),
- US Core careplan-category.

To handle a missing code system:
- Comment out its `codesystem` and `code` declarations with a `NOTE: Codesystems not found in MADiE`
  comment.
- Put the tests that use them in a `/* ... */` block comment, citing that note.
- Remove the tests from `_Passed` as `// and TestX` lines.

The checker ignores tests disabled this way. When you add a code system that MADiE might not have,
tell the user, so they can confirm it's available before importing.

## Writing test libraries

`CQMElementsTests.cql` and `CQMConceptsTests.cql` are the worked examples; follow their layout (header
comment explaining what needs data or terminology, fixture builders, fixtures, then tests grouped by the
function under test).

- Build fixtures inline as FHIR resources, so most tests need no patient data. Use FHIRBuilders
  (`include FHIRBuilders version '0.1.000-draft' called Build`) for primitives: `Build.id`, `Build.string`,
  `Build.uri`, `Build.code`, `Build.Period(Interval<DateTime>)`, `Build.Quantity(System.Quantity)`,
  `Build.Coding(System.Code)`, `Build.CodeableConcept(System.Code | System.Concept)`,
  `Build.Identifier(system, value)`, `Build.Reference('Patient/x')`. Single-argument builders other
  than `Quantity` also have a fluent form named `toFHIR...` (`'x'.toFHIRString()`,
  `Interval[...].toFHIRPeriod()`, `code.toFHIRCodeableConcept()`). Don't redefine these locally in a
  test library.
- Build fixture concepts from Code and Concept literals against code systems declared in the test
  library, e.g. `Build.CodeableConcept(Code '3151-8' from "LOINC")` or
  `Build.CodeableConcept(Concept { Code 'a' from "LOINC", Code 'b' from "LOINC" })`. A `Concept { }`
  selector takes only Code literals: a reference to a define holding a Code (`Concept { "My Code" }`)
  is a syntax error at the reference, so write the `Code '...' from "X"` literal inline.
- Build fixture codings from code systems and codes declared in the test library, not from the code
  declarations of the library under test. Otherwise a wrong system or code in the library is copied into the fixture and the
  test still passes. Test the declarations themselves separately against independently declared codes.
- Status and intent elements each have their own binding type, not a shared one: `FHIR.CarePlanStatus`,
  `FHIR.CarePlanIntent`, `FHIR.ServiceRequestStatus`, `FHIR.ServiceRequestIntent`,
  `FHIR.ObservationStatus`, `FHIR.DiagnosticReportStatus`, `FHIR.EncounterStatus`. `FHIR.RequestStatus`
  is rejected for these.
- Backbone elements are named `<Resource>.<Element>`, e.g. `FHIR.Observation.Component`,
  `USQualityCore.Encounter.Location`. Don't set `id` on them (or on any non-resource element): the
  model info types `Element.id` as `System.String`, so it compiles, but at runtime the engine fails with
  "java.lang.String cannot be cast to class org.hl7.fhir.instance.model.api.IBase" and the whole run
  aborts. Identify which element an accessor returned by its code and value instead. (Resource ids
  set with `Build.id(...)` are fine.)
- `Code '...' from "X"` literals and `code` declarations need the code system `"X"` declared in the same
  library, so declare the code systems the tests use locally.
- Accessors that return a list of FHIR primitives (e.g. `List<FHIR.string>`) should be mapped to system
  values before comparing with a list literal (`values V return V.value`). Don't rely on the implicit
  conversion being applied to each element of the list.
- A Boolean test can't assert that an expression raises an error (e.g. `singleton from` over more than
  one match). Say in the library header that the case is not covered rather than writing a test that
  always fails.
- Functions that take `FHIR.*` types are usually called with profiled types in measure logic. To check
  that they resolve, add invariant tests over retrieves (`AllTrue([USQualityCore.Organization] O return
  ...)`). These are vacuously true with no data, but they still compile-check the call. The
  USQualityCore profile type names are in the model info at
  `~/.fhir/packages/fhir.onc.us-quality-core#0.5.0/package/Library-USQualityCore-ModelInfo.json`
  (base64 content; decode it, then look for `typeInfo` names). Examples: `CarePlan`,
  `DiagnosticReportLab`, `DiagnosticReportNote`, `ServiceRequest`, `Organization`, `Practitioner`,
  `ObservationClinicalResult`, `SimpleObservation`.
- Spec details that matter for expected values: `start of`/`end of` an open interval return the
  successor/predecessor, so an open boundary at midnight moves to the adjacent day. A *closed* null
  boundary means unbounded, not unknown: `end of Interval[x, null]` is `maximum DateTime` and
  `start of Interval[null, y]` is `minimum DateTime`. Only an *open* null boundary
  (`Interval[x, null)`) gives null (confirmed by running FHIRBuildersTests).
- FHIR doesn't allow empty strings, and the engine reads `FHIR.string { value: '' }` back with a null
  `.value`, so `''` is not a usable FHIR string value. The same happens with a whitespace-only value
  (`' '`).
- Confirmed by running FHIRBuildersTests: closed null boundaries, empty and whitespace-only strings, and
  the `Period()` / `Quantity()` round trips through FHIRHelpers (including a Period with no end reading
  back as `Interval[start, null]`). `difference in days`
  counts calendar-day boundaries crossed, not 24-hour periods. `~` on codes compares system and code
  only (not display). Whether the code comparison ignores case depends on the case sensitivity the code
  system declares (`CodeSystem.caseSensitive`); most HL7 code systems (e.g. v2-0074) are case
  sensitive. The engine currently compares codes case-insensitively regardless (an engine issue), so
  `Code 'lab' ~ Code 'LAB'` from v2-0074 comes back true even though the spec says false. Write tests
  to the spec, and mark any test that fails on an engine issue with a NOTE and a TODO to log it (see
  `TestDiagnosticReportHasCategoryCodeCase` in CQMConceptsTests).
- `ToDateTime(Date)` (and anything built on it, e.g. ClaimCommon's `toServicedInterval()` for a
  serviced date) gives a day-precision DateTime with the timezone offset of the evaluation, i.e. the
  user's local zone. Compared with a UTC time on the same local day, the result is uncertain and so
  null, and *which* day a UTC time falls on depends on the zone: `2024-03-02T00:00Z` is still 03-01
  in US zones (confirmed: a test with that boundary came back null on ClaimCommonTests). In fixtures,
  keep times at least a day away from dates they're compared with, and when a same-day comparison is
  the point of the test, use 12:00Z, which is on the same date in effectively every zone.
- An interval selector always has fixed closedness, so rebuilding an interval from `start of` / `end of`
  turns an open null boundary (unknown) into a closed null boundary (unbounded):
  `Interval[f(start of I), f(end of I)]` with `I = Interval[x, null)` gives `Interval[f(x), null]`, whose
  `end of` is the maximum value, not null (confirmed by running CQMConceptsTests).

## CQL mistakes that have come up here

- A function invocation used as a query source needs parentheses: `(F(x)) X where ...`, not
  `F(x) X where ...`. The same applies to fluent calls: `(E.includedEncounters()) I`, to a property
  of a call result: `(Build.CodeableConcept(c).coding) C`, to list literals:
  `({ 'a', 'b' }) U return ...`, and to a property path used as a query source directly inside a
  function call's parentheses: `flatten ((C.item) I return ...)`, not `flatten (C.item I return ...)`
  (without the parentheses it is a syntax error at the alias). A retrieve followed by a fluent call
  needs them too: `([USQualityCore.Claim]).active()`, not `[USQualityCore.Claim].active()`.
- The sources of a multi-source query are independent, and a source can't refer to another source's
  alias, so `from C.item I, C.item.encounter E` (or the same thing through `let`) is the cross
  product of all the items with all the encounters any item references. To unfold a nested list per
  parent, nest the queries:
  `flatten ((C.item) I return I.encounter E return { item: I, encounter: E })` (confirmed: the cross
  product gave six rows instead of two on ClaimElementsTests).
- Fluent overloads in different included libraries are resolved **silently**: when two included
  libraries both define a fluent function with the same name and compatible parameter types, the
  translator reports no ambiguity and picks one. That is harmless when the definitions are identical
  (MedicationCommon duplicating FHIRCommon's MedicationRequest category functions), but not otherwise:
  ClaimCommon's `toInterval(Choice<FHIR.date, FHIR.Period>)` lost to FHIRCommon's `toInterval()` in
  ClaimElements, which includes both, so every serviced date came back null (FHIRCommon 2.0.0's
  `toInterval()` returns null for a `FHIR.date`), with no diagnostic. Don't add an overload of a
  function name that FHIRCommon (or another library commonly included alongside yours) already
  defines, unless it is identical; give it a distinct name (ClaimCommon's is now
  `toServicedInterval()`).
  - **CQMCommon and CQMElements clash.** Both define `hospitalization()` and `edVisit()` on
    `USQualityCore.Encounter` (CQMCommon's `Encounter` parameter means `USQualityCore.Encounter`
    because it declares `using USQualityCore` first). In a library that includes both, the calls
    silently go to CQMCommon's. CQMCommon's version looks for a prior ED visit and returns null when
    there is none, so it doesn't work on CQMElements' "Hospitalization Encounters".
  - Confirmed on HOB. Every stay without an ED visit just before its last encounter got a null
    `hospitalization()`, so it dropped out of every population.
  - Don't include CQMCommon alongside CQMElements just for the other functions.
  - When a function works in a test library but not in a measure, compare their includes first.
- The VS Code diagnostics can miss errors entirely. A new library came back with no diagnostics and a
  `linesInFile`, even after an Edit, but failed to load at run time with "Syntax error at H". The
  cause was an unparenthesized function call used as a query source. Check by eye against the pitfalls
  here, especially for a new file.
- Fluent functions can only be invoked with fluent syntax; `Lib.f(x)` fails with "is a fluent function
  and can only be invoked with fluent syntax".
- CQL is case-sensitive, and system operators are not invocable as fluent functions. But a fluent call
  named after a FHIRPath function (`.toString()`, `.toBoolean()`, `.toInteger()`, `.toDecimal()`,
  `.toDate()`, `.toDateTime()`, `.toTime()`, and likely others such as `.exists()`) is resolved by the
  translator's FHIRPath method invocation support, which maps it to the system operator (`ToString`, ...)
  before any user-defined fluent function is considered. The giveaway is an error naming the capitalised
  operator, e.g. "Could not resolve call to operator ToBoolean with signature (System.Boolean)". This
  support is on unless `DisableMethodInvocation` is in `cql-options.json` (it is not, here). So don't give
  user-defined fluent functions FHIRPath function names. (Confirmed: this is why FHIRBuilders'
  fluent forms were renamed to `toFHIRBoolean()`, `toFHIRString()`, etc.; follow that `toFHIR...`
  convention for new fluent builders.)
- CQL has no `Trim` (that is FHIRPath). To test for a blank string use a regex: `Matches` matches the
  whole string, so `Matches(value, '\\s*')` is true for empty or whitespace-only input. In CQL string
  literals a regex backslash must be written `\\`, and shell heredocs can silently drop one of them, so
  make edits like this with the Edit tool.
- After a shared library changes, the libraries that include it keep showing stale (often cascading)
  errors until they are edited themselves; make a small Edit to the including file before trusting its
  diagnostics.
- Changes to `cql-options.json` are not picked up by the language server until it restarts, so the
  diagnostics won't reflect an options change straight away.
- In a library with `using FHIR`, an unqualified `Quantity { ... }` selector resolves to `FHIR.Quantity`.
  Write `System.Quantity { value: 4.0 }` for the CQL type, or use a quantity literal (`5 'mg'`).
- A string literal that matches a define's name triggers a "String literal ... matches the
  identifier" warning, so avoid listing test names as strings.
- Model elements are FHIR types (`FHIR.id`, `FHIR.string`, `FHIR.EncounterStatus`, `FHIR.Period`).
  Any library written against FHIR (or a model derived from it) must include FHIRHelpers
  (`include hl7.fhir.uv.cql.FHIRHelpers version '4.0.1'`), which supplies the implicit conversions from
  FHIR types to CQL system types. Rely on those conversions and write `E.id = 'x'`,
  `E.status = 'finished'`, `start of E.period`, rather than reaching for `.value`.
- A query `return` removes duplicates; use `return all` when duplicates matter, e.g. a list of
  location references where the same ward appears twice, or several extensions with the same URL.
  A test that expects duplicates fails with plain `return` (confirmed on CQMElementsTests).
- An empty list literal needs a type: `List<USQualityCore.Encounter>{}`.
- FHIR status codes are lowercase (`'finished'`, not `'Finished'`), and string literals take single
  quotes; double quotes are identifiers.
- Before declaring a fluent function locally, check whether FHIRCommon, USCoreCommon, or CQMCommon
  already ships it.
- `FHIR.Extension.url` is a `FHIR.uri`, so build it with `Build.uri('http://...')`. A bare string
  literal is a type error, which then cascades as "could not determine result type" on every
  expression that uses the fixture.
- To give a fixture an optional extension, have a helper return `List<FHIR.Extension>{}` when the
  value is null. Combine several of these with `union` (see `"Asserted Date Extensions"` in
  CQMConceptsTests).
- Extensions the libraries read:
  - FHIRCommon's `abatementInterval()` for AllergyIntolerance reads the `allergyintolerance-abatement`
    extension, because AllergyIntolerance has no abatement element.
  - USCoreCommon's `assertedDate` reads `condition-assertedDate` for both Condition and
    AllergyIntolerance.

  Put these extensions on the fixture, not elements that don't exist.
- AllergyIntolerance's subject is `patient`, not `subject`.
- Overloads often share a body, e.g. the Condition and AllergyIntolerance versions of
  `relevantPeriod`. An Edit `old_string` taken from the body alone then matches both, so include the
  signature or comment line that is unique to the one you mean.

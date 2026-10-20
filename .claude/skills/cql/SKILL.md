---
name: cql
description: How to validate and run CQL in this repo using the VS Code CQL extension. Use whenever writing, editing, reviewing, or validating .cql files (input/cql), or CQL snippets in narrative pages, and before claiming any CQL compiles.
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
  evaluate to `true` when they pass.
- Libraries with retrieves are tested with patient data, not inline fixtures: one folder per case in
  `input/tests/<Library>Tests/<case>/`, with `Patient.id` equal to the folder name, plus a README
  describing the cases (see `input/tests/HOB/README.md` and `input/tests/CQMElementsTests/README.md`).
  Every expression is evaluated once per case, and the results file has a `Patient=Patient(id=...)`
  header before each case's results. Write case tests as
  `case "Case" when '<case>' then <assertion> ... else null end` (with
  `define "Case": FHIRHelpers.ToString(Patient.id)`), so `null` means "not applicable", and mark
  tests that must hold for every case as invariants. Non-compartment resources such as Location can go in the
  case folder; `[USQualityCore.Location]` in Patient context returns them. Use `meta.profile` URLs
  from the model's IG
  (e.g. `http://fhir.org/guides/onc/us-quality-core/StructureDefinition/us-quality-core-encounter`).

## Writing test libraries

`CQMElementsTests.cql` and `CQMConceptsTests.cql` are the worked examples; follow their layout (header
comment explaining what needs data or terminology, fixture builders, fixtures, then tests grouped by the
function under test).

- Build fixtures inline as FHIR resources, so most tests need no patient data. Use FHIRBuilders
  (`include FHIRBuilders version '0.1.000' called Build`) for primitives: `Build.id`, `Build.string`,
  `Build.uri`, `Build.code`, `Build.Period(Interval<DateTime>)`, `Build.Quantity(System.Quantity)`,
  `Build.Coding(System.Code)`, `Build.CodeableConcept(System.Code | System.Concept)`,
  `Build.Identifier(system, value)`, `Build.Reference('Patient/x')`. Single-argument builders other
  than `Quantity` also have a fluent form named `toFHIR...` (`'x'.toFHIRString()`,
  `Interval[...].toFHIRPeriod()`, `code.toFHIRCodeableConcept()`). Don't redefine these locally in a
  test library.
- Build fixture concepts from Code and Concept literals against code systems declared in the test
  library, e.g. `Build.CodeableConcept(Code '3151-8' from "LOINC")` or
  `Build.CodeableConcept(Concept { Code 'a' from "LOINC", Code 'b' from "LOINC" })`.
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
- An interval selector always has fixed closedness, so rebuilding an interval from `start of` / `end of`
  turns an open null boundary (unknown) into a closed null boundary (unbounded):
  `Interval[f(start of I), f(end of I)]` with `I = Interval[x, null)` gives `Interval[f(x), null]`, whose
  `end of` is the maximum value, not null (confirmed by running CQMConceptsTests).

## CQL mistakes that have come up here

- A function invocation used as a query source needs parentheses: `(F(x)) X where ...`, not
  `F(x) X where ...`. The same applies to fluent calls: `(E.includedEncounters()) I`, to a property
  of a call result: `(Build.CodeableConcept(c).coding) C`, and to list literals:
  `({ 'a', 'b' }) U return ...` (without the parentheses it is a syntax error at the alias).
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

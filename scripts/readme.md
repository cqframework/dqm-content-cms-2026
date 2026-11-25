# Test Case Comparison Process

This repository provides a workflow for comparing expected and actual results for measure test cases. The process generates a comparison file at `./scripts/comparison/output_results.csv` that summarizes PASS/FAIL for each population result.

## Workflow Steps

1. **Run the CQL plugin**  
   Execute the CQL plugin to generate actual test results for each measure. This will create files in the `./input/tests/results` directory.

2. **Run the scripts in order:**
   - **Step 1:** `extract_population_expected.py`  
     Parses expected results from MeasureReport files and Measure resources.  
     _Only rerun when MeasureReport expected results change._
   - **Step 2:** `extract_population_actual.py`  
     Parses actual results from the output of the CQL plugin in `./input/tests/results/{MeasureName}.txt`.  
     _Rerun whenever these result files change._
   - **Step 3:** `compare_results.py`  
     Compares expected and actual results, producing the summary file `./scripts/comparison/output_results.csv`.  
     _Rerun whenever either expected or actual results change._

## Script Descriptions

### `extract_population_expected.py`
- Reads MeasureReport JSON files and corresponding Measure resources.
- Extracts population codes and criteria expressions as display names.
- Outputs a CSV of expected results to `./scripts/comparison/expected_results.csv`.

### `extract_population_actual.py`
- Reads actual result files from `./input/tests/results`.
- Parses population results for each test case, handling boolean and list values.
- Outputs a CSV of actual results to `./scripts/comparison/actual_results.csv`.

### `compare_results.py`
- Compares expected and actual results by measure name, guid, and display name.
- Outputs a summary CSV to `./scripts/comparison/output_results.csv` with PASS/FAIL status for each population.
- Prints the number and percentage of PASS and FAIL items to the terminal.

## Reproducing Results Without Running CQL

To quickly reproduce the comparison results without running the CQL plugin:
- Extract `./scripts/results-connectathon-2025-09-13.zip` to `./input/tests/results`.
- This will populate the results directory with sample data, allowing you to run the scripts and generate `./scripts/comparison/output_results.csv
# Packaging and checking test cases for MADiE

These use the cqf-skills `madie` skill's scripts, found in the Claude Code plugin cache or in a
cqf-skills clone named by the `CQF_SKILLS` environment variable (see `madie_skill.py`).

`make_test_case_zip.py` packages a folder of CQL test cases (one subfolder per case, one FHIR
resource per JSON file, as the CQL VS Code extension reads them) as a zip for MADiE's test case
import, in the layout of a MADiE export, and checks it against MADiE's import rules. It writes the
zip into the test case folder, next to its README:

```
python scripts/make_test_case_zip.py input/tests/ClaimElementsTests
```

Its warnings about references to resources the case doesn't contain are real: MADiE leaves those
resources out of execution.

`madie_skill.py` runs any of the `madie` skill's scripts, for example checking a measure's Execute
CQL results against its test cases' expected counts the way MADiE does:

```
python scripts/madie_skill.py check_results input/tests/HOB input/tests/results/HOB.txt --populations input/tests/HOB/populations.json
```

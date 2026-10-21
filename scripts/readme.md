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
# Packaging test cases for MADiE

`make_test_case_zip.py` packages a folder of CQL test cases (one subfolder per case, one FHIR
resource per JSON file, as the CQL VS Code extension reads them) as a zip for MADiE's test case
import, in the layout of a MADiE export: a folder per case named after its patient id, holding a
single collection Bundle of all the case's resources, plus `.madie` and `README.txt`.

```
python scripts/make_test_case_zip.py input/tests/ClaimElementsTests
```

By default the zip is written into the test case folder, next to its README
(`input/tests/ClaimElementsTests/ClaimElementsTests.zip`); use `-o` to write it elsewhere.

It checks each case before packaging (exactly one Patient, no duplicate resources) and warns about
a Patient id that doesn't match the folder name and references to resources the case doesn't
contain. Run `python scripts/make_test_case_zip.py --help` for the options.

"""Check a measure library's results file against the expected populations in its test cases.

Usage (from the repo root):

    python .claude/skills/cql/check_measure_results.py <Library> <populations json>

e.g. `python .claude/skills/cql/check_measure_results.py HOB input/tests/HOB/populations.json`

The populations json names the define for each population code of each group, in the measure's group
order: `[{"initial-population": "...", "denominator": "...", "numerator": "..."}, ...]`. A Measure
resource also works, read from its group.population.criteria expressions.

Reads input/tests/results/<Library>.txt and the test cases in input/tests/<Library>/ (one folder per
patient, each with a test case MeasureReport, in the layout new_test_case.py creates). For each case,
each population in each MeasureReport group is matched to the group in the same position in the
populations json, and the define it names for the population's code.
The checker fails unless:
* no case raised a runtime error (an Error= block in place of the case's results; if every case did,
  the run aborted),
* every case has results and a MeasureReport,
* every population's define is in the case's results, and the number of resources it returned (for an
  episode-based measure, e.g. Encounters) is the population's expected count. A Boolean population
  (patient-based) counts as 1 when true and 0 otherwise.

The MeasureReport group and population ids are MADiE's (`Group_1`, `Numerator_1`, ...); they are not
used here, only the group order and the population codes.
"""
import json
import os
import re
import sys


def blocks(results_path):
    """{patient id: {define: value}} from a results file"""
    text = open(results_path, encoding='utf-8').read()
    result = {}
    for block in re.split(r'\n\s*\n', text):
        values = {}
        for line in block.splitlines():
            m = re.match(r'([^=]+)=(.*)$', line)
            if m:
                values[m.group(1)] = m.group(2)
        m = re.match(r'Patient\(id=([^)]+)\)', values.get('Patient', ''))
        if m:
            result[m.group(1)] = values
        elif 'Error' in values:
            result.setdefault('Error', []).append(values['Error'])
    return result


def count(value):
    value = value.strip()
    if value in ('true', 'false', 'null'):
        return 1 if value == 'true' else 0
    if value == '[]':
        return 0
    # Count the top-level resources in a list, e.g. [Encounter(id=a), Encounter(id=b)]
    depth, n = 0, 0
    for i, ch in enumerate(value):
        if ch in '([{':
            if ch == '(' and depth == 1:
                n += 1
            depth += 1
        elif ch in ')]}':
            depth -= 1
    return n


def main(lib, measure_path):
    results_path = os.path.join('input', 'tests', 'results', lib + '.txt')
    cases_dir = os.path.join('input', 'tests', lib)
    measure = json.load(open(measure_path, encoding='utf-8'))
    if isinstance(measure, list):
        criteria = measure
    else:
        criteria = [{p['code']['coding'][0]['code']: p['criteria']['expression'] for p in g['population']}
                    for g in measure['group']]
    results = blocks(results_path)
    # A runtime error aborts only the case it happens in: that case has a block with just an Error= line
    # (and no Patient= line, so which case it was is shown by the case with no results)
    errors = results.pop('Error', [])
    if errors and not results:
        print(f'{lib}: the run aborted: Error={errors[0]}')
        return 1

    problems, checked = [], 0
    for folder in sorted(os.listdir(cases_dir)):
        case_dir = os.path.join(cases_dir, folder)
        if not os.path.isdir(case_dir):
            continue
        resources = [json.load(open(os.path.join(case_dir, n), encoding='utf-8'))
                     for n in os.listdir(case_dir) if n.lower().endswith('.json')]
        patient = next((r for r in resources if r['resourceType'] == 'Patient'), None)
        label = (patient or {}).get('name', [{}])[0].get('given', [folder])[0]
        report = next((r for r in resources if r['resourceType'] == 'MeasureReport'), None)
        if report is None:
            problems.append(f'{label}: no MeasureReport')
            continue
        values = results.get(folder)
        if values is None:
            problems.append(f'{label}: no results (patient {folder})' + (' - probably the case that raised the Error above' if errors else ''))
            continue
        for i, group in enumerate(report.get('group', [])):
            if i >= len(criteria):
                problems.append(f"{label}: {group.get('id')} has no group in the Measure")
                continue
            for population in group.get('population', []):
                code = population['code']['coding'][0]['code']
                define = criteria[i].get(code)
                if define is None:
                    problems.append(f"{label}: the Measure's group {i + 1} has no {code} population")
                elif define not in values:
                    problems.append(f'{label}: "{define}" is not in the results')
                else:
                    actual = count(values[define])
                    checked += 1
                    if actual != population.get('count'):
                        problems.append(f'{label}: "{define}" expected {population.get("count")}, '
                                        f'got {actual}: {values[define]}')
    for e in errors:
        print(f'Error={e}')
    for p in problems:
        print(p)
    print(f'{lib}: {checked} population counts checked, {len(problems)} problem(s)')
    return 1 if problems else 0


if __name__ == '__main__':
    if len(sys.argv) != 3:
        print(__doc__)
        sys.exit(2)
    sys.exit(main(sys.argv[1], sys.argv[2]))

"""Check a CQL test library's results file.

Usage (from the repo root):  python .claude/skills/cql/check_results.py <Library>Tests

Reads input/cql/<lib>.cql and input/tests/results/<lib>.txt, and fails unless:
* the run didn't abort (no Error= line),
* every `define Test...` in the library appears in every case's results, with the value true,
* every case name used in a `when '<case>' then` clause of a Test define is one of the case folders in
  input/tests/<lib>/ (a misspelled name would otherwise pass silently, since uncovered cases are true).

Libraries with no patient data have a single block of results. With patient data, the results for each
case are separated by blank lines and sorted by name, so `Patient=` is not a header; the case is read
from the `Case=` or `Patient=Patient(id=...)` line anywhere in the block.
"""
import os
import re
import sys


def main(lib):
    cql_path = os.path.join('input', 'cql', lib + '.cql')
    results_path = os.path.join('input', 'tests', 'results', lib + '.txt')
    cases_dir = os.path.join('input', 'tests', lib)

    src = open(cql_path, encoding='utf-8').read()
    test_defines = {}
    for block in re.split(r'\n(?=define )', src):
        m = re.match(r'define (Test\w+)\s*:', block)
        if m:
            test_defines[m.group(1)] = re.findall(r"when '([^']+)' then", block) if 'case "Case"' in block else []

    problems = []

    # Case names used in the tests must be case folders
    folders = sorted(d for d in os.listdir(cases_dir) if os.path.isdir(os.path.join(cases_dir, d))) \
        if os.path.isdir(cases_dir) else []
    for test, names in test_defines.items():
        for name in names:
            if name not in folders:
                problems.append(f'{test}: case {name!r} is not a folder in {cases_dir}')

    # Results, one block per case
    lines = open(results_path, encoding='utf-8').read().splitlines()
    errors = [l for l in lines if l.startswith('Error=')]
    if errors:
        print(f'{lib}: the run aborted:')
        for e in errors:
            print('  ' + e)
        return 1

    blocks, current = [], []
    for line in lines + ['']:
        if line.strip() == '':
            if current:
                blocks.append(current)
            current = []
        else:
            current.append(line)

    checked = 0
    case_names = []
    for block in blocks:
        results = {}
        case = None
        for line in block:
            m = re.match(r'(Test\w+)=(.*)$', line)
            if m:
                results[m.group(1)] = m.group(2)
            m = re.match(r'Case=(.*)$', line) or re.match(r'Patient=Patient\(id=(.*)\)$', line)
            if m and case is None:
                case = m.group(1)
        if not results:
            continue
        label = case or '(no patient)'
        case_names.append(label)
        for test in test_defines:
            checked += 1
            value = results.get(test)
            if value is None:
                problems.append(f'{label}: {test} is missing from the results (re-run?)')
            elif value != 'true':
                problems.append(f'{label}: {test}={value}')
        for test in results:
            if test not in test_defines:
                problems.append(f'{label}: {test} is in the results but not in the library (re-run?)')

    if folders and sorted(case_names) != folders:
        problems.append(f'cases in the results {sorted(case_names)} do not match the folders {folders}')

    print(f'{lib}: {len(test_defines)} tests x {len(case_names)} case(s), {checked} results checked')
    for p in problems:
        print('  ' + p)
    if not problems:
        print('  all true')
    return 1 if problems else 0


if __name__ == '__main__':
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(2)
    sys.exit(main(sys.argv[1]))

"""Check a CQL test library's results file.

Usage (from the repo root):  python .claude/skills/cql/check_results.py <Library>Tests

Reads input/cql/<lib>.cql and input/tests/results/<lib>.txt, and fails unless:
* the run didn't abort (no Error= line),
* every `define Test...` in the library appears in every case's results, with the value true,
* every case name used in a `when '<case>' then` clause of a Test define is one of the case folders in
  input/tests/<lib>/ (a misspelled name would otherwise pass silently, since uncovered cases are true),
* if the library defines `_Passed` (the combined result, for a Cohort measure), it lists every Test
  define exactly once, and is true for every case.

A known failure (e.g. one caused by an engine issue) is excluded by commenting it out in `_Passed` on
a line of its own, `// and TestX`, with a comment explaining why. Its result is then listed as a known
failure rather than a problem, and if it starts passing the checker says to restore it.

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

    # If the library has a combined _Passed define, it must list every Test define exactly once, except
    # for known failures, which are commented out in it (`// and TestX`)
    passed = re.search(r'^define _Passed\s*:(.*?)(?=^define |\Z)', src, re.M | re.S)
    excluded = set()
    if passed:
        body = passed.group(1)
        listed = re.findall(r'\b(Test\w+)\b', re.sub(r'//[^\n]*', '', body))
        excluded = set(re.findall(r'^\s*//\s*(?:and\s+)?(Test\w+)\s*$', body, re.M))
        for test in test_defines:
            expected = 0 if test in excluded else 1
            if listed.count(test) != expected:
                problems.append(f'_Passed lists {test} {listed.count(test)} times (expected {expected})')
        for test in (set(listed) | excluded) - set(test_defines):
            problems.append(f'_Passed lists {test}, which is not a Test define')

    # Case names used in the tests must be case folders
    folders = sorted(d for d in os.listdir(cases_dir) if os.path.isdir(os.path.join(cases_dir, d))) \
        if os.path.isdir(cases_dir) else []
    for test, names in test_defines.items():
        for name in names:
            if name not in folders:
                problems.append(f'{test}: case {name!r} is not a folder in {cases_dir}')

    # Results, one block per case
    if not os.path.exists(results_path):
        print(f'{lib}: no results file at {results_path} (run the library first)')
        for p in problems:
            print('  ' + p)
        return 1
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
    known = []
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
            elif test in excluded:
                if value == 'true':
                    problems.append(f'{label}: {test} now passes; restore it in _Passed')
                else:
                    known.append(f'{label}: {test}={value}')
            elif value != 'true':
                problems.append(f'{label}: {test}={value}')
        for test in results:
            if test not in test_defines:
                problems.append(f'{label}: {test} is in the results but not in the library (re-run?)')
        if passed:
            value = next((l[len('_Passed='):] for l in block if l.startswith('_Passed=')), None)
            if value != 'true':
                problems.append(f'{label}: _Passed={value}' if value is not None
                                else f'{label}: _Passed is missing from the results (re-run?)')

    if folders and sorted(case_names) != folders:
        problems.append(f'cases in the results {sorted(case_names)} do not match the folders {folders}')

    print(f'{lib}: {len(test_defines)} tests x {len(case_names)} case(s), {checked} results checked')
    for p in problems:
        print('  ' + p)
    if known:
        print('  known failures (excluded from _Passed):')
        for k in known:
            print('    ' + k)
    if not problems:
        print('  all true' + (' except the known failures' if known else ''))
    return 1 if problems else 0


if __name__ == '__main__':
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(2)
    sys.exit(main(sys.argv[1]))

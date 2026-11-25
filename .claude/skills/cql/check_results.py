"""Check a run of a CQL test library in this repository.

Usage (from the repo root):  python .claude/skills/cql/check_results.py [--mcp] <Library>Tests

Runs the cqf-skills `cql` skill's check_test_library.py (see scripts/cqf_skill.py) on
input/cql/<Library>Tests.cql, with its test cases in input/tests/<Library>Tests/ (for the case-label
checks) and these results:

* with --mcp: the latest cql-mcp run, .cql-debug/test-runs/latest-<Library>Tests.json;
* otherwise Execute CQL's results: input/tests/results/<Library>Tests/ (individual results) if it
  exists, else input/tests/results/<Library>Tests.txt.

It fails unless every `Test...` is true on every case, no case errored, and `_Passed` lists each test
exactly once and is true. A test commented out of `_Passed` (`// and TestX`) is a known failure.
"""
import os
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..'))
sys.path.insert(0, os.path.join(ROOT, 'scripts'))
from cqf_skill import run  # noqa: E402


def main(argv):
    mcp = '--mcp' in argv
    args = [a for a in argv if a != '--mcp']
    if len(args) != 1:
        print(__doc__)
        return 2
    lib = args[0]
    if mcp:
        results = os.path.join(ROOT, '.cql-debug', 'test-runs', f'latest-{lib}.json')
    else:
        folder = os.path.join(ROOT, 'input', 'tests', 'results', lib)
        results = folder if os.path.isdir(folder) else folder + '.txt'
    command = [os.path.join(ROOT, 'input', 'cql', lib + '.cql'), results]
    cases = os.path.join(ROOT, 'input', 'tests', lib)
    if os.path.isdir(cases):
        command += ['--cases', cases]
    return run('cql', 'check_test_library', command)


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))

"""Create a patient-data test case in this repository, in the layout MADiE expects, or list the cases.

Usage (from the repo root):

    python .claude/skills/cql/new_test_case.py <Library> <NN-Label> "<description>" [options]
    python .claude/skills/cql/new_test_case.py <Library> --list

Runs the cqf-skills `madie` skill's new_test_case.py (see scripts/cqf_skill.py) on
input/tests/<Library>/, with this repository's 2026 measurement period. It creates
input/tests/<Library>/<new patient UUID>/ with the Patient (the label as its given name and key
identifier, system http://example.org/fhir/identifiers) and a test case MeasureReport, and prints the
UUID. Without options the MeasureReport has the Cohort group a test library expects (Group_1,
InitialPopulation_1, count 1). For a measure, pass `--populations input/tests/<Measure>/populations.json`
and fill in each population's expected count. Other options (`--measure`, `--series`, `--period`) are
passed on.

The second form prints each case's folder, label and description, for the README's case table.
"""
import os
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..'))
sys.path.insert(0, os.path.join(ROOT, 'scripts'))
from cqf_skill import run  # noqa: E402

PERIOD = ['--period', '2026-01-01', '2026-12-31']


def main(argv):
    if len(argv) < 2 or argv[0] in ('-h', '--help'):
        print(__doc__)
        return 2
    cases = os.path.join(ROOT, 'input', 'tests', argv[0])
    if argv[1] == '--list':
        return run('madie', 'new_test_case', [cases, '--list'])
    rest = argv[1:]
    return run('madie', 'new_test_case', [cases] + rest + ([] if '--period' in rest else PERIOD))


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))

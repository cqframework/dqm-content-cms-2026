"""Package a folder of CQL test cases as a zip for importing into MADiE.

Usage (from the repo root):

    python scripts/make_test_case_zip.py input/tests/ClaimElementsTests

which writes input/tests/ClaimElementsTests/ClaimElementsTests.zip, next to the folder's README, and
checks it against MADiE's import rules.

This runs the cqf-skills `madie` skill's vscode_to_madie.py (see scripts/madie_skill.py for where it
is found). Each case becomes `<patient id>/<patient id>.json`, a collection Bundle with the Patient
first, and `.madie` lists each case's title (the Patient's given name, the case label), series (the
Patient's family name) and description (from the case's test case MeasureReport). Its warnings about
references to resources that aren't in the case are real: MADiE leaves such resources out of execution.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from madie_skill import run  # noqa: E402

if __name__ == '__main__':
    if len(sys.argv) != 2 or sys.argv[1] in ('-h', '--help'):
        print(__doc__)
        sys.exit(0 if len(sys.argv) == 2 else 2)
    cases = os.path.normpath(sys.argv[1])
    name = os.path.basename(cases)
    sys.exit(run('vscode_to_madie', [cases, '-o', os.path.join(cases, name + '.zip')]))

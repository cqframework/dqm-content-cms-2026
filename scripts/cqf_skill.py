"""Run one of the cqf-skills skills' scripts.

Usage (from the repo root):

    python scripts/cqf_skill.py <skill> <script> [arguments...]

for example

    python scripts/cqf_skill.py madie vscode_to_madie input/tests/HOB -o input/tests/HOB/HOB.zip
    python scripts/cqf_skill.py madie check_results input/tests/HOB input/tests/results/HOB.txt \
        --populations input/tests/HOB/populations.json
    python scripts/cqf_skill.py cql check_test_library input/cql/ClaimCommonTests.cql \
        input/tests/results/ClaimCommonTests.txt

The skill's scripts are found in, in order:
* a cqf-skills clone named by the CQF_SKILLS environment variable (`skills/<skill>/scripts`),
* the newest copy installed by the cqf-skills Claude Code plugins
  (~/.claude/plugins/cache/cqf-skills/<plugin>/<version>/skills/<skill>/scripts).
To get them without Claude Code, clone https://github.com/cqframework/cqf-skills and set CQF_SKILLS.
"""
import glob
import os
import subprocess
import sys


def scripts_dir(skill):
    if os.environ.get('CQF_SKILLS'):
        return os.path.join(os.environ['CQF_SKILLS'], 'skills', skill, 'scripts')
    found = glob.glob(os.path.join(os.path.expanduser('~'), '.claude', 'plugins', 'cache', 'cqf-skills',
                                   '*', '*', 'skills', skill, 'scripts'))
    return max(found, key=os.path.getmtime) if found else None


def run(skill, script, args):
    directory = scripts_dir(skill)
    path = os.path.join(directory, script + '.py') if directory else None
    if not path or not os.path.isfile(path):
        sys.exit(f"Can't find the {skill} skill's {script}.py. Install the cqf-skills plugins in Claude Code, "
                 "or clone https://github.com/cqframework/cqf-skills and set CQF_SKILLS to the clone.")
    # -I: don't let the current directory or the script's folder shadow standard modules
    return subprocess.call([sys.executable, '-I', path] + args)


if __name__ == '__main__':
    if len(sys.argv) < 3 or sys.argv[1] in ('-h', '--help'):
        print(__doc__)
        sys.exit(0 if len(sys.argv) >= 2 and sys.argv[1] in ('-h', '--help') else 2)
    sys.exit(run(sys.argv[1], sys.argv[2].removesuffix('.py'), sys.argv[3:]))

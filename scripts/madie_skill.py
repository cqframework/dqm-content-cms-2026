"""Run one of the cqf-skills `madie` skill's scripts.

Usage (from the repo root):

    python scripts/madie_skill.py <script> [arguments...]

for example

    python scripts/madie_skill.py vscode_to_madie input/tests/HOB -o input/tests/HOB/HOB.zip
    python scripts/madie_skill.py check_results input/tests/HOB input/tests/results/HOB.txt \
        --populations input/tests/HOB/populations.json
    python scripts/madie_skill.py check_test_cases input/tests/HOB/HOB.zip

The scripts are found in, in order:
* the directory named by the CQF_SKILLS_MADIE environment variable (the skill's `scripts` folder),
* a cqf-skills clone named by the CQF_SKILLS environment variable (`skills/madie/scripts`),
* the newest copy installed by the cqf-skills Claude Code plugins
  (~/.claude/plugins/cache/cqf-skills/*/*/skills/madie/scripts).
To get them without Claude Code, clone https://github.com/cqframework/cqf-skills and set CQF_SKILLS.
"""
import glob
import os
import subprocess
import sys


def scripts_dir():
    if os.environ.get('CQF_SKILLS_MADIE'):
        return os.environ['CQF_SKILLS_MADIE']
    if os.environ.get('CQF_SKILLS'):
        return os.path.join(os.environ['CQF_SKILLS'], 'skills', 'madie', 'scripts')
    found = glob.glob(os.path.join(os.path.expanduser('~'), '.claude', 'plugins', 'cache', 'cqf-skills',
                                   '*', '*', 'skills', 'madie', 'scripts'))
    return max(found, key=os.path.getmtime) if found else None


def run(script, args):
    directory = scripts_dir()
    path = os.path.join(directory, script + '.py') if directory else None
    if not path or not os.path.isfile(path):
        sys.exit(f"Can't find the madie skill's {script}.py. Install the cqf-skills plugins in Claude Code, "
                 "or clone https://github.com/cqframework/cqf-skills and set CQF_SKILLS to the clone.")
    # -I: don't let the current directory or the script's folder shadow standard modules
    return subprocess.call([sys.executable, '-I', path] + args)


if __name__ == '__main__':
    if len(sys.argv) < 2 or sys.argv[1] in ('-h', '--help'):
        print(__doc__)
        sys.exit(0 if len(sys.argv) >= 2 else 2)
    sys.exit(run(sys.argv[1].removesuffix('.py'), sys.argv[2:]))

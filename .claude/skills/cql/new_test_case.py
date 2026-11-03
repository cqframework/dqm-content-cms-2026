"""Create a patient-data test case for a CQL test library, in the layout MADiE expects, or list the cases.

Usage (from the repo root):

    python .claude/skills/cql/new_test_case.py <Library>Tests <label> "<description>"
    python .claude/skills/cql/new_test_case.py <Library>Tests --list

The first form creates input/tests/<Library>Tests/<guid>/ holding:

    Patient-<guid>.json        id <guid>, the label as name.given (what the tests' "Case" define reads)
                               and as its key identifier, family <Library>Test, and the USQualityCore
                               Patient profile
    MeasureReport-<uuid>.json  a test case MeasureReport (cqfm-isTestCase) for the patient, in the form
                               MADiE exports: the description in its cqfm-testCaseDescription extension,
                               and the expected initial population (Group_1 / InitialPopulation_1,
                               count 1, since _Passed is true when every test passes)

and prints the guid. Add the case's other resources to the folder, referencing `Patient/<guid>`, each
with its readable key (e.g. `inp-03`, usually also its id) in an identifier with the KEY_SYSTEM system:
MADiE replaces ids that aren't GUIDs on import, so the tests find resources by that key. The label must
not already be used by another case in the library.

The second form prints each case's folder, label, and description, for the README's case table.
"""
import json
import os
import sys
import uuid

CQFM = 'http://hl7.org/fhir/us/cqfmeasures/StructureDefinition/'
# The identifier system for the readable keys the tests find resources by
KEY_SYSTEM = 'http://example.org/fhir/identifiers'
PATIENT_PROFILE = 'http://fhir.org/guides/onc/us-quality-core/StructureDefinition/us-quality-core-patient'


def write(path, resource):
    with open(path, 'w', encoding='utf-8', newline='\n') as f:
        f.write(json.dumps(resource, indent=2) + '\n')


def cases(tests_dir):
    """(folder, label, description) for each case folder, sorted by label."""
    result = []
    for folder in os.listdir(tests_dir):
        case_dir = os.path.join(tests_dir, folder)
        if not os.path.isdir(case_dir):
            continue
        label, description = folder, ''
        for name in os.listdir(case_dir):
            if not name.lower().endswith('.json'):
                continue
            with open(os.path.join(case_dir, name), encoding='utf-8') as f:
                resource = json.load(f)
            if resource.get('resourceType') == 'Patient':
                given = [g for n in resource.get('name', []) for g in n.get('given', [])]
                label = given[0] if given else folder
            elif resource.get('resourceType') == 'MeasureReport':
                description = next((e.get('valueMarkdown', '') for e in resource.get('extension', [])
                                    if e.get('url') == CQFM + 'cqfm-testCaseDescription'), '')
        result.append((folder, label, description))
    return sorted(result, key=lambda c: c[1])


def create(tests_name, tests_dir, label, description):
    if any(c[1] == label for c in cases(tests_dir)):
        sys.exit(f'{tests_name} already has a case labelled {label!r}')
    guid = str(uuid.uuid4())
    case_dir = os.path.join(tests_dir, guid)
    os.makedirs(case_dir)
    write(os.path.join(case_dir, f'Patient-{guid}.json'), {
        'resourceType': 'Patient',
        'id': guid,
        'meta': {'profile': [PATIENT_PROFILE]},
        'identifier': [{'system': KEY_SYSTEM, 'value': label}],
        'name': [{'family': tests_name[:-1] if tests_name.endswith('s') else tests_name, 'given': [label]}],
        'gender': 'female',
        'birthDate': '1970-01-01',
    })
    report_id = str(uuid.uuid4())
    write(os.path.join(case_dir, f'MeasureReport-{report_id}.json'), {
        'resourceType': 'MeasureReport',
        'id': report_id,
        'meta': {'profile': [CQFM + 'test-case-cqfm']},
        'contained': [{
            'resourceType': 'Parameters',
            'id': f'{guid}-parameters',
            'parameter': [{'name': 'subject', 'valueString': guid}],
        }],
        'extension': [
            {'url': 'http://hl7.org/fhir/StructureDefinition/cqf-inputParameters', 'valueReference': {'reference': f'#{guid}-parameters'}},
            {'url': CQFM + 'cqfm-testCaseDescription', 'valueMarkdown': description},
        ],
        'modifierExtension': [{'url': CQFM + 'cqfm-isTestCase', 'valueBoolean': True}],
        'status': 'complete',
        'type': 'individual',
        'measure': 'https://madie.cms.gov/Measure/' + tests_name,
        'period': {'start': '2026-01-01', 'end': '2026-12-31'},
        # The group and population ids MADiE gives a Cohort measure's first group
        'group': [{
            'id': 'Group_1',
            'population': [{
                'id': 'InitialPopulation_1',
                'code': {'coding': [{
                    'system': 'http://terminology.hl7.org/CodeSystem/measure-population',
                    'code': 'initial-population',
                    'display': 'Initial Population',
                }]},
                'count': 1,
            }],
            'measureScore': {'value': 1.0},
        }],
    })
    print(guid)


def main(argv):
    if len(argv) not in (2, 3) or (len(argv) == 2 and argv[1] != '--list'):
        print(__doc__)
        return 2
    tests_name = argv[0]
    tests_dir = os.path.join('input', 'tests', tests_name)
    if argv[1] == '--list':
        if not os.path.isdir(tests_dir):
            sys.exit(f'no test cases at {tests_dir}')
        for folder, label, description in cases(tests_dir):
            print(f'{folder}  {label}\n    {description}')
        return 0
    os.makedirs(tests_dir, exist_ok=True)
    create(tests_name, tests_dir, argv[1], argv[2])
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))

"""Package a folder of CQL test cases as a zip for importing into MADiE.

Usage (from the repo root):

    python scripts/make_test_case_zip.py input/tests/ClaimElementsTests

which writes input/tests/ClaimElementsTests/ClaimElementsTests.zip, next to the folder's README.

The input is a folder with one subfolder per test case, each holding that case's FHIR resources as
separate JSON files (the layout the CQL VS Code extension reads, e.g. input/tests/ClaimElementsTests/).
The zip has the layout of a MADiE test case export:

    <case>/<case>.json   a collection Bundle with every resource in the case, Patient first
    .madie               the test case metadata: patientId, title, series, and description per case
    README.txt           the list of cases

Each case folder in the zip is named after its patient id, which should also be the case folder name.
MADiE expects patient ids to be GUIDs, so a case's label is kept in the Patient's given name instead
(the tests read it from there), and its description in a test case MeasureReport in the case folder
(the cqfm-testCaseDescription extension). Titles in .madie are the labels (the folder name if the
Patient has no given name), and descriptions are the MeasureReport descriptions (empty if none).
Each case also gets a testCaseId in .madie, 24 hex digits like the ids in a MADiE export. It is derived
from the folder and case names, so rebuilding the zip gives the same ids.

Each case is checked before it is packaged: it must have exactly one Patient, every resource needs a
resourceType and an id, and there must be no duplicate resources. A Patient id that doesn't match the
folder name, and references to resources that aren't in the case, are reported as warnings.
"""
import argparse
import hashlib
import json
import os
import re
import sys
import zipfile


def load_case(case_dir):
    resources = []
    for name in sorted(os.listdir(case_dir)):
        path = os.path.join(case_dir, name)
        if not (os.path.isfile(path) and name.lower().endswith('.json')):
            continue
        with open(path, encoding='utf-8') as f:
            resource = json.load(f)
        if resource.get('resourceType') == 'Bundle':
            raise ValueError(f'{path} is already a Bundle; expected one resource per file')
        resources.append((name, resource))
    return resources


def test_case_id(tests_name, case):
    """A stable 24-hex-digit id for a test case, in the form of the testCaseIds in a MADiE export."""
    return hashlib.sha1(f'{tests_name}/{case}'.encode('utf-8')).hexdigest()[:24]


TEST_CASE_DESCRIPTION = 'http://hl7.org/fhir/us/cqfmeasures/StructureDefinition/cqfm-testCaseDescription'


def title_and_description(case, resources):
    """The case's label (the Patient's given name) and description (from its test case MeasureReport)."""
    title, description = case, ''
    for _, resource in resources:
        if resource.get('resourceType') == 'Patient':
            given = [g for n in resource.get('name', []) for g in n.get('given', [])]
            if given:
                title = given[0]
        elif resource.get('resourceType') == 'MeasureReport':
            for ext in resource.get('extension', []):
                if ext.get('url') == TEST_CASE_DESCRIPTION:
                    description = ext.get('valueMarkdown') or ext.get('valueString') or ''
    return title, description


def references(value):
    """Yield every relative reference (Type/id) in a resource."""
    if isinstance(value, dict):
        for key, item in value.items():
            if key == 'reference' and isinstance(item, str):
                m = re.fullmatch(r'([A-Z][A-Za-z]+)/([A-Za-z0-9\-.]{1,64})', item)
                if m:
                    yield m.group(1), m.group(2)
            else:
                yield from references(item)
    elif isinstance(value, list):
        for item in value:
            yield from references(item)


def make_bundle(case, resources, base_url, errors, warnings):
    seen = set()
    patients = []
    for name, resource in resources:
        rtype, rid = resource.get('resourceType'), resource.get('id')
        if not rtype or not rid:
            errors.append(f'{case}/{name}: missing resourceType or id')
            continue
        if (rtype, rid) in seen:
            errors.append(f'{case}/{name}: duplicate {rtype}/{rid}')
        seen.add((rtype, rid))
        if rtype == 'Patient':
            patients.append(rid)

    if len(patients) != 1:
        errors.append(f'{case}: expected exactly one Patient, found {len(patients)}')
    elif patients[0] != case:
        warnings.append(f'{case}: Patient.id is {patients[0]!r}, not the folder name')

    missing = {}
    for name, resource in resources:
        for target in set(references(resource)):
            if target not in seen:
                missing.setdefault(target, []).append(name)
    for (rtype, rid), names in sorted(missing.items()):
        where = names[0] if len(names) == 1 else f'{len(names)} resources'
        warnings.append(f'{case}: {rtype}/{rid} is referenced (from {where}) but not in the case')

    # Patient first, then by type and id, so the bundle is stable from run to run
    ordered = sorted(
        (r for _, r in resources),
        key=lambda r: (r.get('resourceType') != 'Patient', r.get('resourceType', ''), r.get('id', '')))
    bundle = {
        'resourceType': 'Bundle',
        'id': case,
        'type': 'collection',
        'entry': [
            {'fullUrl': f"{base_url.rstrip('/')}/{r['resourceType']}/{r['id']}", 'resource': r}
            for r in ordered if r.get('resourceType') and r.get('id')
        ],
    }
    return bundle, (patients[0] if len(patients) == 1 else case)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('tests_dir', help='folder with one subfolder per test case, e.g. input/tests/ClaimElementsTests')
    parser.add_argument('-o', '--output', help='zip file to write (default: <folder>/<folder name>.zip, inside the test case folder)')
    parser.add_argument('--base-url', default='https://madie.cms.gov',
                        help='base for the entry fullUrls, which are <base>/<Type>/<id> (default: %(default)s)')
    parser.add_argument('--no-metadata', action='store_true', help='leave out the .madie and README.txt files')
    args = parser.parse_args()

    tests_dir = os.path.normpath(args.tests_dir)
    if not os.path.isdir(tests_dir):
        sys.exit(f'{tests_dir} is not a folder')
    output = args.output or os.path.join(tests_dir, os.path.basename(tests_dir) + '.zip')

    cases = sorted(d for d in os.listdir(tests_dir) if os.path.isdir(os.path.join(tests_dir, d)))
    if not cases:
        sys.exit(f'{tests_dir} has no test case folders')

    errors, warnings, bundles = [], [], []
    for case in cases:
        try:
            resources = load_case(os.path.join(tests_dir, case))
        except (ValueError, json.JSONDecodeError) as e:
            errors.append(f'{case}: {e}')
            continue
        bundle, patient_id = make_bundle(case, resources, args.base_url, errors, warnings)
        title, description = title_and_description(case, resources)
        bundles.append((title, description, patient_id, bundle))

    for w in warnings:
        print('warning: ' + w)
    if errors:
        for e in errors:
            print('error: ' + e)
        sys.exit(f'{len(errors)} error(s); no zip written')

    with zipfile.ZipFile(output, 'w', zipfile.ZIP_DEFLATED) as z:
        for _, _, patient_id, bundle in bundles:
            z.writestr(f'{patient_id}/{patient_id}.json', json.dumps(bundle, indent=2) + '\n')
        if not args.no_metadata:
            metadata = [
                {'testCaseId': test_case_id(os.path.basename(tests_dir), title), 'patientId': patient_id,
                 'title': title, 'series': '', 'description': description}
                for title, description, patient_id, _ in bundles
            ]
            z.writestr('.madie', json.dumps(metadata))
            readme = (
                'The purpose of this file is to allow users to view the mapping of test case names to their '
                'test case UUIDs. In order to find a specific test case file in the export, first locate the '
                'test case name in this document and then use the associated UUID to find the name of the '
                'folder in the export.\n\n'
                + '\n'.join(f'Case # {i} - {patient_id} =  {title}'
                            for i, (title, _, patient_id, _) in enumerate(bundles, 1))
            )
            z.writestr('README.txt', readme)

    total = sum(len(b['entry']) for _, _, _, b in bundles)
    print(f'wrote {output}: {len(bundles)} test case(s), {total} resource(s)')


if __name__ == '__main__':
    main()

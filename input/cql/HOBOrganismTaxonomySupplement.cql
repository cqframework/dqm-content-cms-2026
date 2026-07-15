/*
Alternative representation of the HOBOrganismTaxonomy rollup/matching logic.

Instead of the inline OrganismTaxonomy list, this version sources the genus/species
rollup from the SNOMED CT CodeSystem supplement (CodeSystem-hob-organism-taxonomy)
by *retrieving* it and reading its concept properties.

IMPORTANT: a CQL Retrieve reads the DATA provider, not the terminology server, so the
supplement resource must be present in the evaluation data (e.g. included in the
patient bundle / test-case folder) for [CodeSystem] to return it. Placing it in the
terminology folder alone is not sufficient for the Retrieve.

The species()/genus()/organismMatches() signatures match HOBOrganismTaxonomy so this
library can be swapped in for it (change HOB's include and ensure the supplement is in
the retrievable data).
*/
library HOBOrganismTaxonomySupplement

using FHIR version '4.0.1'

include hl7.fhir.uv.cql.FHIRHelpers version '4.0.1' called FHIRHelpers

codesystem "SNOMEDCT": 'http://snomed.info/sct'

context Unfiltered

// The HOB organism taxonomy supplement, retrieved as data.
define function "OrganismTaxonomySupplement"():
  singleton from (
    [CodeSystem] C
      where C.url = 'https://example.org/fhir/CodeSystem/hob-organism-taxonomy'
  )

// Returns the code of a Coding-valued rollup property ('roll-up-genus' /
// 'roll-up-species') for the taxonomy concept matching the given organism.
// Mirrors the inline-table version: a list with one entry per matching concept,
// whose value is null when the property is absent (e.g. species for a genus-level
// concept, which omits the roll-up-species property).
define fluent function taxonomyRollup(organism Concept, propertyCode String):
  ("OrganismTaxonomySupplement"().concept) CSC
    where exists (
      organism.codes C
        where C.system = 'http://snomed.info/sct'
          and C.code = CSC.code
    )
    return singleton from (
      CSC.property P
        where P.code = propertyCode
        return (P.value as FHIR.Coding).code.value
    )

define fluent function species(organism Concept):
  organism.taxonomyRollup('roll-up-species')

define fluent function genus(organism Concept):
  organism.taxonomyRollup('roll-up-genus')

define fluent function organismMatches(organismA Concept, organismB Concept):
  organismA ~ organismB
    or organismA.species() = organismB.species()
    or (
      organismA.species() is null
        and organismB.species() is null
        and organismA.genus() = organismB.genus()
    )

/*
Demonstration expressions — require the supplement in the retrievable data.
These mirror the taxonomy relationships exercised by the HOB numerator test cases
(15-HOB-Excluded-GenusMatch) so the retrieve-based results can be compared against
the inline-table behaviour.
*/
define "Abiotrophia defectiva": Concept { Code '113714003' from "SNOMEDCT" }
define "Legionella A": Concept { Code '266186009' from "SNOMEDCT" }
define "Legionella B": Concept { Code '154315008' from "SNOMEDCT" }
define "Acetobacter aceti": Concept { Code '396950003' from "SNOMEDCT" }

define "Supplement Retrieved": "OrganismTaxonomySupplement"() is not null
define "Species of Abiotrophia defectiva": "Abiotrophia defectiva".species()
define "Genus of Abiotrophia defectiva": "Abiotrophia defectiva".genus()
define "Species of Legionella A (expect null)": "Legionella A".species()
define "Genus of Legionella A": "Legionella A".genus()
define "Legionella A matches Legionella B via genus (expect true)":
  "Legionella A".organismMatches("Legionella B")
define "Abiotrophia defectiva matches Acetobacter aceti (expect false)":
  "Abiotrophia defectiva".organismMatches("Acetobacter aceti")

library HOBOrganismTaxonomy

// TODO: Need to construct more concise tables here
define "OrganismTaxonomy":
{
  { "snomed_preferred_term": '(Cholera) or (Vibrio cholerae)', "snomed_concept_id": '186087007', "roll_up_genus_level": '1', "roll_up_genus_name": 'Vibrio', "roll_up_genus_conceptid": '34872001', "roll_up_species_level": '1', "roll_up_species_name": 'Vibrio cholerae', "roll_up_species_conceptid": '75953000', "nhsn_community_associated": '0', "nhsn_skin_commensal": '0', "snomed_status": '0' }
}

define fluent function species(organism Concept):
  OrganismTaxonomy T
    where exists (organism.codes C where C.system = 'http://snomed.info/sct' and C.code = T.snomed_concept_id)
    return T.roll_up_species_conceptid

define fluent function genus(organism Concept):
  OrganismTaxonomy T
    where exists (organism.codes C where C.system = 'http://snomed.info/sct' and C.code = T.snomed_concept_id)
    return T.roll_up_genus_conceptid

define fluent function organismMatches(organismA Concept, organismB Concept):
  organismA ~ organismB
    or organismA.species() = organismB.species()
    or (
      organismA.species() is null 
        and organismB.species() is null
        and organismA.genus() = organismB.genus()
    )


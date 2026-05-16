library Test

using QICore version '7.0.2'

include hl7.fhir.uv.cql.FHIRHelpers version '4.0.1'
include hl7.fhir.uv.cql.FHIRCommon version '2.0.0'

include QICoreCommon

context Patient

define TestEncounters: [Encounter]
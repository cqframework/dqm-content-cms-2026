/*
NOTE: For use by January 2026 Connectathon participants for internal use only. Not for use or distribution in commercial products.
*/
library AdultOutpatientEncounters version '5.0.000'

using QICore version '7.0.2'
using USCore version '7.0.0'
using FHIR version '4.0.1'

include hl7.fhir.uv.cql.FHIRHelpers version '4.0.1' called FHIRHelpers
include hl7.fhir.uv.cql.FHIRCommon version '2.0.0' called FHIRCommon
include Status version '2.0.000'

valueset "Annual Wellness Visit": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.526.3.1240' 
valueset "Home Healthcare Services": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.464.1003.101.12.1016' 
valueset "Office Visit": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.464.1003.101.12.1001' 
valueset "Virtual Encounter": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.464.1003.101.12.1089' 
valueset "Preventive Care Services Established Office Visit, 18 and Up": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.464.1003.101.12.1025' 
valueset "Preventive Care Services Initial Office Visit, 18 and Up": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.464.1003.101.12.1023' 
valueset "Telephone Visits": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.464.1003.101.12.1080' 

parameter "Measurement Period" Interval<DateTime>

context Patient

define "Qualifying Encounters":
  ( ( [QICore.Encounter: "Office Visit"]
    union [QICore.Encounter: "Annual Wellness Visit"]
    union [QICore.Encounter: "Preventive Care Services Established Office Visit, 18 and Up"]
    union [QICore.Encounter: "Preventive Care Services Initial Office Visit, 18 and Up"]
    union [QICore.Encounter: "Home Healthcare Services"]
    union [QICore.Encounter: "Virtual Encounter"]
    union [QICore.Encounter: "Telephone Visits"] ).isEncounterPerformed() ) ValidEncounter
    where ValidEncounter.period during day of "Measurement Period"
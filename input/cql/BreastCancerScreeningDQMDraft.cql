/*
NOTE: For use by January 2026 Connectathon participants for internal use only. Not for use or distribution in commercial products.
*/
library BreastCancerScreeningDQMDraft version '1.0.000'

using QICore version '7.0.2'
using USCore version '7.0.0'
using C4BB version '2.1.1'
using FHIR version '4.0.1'

include hl7.fhir.uv.cql.FHIRHelpers version '4.0.1' called FHIRHelpers
include hl7.fhir.uv.cql.FHIRCommon version '2.0.0' called FHIRCommon
include hl7.fhir.us.cql.USCoreCommon called USCommon
include QICoreCommon

include SupplementalDataElements version '6.0.000' called SDE
include AdultOutpatientEncounters version '5.0.000' called AdultOutpatientEncounters
include Hospice version '7.0.000' called Hospice
include Status version '2.0.000' called Status
include PalliativeCare version '2.0.000' called PalliativeCare
include AdvancedIllnessandFrailty version '2.0.000' called AIFrailLTCF

codesystem "ClaimTypeCodes": 'http://terminology.hl7.org/CodeSystem/claim-type'
codesystem "SNOMEDCT": 'http://snomed.info/sct'

valueset "Bilateral Mastectomy": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.464.1003.198.12.1005'
valueset "History of bilateral mastectomy": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.464.1003.198.12.1068'
valueset "Mammography": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.464.1003.108.12.1018'
valueset "Status Post Left Mastectomy": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.464.1003.198.12.1069'
valueset "Status Post Right Mastectomy": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.464.1003.198.12.1070'
valueset "Unilateral Mastectomy Left": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.464.1003.198.12.1133'
valueset "Unilateral Mastectomy Right": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.464.1003.198.12.1134'
valueset "Unilateral Mastectomy": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.464.1003.1285'

code "Female (finding)": '248152002' from "SNOMEDCT" display 'Female (finding)'
code "Entire left breast (body structure)": '361716006' from "SNOMEDCT" display 'Entire left breast (body structure)'
code "Entire right breast (body structure)": '361715005' from "SNOMEDCT" display 'Entire right breast (body structure)'
code "institutional": 'Institutional' from "ClaimTypeCodes"
code "professional": 'Professional' from "ClaimTypeCodes"

parameter "Measurement Period" Interval<DateTime>

context Patient

define "Initial Population":
  AgeInYearsAt(date from 
    end of "Measurement Period"
  ) in Interval[42, 74]
    and Patient.sex() = '248152002'
    and exists AdultOutpatientEncounters."Qualifying Encounters"

define "Denominator":
  "Initial Population"

define "Denominator Exclusions":
  "Is deceased during measurement period"
    or Hospice."Has Hospice Services"
    or ( ( exists ( "Right Mastectomy Diagnosis" )
          or exists ( "Right Mastectomy Procedure" )
      )
        and ( exists ( "Left Mastectomy Diagnosis" )
            or exists ( "Left Mastectomy Procedure" )
        )
    )
    or exists "Bilateral Mastectomy Diagnosis"
    or exists "Bilateral Mastectomy Procedure"
    or AIFrailLTCF."Is Age 66 or Older with Advanced Illness and Frailty"
    or AIFrailLTCF."Is Age 66 or Older Living Long Term in a Nursing Home"
    or PalliativeCare."Has Palliative Care in the Measurement Period"

 define "Is deceased during measurement period":
     Patient."Deceased during"("Measurement Period")

 define fluent function "Deceased during"(patient FHIR.Patient, duringPeriod Interval<System.DateTime>):
     if patient is null or duringPeriod is null or patient.deceased is null then false
     else 
         patient."Deceased date"() during duringPeriod

define fluent function "Deceased date"(patient FHIR.Patient):
     if patient is null then null
     else 
         if patient.deceased is null then null
         else
             case 
                 when patient.deceased is FHIR.dateTime then 
                     date from (patient.deceased as FHIR.dateTime)
                 else Message(null, true, 'BreastCancerScreeningDQMDraft.DeceasedDate.NotSupported', 'Error', 'Cannot determine deceased date because deceased is specified as a boolean')
             end

define "Right Mastectomy Diagnosis":
  ( ([Condition: "Status Post Right Mastectomy"]).verified ( ) ) RightMastectomy
    where RightMastectomy.prevalenceInterval ( ) starts on or before end of "Measurement Period"

define "Right Mastectomy Procedure":
  ( ( [QICore.Procedure: "Unilateral Mastectomy Right"]
  union [QICore.Procedure: "Unilateral Mastectomy"] UnilateralMastectomyProcedure 
  where exists UnilateralMastectomyProcedure.bodySite S where S ~ "Entire right breast (body structure)" 
  ).isProcedurePerformed ( ) ) UnilateralMastectomyRightPerformed
    where UnilateralMastectomyRightPerformed.performed.toInterval ( ) ends on or before end of "Measurement Period"

define "Left Mastectomy Diagnosis":
  ( ( [Condition: "Status Post Left Mastectomy"] ).verified ( ) ) LeftMastectomy
    where LeftMastectomy.prevalenceInterval ( ) starts on or before end of "Measurement Period"

define "Left Mastectomy Procedure":
  ( ( [QICore.Procedure: "Unilateral Mastectomy Left"] 
        union [QICore.Procedure: "Unilateral Mastectomy"] UnilateralMastectomyProcedure
        where exists UnilateralMastectomyProcedure.bodySite S where S ~ "Entire left breast (body structure)"
  ).isProcedurePerformed ( ) ) UnilateralMastectomyLeftPerformed
    where UnilateralMastectomyLeftPerformed.performed.toInterval ( ) ends on or before end of "Measurement Period"

define "Bilateral Mastectomy Diagnosis":
  ( ( [Condition: "History of bilateral mastectomy"] ).verified ( ) ) BilateralMastectomyHistory
    where BilateralMastectomyHistory.prevalenceInterval ( ) starts on or before end of "Measurement Period"

define "Bilateral Mastectomy Procedure":
  ( ( [QICore.Procedure: "Bilateral Mastectomy"] ).isProcedurePerformed ( ) ) BilateralMastectomyPerformed
    where BilateralMastectomyPerformed.performed.toInterval ( ) ends on or before end of "Measurement Period"

define "Numerator":
exists "Mammography Observation"
  or ([QICore.Claim])."With mammography during"(
        Interval["October 1 Two Years Prior to the Measurement Period", end of "Measurement Period"]
    ) is not null
  or ([ExplanationOfBenefit])."With mammography during"(
        Interval["October 1 Two Years Prior to the Measurement Period", end of "Measurement Period"]
    ) is not null
    
//Mammography Observation
define "Mammography Observation":
     ( ( [ObservationClinicalResult: code ~ "Mammography"] ).isDiagnosticStudyPerformed ( ) ) Mammogram
    where Mammogram.effective.toInterval ( ) ends during day of Interval["October 1 Two Years Prior to the Measurement Period", end of "Measurement Period"] 

define "October 1 Two Years Prior to the Measurement Period":
  DateTime((year from start of "Measurement Period" - 2), 10, 1, 0, 0, 0, 0, 0)

//Mammography Claim
define fluent function "With mammography during"(
    claims List<FHIR.Claim>,
    duringPeriod Interval<System.DateTime>
):
    if duringPeriod is null then null
    else
        claims
            ."With product or service during"(
                "Mammography",
                duringPeriod
            )

define fluent function "With product or service during"(
    claims List<FHIR.Claim>, 
    productOrServiceCodes System.ValueSet, 
    duringPeriod Interval<Date>
):
    if duringPeriod is null then null
    else 
        (claims."Professional or institutional"()) singleClaim
        with (
            singleClaim.item
                ."Starts during"(duringPeriod)
        ) item
        such that item."Has product or service"(productOrServiceCodes)

define fluent function "Professional or institutional"(claims List<FHIR.Claim>):
    (claims) claim
      where claim.type ~ "institutional"
        or claim.type ~ "professional"

define fluent function "Starts during"(items List<FHIR.Claim.Item>, interval Interval<Date>):
    if interval is null then null
    else 
        (items) item
        where item."Serviced"() starts during interval

define fluent function "Serviced"(item FHIR.Claim.Item):
    if item is null or item.serviced is null then null
    else 
        case 
            when item.serviced is FHIR.date then 
                (item.serviced as FHIR.date)."Serviced internal"()
            when item.serviced is FHIR.Period then 
                (item.serviced as FHIR.Period)."To date interval"()
            else null
        end

define fluent function "Serviced internal"(serviced FHIR.date):
    if serviced is null then null
    else 
        Interval[FHIRHelpers.ToDate(serviced), FHIRHelpers.ToDate(serviced)]

define fluent function "To date interval"(period FHIR.Period):
    if period is null then null
    else 
        Interval[date from period.start, date from period.end]

//Mammography EOB
define fluent function "With mammography during"(
    eobs List<FHIR.ExplanationOfBenefit>,
    duringPeriod Interval<System.Date>
):
    if duringPeriod is null then null
    else
        eobs
            ."With product or service during"(
                "Mammography",
                duringPeriod
            )

define fluent function "With product or service during"(
    eobs List<FHIR.ExplanationOfBenefit>, 
    productOrServiceCodes System.ValueSet, 
    duringPeriod Interval<Date>
):
    if duringPeriod is null then null
    else 
        ( eobs."Professional or institutional"() ) singleEob
        with (
            singleEob.item
                ."During"(duringPeriod)
        ) item
        such that item."Has product or service"(productOrServiceCodes)

define fluent function "During"(items List<FHIR.ExplanationOfBenefit.Item>, interval Interval<Date>):
    if interval is null then null
    else 
        (items) item
        where item."Serviced"() overlaps interval 

define fluent function "Has product or service"(item FHIR.ExplanationOfBenefit.Item, codes System.ValueSet):
    if item is null or item.productOrService is null then false
    else 
        item.productOrService in codes

define fluent function "Professional or institutional"(eobs List<FHIR.ExplanationOfBenefit>): 
    (eobs) eob
      where eob.type ~ "institutional"
        or eob.type ~ "professional"

define fluent function "Has"(coding FHIR.Coding, code System.Code):
    if coding is null or code is null then false
    else 
        FHIRHelpers.ToCode(coding) ~ code

define "SDE Ethnicity":
  SDE."SDE Ethnicity"

define "SDE Payer":
  SDE."SDE Payer"

define "SDE Race":
  SDE."SDE Race"

define "SDE Sex":
  SDE."SDE Sex"

define "Stratification 1":
  AgeInYearsAt(date from 
    end of "Measurement Period"
  ) in Interval[42, 51]

define "Stratification 2":
  AgeInYearsAt(date from 
    end of "Measurement Period"
  ) in Interval[52, 74]

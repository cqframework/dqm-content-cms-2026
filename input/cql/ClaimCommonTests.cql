/*
@description: Tests for the ClaimCommon library
@comment: Each test expression is named `Test...` and evaluates to `true` when the test passes.

The fixtures build their resources inline with FHIRBuilders, so most tests need neither patient data
nor terminology. Fixture codings are built from code systems and codes declared in this library rather
than from the ClaimCommon code declarations, so that a wrong system or code in ClaimCommon makes a test
fail instead of being reproduced in the fixture. The code declarations are tested separately against
independently declared codes. The exceptions are:
* The value set test checks that the expected members are in the "Present on Admission or Clinically
  Undetermined" value set, so it needs the expansion of that value set.
* The profile tests run the functions over retrieved US Quality Core claims. They check that the
  FHIR-typed overloads resolve for profiled inputs, and are invariants that must hold for whatever data
  is loaded. With no data loaded they are vacuously true.

`dischargeStatus()` and `pointOfOrigin()` use `single()`, which throws when more than one matching
supporting info entry is present. That behavior cannot be expressed as a passing Boolean test, so it is
not covered here.
*/
library ClaimCommonTests version '0.4.000-draft'

using USQualityCore version '0.5.0'
using USCore version '6.1.0-derived'
using FHIR version '4.0.1'

include hl7.fhir.uv.cql.FHIRHelpers version '4.0.1'

include ClaimCommon version '0.4.000-draft'
include FHIRBuilders version '0.1.000-draft' called Build

codesystem "FMStatus": 'http://hl7.org/fhir/fm-status'
codesystem "ExplanationOfBenefitStatus": 'http://hl7.org/fhir/explanationofbenefit-status'
codesystem "ClaimUse": 'http://hl7.org/fhir/claim-use'
codesystem "ClaimType": 'http://terminology.hl7.org/CodeSystem/claim-type'
codesystem "DiagnosisRole": 'http://terminology.hl7.org/CodeSystem/diagnosis-role'
codesystem "DiagnosisType": 'http://terminology.hl7.org/CodeSystem/ex-diagnosistype'
codesystem "ProcedureType": 'http://terminology.hl7.org/CodeSystem/ex-procedure-type'
codesystem "POA": 'https://www.cms.gov/Medicare/Medicare-Fee-for-Service-Payment/HospitalAcqCond/Coding'
codesystem "C4BBInstitutionalClaimSubType": 'http://hl7.org/fhir/us/carin-bb/CodeSystem/C4BBInstitutionalClaimSubType'
codesystem "C4BBSupportingInfoType": 'http://hl7.org/fhir/us/carin-bb/CodeSystem/C4BBSupportingInfoType'
codesystem "NUBCPatientDischargeStatus": 'https://www.nubc.org/CodeSystem/PatDischargeStatus'
codesystem "NUBCPointOfOrigin": 'https://www.nubc.org/CodeSystem/PointOfOrigin'

// A code system that is deliberately not one the ClaimCommon terminology uses
codesystem "Example Codes": 'http://example.org/codes'

context Patient

/*
 * Fixture builders
 */

define function "Test Claim"(id String, status String, use String, type System.Code, subType System.Code):
  FHIR.Claim {
    id: Build.id(id),
    status: FHIR.ClaimStatus { value: status },
    use: FHIR.Use { value: use },
    type: Build.CodeableConcept(type),
    subType: Build.CodeableConcept(subType),
    patient: Build.Reference('Patient/test-patient')
  }

define function "Test ExplanationOfBenefit"(id String, status String, use String, type System.Code, subType System.Code):
  FHIR.ExplanationOfBenefit {
    id: Build.id(id),
    status: FHIR.ExplanationOfBenefitStatus { value: status },
    use: FHIR.Use { value: use },
    type: Build.CodeableConcept(type),
    subType: Build.CodeableConcept(subType),
    patient: Build.Reference('Patient/test-patient')
  }

define function "Supporting Info"(sequence Integer, category System.Code, code System.Code):
  FHIR.Claim.SupportingInfo {
    sequence: FHIR.positiveInt { value: sequence },
    category: Build.CodeableConcept(category),
    code: Build.CodeableConcept(code)
  }

define function "Claim With Supporting Info"(supportingInfo List<FHIR.Claim.SupportingInfo>):
  FHIR.Claim {
    id: Build.id('test-claim-supporting-info'),
    status: FHIR.ClaimStatus { value: 'active' },
    use: FHIR.Use { value: 'claim' },
    type: Build.CodeableConcept(Code 'institutional' from "ClaimType"),
    patient: Build.Reference('Patient/test-patient'),
    supportingInfo: supportingInfo
  }

define function "Ids"(resources List<FHIR.Resource>):
  resources R
    return R.id.value

// True if the resources have exactly the given ids, in any order
define function "Has Ids"(resources List<FHIR.Resource>, ids List<String>):
  Count(resources) = Count(ids)
    and "Ids"(resources) includes ids

/*
 * Fixtures
 */

define "Institutional": Code 'institutional' from "ClaimType"
define "Professional": Code 'professional' from "ClaimType"
define "Pharmacy": Code 'pharmacy' from "ClaimType"
define "Oral": Code 'oral' from "ClaimType"
define "Vision": Code 'vision' from "ClaimType"
define "Inpatient": Code 'inpatient' from "C4BBInstitutionalClaimSubType"
define "Outpatient": Code 'outpatient' from "C4BBInstitutionalClaimSubType"

define "Active Institutional Claim": "Test Claim"('active-institutional', 'active', 'claim', "Institutional", "Inpatient")
define "Active Professional Claim": "Test Claim"('active-professional', 'active', 'claim', "Professional", null)
define "Cancelled Claim": "Test Claim"('cancelled', 'cancelled', 'claim', "Institutional", "Outpatient")
define "Draft Claim": "Test Claim"('draft', 'draft', 'claim', "Professional", null)
define "Entered In Error Claim": "Test Claim"('entered-in-error', 'entered-in-error', 'claim', "Pharmacy", null)
define "Preauthorization Claim": "Test Claim"('preauthorization', 'active', 'preauthorization', "Oral", null)
define "Predetermination Claim": "Test Claim"('predetermination', 'active', 'predetermination', "Vision", null)
define "Claim Without Status Or Use": "Test Claim"('no-status', null, null, null, null)

define "All Claims":
  {
    "Active Institutional Claim",
    "Active Professional Claim",
    "Cancelled Claim",
    "Draft Claim",
    "Entered In Error Claim",
    "Preauthorization Claim",
    "Predetermination Claim",
    "Claim Without Status Or Use"
  }

define "Active Institutional EOB": "Test ExplanationOfBenefit"('active-institutional', 'active', 'claim', "Institutional", "Inpatient")
define "Active Professional EOB": "Test ExplanationOfBenefit"('active-professional', 'active', 'claim', "Professional", null)
define "Cancelled EOB": "Test ExplanationOfBenefit"('cancelled', 'cancelled', 'claim', "Institutional", "Outpatient")
define "Draft EOB": "Test ExplanationOfBenefit"('draft', 'draft', 'claim', "Professional", null)
define "Entered In Error EOB": "Test ExplanationOfBenefit"('entered-in-error', 'entered-in-error', 'claim', "Pharmacy", null)
define "Preauthorization EOB": "Test ExplanationOfBenefit"('preauthorization', 'active', 'preauthorization', "Oral", null)
define "Predetermination EOB": "Test ExplanationOfBenefit"('predetermination', 'active', 'predetermination', "Vision", null)
define "EOB Without Status Or Use": "Test ExplanationOfBenefit"('no-status', null, null, null, null)

define "All EOBs":
  {
    "Active Institutional EOB",
    "Active Professional EOB",
    "Cancelled EOB",
    "Draft EOB",
    "Entered In Error EOB",
    "Preauthorization EOB",
    "Predetermination EOB",
    "EOB Without Status Or Use"
  }

define "Discharged Home": Code '01' from "NUBCPatientDischargeStatus"
define "Transfer From Hospital": Code '4' from "NUBCPointOfOrigin"

define "Claim With Discharge Status And Point Of Origin":
  "Claim With Supporting Info"({
    "Supporting Info"(1, Code 'admtype' from "C4BBSupportingInfoType", Code '1' from "Example Codes"),
    "Supporting Info"(2, Code 'discharge-status' from "C4BBSupportingInfoType", "Discharged Home"),
    "Supporting Info"(3, Code 'pointoforigin' from "C4BBSupportingInfoType", "Transfer From Hospital")
  })

define "Principal Type": { Build.CodeableConcept(Code 'principal' from "DiagnosisType") }
define "Admitting Type": { Build.CodeableConcept(Code 'admitting' from "DiagnosisType") }
define "Principal And Admitting Types":
  {
    Build.CodeableConcept(Code 'admitting' from "DiagnosisType"),
    Build.CodeableConcept(Code 'principal' from "DiagnosisType")
  }
define "Principal Type Wrong System": { Build.CodeableConcept(Code 'principal' from "Example Codes") }
define "Primary Procedure Type": { Build.CodeableConcept(Code 'primary' from "ProcedureType") }
define "Secondary Procedure Type": { Build.CodeableConcept(Code 'secondary' from "ProcedureType") }
define "No Types": List<FHIR.CodeableConcept>{}

/*
 * Code declarations
 */

define TestClaimStatusDeclarations:
  ClaimCommon."claim-active" ~ Code 'active' from "FMStatus"
    and ClaimCommon."claim-cancelled" ~ Code 'cancelled' from "FMStatus"
    and ClaimCommon."claim-draft" ~ Code 'draft' from "FMStatus"
    and ClaimCommon."claim-entered-in-error" ~ Code 'entered-in-error' from "FMStatus"

define TestExplanationOfBenefitStatusDeclarations:
  ClaimCommon."eob-active" ~ Code 'active' from "ExplanationOfBenefitStatus"
    and ClaimCommon."eob-cancelled" ~ Code 'cancelled' from "ExplanationOfBenefitStatus"
    and ClaimCommon."eob-draft" ~ Code 'draft' from "ExplanationOfBenefitStatus"
    and ClaimCommon."eob-entered-in-error" ~ Code 'entered-in-error' from "ExplanationOfBenefitStatus"

define TestUseDeclarations:
  ClaimCommon."use-claim" ~ Code 'claim' from "ClaimUse"
    and ClaimCommon."use-preauthorization" ~ Code 'preauthorization' from "ClaimUse"
    and ClaimCommon."use-predetermination" ~ Code 'predetermination' from "ClaimUse"

define TestTypeDeclarations:
  ClaimCommon."type-institutional" ~ Code 'institutional' from "ClaimType"
    and ClaimCommon."type-oral" ~ Code 'oral' from "ClaimType"
    and ClaimCommon."type-pharmacy" ~ Code 'pharmacy' from "ClaimType"
    and ClaimCommon."type-professional" ~ Code 'professional' from "ClaimType"
    and ClaimCommon."type-vision" ~ Code 'vision' from "ClaimType"

define TestSubTypeDeclarations:
  ClaimCommon."subtype-inpatient" ~ Code 'inpatient' from "C4BBInstitutionalClaimSubType"
    and ClaimCommon."subtype-outpatient" ~ Code 'outpatient' from "C4BBInstitutionalClaimSubType"

define TestSupportingInfoTypeDeclarations:
  ClaimCommon."discharge-status" ~ Code 'discharge-status' from "C4BBSupportingInfoType"
    and ClaimCommon."pointoforigin" ~ Code 'pointoforigin' from "C4BBSupportingInfoType"

define TestDiagnosisRoleDeclarations:
  ClaimCommon."Billing" ~ Code 'billing' from "DiagnosisRole"

// The diagnosis type codes are declared twice, once with a diagnosistype- prefix and once by name
define TestDiagnosisTypeDeclarations:
  ClaimCommon."diagnosistype-principal" ~ Code 'principal' from "DiagnosisType"
    and ClaimCommon."diagnosistype-admitting" ~ Code 'admitting' from "DiagnosisType"
    and ClaimCommon."diagnosistype-discharge" ~ Code 'discharge' from "DiagnosisType"
    and ClaimCommon."Principal Diagnosis" ~ Code 'principal' from "DiagnosisType"
    and ClaimCommon."Admitting Diagnosis" ~ Code 'admitting' from "DiagnosisType"
    and ClaimCommon."Discharge Diagnosis" ~ Code 'discharge' from "DiagnosisType"
    and ClaimCommon."Clinical Diagnosis" ~ Code 'clinical' from "DiagnosisType"
    and ClaimCommon."Differential Diagnosis" ~ Code 'differential' from "DiagnosisType"
    and ClaimCommon."Laboratory Diagnosis" ~ Code 'laboratory' from "DiagnosisType"
    and ClaimCommon."Nursing Diagnosis" ~ Code 'nursing' from "DiagnosisType"
    and ClaimCommon."Prenatal Diagnosis" ~ Code 'prenatal' from "DiagnosisType"
    and ClaimCommon."Radiology Diagnosis" ~ Code 'radiology' from "DiagnosisType"
    and ClaimCommon."Remote Diagnosis" ~ Code 'remote' from "DiagnosisType"
    and ClaimCommon."Retrospective Diagnosis" ~ Code 'retrospective' from "DiagnosisType"
    and ClaimCommon."Self Diagnosis" ~ Code 'self' from "DiagnosisType"

define TestProcedureTypeDeclarations:
  ClaimCommon."proceduretype-primary" ~ Code 'primary' from "ProcedureType"
    and ClaimCommon."proceduretype-secondary" ~ Code 'secondary' from "ProcedureType"
    and ClaimCommon."Primary procedure" ~ Code 'primary' from "ProcedureType"

define TestPresentOnAdmissionDeclarations:
  ClaimCommon."POA-Y" ~ Code 'Y' from "POA"
    and ClaimCommon."POA-N" ~ Code 'N' from "POA"
    and ClaimCommon."POA-W" ~ Code 'W' from "POA"
    and ClaimCommon."POA-1" ~ Code '1' from "POA"
    and ClaimCommon."POA-U" ~ Code 'U' from "POA"

/*
 * Value sets
 */

define TestPresentOnAdmissionOrClinicallyUndetermined:
  Code 'Y' from "POA" in ClaimCommon."Present on Admission or Clinically Undetermined"
    and Code 'W' from "POA" in ClaimCommon."Present on Admission or Clinically Undetermined"
    and not (Code 'N' from "POA" in ClaimCommon."Present on Admission or Clinically Undetermined")
    and not (Code 'U' from "POA" in ClaimCommon."Present on Admission or Clinically Undetermined")

/*
 * Claim status
 */

define TestClaimIsActive:
  "Active Institutional Claim".isActive()
    and not "Cancelled Claim".isActive()
    and not "Draft Claim".isActive()
    and not "Entered In Error Claim".isActive()

define TestClaimIsActiveNoStatus:
  not "Claim Without Status Or Use".isActive()

define TestClaimActive:
  "Has Ids"(
    "All Claims".active(),
    { 'active-institutional', 'active-professional', 'preauthorization', 'predetermination' }
  )

define TestClaimActiveEmpty:
  not exists (List<FHIR.Claim>{}).active()

define TestClaimIsCancelled:
  "Cancelled Claim".isCancelled()
    and not "Active Institutional Claim".isCancelled()
    and not "Claim Without Status Or Use".isCancelled()

define TestClaimIsDraft:
  "Draft Claim".isDraft()
    and not "Active Institutional Claim".isDraft()
    and not "Claim Without Status Or Use".isDraft()

define TestClaimIsEnteredInError:
  "Entered In Error Claim".isEnteredInError()
    and not "Active Institutional Claim".isEnteredInError()
    and not "Claim Without Status Or Use".isEnteredInError()

/*
 * Claim use
 */

define TestClaimIsClaim:
  "Active Institutional Claim".isClaim()
    and not "Preauthorization Claim".isClaim()
    and not "Predetermination Claim".isClaim()
    and not "Claim Without Status Or Use".isClaim()

define TestClaimClaims:
  "Has Ids"(
    "All Claims".claims(),
    { 'active-institutional', 'active-professional', 'cancelled', 'draft', 'entered-in-error' }
  )

define TestClaimIsPreauthorization:
  "Preauthorization Claim".isPreauthorization()
    and not "Active Institutional Claim".isPreauthorization()
    and not "Predetermination Claim".isPreauthorization()

define TestClaimIsPredetermination:
  "Predetermination Claim".isPredetermination()
    and not "Active Institutional Claim".isPredetermination()
    and not "Preauthorization Claim".isPredetermination()

/*
 * Claim type
 */

define TestClaimIsInstitutional:
  "Active Institutional Claim".isInstitutional()
    and not "Active Professional Claim".isInstitutional()
    and not "Claim Without Status Or Use".isInstitutional()

define TestClaimIsInstitutionalWrongSystem:
  not "Test Claim"('wrong-system', 'active', 'claim', Code 'institutional' from "Example Codes", null).isInstitutional()

// A type is matched by any of its codings
define TestClaimIsInstitutionalMatchesAnyCoding:
  (FHIR.Claim {
    id: Build.id('two-codings'),
    status: FHIR.ClaimStatus { value: 'active' },
    use: FHIR.Use { value: 'claim' },
    type: Build.CodeableConcept(Concept { Code '13' from "Example Codes", Code 'institutional' from "ClaimType" })
  }).isInstitutional()

define TestClaimInstitutional:
  "Has Ids"("All Claims".institutional(), { 'active-institutional', 'cancelled' })

define TestClaimIsProfessional:
  "Active Professional Claim".isProfessional()
    and not "Active Institutional Claim".isProfessional()

define TestClaimProfessional:
  "Has Ids"("All Claims".professional(), { 'active-professional', 'draft' })

define TestClaimIsPharmacy:
  "Entered In Error Claim".isPharmacy()
    and not "Active Institutional Claim".isPharmacy()

define TestClaimIsOral:
  "Preauthorization Claim".isOral()
    and not "Active Institutional Claim".isOral()

define TestClaimIsVision:
  "Predetermination Claim".isVision()
    and not "Active Institutional Claim".isVision()

/*
 * ExplanationOfBenefit status
 */

define TestEOBIsActive:
  "Active Institutional EOB".isActive()
    and not "Cancelled EOB".isActive()
    and not "Draft EOB".isActive()
    and not "Entered In Error EOB".isActive()
    and not "EOB Without Status Or Use".isActive()

define TestEOBActive:
  "Has Ids"(
    "All EOBs".active(),
    { 'active-institutional', 'active-professional', 'preauthorization', 'predetermination' }
  )

define TestEOBIsCancelled:
  "Cancelled EOB".isCancelled()
    and not "Active Institutional EOB".isCancelled()

define TestEOBIsDraft:
  "Draft EOB".isDraft()
    and not "Active Institutional EOB".isDraft()

define TestEOBIsEnteredInError:
  "Entered In Error EOB".isEnteredInError()
    and not "Active Institutional EOB".isEnteredInError()

/*
 * ExplanationOfBenefit use
 */

define TestEOBIsClaim:
  "Active Institutional EOB".isClaim()
    and not "Preauthorization EOB".isClaim()
    and not "Predetermination EOB".isClaim()
    and not "EOB Without Status Or Use".isClaim()

define TestEOBClaims:
  "Has Ids"(
    "All EOBs".claims(),
    { 'active-institutional', 'active-professional', 'cancelled', 'draft', 'entered-in-error' }
  )

define TestEOBIsPreauthorization:
  "Preauthorization EOB".isPreauthorization()
    and not "Active Institutional EOB".isPreauthorization()

define TestEOBIsPredetermination:
  "Predetermination EOB".isPredetermination()
    and not "Active Institutional EOB".isPredetermination()

/*
 * ExplanationOfBenefit type
 */

define TestEOBIsInstitutional:
  "Active Institutional EOB".isInstitutional()
    and not "Active Professional EOB".isInstitutional()
    and not "EOB Without Status Or Use".isInstitutional()

define TestEOBInstitutional:
  "Has Ids"("All EOBs".institutional(), { 'active-institutional', 'cancelled' })

define TestEOBIsProfessional:
  "Active Professional EOB".isProfessional()
    and not "Active Institutional EOB".isProfessional()

define TestEOBProfessional:
  "Has Ids"("All EOBs".professional(), { 'active-professional', 'draft' })

define TestEOBIsPharmacy:
  "Entered In Error EOB".isPharmacy()
    and not "Active Institutional EOB".isPharmacy()

define TestEOBIsOral:
  "Preauthorization EOB".isOral()
    and not "Active Institutional EOB".isOral()

define TestEOBIsVision:
  "Predetermination EOB".isVision()
    and not "Active Institutional EOB".isVision()

/*
 * Claim supporting information
 */

define TestDischargeStatus:
  "Claim With Discharge Status And Point Of Origin".dischargeStatus() ~ Build.CodeableConcept("Discharged Home")

define TestDischargeStatusMissing:
  "Claim With Supporting Info"({ "Supporting Info"(1, Code 'pointoforigin' from "C4BBSupportingInfoType", "Transfer From Hospital") })
    .dischargeStatus() is null

define TestDischargeStatusNoSupportingInfo:
  "Active Institutional Claim".dischargeStatus() is null

define TestDischargeStatusWrongSystem:
  "Claim With Supporting Info"({ "Supporting Info"(1, Code 'discharge-status' from "Example Codes", "Discharged Home") })
    .dischargeStatus() is null

define TestPointOfOrigin:
  "Claim With Discharge Status And Point Of Origin".pointOfOrigin() ~ Build.CodeableConcept("Transfer From Hospital")

define TestPointOfOriginMissing:
  "Claim With Supporting Info"({ "Supporting Info"(1, Code 'discharge-status' from "C4BBSupportingInfoType", "Discharged Home") })
    .pointOfOrigin() is null

define TestPointOfOriginNoSupportingInfo:
  "Active Institutional Claim".pointOfOrigin() is null

/*
 * Claim diagnosis and procedure type
 */

define TestIsPrincipalDiagnosis:
  "Principal Type".isPrincipalDiagnosis()
    and "Principal And Admitting Types".isPrincipalDiagnosis()
    and not "Admitting Type".isPrincipalDiagnosis()

define TestIsPrincipalDiagnosisWrongSystem:
  not "Principal Type Wrong System".isPrincipalDiagnosis()

define TestIsPrincipalDiagnosisNoTypes:
  not "No Types".isPrincipalDiagnosis()

define TestIsAdmittingDiagnosis:
  "Admitting Type".isAdmittingDiagnosis()
    and "Principal And Admitting Types".isAdmittingDiagnosis()
    and not "Principal Type".isAdmittingDiagnosis()
    and not "No Types".isAdmittingDiagnosis()

define TestIsPrimaryProcedure:
  "Primary Procedure Type".isPrimaryProcedure()
    and not "Secondary Procedure Type".isPrimaryProcedure()
    and not "No Types".isPrimaryProcedure()

define TestIsSecondaryProcedure:
  "Secondary Procedure Type".isSecondaryProcedure()
    and not "Primary Procedure Type".isSecondaryProcedure()
    and not "No Types".isSecondaryProcedure()

/*
 * Institutional claim subtype (US Realm)
 */

define TestClaimIsInpatient:
  "Active Institutional Claim".isInpatient()
    and not "Cancelled Claim".isInpatient()
    and not "Active Professional Claim".isInpatient()

define TestClaimInpatient:
  "Has Ids"("All Claims".inpatient(), { 'active-institutional' })

define TestClaimIsOutpatient:
  "Cancelled Claim".isOutpatient()
    and not "Active Institutional Claim".isOutpatient()
    and not "Active Professional Claim".isOutpatient()

define TestClaimOutpatient:
  "Has Ids"("All Claims".outpatient(), { 'cancelled' })

define TestEOBIsInpatient:
  "Active Institutional EOB".isInpatient()
    and not "Cancelled EOB".isInpatient()
    and not "Active Professional EOB".isInpatient()

define TestEOBInpatient:
  "Has Ids"("All EOBs".inpatient(), { 'active-institutional' })

define TestEOBIsOutpatient:
  "Cancelled EOB".isOutpatient()
    and not "Active Institutional EOB".isOutpatient()

define TestEOBOutpatient:
  "Has Ids"("All EOBs".outpatient(), { 'cancelled' })

/*
 * toServicedInterval
 */

// A serviced date is a day-precision interval of DateTime
define TestToServicedIntervalDate:
  Build.date(@2024-03-01).toServicedInterval() = Interval[ToDateTime(@2024-03-01), ToDateTime(@2024-03-01)]

// The date is converted with the timezone offset of the evaluation, so the boundaries are kept at least a
// day clear of it in any timezone
define TestToServicedIntervalDateDuringDay:
  Build.date(@2024-03-01).toServicedInterval() during Interval[@2024-02-28T00:00:00.000Z, @2024-03-03T00:00:00.000Z]

// A boundary with a time on the same day as the date can't be compared at day precision, so whether the
// date is during the interval is unknown. 2024-03-01T12:00Z is on 2024-03-01 in every timezone.
define TestToServicedIntervalDateDuringSameDayBoundary:
  (Build.date(@2024-03-01).toServicedInterval() during Interval[@2024-03-01T12:00:00.000Z, @2024-03-03T00:00:00.000Z]) is null

define TestToServicedIntervalPeriod:
  Build.Period(Interval[@2024-03-01T08:00:00.000Z, @2024-03-05T10:00:00.000Z]).toServicedInterval()
    = Interval[@2024-03-01T08:00:00.000Z, @2024-03-05T10:00:00.000Z]

define TestToServicedIntervalPeriodNoEnd:
  start of Build.Period(Interval[@2024-03-01T08:00:00.000Z, null as DateTime]).toServicedInterval() = @2024-03-01T08:00:00.000Z
    and Build.Period(Interval[@2024-03-01T08:00:00.000Z, null as DateTime]).toServicedInterval().high is null

define TestToServicedIntervalNull:
  (null as Choice<FHIR.date, FHIR.Period>).toServicedInterval() is null

/*
 * Profiles
 *
 * Invariants: the FHIR-typed functions resolve for US Quality Core claims, and agree with the elements
 * they test.
 */

define TestProfileClaimStatus:
  AllTrue([USQualityCore.Claim] C return C.isActive() implies C.status = 'active')
    and Count(([USQualityCore.Claim]).active()) = Count([USQualityCore.Claim] C where C.status = 'active')

define TestProfileClaimUse:
  AllTrue([USQualityCore.Claim] C return C.isClaim() implies C.use = 'claim')
    and Count(([USQualityCore.Claim]).claims()) = Count([USQualityCore.Claim] C where C.use = 'claim')

define TestProfileClaimType:
  AllTrue([USQualityCore.Claim] C return not (C.isInstitutional() and C.isProfessional()))
    and AllTrue([USQualityCore.Claim] C return not (C.isInpatient() and C.isOutpatient()))

/*
 * Combined result
 */

// True only if every test in this library is true, for use as the population criteria of a Cohort
// measure. It uses `and` rather than AllTrue(), which ignores nulls, so that a null test fails it.
// It must list each Test define; .claude/skills/cql/check_results.py checks this.
define _Passed:
  TestClaimStatusDeclarations
    and TestExplanationOfBenefitStatusDeclarations
    and TestUseDeclarations
    and TestTypeDeclarations
    and TestSubTypeDeclarations
    and TestSupportingInfoTypeDeclarations
    and TestDiagnosisRoleDeclarations
    and TestDiagnosisTypeDeclarations
    and TestProcedureTypeDeclarations
    and TestPresentOnAdmissionDeclarations
    and TestPresentOnAdmissionOrClinicallyUndetermined
    and TestClaimIsActive
    and TestClaimIsActiveNoStatus
    and TestClaimActive
    and TestClaimActiveEmpty
    and TestClaimIsCancelled
    and TestClaimIsDraft
    and TestClaimIsEnteredInError
    and TestClaimIsClaim
    and TestClaimClaims
    and TestClaimIsPreauthorization
    and TestClaimIsPredetermination
    and TestClaimIsInstitutional
    and TestClaimIsInstitutionalWrongSystem
    and TestClaimIsInstitutionalMatchesAnyCoding
    and TestClaimInstitutional
    and TestClaimIsProfessional
    and TestClaimProfessional
    and TestClaimIsPharmacy
    and TestClaimIsOral
    and TestClaimIsVision
    and TestEOBIsActive
    and TestEOBActive
    and TestEOBIsCancelled
    and TestEOBIsDraft
    and TestEOBIsEnteredInError
    and TestEOBIsClaim
    and TestEOBClaims
    and TestEOBIsPreauthorization
    and TestEOBIsPredetermination
    and TestEOBIsInstitutional
    and TestEOBInstitutional
    and TestEOBIsProfessional
    and TestEOBProfessional
    and TestEOBIsPharmacy
    and TestEOBIsOral
    and TestEOBIsVision
    and TestDischargeStatus
    and TestDischargeStatusMissing
    and TestDischargeStatusNoSupportingInfo
    and TestDischargeStatusWrongSystem
    and TestPointOfOrigin
    and TestPointOfOriginMissing
    and TestPointOfOriginNoSupportingInfo
    and TestIsPrincipalDiagnosis
    and TestIsPrincipalDiagnosisWrongSystem
    and TestIsPrincipalDiagnosisNoTypes
    and TestIsAdmittingDiagnosis
    and TestIsPrimaryProcedure
    and TestIsSecondaryProcedure
    and TestClaimIsInpatient
    and TestClaimInpatient
    and TestClaimIsOutpatient
    and TestClaimOutpatient
    and TestEOBIsInpatient
    and TestEOBInpatient
    and TestEOBIsOutpatient
    and TestEOBOutpatient
    and TestToServicedIntervalDate
    and TestToServicedIntervalDateDuringDay
    and TestToServicedIntervalDateDuringSameDayBoundary
    and TestToServicedIntervalPeriod
    and TestToServicedIntervalPeriodNoEnd
    and TestToServicedIntervalNull
    and TestProfileClaimStatus
    and TestProfileClaimUse
    and TestProfileClaimType

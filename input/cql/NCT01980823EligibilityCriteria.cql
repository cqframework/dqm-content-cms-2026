library NCT01980823EligibilityCriteria version '1.0.0'

using FHIR version '4.0.1'

include hl7.fhir.uv.cql.FHIRHelpers version '4.0.1' called FHIRHelpers
include hl7.fhir.uv.cql.FHIRCommon version '2.0.0' called FHIRCommon

codesystem "SNOMED-CT": 'http://snomed.info/sct'
codesystem "LOINC": 'http://loinc.org'

// --- VALUESETS ---

valueset "Chemotherapy or Radiation or Breast Resection Codes":
  'https://example.org/fhir/ValueSet/chemo-radiation-breast-resection'

valueset "Diabetes or Hypercholesterolemia Medications":
  'https://example.org/fhir/ValueSet/diabetes-hypercholesterolemia-medications'

valueset "Strong CYP3A4 Inhibitor Medications":
  'https://example.org/fhir/ValueSet/strong-cyp3a4-inhibitors'

valueset "Serum creatinine":
  'https://example.org/fhir/ValueSet/serum-creatinine'
  //'https://vsac.nlm.nih.gov/valueset/2.16.840.1.113883.3.526.3.1139'

valueset "AST":
  'https://example.org/fhir/ValueSet/ast-lab-tests'

valueset "ALT":
  'https://example.org/fhir/ValueSet/alt-lab-tests'

valueset "Total Bilirubin":
  'https://example.org/fhir/ValueSet/total-bilirubin'

valueset "Alkaline Phosphatase":
  'https://example.org/fhir/ValueSet/alkaline-phosphatase'

valueset "Core needle biopsy":
  'https://example.org/fhir/ValueSet/core-needle-biopsy'

valueset "Histologic test":
  'https://example.org/fhir/ValueSet/histologic-test'

valueset "Tumor Size Observations":
  'https://example.org/fhir/ValueSet/tumor-size-observations'

 
// --- CODES ---

code "Female": '248152002' from "SNOMED-CT" display 'Female (finding)'
code "Carcinoma of breast": '254838004' from "SNOMED-CT" display 'Carcinoma of breast'
code "ECOG Performance Status": '89247-1' from "LOINC" display 'ECOG Performance Status score'
code "Informed consent given": '203031000000107' from "SNOMED-CT" display 'Informed consent given'
code "Entered into drug clinical trial": '713670002' from "SNOMED-CT" display 'Entered into drug clinical trial'

// --- CONTEXT ---

context Patient

// ===========================
// INCLUSION CRITERIA
// ===========================

// 1. Female
define "Is Female":
  Patient.gender = 'female'

// 2. Histologically confirmed invasive breast cancer or DCIS
define "Has Histologically Confirmed Breast Cancer or DCIS":
  exists (
    [Condition: "Carcinoma of breast"] C
      where C.verificationStatus ~ FHIRCommon."confirmed"
        and exists (
          C.evidence E
            where E.code in "Histologic test"
        )
  )

// 3. Operable tumor with core needle biopsy followed by surgical excision >= 2 weeks after enrollment
define "Has Operable Tumor With Planned Surgical Excision":
  exists (
    [Procedure: "Core needle biopsy"] P
      where P.status = 'completed'
  )
  // Surgical excision timing (>= 2 weeks post-enrollment) assumed tracked externally

// 4. Tumor size >= 5 mm by imaging or pathology
define "Tumor Size At Least 5mm":
  exists (
    [Observation: "Tumor Size Observations"] O
      where O.status in { 'final', 'amended' }
        and (O.value as FHIR.Quantity) >= 5 'mm'
  )

// 5. Age >= 21 years
define "Is At Least 21 Years Old":
  AgeInYears() >= 21

// 6. No prior chemo, radiation, or breast resection within 6 months of study entry
define "No Prior Treatment Within 6 Months":
  not exists (
    [Procedure] P
      where P.status = 'completed'
        and P.code in "Chemotherapy or Radiation or Breast Resection Codes"
        and P.performed.toInterval() ends 6 months or less before Today()
  )

// 7. ECOG Performance Status 0-1
define "Has Acceptable ECOG Status":
  exists (
    [Observation: "ECOG Performance Status"] O
      where O.status in { 'final', 'amended' }
        and (O.value as FHIR.integer) in Interval[0, 1]
  )

// 8. Signed informed consent
define "Has Signed Informed Consent":
  exists (
    [Consent] C
      where C.status = 'active'
  )

// ===========================
// EXCLUSION CRITERIA
// ===========================

// 9. Currently on medication for diabetes or hypercholesterolemia
define "On Diabetes Or Hypercholesterolemia Medication":
  exists (
    [MedicationRequest] M
      where M.status = 'active'
        and M.medication in "Diabetes or Hypercholesterolemia Medications"
  )

// 10. Treatment with investigational drugs within 6 months
define "On Investigational Drug Within 6 Months":
  exists (
    [Observation: "Entered into drug clinical trial"] O
      where O.effective ends 6 months or less before Today()
  )

// 11. Strong CYP3A4 inhibitor use (e.g. clarithromycin, HIV protease inhibitors, itraconazole)
define "On Strong CYP3A4 Inhibitor":
  exists (
    [MedicationRequest] M
      where M.status = 'active'
        and M.medication in "Strong CYP3A4 Inhibitor Medications"
  )

// 12. Renal impairment: creatinine > 1.4 mg/dL
define "Has Renal Impairment":
  exists (
    [Observation: "Serum creatinine"] O
      where O.status in { 'final', 'amended' }
        and (O.value as FHIR.Quantity) > 1.4 'mg/dL'
  )

// TODO: Define Gilberts Syndrome
define "Has Gilberts Syndrome":
  false

define fluent function "Upper Limit of Normal"(O Observation):
  if exists(O.referenceRange) then
    O.referenceRange[0].high
  else
    null

// 13. Hepatic impairment
define "Has Hepatic Impairment":
  exists (
    [Observation: "AST"] O
      where (O.value as FHIR.Quantity) >= 2.5 * O."Upper Limit of Normal"()
  )
  or exists (
    [Observation: "ALT"] O
      where (O.value as FHIR.Quantity) >= 2.5 * O."Upper Limit of Normal"()
  )
  or exists (
    [Observation: "Total Bilirubin"] O
      where (O.value as FHIR.Quantity) >= 1.5 * O."Upper Limit of Normal"()
        and not "Has Gilberts Syndrome"
  )
  or exists (
    [Observation: "Alkaline Phosphatase"] O
      where (O.value as FHIR.Quantity) > 2.5 * O."Upper Limit of Normal"()
  )

// ===========================
// COMPOSITE ELIGIBILITY
// ===========================

define "Meets Inclusion Criteria":
  "Is Female"
    and "Has Histologically Confirmed Breast Cancer or DCIS"
    and "Has Operable Tumor With Planned Surgical Excision"
    and "Tumor Size At Least 5mm"
    and "Is At Least 21 Years Old"
    and "No Prior Treatment Within 6 Months"
    and "Has Acceptable ECOG Status"
    and "Has Signed Informed Consent"

define "Meets Exclusion Criteria":
  "On Diabetes Or Hypercholesterolemia Medication"
    or "On Investigational Drug Within 6 Months"
    or "On Strong CYP3A4 Inhibitor"
    or "Has Renal Impairment"
    or "Has Hepatic Impairment"

define "Is Eligible":
  "Meets Inclusion Criteria"
    and not "Meets Exclusion Criteria"
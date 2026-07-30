# HOB Test Cases Specification

## Overview

This document specifies all test cases for the HOB (Hospital-Onset Bacteremia & Fungemia) protocol, supporting the NHSN HOB Surveillance Metrics.

**Measurement Period**: January 1, 2025 to January 31, 2025
**CQL Module**: `NHSNAcuteCareHospitalMonthlyInitialPopulation1`
**HOB Definition**: Blood culture positive on hospital day 4+ (admission = day 1)

---

## NHSN HOB Surveillance Metrics Coverage

| Metric | Description | Positive Test | Negative Test |
|--------|-------------|---------------|---------------|
| HOB Event | Pathogenic bacteria/fungi on day 4+ | 1, 2, 4, 9, 10 | 3, 11 |
| Blood Culture Contamination | 1 of 2 sets positive for skin commensal | 5 | 6 |
| Matching Commensal HOB | Skin commensal + ≥4 days antibiotics | 7 | 8 |
| Non-Measure HOB | HOB in patient with non-preventability conditions | 9 | 10 |
| Species Code Matching | Same species with different SNOMED codes (base vs. phenotype) | - | 11 |

---

## Test Case 1: HOB Positive - Day 4 S. aureus

**File**: `HOBPositiveDay4SAureus.json`

**Scenario**: Basic HOB positive event with pathogenic organism on hospital day 4

**Purpose**: Validates primary HOB Event metric - blood culture positive on day 4+

**Clinical Narrative**:
> Patient Day4SAureus HOBPositive is a 55-year-old male admitted to the Trauma Critical Care unit on January 2, 2025 following a motor vehicle accident with multiple injuries requiring surgical intervention.
>
> **Hospital Course:**
> - **Day 1-3:** Patient was hemodynamically stable post-surgery. Received standard post-operative care with routine vital signs, admission labs (CBC, BMP), and chest X-ray. Daily nursing assessments documented pain management and fall risk.
> - **Day 4:** Patient developed fever (38.5°C) and tachycardia. Blood cultures were drawn due to concern for hospital-acquired infection.
> - **Day 5:** Blood culture returned positive for **Staphylococcus aureus**. Infectious disease consulted. Vancomycin initiated.
> - **Discharge:** Patient completed antibiotic course and was discharged in stable condition.
>
> **HOB Event:** Blood culture positive for S. aureus on hospital day 4 meets HOB criteria (pathogenic organism on day 4+).

| Resource | ID | Details |
|----------|-----|---------|
| Practitioner | 6cd148c3-2118-5e5c-9ed5-9111c773a579 | Practitioner GeneralPractitioner |
| Patient | 1c61d5db-b65e-5f83-8d39-724c16487e20 | Day4SAureus HOBPositive, male, DOB 1970-01-15 |
| Location | a4d059ac-4219-5a60-888d-b53d054fc894 | HSLOC 1025-6 (Trauma Critical Care) |
| Encounter | 63d1ed3e-9eb7-510c-a458-b4a120190d7d | Admit 2025-01-02, class=IMP, status=finished |
| Coverage | deb3455e-31d2-57f4-8f33-26c06214c4d3 | Coverage 2025-01-01T00:00:00.000Z to 2025-12-31T23:59:59.000Z |
| Practitioner | aaa0baa6-32b0-5818-bd20-d52db59bb7a4 | Practitioner Ordering |
| ServiceRequest | 96613011-516d-55b5-a3da-52f65e0ea874 | Bacteria identified in Blood by Culture, authored 2025-01-05T09:00 |
| Specimen | 7646ad0c-c21a-5022-9fdc-c530c36c25ec | Blood specimen, collected 2025-01-05T10:00 |
| Observation | 3a292731-3866-5342-ae4f-9f45b3446087 | Bacteria identified in Blood by Culture, 2025-01-05T10:00, Staphylococcus aureus |
| MeasureReport | d91d2058-bd6d-5394-9750-4a6f7bb9e4ac | MeasureReport |

**Expected Outcome**:
- Initial Population: 1
- HOB Event: **Positive** (pathogenic organism on day 4)

---

## Test Case 2: HOB Positive - Day 5 Candida (Fungemia)

**File**: `HOBPositiveDay5Candida.json`

**Scenario**: HOB positive event with fungal organism (fungemia)

**Purpose**: Validates HOB Event metric includes fungemia

**Clinical Narrative**:
> Patient Day5Candida HOBPositive is a 59-year-old female admitted to the Trauma Critical Care unit on January 3, 2025 with severe abdominal sepsis requiring emergency surgery and prolonged ICU stay.
>
> **Hospital Course:**
> - **Day 1-4:** Patient underwent exploratory laparotomy. Required central venous catheter for TPN and vasopressor support. Broad-spectrum antibiotics initiated.
> - **Day 5:** Despite antibiotic therapy, patient remained febrile with new onset hypotension. Blood cultures obtained.
> - **Day 6:** Blood culture returned positive for **Candida albicans** (fungemia). Central line removed. Antifungal therapy (micafungin) initiated.
> - **Discharge:** Patient completed antifungal course with clinical improvement and was discharged to rehabilitation.
>
> **HOB Event:** Blood culture positive for Candida albicans on hospital day 5 meets HOB criteria (fungal pathogen on day 4+).

| Resource | ID | Details |
|----------|-----|---------|
| Practitioner | 716ff809-54a5-53db-9f3c-81ec356aea1a | Practitioner GeneralPractitioner |
| Patient | 776c8ddf-fe3a-59a6-96bb-bfd5ee465418 | Day5Candida HOBPositive, female, DOB 1965-06-20 |
| Location | e25de16f-ef53-57d0-ada0-55d106f78f33 | HSLOC 1025-6 (Trauma Critical Care) |
| Encounter | b9c07caf-78d0-551c-89bd-7203a11da61e | Admit 2025-01-03, class=IMP, status=finished |
| Coverage | 95a355d2-87f0-5e3c-a710-d52708835435 | Coverage 2025-01-01T00:00:00.000Z to 2025-12-31T23:59:59.000Z |
| Practitioner | d01113cb-9c5e-57bb-a641-1d74e9381c45 | Practitioner Ordering |
| ServiceRequest | 61aac911-a013-5e8e-bfd5-183ce5d39079 | Bacteria identified in Blood by Culture, authored 2025-01-07T08:00 |
| Specimen | 97f73dfa-8d8a-53fd-b7fb-405d810c041e | Blood specimen, collected 2025-01-07T09:00 |
| Observation | 1262c092-b744-5500-bf93-71e1474cf84c | Bacteria identified in Blood by Culture, 2025-01-07T09:00, Candida albicans |
| MeasureReport | a6e90085-2cbc-55e8-9215-100e2fa24a77 | MeasureReport |

**Expected Outcome**:
- Initial Population: 1
- HOB Event: **Positive** (fungemia qualifies as HOB)

---

## Test Case 3: HOB Excluded - Matching COB Organism

**File**: `HOBExcludedMatchingCOB.json`

**Scenario**: Same organism on COB (day 2) and potential HOB (day 5) - excluded

**Purpose**: Validates HOB exclusion when organism matches prior COB event

**Clinical Narrative**:
> Patient MatchingCOB HOBExcluded is a 44-year-old male admitted to the Trauma Critical Care unit on January 2, 2025 with community-acquired pneumonia and sepsis.
>
> **Hospital Course:**
> - **Day 2 (COB Event):** Patient presented with fever, productive cough, and hypotension. Blood cultures drawn in ED returned positive for **Escherichia coli** bacteremia (Community-Onset Bacteremia). IV antibiotics initiated.
> - **Day 3-4:** Patient showed initial improvement on antibiotics. Remained hospitalized for IV antibiotic completion.
> - **Day 5:** Routine surveillance blood cultures obtained. Again positive for **E. coli** (same organism as day 2 COB).
> - **Discharge:** Patient completed antibiotic course and was discharged with improvement.
>
> **HOB Exclusion:** Although blood culture positive on day 5 (hospital day 4+), this is **excluded as HOB** because the same organism (E. coli) was already identified in a prior Community-Onset Bacteremia event on day 2.

| Resource | ID | Details |
|----------|-----|---------|
| Practitioner | 5ccd63d8-4822-5f0a-bffd-1917ab5e6503 | Practitioner GeneralPractitioner |
| Patient | 7c63c129-61ff-50fe-b682-50925fb6659f | MatchingCOB HOBExcluded, male, DOB 1980-03-10 |
| Location | 5892a632-f03d-5afd-b3e3-3c1c065bf01e | HSLOC 1025-6 (Trauma Critical Care) |
| Encounter | a14b53b4-5de1-5ca2-9578-41db66491222 | Admit 2025-01-02, class=IMP, status=finished |
| Coverage | a2e473b4-98de-5c4f-b11d-3c82692badac | Coverage 2025-01-01T00:00:00.000Z to 2025-12-31T23:59:59.000Z |
| Practitioner | 0ab760d6-e015-50b3-971d-5f2371580ae3 | Practitioner Ordering |
| ServiceRequest | 677686d0-f932-5c5f-b8ff-aa54dd80361d | Bacteria identified in Blood by Culture, authored 2025-01-03T07:00 |
| Specimen | ca405637-b992-5dc4-ad32-2f90a99fcae4 | Blood specimen, collected 2025-01-03T08:00 |
| Observation | 10947384-6c85-5f92-8a56-4a94c31c0adb | Bacteria identified in Blood by Culture, 2025-01-03T08:00, Escherichia coli |
| Practitioner | ccfb2af7-bdce-59ce-963e-894654a68e07 | Practitioner Ordering |
| ServiceRequest | 3f1563dc-540c-5e5f-8f2c-d486c230eac4 | Bacteria identified in Blood by Culture, authored 2025-01-06T08:00 |
| Specimen | 26ce5e00-b8da-56f9-bde3-bdf0395552d7 | Blood specimen, collected 2025-01-06T09:00 |
| Observation | a1f96346-0704-53bd-9c29-b8ae78e2e40a | Bacteria identified in Blood by Culture, 2025-01-06T09:00, Escherichia coli |
| MeasureReport | 8591eb64-8917-501f-aa13-d7f89e9dccc9 | MeasureReport |

**Expected Outcome**:
- Initial Population: 1
- COB Event: **Positive** (day 2 culture)
- HOB Event: **Excluded** (matches prior COB organism)

---

## Test Case 4: HOB Positive - Non-Matching Prior COB

**File**: `HOBPositiveNonMatchingCOB.json`

**Scenario**: Different organisms on COB (day 2) and HOB (day 5) - HOB qualifies

**Purpose**: Validates HOB counts when organism differs from prior COB

**Clinical Narrative**:
> Patient NonMatchingCOB HOBPositive is a 49-year-old female admitted to the Trauma Critical Care unit on January 2, 2025 with urosepsis and acute kidney injury.
>
> **Hospital Course:**
> - **Day 2 (COB Event):** Patient presented with fever, flank pain, and pyuria. Blood cultures positive for **Escherichia coli** (Community-Onset Bacteremia from urinary source). IV antibiotics started.
> - **Day 3-4:** Patient improved on antibiotics but developed new central line for dialysis access due to worsening renal function.
> - **Day 5:** New fever spike. Blood cultures obtained showed **Staphylococcus aureus** (different organism from day 2 E. coli).
> - **Discharge:** Both infections treated successfully; patient discharged with outpatient dialysis follow-up.
>
> **HOB Event:** Day 5 blood culture positive for S. aureus qualifies as HOB because it is a **different organism** from the prior COB (E. coli). The matching COB exclusion does not apply.

| Resource | ID | Details |
|----------|-----|---------|
| Practitioner | 1c7a1766-f56a-517f-8c89-42f84e5fd1cf | Practitioner GeneralPractitioner |
| Patient | af355530-608c-5297-9d6d-0e18e18244de | NonMatchingCOB HOBPositive, female, DOB 1975-09-25 |
| Location | 1c3df836-e382-53dc-9506-57405bf98681 | HSLOC 1025-6 (Trauma Critical Care) |
| Encounter | 578e778d-bdd0-55d4-8124-fe7970eef36e | Admit 2025-01-02, class=IMP, status=finished |
| Coverage | abfd9893-dd7e-5e5a-92f6-2a81b19a6d10 | Coverage 2025-01-01T00:00:00.000Z to 2025-12-31T23:59:59.000Z |
| Practitioner | 09932750-640a-543c-82e9-cde62caa1e7b | Practitioner Ordering |
| ServiceRequest | 409db263-d20a-53d6-b918-491afdfbbf3e | Bacteria identified in Blood by Culture, authored 2025-01-03T06:00 |
| Specimen | 187ea1cf-0489-5de1-9176-a09563f3d66a | Blood specimen, collected 2025-01-03T07:00 |
| Observation | 1d9df8aa-72ee-550d-ab2a-b39dee2252a6 | Bacteria identified in Blood by Culture, 2025-01-03T07:00, Escherichia coli |
| Practitioner | 646df871-e9cd-5224-83bf-2f40357713b2 | Practitioner Ordering |
| ServiceRequest | 8a4ef897-f2fd-5ef1-adcc-36bd7ab11f21 | Bacteria identified in Blood by Culture, authored 2025-01-06T09:00 |
| Specimen | e17bc081-f708-57d4-b0a9-4a22620119df | Blood specimen, collected 2025-01-06T10:00 |
| Observation | 54e7e8a3-1567-5772-bc10-15084619e1b3 | Bacteria identified in Blood by Culture, 2025-01-06T10:00, Staphylococcus aureus |
| MeasureReport | 7809bf43-716e-5b44-9808-3f5ef69d87cd | MeasureReport |

**Expected Outcome**:
- Initial Population: 1
- COB Event: **Positive** (E. coli on day 2)
- HOB Event: **Positive** (S. aureus on day 5 - different organism)

---

## Test Case 5: Blood Culture Contamination - 1 of 2 Positive

**File**: `HOBContamination1of2Positive.json`

**Scenario**: Paired blood culture sets; only 1 set positive for skin commensal

**Purpose**: Validates Blood Culture Contamination metric numerator

**Clinical Narrative**:
> Patient Contamination1of2 is a 62-year-old male admitted to the Trauma Critical Care unit on January 2, 2025 with community-acquired pneumonia requiring hospitalization.
>
> **Hospital Course:**
> - **Day 1-4:** Patient received standard pneumonia treatment with improvement in respiratory symptoms. Routine vital signs and nursing assessments performed.
> - **Day 5:** Per protocol, paired blood culture sets (2 separate venipunctures) were obtained due to mild temperature elevation.
> - **Day 6:** Results returned: **Set 1: Positive** for *Coagulase-negative staphylococcus* (skin commensal); **Set 2: Negative** (no growth).
> - **Discharge:** Patient completed pneumonia treatment and was discharged. Single positive skin commensal considered contamination.
>
> **Blood Culture Contamination:** Only 1 of 2 paired blood culture sets positive for a skin commensal organism meets criteria for **contamination** (not true bacteremia).

| Resource | ID | Details |
|----------|-----|---------|
| Practitioner | 8a97d1f0-00e9-5369-b919-a8be396eb743 | Practitioner GeneralPractitioner |
| Patient | a968eaa1-0e1f-5eb9-95de-24cafe3b064b | 1of2Positive HOBContamination, male, DOB 1972-11-08 |
| Location | 0fa02f85-2352-55c7-858a-799f1bbe9565 | HSLOC 1025-6 (Trauma Critical Care) |
| Encounter | 39502f60-bf8e-5a00-b736-b52661aa6de4 | Admit 2025-01-02, class=IMP, status=finished |
| Coverage | 97000ba5-cdf8-5628-b582-1eeb480b4124 | Coverage 2025-01-01T00:00:00.000Z to 2025-12-31T23:59:59.000Z |
| Practitioner | 7c0d1f66-997e-5cd9-98f0-f96b258a75b0 | Practitioner Ordering |
| ServiceRequest | 1e01216d-22aa-509c-a8f6-5a367f93ef74 | Bacteria identified in Blood by Culture, authored 2025-01-05T09:00 |
| Specimen | 8179d434-3fd0-5d50-b961-948b836b2b35 | Blood specimen, collected 2025-01-05T10:00 |
| Observation | 1f6c8c62-80e9-5621-bd67-ccee177e512b | Bacteria identified in Blood by Culture, 2025-01-05T10:00, Staphylococcus epidermidis |
| Practitioner | 1302b77c-d57f-5f78-b99c-dd6162e934cf | Practitioner Ordering |
| ServiceRequest | d6dee858-a98b-5e2f-b7e1-5e6281e4a63d | Bacteria identified in Blood by Culture, authored 2025-01-05T09:05 |
| Specimen | b9a91622-ca9b-5c9a-ab1a-fcf24f9eb243 | Blood specimen, collected 2025-01-05T10:05 |
| Observation | 2c69cd87-6e55-50a7-bae4-bc4686f64847 | Bacteria identified in Blood by Culture, 2025-01-05T10:05, No growth |
| MeasureReport | dca6fc80-f7d8-5654-a965-1e4ae972a785 | MeasureReport |

**Expected Outcome**:
- Initial Population: 1
- Blood Culture Contamination: **Yes** (1 of 2 sets positive for skin commensal)
- HOB Event: **Excluded** (skin commensal only, likely contamination)

---

## Test Case 6: Blood Culture - 2 of 2 Positive (NOT Contamination)

**File**: `HOBContamination2of2Positive.json`

**Scenario**: Both paired culture sets positive for same skin commensal

**Purpose**: Validates that 2/2 positive does NOT count as contamination

**Clinical Narrative**:
> Patient 2of2Positive is a 58-year-old female admitted to the Trauma Critical Care unit on January 2, 2025 with central line-associated bloodstream infection suspected.
>
> **Hospital Course:**
> - **Day 1-4:** Patient with existing tunneled catheter for chemotherapy. Developed fever and chills concerning for line infection.
> - **Day 5:** Paired blood culture sets obtained from two separate venipuncture sites.
> - **Day 6:** Results returned: **Both Set 1 AND Set 2 positive** for *Coagulase-negative staphylococcus*.
> - **Treatment:** Central line removed. Vancomycin initiated for true CoNS bacteremia.
> - **Discharge:** Patient completed antibiotic course with clinical improvement.
>
> **NOT Contamination:** When both paired blood culture sets (2 of 2) are positive for the same skin commensal organism, this represents **true bacteremia**, not contamination.

| Resource | ID | Details |
|----------|-----|---------|
| Practitioner | ea26d37a-24b4-5fdd-8d92-eb57d6f18691 | Practitioner GeneralPractitioner |
| Patient | cd473f06-05b2-54fe-a1c1-df10e54d6d56 | 2of2Positive HOBContamination, female, DOB 1980-05-22 |
| Location | 1f9501dc-e5b7-5d09-bd24-e063e0e3491a | HSLOC 1025-6 (Trauma Critical Care) |
| Encounter | 74ab6b05-e189-5dd8-ab2e-e873709545bb | Admit 2025-01-02, class=IMP, status=finished |
| Coverage | fa5304ff-733f-5cea-abd8-c1c3ec916715 | Coverage 2025-01-01T00:00:00.000Z to 2025-12-31T23:59:59.000Z |
| Practitioner | 639a2302-9b32-53fd-b21c-9ce35fe751e7 | Practitioner Ordering |
| ServiceRequest | 6aa52e42-4a31-555c-9cee-f61b068183fd | Bacteria identified in Blood by Culture, authored 2025-01-05T13:00 |
| Specimen | 5d3d6bb2-ae91-5e15-b25f-d019fe38080a | Blood specimen, collected 2025-01-05T14:00 |
| Observation | bc0d01b9-0541-5a46-bf3b-3510b7166b37 | Bacteria identified in Blood by Culture, 2025-01-05T14:00, Staphylococcus epidermidis |
| Practitioner | dd27d4bc-a102-5232-a6af-34df7d82ca26 | Practitioner Ordering |
| ServiceRequest | 4e62e70c-bbd7-5c26-b437-22a2a0b50db0 | Bacteria identified in Blood by Culture, authored 2025-01-05T13:05 |
| Specimen | ccab1ccc-75f1-5650-bc11-d9caeea9f934 | Blood specimen, collected 2025-01-05T14:05 |
| Observation | 56e639f2-9e7a-5794-a8ab-830c8397c1d7 | Bacteria identified in Blood by Culture, 2025-01-05T14:05, Staphylococcus epidermidis |
| MeasureReport | dd368dc3-02ef-56bb-9118-7727dc9fe8a5 | MeasureReport |

**Expected Outcome**:
- Initial Population: 1
- Blood Culture Contamination: **No** (both sets positive = true bacteremia)
- HOB Event: **Excluded** (skin commensal, but may qualify for Matching Commensal)

---

## Test Case 7: Matching Commensal HOB - Positive

**File**: `HOBMatchingCommensalPositive.json`

**Scenario**: Skin commensal from ≥2 blood cultures AND ≥4 days antibiotic treatment

**Purpose**: Validates Matching Commensal HOB Event metric numerator

**Clinical Narrative**:
> Patient CommensalPositive is a 70-year-old male admitted to the Trauma Critical Care unit on January 2, 2025 with prosthetic joint infection requiring IV antibiotics.
>
> **Hospital Course:**
> - **Day 1-3:** Patient with infected knee prosthesis. IV vancomycin initiated for empiric Gram-positive coverage.
> - **Day 5:** Developed new fever. Blood cultures obtained from 2 separate sites.
> - **Day 6:** Both blood culture sets returned positive for **Coagulase-negative staphylococcus** (skin commensal from ≥2 cultures).
> - **Day 5-12:** Patient received **≥4 qualifying antibiotic days (QADs)** of vancomycin for treatment.
> - **Discharge:** Patient completed antibiotic course with plan for surgical revision.
>
> **Matching Commensal HOB:** Skin commensal organism from ≥2 blood cultures PLUS ≥4 days of antibiotic treatment meets criteria for **Matching Commensal HOB** (true infection, not contamination).

| Resource | ID | Details |
|----------|-----|---------|
| Practitioner | 0a6d6e9b-acab-53ce-a966-1f8a15d49fc2 | Practitioner GeneralPractitioner |
| Patient | 61969c09-6113-5527-b8a2-7b716d398cc1 | Positive HOBMatchingCommensal, female, DOB 1965-03-20 |
| Location | bb193063-cbf7-5d79-a0b5-639ffe54df36 | HSLOC 1025-6 (Trauma Critical Care) |
| Encounter | 923ee9d7-6745-582d-85a2-0e3d6d27ac14 | Admit 2025-01-02, class=IMP, status=finished |
| Coverage | 7ec21311-3f3a-5734-b35b-10928a6563ea | Coverage 2025-01-01T00:00:00.000Z to 2025-12-31T23:59:59.000Z |
| Practitioner | 87f516df-2ee1-541d-9d1d-2bc760b22b54 | Practitioner Ordering |
| ServiceRequest | 1d214d29-4dc5-5883-b3a9-c823be626591 | Bacteria identified in Blood by Culture, authored 2025-01-06T09:00 |
| Specimen | 6884ce4f-78cb-5694-ba8e-2885738b685b | Blood specimen, collected 2025-01-06T10:00 |
| Observation | 03f3919a-4c91-5d90-803e-df5184d45b22 | Bacteria identified in Blood by Culture, 2025-01-06T10:00, Staphylococcus epidermidis |
| Practitioner | f43efb6b-cf85-5142-9cd9-5ea270898110 | Practitioner Ordering |
| ServiceRequest | 405421b9-424b-5207-acd6-d77b5080cf6f | Bacteria identified in Blood by Culture, authored 2025-01-08T13:00 |
| Specimen | 8afc8b8e-6205-5bdb-9bfc-dbde5db375bf | Blood specimen, collected 2025-01-08T14:00 |
| Observation | 3b73dd53-899a-5331-9edd-a67199ce51ac | Bacteria identified in Blood by Culture, 2025-01-08T14:00, Staphylococcus epidermidis |
| Medication | eca341ce-5b65-5c3e-bca4-10efe96515fe | Vancomycin 1000 MG Injection |
| Practitioner | b24a9acf-5216-5549-9a3c-0033d288f4dd | Practitioner Prescriber |
| MedicationRequest | cab9cd3e-76c4-5420-9e51-00c815fed7df | Order authored 2025-01-06T11:00 |
| Practitioner | c4be8372-731a-5b0b-b817-da01860ceade | Practitioner Nurse |
| MedicationAdministration | b5aa9109-193c-5704-b2d8-7bc0a5952be2 | Admin 2025-01-06 to 2025-01-10 |
| MeasureReport | a72538d3-a8df-50ec-a683-b6a2a1dec8e5 | MeasureReport |

**Expected Outcome**:
- Initial Population: 1
- Matching Commensal HOB: **Positive** (≥2 cultures + ≥4 days antibiotics)
- Standard HOB Event: **Excluded** (skin commensal)

---

## Test Case 8: Matching Commensal HOB - Insufficient Antibiotics

**File**: `HOBMatchingCommensalInsufficientAbx.json`

**Scenario**: Skin commensal from ≥2 cultures but <4 days antibiotics

**Purpose**: Validates exclusion from Matching Commensal when treatment threshold not met

**Clinical Narrative**:
> Patient InsufficientAbx is a 65-year-old female admitted to the Trauma Critical Care unit on January 2, 2025 with cellulitis and possible bacteremia.
>
> **Hospital Course:**
> - **Day 1-4:** Patient with lower extremity cellulitis. Blood cultures obtained on admission.
> - **Day 5:** Surveillance blood cultures obtained. Both sets positive for **Coagulase-negative staphylococcus**.
> - **Day 5-7:** Patient received only **3 days** of vancomycin before clinical improvement led to early antibiotic discontinuation.
> - **Discharge:** Patient discharged with oral antibiotics for cellulitis. CoNS bacteremia felt to be contamination given rapid improvement.
>
> **NOT Matching Commensal HOB:** Although skin commensal was isolated from ≥2 blood cultures, patient received **<4 qualifying antibiotic days**. Does not meet Matching Commensal HOB criteria.

| Resource | ID | Details |
|----------|-----|---------|
| Practitioner | 6128b06e-6856-533d-9610-d8058ca7ec88 | Practitioner GeneralPractitioner |
| Patient | fee69f36-5bb9-52e3-a316-0bbfdf8f048f | InsufficientAbx HOBMatchingCommensal, male, DOB 1955-09-15 |
| Location | de27ffb2-b93b-58b4-a770-bca77e8fe1ec | HSLOC 1025-6 (Trauma Critical Care) |
| Encounter | df34fe65-16bf-50e3-947e-69ee6aacc46c | Admit 2025-01-02, class=IMP, status=finished |
| Coverage | 83264fc1-73df-5a00-aa1c-e43a9c1dfad9 | Coverage 2025-01-01T00:00:00.000Z to 2025-12-31T23:59:59.000Z |
| Practitioner | 1182622d-46cf-56f5-9593-ea207cbf2dc9 | Practitioner Ordering |
| ServiceRequest | 9bae39a1-0d47-50d5-b2b3-eeab4b646fac | Bacteria identified in Blood by Culture, authored 2025-01-06T07:00 |
| Specimen | 1cba2a6a-ca1c-5fed-b68b-7a3b43802718 | Blood specimen, collected 2025-01-06T08:00 |
| Observation | 0c935def-a16e-5d55-87bd-877ae267c7e9 | Bacteria identified in Blood by Culture, 2025-01-06T08:00, Staphylococcus epidermidis |
| Practitioner | 4f40336a-5508-5fd9-8821-3f0df964d071 | Practitioner Ordering |
| ServiceRequest | cb1f6967-0122-5c78-91cf-d7702303b075 | Bacteria identified in Blood by Culture, authored 2025-01-08T09:00 |
| Specimen | 57798323-2889-5173-af87-17aa00a5d9ea | Blood specimen, collected 2025-01-08T10:00 |
| Observation | dbddacfe-e264-5bc2-92bb-3d375a1638ce | Bacteria identified in Blood by Culture, 2025-01-08T10:00, Staphylococcus epidermidis |
| Medication | e7ed6e6a-e9b2-5d0c-8551-a43508c14fb7 | Vancomycin 1000 MG Injection |
| Practitioner | 36428a91-9703-5912-bf3c-ac3bf9fb8532 | Practitioner Prescriber |
| MedicationRequest | b261f5d7-8a92-5ceb-8e9e-ca059e589efc | Order authored 2025-01-06T11:00 |
| Practitioner | 5365932f-2f9c-51f4-a142-4d8408e7eb93 | Practitioner Nurse |
| MedicationAdministration | d7629614-15c0-520b-9e1f-700c9ca0dbb8 | Admin 2025-01-06 to 2025-01-08 |
| MeasureReport | 6228f6c1-f301-5cfd-b4bb-546fbd6a4c3d | MeasureReport |

**Expected Outcome**:
- Initial Population: 1
- Matching Commensal HOB: **Excluded** (<4 days antibiotics)
- Standard HOB Event: **Excluded** (skin commensal)

---

## Test Case 9: Non-Measure HOB - High Risk (Non-Preventability)

**File**: `HOBNonMeasureHighRisk.json`

**Scenario**: HOB event in patient with conditions predicting non-preventability

**Purpose**: Validates Non-Measure HOB Event metric numerator

**Clinical Narrative**:
> Patient HighRisk is a 72-year-old male with **acute myeloid leukemia (AML)** admitted to the Trauma Critical Care unit on January 2, 2025 for febrile neutropenia during chemotherapy.
>
> **Hospital Course:**
> - **Day 1-4:** Patient with profound neutropenia (ANC <100) following chemotherapy. Broad-spectrum antibiotics initiated for fever.
> - **Day 5:** Persistent fever despite antibiotics. Blood cultures obtained.
> - **Day 6:** Blood culture positive for **Escherichia coli** bacteremia.
> - **Treatment:** Continued broad-spectrum coverage. Patient's immunocompromised state from AML predisposed him to infection.
> - **Discharge:** Patient eventually recovered counts and was discharged for outpatient chemotherapy.
>
> **Non-Measure HOB:** This HOB event occurs in a patient with **high-risk, non-preventable conditions** (acute leukemia with neutropenia). Classified as **Non-Measure HOB** - not attributed to preventable hospital factors.

| Resource | ID | Details |
|----------|-----|---------|
| Practitioner | 315aaf02-7c64-52fb-9a5b-ea92a7d58d39 | Practitioner GeneralPractitioner |
| Patient | f095cd82-52b9-52d7-8171-91686989dcba | HighRisk HOBNonMeasure, male, DOB 1958-07-12 |
| Location | f058ec27-9666-5092-aa1a-cefdd3bb9a98 | HSLOC 1025-6 (Trauma Critical Care) |
| Encounter | 9c36b190-8887-56dc-8a96-b9da0defe3de | Admit 2025-01-02, class=IMP, status=finished |
| Coverage | a7beff83-9a76-5fa6-8b17-a6e63974ca07 | Coverage 2025-01-01T00:00:00.000Z to 2025-12-31T23:59:59.000Z |
| Condition | eca485be-30dc-598d-84b1-32fe28d48b88 | Acute myeloid leukemia |
| Condition | c9c5f74c-c3cc-59b6-90f8-d8933e3d234b | Neutropenia |
| Practitioner | a7996cc3-90c0-5c65-96ab-e633b3e1fa4c | Practitioner Ordering |
| ServiceRequest | ab2cc3ee-665a-526f-bb4e-7f11167b1533 | Bacteria identified in Blood by Culture, authored 2025-01-06T13:00 |
| Specimen | 9891f619-ac8a-5fee-bcbc-9a72b785dbde | Blood specimen, collected 2025-01-06T14:00 |
| Observation | 506ece99-0ef9-558d-8bcd-0bbc0c721c0b | Bacteria identified in Blood by Culture, 2025-01-06T14:00, Escherichia coli |
| MeasureReport | 7b80d3e8-7fe4-5108-8271-02dcf30d67cc | MeasureReport |

**Expected Outcome**:
- Initial Population: 1
- HOB Event: **Positive** (pathogenic organism on day 4+)
- Non-Measure HOB: **Positive** (AML + neutropenia = high non-preventability)

---

## Test Case 10: Measurable HOB - No Risk Factors

**File**: `HOBMeasurableNoRiskFactors.json`

**Scenario**: HOB event in patient without non-preventability conditions

**Purpose**: Validates standard HOB counted, NOT Non-Measure HOB

**Clinical Narrative**:
> Patient NoRiskFactors is a 45-year-old female admitted to the Trauma Critical Care unit on January 2, 2025 following elective abdominal surgery with no significant comorbidities.
>
> **Hospital Course:**
> - **Day 1-4:** Patient underwent uncomplicated elective cholecystectomy. No immunocompromising conditions. Standard post-operative care.
> - **Day 5:** Developed fever and abdominal pain concerning for surgical site infection. Blood cultures obtained.
> - **Day 6:** Blood culture positive for **Escherichia coli** bacteremia, likely from intra-abdominal source.
> - **Treatment:** Antibiotics initiated; surgical consultation obtained.
> - **Discharge:** Patient recovered following antibiotic therapy and was discharged in stable condition.
>
> **Measurable HOB:** This HOB event occurs in a patient **without high-risk, non-preventable conditions**. This is a standard, **measurable HOB event** that may be attributable to preventable hospital factors.

| Resource | ID | Details |
|----------|-----|---------|
| Practitioner | 397aec4a-6b10-5936-925c-4df7c18e03bd | Practitioner GeneralPractitioner |
| Patient | 207ff6dc-067f-5191-b3b7-58543471a88a | NoRiskFactors HOBMeasurable, female, DOB 1968-12-03 |
| Location | 56883864-b9f8-5244-b0a2-4238077fc212 | HSLOC 1025-6 (Trauma Critical Care) |
| Encounter | 684ae21e-47f3-5d28-8666-00ea62a86885 | Admit 2025-01-02, class=IMP, status=finished |
| Coverage | 1219799a-7e58-5efd-803a-5a1c8511834a | Coverage 2025-01-01T00:00:00.000Z to 2025-12-31T23:59:59.000Z |
| Condition | 3ad89d88-21cf-5085-aa79-e9d68b95bf46 | Diabetes mellitus type 2 |
| Condition | a8ed8e4a-688e-545b-a473-e7979aa0a4cd | Hypertensive disorder |
| Practitioner | 11ca9ad0-3bb9-595a-92ab-8633e29d73ef | Practitioner Ordering |
| ServiceRequest | 2011edc6-713c-5a35-9251-bc97baaa418d | Bacteria identified in Blood by Culture, authored 2025-01-06T08:00 |
| Specimen | c160e9ce-2857-516f-ad03-849c1e7de372 | Blood specimen, collected 2025-01-06T09:00 |
| Observation | bd446780-6924-5723-ab90-e9d99056549f | Bacteria identified in Blood by Culture, 2025-01-06T09:00, Staphylococcus aureus |
| MeasureReport | 7ca45e35-b442-58b8-8588-a689342bf7ce | MeasureReport |

**Expected Outcome**:
- Initial Population: 1
- HOB Event: **Positive** (pathogenic organism on day 4+)
- Non-Measure HOB: **Excluded** (no non-preventability conditions)

---

## Test Case 11: HOB Excluded - Different SNOMED Codes, Same Species

**File**: `HOBExcludedSameSpeciesDifferentCodes.json`

**Scenario**: Patient with differing SNOMED codes of the same species on day 2 and day 6

**Purpose**: Validates HOB code matching correctly identifies same species across different SNOMED codes (base organism vs. resistance phenotype)

**Clinical Narrative**:
> Patient SameSpecies is a 55-year-old male admitted to the Trauma Critical Care unit on January 2, 2025 with community-acquired MRSA bacteremia.
>
> **Hospital Course:**
> - **Day 2 (COB Event):** Patient presented with sepsis. Blood cultures positive for **Staphylococcus aureus** (SNOMED: 3092008 - base organism code). MRSA confirmed by susceptibility testing. IV vancomycin initiated.
> - **Day 3-5:** Patient clinically improving on vancomycin. Remained hospitalized for IV therapy completion.
> - **Day 6:** Surveillance blood cultures obtained to document clearance. Culture positive for **Methicillin-resistant Staphylococcus aureus** (SNOMED: 115329001 - MRSA phenotype code).
> - **Discharge:** Patient completed antibiotic course with documented bacteremia clearance.
>
> **HOB Exclusion:** Although day 2 and day 6 cultures have **different SNOMED codes** (3092008 vs. 115329001), they represent the **same species** (S. aureus). The CQL measure correctly identifies this as a matching organism, so the day 6 culture is **excluded from HOB** as it matches the prior COB.

| Resource | ID | Details |
|----------|-----|---------|
| Practitioner | 28c1b74f-af15-504b-872e-5bf8a5389fb9 | Practitioner GeneralPractitioner |
| Patient | 767e83b2-9a68-5220-82ae-4037d362b64a | SameSpeciesDifferentCodes HOBExcluded, male, DOB 1972-11-30 |
| Location | 1e65106b-6285-59bc-85fe-c7d08aa53869 | HSLOC 1108-0 (Emergency Department) |
| Location | 9f48fcb1-3e0f-5195-af53-4764e9803a4e | HSLOC 1162-7 (24 Hour Observation Area) |
| Location | 0d208a06-72f7-5cb9-92de-492f04f0641d | HSLOC 1060-3 (Medical Ward) |
| Encounter | ca58c649-c979-51fa-9e80-48697690b00d | Admit 2025-01-02, class=IMP, status=finished |
| Coverage | e6d39019-608d-5a4f-802c-6f4ee02c961d | Coverage 2025-01-01T00:00:00.000Z to 2025-12-31T23:59:59.000Z |
| Practitioner | fb88566d-4eba-5c0b-97f3-8aa573b7ff66 | Practitioner Ordering |
| ServiceRequest | 22d7f353-b4ef-5478-b261-1838f6c619d5 | Bacteria identified in Blood by Culture, authored 2025-01-03T17:43 |
| Specimen | fcbc39fc-febd-5395-bb34-7fccb03f8091 | Blood specimen, collected 2025-01-03T18:43 |
| Observation | 2ac1e0e7-e348-5823-9523-c4bdbd2d3d81 | Bacteria identified in Blood by Culture, 2025-01-03T18:43, Pseudomonas aeruginosa |
| Practitioner | 560a24cb-781e-51e1-a465-0cc7cc243c94 | Practitioner Ordering |
| ServiceRequest | befad44e-864e-5cf4-ae86-02b5180e9f6e | Bacteria identified in Blood by Culture, authored 2025-01-07T17:43 |
| Specimen | 6020c7fc-aad7-5f45-b0aa-3cd36252b190 | Blood specimen, collected 2025-01-07T18:43 |
| Observation | bf7c824e-58ba-5771-acdc-7bdcf138088b | Bacteria identified in Blood by Culture, 2025-01-07T18:43, Carbapenem resistant Pseudomonas aeruginosa |
| MeasureReport | 5ed2b8a6-0e28-5d62-924e-1d3c779528c2 | MeasureReport |

**Why Two Specimens?**

This test requires two blood cultures to validate the COB exclusion logic:

| Day | Specimen | Organism | SNOMED Code | Event Type |
|-----|----------|----------|-------------|------------|
| Day 2 | Specimen 1 | P. aeruginosa | 52499004 | **COB** (Community-Onset, day 1-3) |
| Day 6 | Specimen 2 | CR P. aeruginosa | 726492000 | Would be HOB, but **EXCLUDED** |

The Day 6 culture timing qualifies for HOB (day 4+), but it must be excluded because the organism matches the prior COB event. Without both cultures, we cannot test whether the measure correctly matches organisms across different SNOMED codes.

**Expected Outcome**:
- Initial Population: 1
- HOB Event: **Negative** (matching pathogenic organisms on day 2 and 6 - same species despite different codes)
- Community-Onset Bacteremia & Fungemia Event: **Positive** (day 2 culture)

**Key Insight**: The CQL measure must recognize that SNOMED 52499004 (Pseudomonas aeruginosa) and 726492000 (Carbapenem resistant Pseudomonas aeruginosa) represent the same bacterial species. The resistance phenotype does not change organism identity for COB exclusion purposes.

---

## FHIR Resources by Test Case

| Test Case | Patient | Encounter | Location | Specimen | Observation | Condition | MedicationAdmin |
|-----------|:-------:|:---------:|:--------:|:--------:|:-----------:|:---------:|:---------------:|
| 1 | ✓ | ✓ | ✓ | 1 | 1 | - | - |
| 2 | ✓ | ✓ | ✓ | 1 | 1 | - | - |
| 3 | ✓ | ✓ | ✓ | 2 | 2 | - | - |
| 4 | ✓ | ✓ | ✓ | 2 | 2 | - | - |
| 5 | ✓ | ✓ | ✓ | 2 | 2 | - | - |
| 6 | ✓ | ✓ | ✓ | 2 | 2 | - | - |
| 7 | ✓ | ✓ | ✓ | 2 | 2 | - | 1 |
| 8 | ✓ | ✓ | ✓ | 2 | 2 | - | 1 |
| 9 | ✓ | ✓ | ✓ | 1 | 1 | 2 | - |
| 10 | ✓ | ✓ | ✓ | 1 | 1 | 2 | - |
| 11 | ✓ | ✓ | 3 | 2 | 2 | - | - |

---

## Code Reference

### Pathogenic Organisms (HOB Eligible)

| Organism | SNOMED Code | Display |
|----------|-------------|---------|
| Staphylococcus aureus | 3092008 | Staphylococcus aureus |
| Escherichia coli | 112283007 | Escherichia coli |
| Candida albicans | 53326005 | Candida albicans |
| Pseudomonas aeruginosa | 52499004 | Pseudomonas aeruginosa |
| Carbapenem resistant Pseudomonas aeruginosa | 726492000 | Carbapenem resistant Pseudomonas aeruginosa |

### Skin Commensals (Standard HOB Excluded)

| Organism | SNOMED Code | Display |
|----------|-------------|---------|
| Staphylococcus epidermidis | 60875001 | Staphylococcus epidermidis |

### Non-Preventability Conditions

| Condition | SNOMED Code | Display |
|-----------|-------------|---------|
| Acute myeloid leukemia | 91861009 | Acute myeloid leukemia |
| Neutropenia | 165517008 | Neutropenia |

### Common Conditions (NOT Non-Preventability)

| Condition | SNOMED Code | Display |
|-----------|-------------|---------|
| Diabetes mellitus type 2 | 44054006 | Diabetes mellitus type 2 |
| Hypertensive disorder | 38341003 | Hypertensive disorder |

### Antibiotic Medications (RxNorm)

| Medication | RxNorm Code | Display |
|------------|-------------|---------|
| Vancomycin 1000 MG Injection | 1664986 | Vancomycin 1000 MG Injection |

### Blood Culture Observation

| Element | Code System | Code | Display |
|---------|-------------|------|---------|
| Observation Code | LOINC | 600-7 | Bacteria identified in Blood by Culture |
| Specimen Type | SNOMED | 119297000 | Blood specimen |
| No Growth Result | SNOMED | 264868006 | No growth |

---

## Hospital Day Calculation

| Admission Date | Day 1 | Day 2 | Day 3 | Day 4 (HOB eligible) |
|----------------|-------|-------|-------|----------------------|
| 2025-01-02 | Jan 2 | Jan 3 | Jan 4 | **Jan 5** |
| 2025-01-03 | Jan 3 | Jan 4 | Jan 5 | **Jan 6** |

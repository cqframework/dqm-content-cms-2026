### Inclusion Tests

* Patient 1 — Straightforward Inclusion
* Patient 2 — Older Patient, ECOG 1, Larger Tumor
* Patient 3 — DCIS Diagnosis, Borderline Tumor Size

| | Patient 1 — Mary Johnson | Patient 2 — Priya Patel | Patient 3 — Linh Nguyen |
|---|---|---|---|
| **Age** | 51 | 68 | 43 |
| **Diagnosis** | Invasive breast cancer | Invasive breast cancer | DCIS |
| **Tumor size** | 18 mm | 32 mm | 6 mm (borderline) |
| **ECOG** | 0 | 1 | 0 |
| **Creatinine** | 0.9 mg/dL | 1.1 mg/dL | 0.8 mg/dL |
| **Liver labs** | All normal | All normal | All normal |
| **Exclusions** | None | None | None |

### Exclusion Tests

* Patient 4 — Fails: On Diabetes Medication
* Patient 5 — Fails: Renal Impairment (Creatinine > 1.4 mg/dL)
* Patient 6 — Fails: Hepatic Impairment (Elevated AST)
* Patient 7 — Fails: Age < 21
* Patient 8 — Fails: On Strong CYP3A4 Inhibitor (Clarithromycin)
* Patient 9 — Fails: ECOG Score of 2

### Summary of Negative Test Patients

| | Patient 4 — Carol Smith | Patient 5 — Rosa Garcia | Patient 6 — Chioma Okafor | Patient 7 — Sophie Williams | Patient 8 — Jung-Yeon Lee | Patient 9 — Elena Martinez |
|---|---|---|---|---|---|---|
| **Age** | 56 | 59 | 48 | 17 | 61 | 65 |
| **Failing criterion** | On Metformin (diabetes med) | Creatinine 1.8 mg/dL | AST 112 U/L (2.8x ULN) | Age < 21 | On Clarithromycin (CYP3A4) | ECOG score = 2 |
| **Fails at** | Exclusion #1 | Exclusion #4 | Exclusion #5 | Inclusion #3 | Exclusion #3 | Inclusion #5 |
| **Expected result** | `Is Eligible = false` | `Is Eligible = false` | `Is Eligible = false` | `Is Eligible = false` | `Is Eligible = false` | `Is Eligible = false` |


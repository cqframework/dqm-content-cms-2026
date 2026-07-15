# HOB test cases

Test data for the `HOB` CQL library, evaluated by the CQL VS Code extension
(`CQL: Execute`). Each subfolder is one patient context (**`Patient.id` must equal
the folder name** — that is how the executor keys the context patient); results
are written to [../results/HOB.txt](../results/HOB.txt).

Cases **01–09** exercise the **denominator / population** logic (encounter
normalization, eligibility windows). Cases **10–15** exercise the **numerator /
event** logic (blood-culture events, COB/HOB organism de-duplication).

**Terminology.** Denominator cases need only the ED / Inpatient / Observation
encounter value sets. Numerator cases additionally need the blood-culture test,
blood specimen, skin-commensal, and HOB-specific-organism value sets. Two of
those were pulled from VSAC; two are **local starters** (not authoritative) so
the logic can be exercised locally:

- `Specimen Type - Blood` (`external/ValueSet-2.16.840.1.114222.24.7.315-…`) —
  VSAC has no expansion; seeded with SNOMED blood-specimen codes.
- `Bacteria and Fungi - HOB Specific`
  (`ValueSet-bacteria-and-fungi-hob-specific.json`) — replaces the former `'TBD'`
  on `HOB.cql` line 14; derived from `HOBOrganismTaxonomy` (all organisms not
  flagged `nhsn_skin_commensal`). The taxonomy table is itself a work-in-progress
  fragment, so **numerator test organisms are drawn from that fragment**
  (e.g. Abiotrophia defectiva `113714003`) rather than the organisms in the NHSN
  reference spec (S. aureus etc.), which are not yet in the table.

Both starters are labelled in their `description` and should be swapped for the
authoritative expansions when available.

> **Gotcha (confirmed on the run):** this engine build (extension 0.9.8) resolves
> value-set membership from `expansion.contains`, **not** from a `compose`-only
> definition. A compose-only value set silently behaves as empty, so
> `R.value in "…"` is always false. Both local starters therefore include an
> `expansion.contains`. (The `[Observation: …]` / `[Encounter: …]` retrieves are
> what confirmed it: the VSAC sets with expansions matched, while the first,
> compose-only, cut of the organism set did not.)

Measurement Period = the library default, **Jan 2026**
(`Interval[@2026-01-01T00:00:00.0, @2026-01-31T23:59:59.999]`).

## Encounter coding

Retrieves match on `Encounter.type`:

| Kind        | SNOMED code       | Value set                  |
|-------------|-------------------|----------------------------|
| ED          | `4525004`         | Emergency Department Visit |
| Inpatient   | `32485007`        | Encounter Inpatient        |
| Observation | `448951000124107` | Observation Services       |

## Expected denominator membership

`O-COB` = O-COB Prevalence Rate IP/Denominator (returns the ED encounter).
`COB` = COB Prevalence Rate IP/Denominator (returns the inpatient encounter).
`HOB` = HOB Crude Risk **and** HOB Incidence Density IP/Denominator (inpatient encounter).

| # | Case | Encounters | O-COB | COB | HOB | Point being tested |
|---|------|-----------|:-----:|:---:|:---:|--------------------|
| 01 | OCOB-EDOnly-InMP | ED 01-10 08:00→14:00 | ✅ `ed-ococb1` | – | – | ED-only outpatient stay in MP |
| 02 | Outpatient-Outside-MP | ED 2025-12-15 | – | – | – | MP overlap filter (negative) |
| 03 | OBS-To-Inpatient | OBS 01-06 →IP 01-06 20:30→01-11 09:00 | – | ✅ `ip-obs1` | ✅ `ip-obs1` | OBS→IP; 4d stay. Also shows ED-driven gap → O-COB empty. At-threshold HOB inclusion (duration = 4 > 3) |
| 04 | COB-ShortInpatientStay | IP 01-15→01-17 (2d) | – | ✅ `ip-cob1` | – | COB yes, HOB no (duration ≤ 3). Regression guard for the short-stay interval crash (see obs. 4) |
| 05 | HOB-ThreeDayBoundary | IP 01-10→01-13 (3d) | – | ✅ `ip-three1` | – | Boundary: duration = 3, HOB needs > 3 (excluded). Also guards the short-stay interval crash (see obs. 4) |
| 06 | HOB-EligibleLongStay | IP 01-05→01-20 (15d) | – | ✅ `ip-hob1` | ✅ `ip-hob1` | Eligible for all inpatient denominators |
| 07 | HOB-WindowOutsideMP | IP 01-29→02-15 | – | ✅ `ip-win1` | – | COB yes, HOB no by **window placement** (day 4+ falls in Feb) |
| 08 | ED-To-Inpatient-Linked | ED 01-04 09:00→12:00, IP 01-04 12:00→01-12 12:00 | ✅ `ed-link1` | ✅ `ip-link1` | ✅ `ip-link1` | ED↔IP linked within 1h; all three denominators |
| 09 | ED-Inpatient-Gap-Over-Hour | ED 01-06 09:00→12:00, IP 01-06 14:00→01-11 14:00 | ✅ `ed-gap1` | ✅ `ip-gap1` | ✅ `ip-gap1` | > 1h gap → ED and IP counted **independently** (no linkage) |

Notes on the intermediate defines:

- Case 02: `Outpatient Encounter` is non-empty but `Outpatient Encounter During
  Measurement Period` is empty, so `O-COB ... Denominator` is empty.
- Case 08: the inpatient links in **both** `Outpatient Encounter`
  (`inpatientEncounter = ip-link1`) and `Inpatient Encounter`
  (`edEncounter = ed-link1`).
- Case 09: `Inpatient Encounter` for `ip-gap1` has `edEncounter = null` and
  `outpatientStay = null` (the > 1h gap breaks the link), while `ed-gap1` still
  stands alone in the O-COB denominator.

## Numerator / event test cases (10–15)

All use an 11-day inpatient stay `2026-01-05 → 2026-01-16` (day 1 = Jan 5) unless
noted. Blood-culture events are an `Observation` (`status=final`,
`category=laboratory`, LOINC `600-7`, organism in `valueCodeableConcept`) plus a
blood `Specimen` it references, with the **specimen collection time** driving the
event date. COB window = day of `[admit, admit+3d]`; HOB window = day of
`[admit+4d, discharge]`.

Organisms (all in the HOB-specific starter, none skin commensals):
`113714003` Abiotrophia defectiva, `396950003` Acetobacter aceti,
`266186009` / `154315008` two Legionella codes (same genus, species null).

| # | Case | Blood cultures | O-COB num | COB num | HOB num | Point being tested |
|---|------|----------------|:---------:|:-------:|:-------:|--------------------|
| 10 | HOB-Numerator-Day6 | day 6: `113714003` | – | – | ✅ `ip-n1` | Basic HOB event on day 4+ |
| 11 | COB-Numerator-Day2 | day 2: `396950003` | – | ✅ `ip-n2` | – | Community-onset event in first 3 days |
| 12 | OCOB-Numerator-Outpatient | during ED stay: `113714003` | ✅ `ed-n3` | – | – | Outpatient community-onset (ED→IP linked; culture drawn in ED) |
| 13 | HOB-Excluded-MatchingCOB | day 2 & day 6: both `113714003` | – | ✅ `ip-n4` | – (excluded) | HOB suppressed when day-6 organism == prior COB organism (exact match) |
| 14 | HOB-Positive-NonMatchingCOB | day 2 `113714003`, day 6 `396950003` | – | ✅ `ip-n5` | ✅ `ip-n5` | HOB counts when day-6 organism differs from COB |
| 15 | HOB-Excluded-GenusMatch | day 2 `266186009`, day 6 `154315008` | – | ✅ `ip-n6` | – (excluded) | ✅ **confirmed**: genus rollup via `HOBOrganismTaxonomy.organismMatches` (different codes, same genus, species null) suppresses HOB |
| 16 | Day4-Boundary | day 4 (`admit+3d`): `113714003` | – | ✅ `ip-n7` | – (excluded) | ✅ **confirmed COB, not HOB** — day-4 culture lands in COB; confirms the one-day shift in obs. #5 |

`HOB Incidence Density Numerator` tracks `HOB Crude Risk Numerator` (cases 10, 14).
Both watch items came back clean: case 15 confirms the genus rollup works (the
`species()`/`genus()` list concern was unfounded — HOB was correctly suppressed),
and case 16 confirms a day-4 culture is classified COB (see obs. #5).

## Observations surfaced while tracing the logic (for review, not test failures)

1. **`Outpatient Encounter` is ED-driven only** (`HOB.cql` line 69 retrieves
   `[Encounter: "Emergency Department Visit"]`). A standalone Observation stay —
   or an OBS that leads to an inpatient admission without a preceding ED — is
   never captured as an outpatient encounter and is therefore excluded from the
   O-COB denominator. Case 03 demonstrates this.
2. **Asymmetric 1-hour linking windows.** `Outpatient Encounter` links an
   inpatient with `E.period starts 1 hour or less on or before endOfStay`
   (admission starting in the hour *before* the ED/OBS ends), whereas `Inpatient
   Encounter` links an ED with `ED.period ends 1 hour or less on or before
   visitStart` (ED ending in the hour *before* admission starts). These windows
   point in opposite directions, so an admission that begins shortly *after* the
   ED ends links in `Inpatient Encounter` but not in `Outpatient Encounter`.
   Case 08 links in both only because ED-end and IP-start are the same instant.
3. **Duration threshold — resolved.** The HOB denominator
   (`Hospital Eligible Inpatient Encounter During Measurement Period`) now uses
   `duration in days of I.inpatientStay > 3`, matching `Encounter With HOB
   Result`. The boundary is a 3-day stay (excluded, case 05) vs a 4-day stay
   (included, case 03).
4. **Short-stay interval crash — fixed.** Cases 04 (2-day) and 05 (3-day)
   originally aborted the whole context with `Invalid Interval` because
   `hospitalEligible: Interval[start + 4 days, end]` was constructed for every
   inpatient encounter in the `let` (before the `duration > 3` filter), and for
   stays ≤ 3 days `start + 4 days` falls after the stay end → an inverted
   interval. `Community Eligible` avoided this by clamping the high boundary with
   `Min({ start + 3 days, end })`; `Hospital Eligible` had no guard. Fixed by
   constructing the interval conditionally (`if duration > 3 then Interval[…]
   else null`), which also folds in the duration check. The same latent trap in
   `Encounter With HOB Result` (identical `Interval[start + 4 days, end]`, dormant
   only because there is no blood-culture data to iterate yet) was guarded the
   same way pre-emptively.

5. **Day-4 window boundary is shifted one day late — confirmed by case 16.**
   With admission = hospital day 1, the HOB window `[admit + 4 days, discharge]`
   starts on day **5**, and the COB window `[admit, admit + 3 days]` covers days
   1–4. The NHSN spec defines HOB as "day **4**+" (day 4 = `admit + 3 days`) and
   COB as the first three days. Case 16 (a single culture on day 4 =
   `admit + 3 days`) produced a **COB** event, not HOB — confirming the shift.
   To match NHSN, both boundaries move one day earlier:
   - COB `Interval[start, Min({start + 3 days, end})]` → `start + 2 days`
     (`Encounter With COB Result`, and `Community Eligible …` denominator)
   - HOB `Interval[start + 4 days, …]` → `start + 3 days`
     (`Encounter With HOB Result`, and `Hospital Eligible …` denominator)

   NB the recent `duration in days > 3` change (obs. 3/4) is consistent with the
   current day-5 HOB start; if the windows move to `+3 days`, the duration gate
   likely becomes `> 2`. Confirm the intended day semantics before changing.

Remaining items are candidates for fixing the CQL (obs. 1–2, and obs. 5) or
extending the suite. Everything else in the 16-case suite matches expectations.

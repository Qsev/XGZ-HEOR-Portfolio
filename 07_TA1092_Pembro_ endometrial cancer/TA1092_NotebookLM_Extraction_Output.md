# TA1092 NotebookLM Extraction Output

Notebook used: `TA1092`  
Notebook ID: `670f6286-b91e-44bd-a56f-5c55902c0505`  
Sources present in notebook:

- NICE TA1092 guidance PDF
- Draft guidance consultation committee papers, 27 August 2025
- Final draft guidance committee papers, 27 August 2025

This document records the NotebookLM extraction used to plan a Quarto/R replication case study. Values marked confidential/redacted should not be invented in the QMD.

## Case Identification

| Item | Extracted detail |
|---|---|
| NICE TA | TA1092 |
| Intervention | Pembrolizumab with carboplatin and paclitaxel, followed by pembrolizumab maintenance |
| Company | MSD |
| Indication | First-line treatment of primary advanced or recurrent endometrial cancer in adults |
| Comparator | Platinum-based chemotherapy, specifically carboplatin and paclitaxel |
| Recommendation | Recommended if supplied according to the commercial arrangement |
| Stopping rule | Stop pembrolizumab after 2 years, or earlier for progression or unacceptable toxicity |
| Publication date | 27 August 2025 |
| Subgroups | dMMR and pMMR; also described as dMMR/MSI-H and pMMR/MSS terminology in the appraisal context |

## Evidence Base

| Domain | Extracted detail |
|---|---|
| Pivotal trial | KEYNOTE-868 / NRG-GY018 |
| Design | Phase 3, international, multicentre, randomised, double-blind, placebo-controlled trial |
| Population | Adults with previously untreated advanced stage measurable stage III or IVA, stage IVB, or recurrent endometrial cancer |
| Intervention regimen | Pembrolizumab 200 mg IV Q3W + paclitaxel 175 mg/m2 IV Q3W + carboplatin AUC 5 IV Q3W for 6 cycles; then pembrolizumab 400 mg IV Q6W maintenance for up to 14 cycles |
| Comparator regimen | Placebo + paclitaxel + carboplatin for 6 cycles; then placebo maintenance |
| Primary endpoint | Investigator-assessed PFS by RECIST v1.1 |
| Key secondary endpoints | OS, ORR, DOR, HRQoL |
| Data cut-offs | Pre-specified interim analysis: December 2022; efficacy and safety update: August 2023 |
| Follow-up duration | Exact median follow-up durations redacted as commercial in confidence |
| Overall sample size | 819 randomised: 408 pembrolizumab arm, 411 placebo arm |
| dMMR cohort | 222 patients |
| pMMR cohort | 597 patients |

## Key Clinical Results

| Population | Endpoint | HR | 95% CI | Direction |
|---|---|---:|---|---|
| dMMR | PFS | 0.34 | 0.22 to 0.53 | Favours pembrolizumab + chemotherapy |
| dMMR | OS | 0.57 | 0.31 to 1.04 | Favours pembrolizumab + chemotherapy, but uncertain |
| pMMR | PFS | 0.57 | 0.44 to 0.74 | Favours pembrolizumab + chemotherapy |
| pMMR | OS | 0.80 | 0.59 to 1.08 | Directionally favours pembrolizumab + chemotherapy, but uncertain |
| All-comer | PFS | 0.60 | 0.50 to 0.72 | Favours pembrolizumab + chemotherapy |
| All-comer | OS | 0.74 | 0.57 to 0.97 | Favours pembrolizumab + chemotherapy |

## Economic Model Overview

| Model feature | Extracted detail |
|---|---|
| Model type | De novo 3-state partitioned survival model |
| Health states | Progression-free, progressed disease, death |
| Cycle length | 1 week |
| Time horizon | Lifetime, 35 years |
| Discounting | 3.5% per year for costs and health effects |
| Perspective | UK NHS and Personal Social Services |
| Subgroup handling | Company initially modelled all-comer base case; EAG and committee preferred separate dMMR and pMMR subgroup analyses |
| Treatment discontinuation | Derived from TTD Kaplan-Meier data; 2-year stopping rule applied to pembrolizumab |
| Adverse events | Grade 3 to 5 AEs occurring in at least 5% of either arm; one-off cost and QALY decrement in first cycle |
| Subsequent treatments | One-off cost applied on entry to progressed disease; trial data adjusted to NHS pathway based on clinical expert input |

## Company Survival Modelling

NotebookLM reported that proportional hazards assumptions were violated, based on Schoenfeld residuals and crossing log-cumulative hazard plots. The company therefore used independently fitted models by treatment arm.

| Subgroup | Endpoint | Arm | Company selected model |
|---|---|---|---|
| dMMR | PFS | Pembrolizumab + chemotherapy | Generalised gamma |
| dMMR | PFS | Chemotherapy | 2-piece gamma with 27-week cut |
| dMMR | OS | Pembrolizumab + chemotherapy | Log-logistic |
| dMMR | OS | Chemotherapy | Exponential |
| pMMR | PFS | Pembrolizumab + chemotherapy | 2-piece generalised gamma with 37-week cut |
| pMMR | PFS | Chemotherapy | 1-knot odds spline |
| pMMR | OS | Pembrolizumab + chemotherapy | Log-logistic |
| pMMR | OS | Chemotherapy | Gamma |

Additional modelling points:

- Survival extrapolations used KEYNOTE-868 patient-level data up to the August 2023 cut-off.
- General population mortality was capped using age-matched ONS life tables.
- Long-term extrapolations were clinically validated against 2-, 5-, 10-, and 20-year landmark estimates and previous appraisal evidence such as TA963.
- Company argued that the EAG's preferred pMMR PFS extrapolations created clinically implausible crossing where chemotherapy PFS exceeded pembrolizumab + chemotherapy PFS.

## EAG Survival Critique and Preferred Models

The EAG concern was mainly that immature follow-up made the company's long-term survival projections too optimistic, especially OS benefit in the pembrolizumab arm.

| Subgroup | Endpoint | Arm | EAG preferred model |
|---|---|---|---|
| dMMR | PFS | Pembrolizumab + chemotherapy | Log-logistic |
| dMMR | PFS | Chemotherapy | Generalised gamma |
| dMMR | OS | Pembrolizumab + chemotherapy | Log-logistic |
| dMMR | OS | Chemotherapy | Exponential |
| pMMR | PFS | Pembrolizumab + chemotherapy | 1-knot hazard spline |
| pMMR | PFS | Chemotherapy | 2-knot hazard spline |
| pMMR | OS | Pembrolizumab + chemotherapy | 1-knot normal spline |
| pMMR | OS | Chemotherapy | 1-knot hazard spline |

Committee position:

- The committee accepted the EAG's more cautious survival models across both subgroups.
- To handle the company's valid concern about pMMR PFS crossing, the committee applied a cap so that chemotherapy PFS could not exceed pembrolizumab + chemotherapy PFS.
- The committee preferred gradual treatment-effect waning from year 5 to year 7 after starting pembrolizumab.
- With committee preferred assumptions, ICERs for both dMMR and pMMR were below the middle of the usual NICE acceptable range.

## Treatment Effect Waning

| Item | Extracted detail |
|---|---|
| Company base case | No treatment-effect waning |
| Company rationale | Immunotherapy mechanism and durable response evidence from KEYNOTE-006 and KEYNOTE-158 |
| Company scenarios | Gradual waning from years 7 to 9, applied either to all patients or only those without complete response |
| EAG base case | Gradual waning from years 5 to 7 after pembrolizumab start |
| Committee preferred | Gradual waning from years 5 to 7 |
| Endpoint affected | OS relative treatment effect |
| Method | Cycle-specific pembrolizumab + chemotherapy hazard converges to chemotherapy hazard by end of waning |
| ICER direction | Waning increases ICER |
| Reported scenario impact | Company 7-9 year all-patient waning increased ICER by 59% in dMMR and 53% in pMMR |

Important implementation point to manually verify: the third NotebookLM answer stated waning applies to the proportion without complete response, but the second answer stated EAG applied 5-7 year waning for all patients. This should be checked directly in the committee papers before coding.

## Cost and Resource Use Parameters

| Domain | Parameter | Value | Unit/status |
|---|---|---:|---|
| Drug cost | Pembrolizumab | 2,630 | GBP per 100 mg vial, list price |
| Drug cost | Carboplatin 150 mg vial | 20.22 | GBP |
| Drug cost | Carboplatin 450 mg vial | 48.09 | GBP |
| Drug cost | Paclitaxel 30 mg vial | 3.88 | GBP |
| Drug cost | Paclitaxel 300 mg vial | 24.43 | GBP |
| Administration | Complex chemotherapy | 277.00 | GBP per cycle |
| Administration | Simple chemotherapy | 217.00 | GBP per cycle |
| Treatment duration | Pembrolizumab | 20 | Total cycles: 6 combination + 14 maintenance |
| Treatment duration | Pembrolizumab cap | 24 | Months / 2 years |
| Treatment duration | Chemotherapy | 6 | Cycles |
| Carboplatin dose | AUC 5, max 750 mg | Public | Q3W for up to 6 cycles |
| Paclitaxel dose | 175 mg/m2 | Public | Q3W for up to 6 cycles |
| Body size | Mean baseline BSA/weight | Redacted | Needed for exact dosing |
| Terminal care | End-of-life cost | 8,829.07 | GBP, one-off at death |
| Commercial arrangement | Pembrolizumab CAA | Confidential | Real ICER uses undisclosed discount |

Resource use frequencies:

| Health state/status | CT scan | Outpatient visit | Blood test | Unit |
|---|---:|---:|---:|---|
| PFS on treatment, pembrolizumab + chemotherapy | 0.08 | 0.33 | 0.17 | per week |
| PFS off treatment, pembrolizumab + chemotherapy | 0.08 | 0.04 | 0.04 | per week |
| Progressed disease | 0.04 | 0.11 | 0.11 | per week |

## Utilities and QALYs

| Item | Extracted detail |
|---|---|
| Utility source | Initially KEYNOTE-158 dMMR EC subgroup with 1 prior line; later PF utility updated using pMMR disease recurrence cohort from KEYNOTE-B21 |
| Instrument/tariff | EQ-5D-3L, mapped via Hernandez-Alava algorithm using UK value set |
| Approach | Health-state based: progression-free and progressed disease |
| Base-case values | Redacted/confidential |
| Age adjustment | Applied using general female population decrement via Hernandez-Alava algorithm |
| AE disutilities | One-off decrement in first cycle |
| EAG critique | Concern that dMMR-derived utilities may not represent pMMR population; EAG preferred KEYNOTE-775, but access blocked by third-party contractual obligations |
| Committee preferred | KEYNOTE-158 utilities for both subgroups and both health states, because ICER impact was limited |

Public AE disutilities:

| AE | Disutility |
|---|---:|
| Anaemia | -0.119 |
| Hypertension | -0.020 |
| Decreased neutrophil count / WBC / lymphocyte count | 0.000 |

## Adverse Events

| Item | Extracted detail |
|---|---|
| Inclusion threshold | AEs occurring in at least 5% of either arm |
| Grade threshold | Grade 3 to 5 |
| Application | One-off cost and QALY decrement in first model cycle |
| Anaemia cost | GBP 565.40 |
| Hypertension cost | GBP 735.07 |
| Other haematological AE cost/disutility | Reported as GBP 0 / 0 disutility for some count decreases |
| AE duration | Exact durations redacted |
| EAG critique | EAG argued immune-related AEs at at least 2% should be included |
| ICER impact of EAG AE scenario | Minimal |

## Subsequent Treatments

| Item | Extracted detail |
|---|---|
| Costing approach | One-off calculated cost on entry to progressed disease |
| Treatments listed | Pembrolizumab, pembrolizumab + lenvatinib, dostarlimab, carboplatin, carboplatin + paclitaxel, doxorubicin, letrozole, megestrol, paclitaxel, radiotherapy, no active treatment |
| dMMR chemotherapy arm | 63.10% assumed to receive pembrolizumab |
| pMMR chemotherapy arm | 32.59% assumed to receive pembrolizumab + lenvatinib |
| Weekly cost example | Pembrolizumab GBP 1,753.33/week |
| Weekly cost example | Pembrolizumab + lenvatinib GBP 2,423.93/week |
| EAG/NHS pathway concern | Pembrolizumab monotherapy is not standard for pMMR patients after chemotherapy in NHS practice |
| NHS adjustment | pMMR pembrolizumab monotherapy market share redistributed to other non-IO treatments or pembrolizumab + lenvatinib |
| Retreatment rule | Immunotherapy retreatment in pembrolizumab + chemotherapy arm set to 0% for UK practice |

## Results

| Result set | Extracted detail |
|---|---|
| Company base case QALY gain, all-comer | 1.39 |
| Company base case QALY gain, dMMR | 2.24 |
| Company base case QALY gain, pMMR | 1.21 |
| EAG preferred QALY gain, all-comer | 0.71 |
| EAG preferred QALY gain, dMMR | 1.08 |
| EAG preferred QALY gain, pMMR | 0.46 |
| Exact ICERs | Confidential/redacted |
| Committee ICER conclusion | Below the middle of the usual NICE range for both dMMR and pMMR |
| PSA/DSA | Conducted; outputs mostly confidential |
| Severity modifier | Not applied; QALY weight = 1 |
| NICE threshold | GBP 20,000 to GBP 30,000 per QALY gained |

## R Implementation Plan

### Input Tables

Create these input tables:

- `model_settings`: cycle length, horizon, discount rate, starting age, severity modifier.
- `regimens`: dose, dosing interval, cycle limit, vial costs, administration cost.
- `survival_models`: subgroup, endpoint, arm, model type, parameter placeholders.
- `resource_use`: health state/status, scan/visit/blood-test weekly frequencies.
- `utilities`: health state, value, source, public status.
- `ae_inputs`: AE name, rate by arm, cost, disutility, duration, public status.
- `subsequent_treatments`: subgroup, prior arm, treatment, proportion, weekly cost, duration.
- `scenario_settings`: company base case, EAG preferred, committee preferred.

### Core Functions

```r
make_time_grid <- function(horizon_years = 35, cycle_length_weeks = 1)

surv_parametric <- function(t, dist, pars)

surv_spline <- function(t, scale, knots, coefficients)

apply_general_population_mortality_cap <- function(os_curve, age, sex = "female")

cap_pfs_crossing <- function(pfs_ct, pfs_pembro)

apply_os_waning <- function(os_pembro, os_ct, start_year = 5, end_year = 7, target_prop = 1)

make_psm_trace <- function(pfs, os)

calculate_drug_costs <- function(trace, regimen, ttd_curve)

calculate_health_state_costs <- function(trace, resource_use)

calculate_ae_costs_qalys <- function(ae_inputs)

calculate_subsequent_treatment_costs <- function(pd_entries, subsequent_treatment_mix)

calculate_qalys <- function(trace, utilities, age_adjustment)

discount <- function(value, cycle, annual_rate = 0.035, cycles_per_year = 52)

calculate_icer <- function(cost_int, qaly_int, cost_comp, qaly_comp)
```

### Algorithm

1. Build weekly time grid for 35 years.
2. Load subgroup-specific scenario settings.
3. Generate PFS and OS curves by subgroup, endpoint, and arm.
4. Apply general population mortality cap to OS.
5. For pMMR, cap chemotherapy PFS so it never exceeds pembrolizumab + chemotherapy PFS.
6. Apply treatment-effect waning to pembrolizumab OS from years 5 to 7 under EAG/committee scenarios.
7. Enforce `OS >= PFS` for each arm and subgroup.
8. Compute PSM state occupancy: PF = PFS, PD = OS - PFS, Death = 1 - OS.
9. Apply drug and administration costs during combination and maintenance phases, bounded by TTD and stopping rules.
10. Apply health-state resource-use costs by on-treatment/off-treatment/PF/PD status.
11. Apply one-off AE costs and disutilities in cycle 1.
12. Apply one-off subsequent-treatment cost on entry into PD.
13. Apply one-off terminal-care cost on transition to death.
14. Apply utilities and age adjustment.
15. Discount costs and QALYs at 3.5% per year.
16. Sum total discounted costs and QALYs.
17. Calculate incremental costs, incremental QALYs, and ICERs.
18. Run scenarios: company base case, EAG preferred, committee preferred, waning/no waning, pMMR PFS cap/no cap.

## KM Digitisation and Pseudo-IPD Feasibility

NotebookLM was asked whether the TA1092 sources include visible Kaplan-Meier curves that could support digitisation and pseudo-IPD reconstruction using the Guyot method.

Key conclusion:

- Correction after follow-up check: the original standalone dMMR/pMMR subgroup KM curves are **not visible in the public committee papers** available in the notebook.
- The public documents state that the EAG digitised subgroup PFS/OS plots from **CS Section E.2**, but the underlying company appendix containing those original subgroup plots appears to be omitted from the public PDF compilation.
- The original standalone KM curves publicly available for primary digitisation are the **all-comer** curves in Document B.
- Subgroup curves are publicly visible only as **EAG modelling overlay plots** in Appendix 9 of the EAG supplementary report. These may show the EAG's reconstructed `KM Est` step-lines, but they are not clean original KM plots.
- Therefore, subgroup digitisation from public sources is possible only as a rough fallback/validation exercise and would compound digitisation error.

| Curve needed | Present in sources? | Visible/not redacted? | Numbers at risk visible? | Source figure/page | Digitisation feasibility | Notes |
|---|---|---|---|---|---|---|
| All-comer PFS | Yes | Yes | Yes | CS Document B, Figure 5 | Moderate/poor | Dashed control line and thick censor marks may disrupt automated pixel tracking. |
| All-comer OS | Yes | Yes | Yes | CS Document B, Figure 6 | Moderate/poor | Same dashed-line and censor-mark issues; EAG noted extraction accuracy issues. |
| dMMR PFS | Original plot not publicly visible | EAG overlay visible only | Unclear from NotebookLM text | EAG Appendix 9 overlay figures | Low/moderate | Original CS Section E.2 plot omitted from public PDF; overlay can only support rough approximation/validation. |
| dMMR OS | Original plot not publicly visible | EAG overlay visible only | Unclear from NotebookLM text | EAG Appendix 9 overlay figures | Low/moderate | Original CS Section E.2 plot omitted from public PDF; overlay can only support rough approximation/validation. |
| pMMR PFS | Original plot not publicly visible | EAG overlay visible only | Unclear from NotebookLM text | EAG Appendix 9 overlay figures | Low/moderate | Original CS Section E.2 plot omitted from public PDF; overlay can only support rough approximation/validation. |
| pMMR OS | Original plot not publicly visible | EAG overlay visible only | Unclear from NotebookLM text | EAG Appendix 9 overlay figures | Low/moderate | Original CS Section E.2 plot omitted from public PDF; overlay can only support rough approximation/validation. |
| All-comer TTD | Yes | Yes | Unclear from NotebookLM text | CS Document B, Figure 47 | Moderate | Useful for treatment discontinuation and drug-cost modelling. |
| All-comer DOR | Yes | Yes | Yes | CS Document B, Figure 7 | Moderate | Secondary; not essential for the main PSM. |
| All-comer PFS2 | Yes | Yes | Unclear from NotebookLM text | CS Document B, Figure 8 | Moderate | Secondary exploratory endpoint; not essential for the main PSM. |

User manual check on 29 May 2026:

- Public NICE Figure 5 appears to show the title, key, and source only; the PFS plot body is not visible in the accessible PDF/screenshot.
- Public NICE Figure 6 all-comer OS is visible with axes, arm lines, censor marks, and number-at-risk table.
- Therefore, update the practical interpretation: **clean NICE-source digitisation is currently reliable only for all-comer OS, not all-comer PFS**.
- Any PFS reconstruction should use an external publication, EAG overlay, landmark calibration, or synthetic placeholder curves rather than claiming extraction from NICE Figure 5.

External publication / appendix image check by user on 29 May 2026:

| External figure | Content | Usefulness for replication | Digitisation priority | Notes |
|---|---|---|---|---|
| NEJM Figure 2A | dMMR PFS KM, pembrolizumab + chemotherapy vs placebo + chemotherapy | Directly useful | Very high | Clear subgroup PFS curve, event counts, patient counts, median PFS, HR, and number-at-risk table. Best source for dMMR PFS pseudo-IPD. |
| NEJM Figure 2B | pMMR PFS KM, pembrolizumab + chemotherapy vs placebo + chemotherapy | Directly useful | Very high | Clear subgroup PFS curve, event counts, patient counts, median PFS, HR, and number-at-risk table. Best source for pMMR PFS pseudo-IPD. |
| Supplementary Figure S1A | dMMR interim OS KM | Useful with caveats | Medium | OS curve is visible with number-at-risk information. It appears to be interim OS rather than the later NICE August 2023 update, so use as a technical demonstration or sensitivity input, not as exact NICE replication. |
| Supplementary Figure S1B | pMMR interim OS KM | Useful with caveats | Medium | OS curve is visible with number-at-risk information. Same caveat: likely interim OS, not exact NICE update. |
| Supplementary Figure S4A | dMMR PFS KM with 95% pointwise confidence intervals | Useful as validation | Low/medium | Smaller plot with confidence bands; use to validate Figure 2A or extract 10th percentile/early survival landmarks, not as first-choice digitisation source. |
| Supplementary Figure S4B | pMMR PFS KM with 95% pointwise confidence intervals | Useful as validation | Low/medium | Smaller plot with confidence bands; use to validate Figure 2B or extract 10th percentile/early survival landmarks, not as first-choice digitisation source. |
| Supplementary Figure S3 | All-comer PFS KM | Useful replacement for missing NICE Figure 5 | High | Provides all-comer PFS curve with events, total N, median PFS, and number-at-risk table. Useful if the QMD includes an all-comer PFS demonstration. |

Updated implication:

- The best public technical route is now to digitise **NEJM Figure 2A/B for subgroup PFS** and use **supplementary Figure S1A/B for subgroup OS** if OS reconstruction is required.
- This will not exactly reproduce the NICE August 2023 economic model because the publication/appendix curves may use a different data cut and reporting basis.
- The QMD should label these as `public trial publication reconstruction`, separate from `NICE committee-paper economic model replication`.
- For a rigorous portfolio story, use publication-derived pseudo-IPD to demonstrate survival fitting mechanics, then discuss how the EAG/NICE model used later and partly non-public subgroup evidence.

Implication for the QMD:

- A clean public-source Guyot reconstruction is feasible for all-comer PFS/OS, but not for original dMMR/pMMR subgroup PFS/OS because the original subgroup KM plots are omitted from public papers.
- The first implementation can either: (a) digitise all-comer PFS/OS as the high-fidelity technical demonstration, or (b) approximate subgroup curves from EAG overlay `KM Est` lines while clearly labelling this as secondary extraction from already reconstructed plots.
- TTD digitisation is useful but optional. A simpler first version can model treatment costs using the published stopping rule and a simplified treatment-duration curve.
- Before coding, manually inspect Document B Figures 5, 6, 7, 8 and 47, plus EAG Appendix 9 Figures 5-44, to decide whether subgroup overlay extraction is worth doing.

### Exact KM Plot Location Check

NotebookLM was asked for the specific location of dMMR and pMMR PFS/OS KM curves. A follow-up check corrected the earlier interpretation: the **original company KM plots in Company Submission Appendix E, Section E.2 are referred to by the EAG but are not visible in the public committee papers PDF compilation**. The EAG supplementary report states that, in the absence of Kaplan-Meier IPD, it digitised the PFS and OS plots for the MMR subgroups presented in CS Section E.2, but those original CS Appendix E plots are omitted from the public documents available in the notebook.

Important limitation: there may be no public page/figure number to inspect for the original subgroup plots, because Appendix E appears not to be publicly included.

| Curve | Best source document | Section/appendix | Figure/page reference | Original vs EAG overlay | Arms shown | Numbers at risk | Visual clarity | Recommended for digitisation? | Notes |
|---|---|---|---|---|---|---|---|---|---|
| dMMR PFS | Not publicly visible as original company plot | CS Appendix E, Section E.2 referenced by EAG only | Not publicly available in current source set | Original company KM plot omitted; EAG overlay visible | Pembrolizumab + chemotherapy vs placebo + chemotherapy | Not available | EAG found it digitisation-ready, but public cannot access original plot | No for clean public reconstruction | Use EAG overlay only as rough fallback or seek CS Appendix E via FOI/source request. |
| dMMR OS | Not publicly visible as original company plot | CS Appendix E, Section E.2 referenced by EAG only | Not publicly available in current source set | Original company KM plot omitted; EAG overlay visible | Pembrolizumab + chemotherapy vs placebo + chemotherapy | Not available | EAG found it digitisation-ready, but public cannot access original plot | No for clean public reconstruction | Use EAG overlay only as rough fallback or seek CS Appendix E via FOI/source request. |
| pMMR PFS | Not publicly visible as original company plot | CS Appendix E, Section E.2 referenced by EAG only | Not publicly available in current source set | Original company KM plot omitted; EAG overlay visible | Pembrolizumab + chemotherapy vs placebo + chemotherapy | Not available | EAG found it digitisation-ready, but public cannot access original plot | No for clean public reconstruction | Use EAG overlay only as rough fallback or seek CS Appendix E via FOI/source request. |
| pMMR OS | Not publicly visible as original company plot | CS Appendix E, Section E.2 referenced by EAG only | Not publicly available in current source set | Original company KM plot omitted; EAG overlay visible | Pembrolizumab + chemotherapy vs placebo + chemotherapy | Not available | EAG found it digitisation-ready, but public cannot access original plot | No for clean public reconstruction | Use EAG overlay only as rough fallback or seek CS Appendix E via FOI/source request. |

EAG Appendix 9 contains reconstructed / overlay plots. These are **not** recommended for clean raw KM digitisation because the KM estimates are overlaid with many parametric and spline curves, but they are the only public subgroup curve visuals currently identified.

| Curve | EAG overlay location | EAG figure references from NotebookLM | Recommended for raw digitisation? | Reason |
|---|---|---|---|---|
| dMMR PFS | Final draft guidance committee papers, EAG Supplementary Report Appendix 9 | Figures 5, 8, 15, 18 | No | Cluttered overlay with multiple parametric/spline fits. |
| dMMR OS | Final draft guidance committee papers, EAG Supplementary Report Appendix 9 | Figures 10, 13, 20, 23 | No | Cluttered overlay with multiple parametric/spline fits. |
| pMMR PFS | Final draft guidance committee papers, EAG Supplementary Report Appendix 9 | Figures 25, 28, 35, 38 | No | Cluttered overlay with multiple parametric/spline fits. |
| pMMR OS | Final draft guidance committee papers, EAG Supplementary Report Appendix 9 | Figures 30, 33, 40, 43 | No | Cluttered overlay with multiple parametric/spline fits. |

Practical next step:

1. Use Document B Figures 5 and 6 for high-fidelity all-comer PFS/OS reconstruction.
2. Inspect EAG Appendix 9 Figures 5-44 to see whether the `KM Est` step-lines can be approximately extracted for subgroup demonstration.
3. Treat any subgroup curve extraction from EAG overlay plots as approximate and second-generation, not equivalent to original CS KM digitisation.
4. Consider recording the missing CS Appendix E as a real-world public-evidence limitation in the QMD.
5. If a high-fidelity subgroup reconstruction is essential, consider an FOI/source request for CS Appendix E or use landmark survival calibration instead.

## Replication Feasibility

| Component | Fully reproducible? | Barrier | Workaround for portfolio case | Importance |
|---|---|---|---|---|
| Model structure and cycle length | Yes | None | Implement 3-state weekly PSM over 35 years | High |
| Survival parameters | No | Exact parametric/spline parameters redacted | Reconstruct pseudo-IPD from visible KM curves or calibrate to reported landmark survival probabilities | High |
| KM digitisation | Partially | Curves appear visible, but dashed lines and censor marks may affect extraction accuracy | Prioritise dMMR/pMMR PFS and OS curves; use WebPlotDigitizer/manual correction; document uncertainty | High |
| Curve crossing cap | Yes | None | Implement `pmin(PFS_CT, PFS_pembro)` for pMMR PFS | High |
| Treatment-effect waning | Mostly | Need verify target population: all patients vs non-CR only | Implement flexible function with both settings as scenarios | High |
| Drug/admin list costs | Yes | Confidential CAA discount unavailable | Use list prices and state this limitation | High |
| Exact ICER replication | No | Confidential discounts and redacted parameters | Present directional ICERs and scenario deltas, not claimed NICE ICER | High |
| Health-state utilities | Partially | Base-case values redacted | Use public scenario utilities or plausible placeholders, labelled clearly | Medium |
| AE modelling | Partially | AE rates/durations may be redacted | Use public AE costs/disutilities; sensitivity analysis for rates | Medium |
| Subsequent treatment costs | Partially | Some proportions/costs public, full detail may be incomplete | Build weighted average one-off PD-entry cost using public proportions | Medium |
| PSA | No | Distributions/covariance/confidential inputs missing | Omit PSA or use illustrative deterministic scenario analysis | Low-medium |

## Recommended Quarto Strategy

Replicate exactly:

- 3-state PSM structure.
- Weekly cycle length.
- 35-year horizon.
- 3.5% annual discounting.
- 2-year pembrolizumab stopping rule.
- 6-cycle chemotherapy phase and 14-cycle pembrolizumab maintenance phase.
- EAG/committee pMMR PFS curve-crossing cap.
- Committee preferred 5-7 year treatment-effect waning scenario.
- Public list prices, administration costs, AE costs/disutilities, and terminal-care cost.

Replicate approximately:

- Survival curves, using calibrated or synthetic parameters.
- Subgroup-specific QALY and cost outputs.
- Subsequent-treatment cost as a weighted average.
- Utility values using public scenario proxies or clearly labelled placeholders.

Discuss qualitatively:

- Why the EAG preferred separate dMMR and pMMR analyses.
- Why OS immaturity makes the company's tail extrapolation vulnerable.
- Why curve crossing is both a technical and clinical plausibility issue.
- Why treatment stopping is not the same as treatment-effect waning.
- Why exact NICE ICERs cannot be reproduced from public materials.

Avoid:

- Claiming exact reproduction of confidential ICERs.
- Reconstructing the commercial access agreement.
- Overfitting fake survival parameters to imply precision.
- Full PSA unless the public parameter distributions are sufficient.

## Suggested QMD Figures and Tables

Figures:

- PSM structure and dosing timeline.
- dMMR and pMMR survival model selection diagram.
- pMMR PFS crossing/cap diagnostic.
- OS treatment-effect waning plot from years 5 to 7.
- State occupancy traces for company-style and EAG-style scenarios.
- Tornado-style deterministic scenario comparison, if enough public values exist.

Tables:

- Model settings and decision problem.
- Company vs EAG vs committee assumptions.
- Survival model selection matrix.
- Public parameter inventory.
- Confidentiality/reproducibility barrier table.
- Scenario results table using labelled approximate or synthetic inputs.

## Top 10 Facts to Verify Manually Before Coding

1. Whether committee preferred waning applies to all patients or only those without complete response.
2. Exact pMMR PFS cap wording and whether cap is applied to PFS probabilities, hazards, or extrapolated curve selection.
3. Survival model selections in final draft guidance versus final guidance.
4. Whether dMMR and pMMR starting age is exactly 65.4 in the committee preferred case.
5. Whether the cycle length is consistently weekly in all cost and utility calculations.
6. Whether pembrolizumab 20-cycle treatment duration maps exactly to 24 months in model cycles.
7. Which utility set the committee finally preferred for PF and PD health states.
8. Which AE rates are public and whether immune-related AEs at 2% are included only in scenario analysis.
9. How subsequent-treatment proportions differ by subgroup and prior arm.
10. Whether landmark survival probabilities are available and sufficient for calibration.

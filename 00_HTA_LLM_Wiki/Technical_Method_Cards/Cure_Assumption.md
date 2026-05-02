---
tags: [hta-concept]
---

# Cure Assumption

Modelling assumption that patients in a defined disease state (e.g., sustained complete remission) are assumed to revert to general population mortality rates after a specified time horizon, rather than carrying elevated cancer mortality indefinitely (来源：/raw/storyboards/TA1013_Quizartinib_FLT3-ITD_AML.md, Section 3).

## Why Companies Use It
Allows lifetime economic models to avoid extrapolating unfavourable mortality trends beyond available trial follow-up, thereby improving projected QALYs and ICER. In [[TA1013]], [[Quizartinib]] company applied a "cure assumption" at exactly 3 years for patients in complete remission or post-[[HSCT]], reverting them to general population mortality thereafter (来源：/raw/storyboards/TA1013_Quizartinib_FLT3-ITD_AML.md, Section 3).

## Why EAG Challenges It
EAG challenges on two fronts: (1) [[AML_FLT3-ITD]] patients do not truly "cure" at 3 years; relapse risk persists, especially in older patients; (2) in second-line (2L) setting, company's [[Markov_Model]] explicitly denied 2L cure possibility, creating asymmetric punishment of the comparator arm (more failures → all deaths; no 2L recovery). This biases ICER against [[Midostaurin]] (来源：/raw/storyboards/TA1013_Quizartinib_FLT3-ITD_AML.md, Section 4, Conflict 3).

## Committee Judgment Tendencies

Based on [[TA1013]] and [[TA1017]], the committee's decision logic is as follows:

**Conditions under which the cure assumption is accepted:**
- Biological plausibility is supported by disease-specific literature (e.g., documented long-term cure rates in haematological malignancies post-CR)
- Applied symmetrically across both treatment and comparator arms — no one-sided advantage
- Accompanied by SMR sensitivity analyses demonstrating that conclusions are robust to the assumption

**Conditions under which the cure assumption is rejected:**
- The disease carries ongoing relapse risk beyond the assumed cure horizon (e.g., late relapse in AML beyond 3 years)
- Patients carry permanent comorbidity burden that prevents reversion to general population mortality (e.g., smoking history and chemotherapy toxicity in NSCLC)
- The assumption is applied asymmetrically — treatment arm granted cure while comparator arm is denied equivalent recovery
- Trial follow-up is too immature to credibly support a cure timepoint

## Preventive Modelling Guidance for Companies

> ⚠️ The following is inferential guidance derived from case records — not sourced from primary documents. Apply with judgement and revise as further cases are ingested.

1. **Symmetry first**: If the cure assumption is applied only to the treatment arm while the comparator arm is denied equivalent recovery, EAG will challenge it without exception. Ensure both arms follow the same structural logic, or provide explicit clinical justification for any asymmetry in the submission.

2. **Disease-specific evidence**: Do not rely on generic survival curve assumptions. Cite long-term follow-up data or registry evidence specific to the indication to justify the cure timepoint (e.g., 10-year AML registry data rather than a generic 3-year threshold).

3. **SMR assumptions**: For diseases with smoking history, chemo/radiotherapy toxicity, or chronic comorbidities, proactively incorporate SMR > 1.0 sensitivity analyses rather than waiting for EAG to demand them. This signals model robustness and reduces back-and-forth.

4. **Cure timepoint selection**: The earlier the assumed cure timepoint, the more vulnerable it is to EAG challenge. Select a timepoint consistent with the disease's natural history and clinical consensus, and support it with clinical expert opinion documented in the submission.

## Case Records

### [[TA1013]]
- **Company 1L cure**: Applied at 3 years post-CR or post-HSCT; patients revert to general population mortality
- **Company 2L**: No cure allowed; relapsed patients on [[Gilteritinib]] face death without recovery option
- **EAG critique**: 2L "no-cure" violates [[Partitioned_Survival_Model|PSM]] structure used in prior [[TA523]] and [[TA642]] appraisals; EAG requested nested 2L PSM with 90% [[Gilteritinib]] uptake and cure possibility
- **Company revision**: Provided 2L PSM scenario; noted ICER worsened slightly with cure included
- **Committee**: "EAG's modelling of second-line treatment was more appropriate... better reflected both previous evaluation of gilteritinib and expected NHS clinical practice" (来源：/raw/storyboards/TA1013_Quizartinib_FLT3-ITD_AML.md, Section 4, Conflict 3)
- **ICER impact**: Adding 2L cure worsens ICER for [[Quizartinib]] (reduces asymmetric mortality penalty on [[Midostaurin]] arm)

### [[TA1017]]

**Company Assumption** (来源：/raw/storyboards/TA1017_Pembrolizumab_Resectable_NSCLC.md, Section 4, Conflict 2):
- 95% of event-free patients assumed "cured" at 7 years post-surgery
- Cured patients revert to age- and sex-matched general population mortality rates
- SMR = 1.0 (no excess mortality)
- Reflects biologic concept: early NSCLC successfully treated = functional cure

**Impact on QALY/ICER**:
Cure assumption (SMR = 1.0) inflates long-term life expectancy, significantly overestimating total QALYs gained by pembrolizumab over 36.9-year lifetime horizon.

**EAG Challenge** (EAG report, Section 1.5; TA1017, Section 3.13):
> "Patients alive after 5 years may experience long-term excess mortality due to the increased risk of a second cancer diagnosis."
- NSCLC survivors carry permanent excess mortality from smoking history, chemotherapy toxicity, radiation
- Risk of therapy-induced second malignancy persists lifelong
- Cardiovascular disease (smoking-related comorbidities) remains elevated
- Cannot assume reversion to general population mortality

**EAG Demand**: 
Apply Standardized Mortality Ratio (SMR) = 1.453 to general population mortality for all surviving patients, reflecting permanent ~45% excess mortality burden.

**Committee Resolution** (TA1017, Section 3.14):
"Agreed that people who have had NSCLC would not have the same mortality as the general population," largely due to smoking history and cardiovascular comorbidities. (来源：/raw/storyboards/TA1017_Pembrolizumab_Resectable_NSCLC.md, Section 4)
- **Accepted EAG's SMR = 1.453** as final parameter
- Applied to all event-free survivors (not just post-cure population)
- No time-limit; permanent excess mortality assumption

**Net Impact**:
SMR 1.453 vs. 1.0 reduces cumulative projected survival over 36.9-year horizon by ~1.5–2.5 QALYs, raising ICER by approximately £2,000–£5,000 per QALY. Despite this reduction, pembrolizumab remained recommended, indicating baseline ICER remained below threshold.

**Key Difference from TA1013**:
- **TA1013 (Quizartinib)**: Cure assumption contested for symmetry (2L arm denied cure); EAG modified structural asymmetry
- **TA1017 (Pembrolizumab)**: Cure assumption rejected outright; SMR imposed across all survivors universally

**Lesson**: NSCLC/lung disease cases particularly vulnerable to cure assumption challenge due to smoking-related permanent comorbidities and therapy toxicity burden.

### [[TA975]] ([[Tisagenlecleucel]] in r/r B-cell ALL)

Note: In TA975, the cure assumption is implemented via a [[Mixture_Cure_Model]] (MCM) — a specific statistical methodology that embeds the cure fraction directly into the survival extrapolation structure, rather than applying it as a post-hoc adjustment. See [[Mixture_Cure_Model]] for full case record.

**Key distinction from TA1013/TA1017**: In those cases, the cure assumption was a modelling *choice* applied on top of a parametric survival model. In TA975, MCM is the *model structure itself* — the cure fraction is a parameter estimated from the data, not imposed externally. EAG challenge focused on which data fed the MCM (ELIANA-only vs. pooled), not on whether MCM was appropriate.

**Committee verdict**: MCM structure accepted without challenge; EAG's demand for pooled input data was upheld. (来源：/raw/storyboards/TA975_Tisagenlecleucel_CAR_T_ALL.md, Section 4, Conflict 1)

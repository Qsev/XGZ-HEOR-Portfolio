---
tags: [hta-concept]
---

# Partitioned Survival Model (PSM)

Economic modelling framework that estimates the proportion of patients in each health state (e.g., progression-free, post-progression, dead) directly from survival curves, without explicit state-transition probabilities. Each health state is defined as the area between two survival curves, and patients are "partitioned" across states at each model cycle. Contrasts with the [[Markov_Model]], which requires explicit transition probabilities between states (来源：/raw/storyboards/TA1013_Quizartinib_FLT3-ITD_AML.md, Section 4, Conflict 3).

## Why Companies Use It

PSM is structurally simpler than a Markov model and requires fewer parametric assumptions about how patients move between states. It is particularly useful when:
- Trial data is available as survival curves (PFS, OS) rather than state-transition counts
- The disease has a natural progression-free → post-progression → death structure
- The company wants to incorporate long-term extrapolation directly from parametric curve fits

In [[TA1086]], [[Ribociclib]]'s manufacturer used a semi-Markov + PSM hybrid — applying PSM specifically to the distant-recurrence substates where transition probability data was sparse, allowing more flexible modelling of treatment-sensitive and treatment-resistant states.

## Why EAG Prefers It (and When They Demand It)

EAG tends to prefer PSM over Markov when:
- Prior NICE appraisals for the same drug class used PSM (consistency with precedent)
- The Markov structure imposes artificial constraints that disadvantage the comparator arm (e.g., denying cure in the 2L setting)
- PSM better reflects NHS clinical practice by allowing flexible treatment sequencing

In [[TA1013]], EAG demanded replacement of the company's 2L Markov structure with a nested PSM precisely because the Markov model denied [[Cure_Assumption|cure]] in the second-line setting, creating an asymmetric penalty on [[Midostaurin]] (来源：/raw/storyboards/TA1013_Quizartinib_FLT3-ITD_AML.md, Section 4, Conflict 3).

## Committee Judgment Tendencies

Based on [[TA1013]] and [[TA1086]]:

**Conditions under which PSM is endorsed or mandated:**
- A prior NICE appraisal for the same comparator drug used PSM — consistency with precedent carries significant weight
- The alternative Markov structure introduces asymmetric structural disadvantages to the comparator arm
- Clinical experts confirm that PSM better reflects the actual NHS treatment pathway

**Conditions under which PSM is accepted as-is (company choice):**
- The PSM structure itself is not the source of controversy — the dispute is about inputs (parametric curves, immature data) rather than model architecture
- EAG accepts the structural framework but challenges specific parameters within it

**Key pattern**: The committee rarely overrides the choice of PSM vs. Markov on technical grounds alone. The trigger for demanding a structural change (as in TA1013) is almost always an **asymmetry** — when the chosen structure demonstrably disadvantages one arm in a way that is not clinically justified. When both sides can use the same structure symmetrically, the committee accepts whichever the company chose and focuses scrutiny on the inputs instead.

## Preventive Modelling Guidance for Companies

> ⚠️ The following is inferential guidance derived from case records — not sourced from primary documents. Apply with judgement and revise as further cases are ingested.

1. **Check precedent before choosing model structure**: If a prior NICE appraisal for your key comparator used PSM, defaulting to a different structure requires explicit justification. EAG will use the precedent to demand consistency, and the committee tends to agree.

2. **Symmetry test your structure**: Before submission, ask — does this model structure apply the same logic to both the treatment arm and the comparator arm? If the answer is no (e.g., treatment arm can achieve cure but comparator arm cannot), EAG will flag it. Either justify the asymmetry with clinical evidence or redesign for symmetry.

3. **Hybrid PSM + Markov is acceptable if justified**: The TA1086 semi-Markov + PSM hybrid was accepted without structural challenge. A mixed approach is viable when different parts of the disease pathway genuinely warrant different structures — but the reasoning should be documented explicitly in the submission.

4. **Distinguish structural challenges from input challenges**: If EAG is challenging your parametric curves or transition probabilities, that is a different problem from challenging your model structure. Do not conflate the two. A structurally sound PSM with disputed inputs is a more defensible position than a structurally challenged Markov with clean inputs.

## Case Records

### [[TA1013]]

- **Company**: Built a Markov state-transition model for 2L treatment that explicitly disallowed patient recovery or cure after relapse — relapsed patients on [[Gilteritinib]] faced only death as an outcome, with no recovery state (来源：/raw/storyboards/TA1013_Quizartinib_FLT3-ITD_AML.md, Section 4, Conflict 3)
- **EAG**: Flagged structural asymmetry — 1L [[Cure_Assumption]] was allowed for [[Quizartinib]] patients, but 2L cure was denied for the comparator ([[Midostaurin]]) arm via Markov structure. Demanded replacement with nested 2L PSM with 90% [[Gilteritinib]] uptake and 2L cure possibility, consistent with [[TA523]] and [[TA642]] precedents
- **Company revision**: Provided 2L PSM scenario as requested; acknowledged ICER worsened slightly when 2L cure was included
- **Committee**: "EAG's modelling of second-line treatment was more appropriate... better reflected both previous evaluation of gilteritinib and expected NHS clinical practice." Endorsed PSM as the accepted 2L structure (来源：/raw/storyboards/TA1013_Quizartinib_FLT3-ITD_AML.md, Section 4, Conflict 3)
- **ICER impact**: Switching to 2L PSM with cure removed the asymmetric mortality penalty on [[Midostaurin]] arm, worsening [[Quizartinib]]'s relative ICER advantage

### [[TA1086]]

- **Company**: Used a semi-Markov model with PSM submodel for distant-recurrence health states — a hybrid approach applying PSM to the substates (ET-resistant and ET-sensitive distant recurrence) where transition probability data was sparse (来源：/raw/storyboards/TA1086_Ribociclib_Adjuvant_Early_Breast_Cancer.md, Section 3-4)
- **EAG**: Did not challenge the PSM/semi-Markov hybrid structure itself. Scrutiny focused entirely on the parametric curve inputs ([[Immature_Data_Extrapolation]], [[Curve_Fitting_Parametric_Assumptions]]) — specifically demanding uniform parametric distributions across both arms rather than arm-specific distributions
- **Company revision**: Accepted uniform parametric approach under committee pressure
- **Committee**: Accepted the structural hybrid without comment; directed all attention to parametric curve consistency
- **ICER impact**: Structural PSM choice had no direct ICER impact — the ICER movement came from parametric curve changes, not model architecture

### [[TA975]] ([[Tisagenlecleucel]] in r/r B-cell ALL)

- **Company**: Used a PSM with three health states (Event-Free, Relapsed/Progressed, Dead) plus an upfront decision tree for manufacturing failure/pre-infusion death. Survival curves extrapolated using [[Mixture_Cure_Model]] within PSM framework — cure fraction estimated from ELIANA trial data. 88-year time horizon. (来源：/raw/storyboards/TA975_Tisagenlecleucel_CAR_T_ALL.md, Section 3)
- **EAG**: Did not challenge PSM structure or the MCM extrapolation method. All three EAG conflicts focused on model *inputs*: which trial data to use (ELIANA vs. pooled), which comparator historical trials to use, and IVIg duration.
- **Committee**: PSM + MCM structure accepted without challenge. Pattern consistent with TA1086: when EAG disputes are about inputs rather than architecture, the committee focuses on inputs and accepts the structure.
- **ICER impact**: PSM structure itself had no ICER impact; all ICER movements in TA975 came from input parameter changes (pooled vs. ELIANA data, IVIg duration).

### [[TA992]] ([[Trastuzumab_Deruxtecan]] in HER2-low metastatic breast cancer)

- **Company**: Used a PSM with three health states (Progression-Free, Post-Progression, Dead); 3-week cycle, 30-year time horizon. Standard parametric curves fitted to DESTINY-Breast04 Kaplan-Meier data. (来源：/raw/storyboards/TA992_Trastuzumab_Deruxtecan_HER2low.md, Section 3)
- **EAG**: Did not challenge PSM structure. All disputes focused on parametric curve inputs (OS extrapolation — log-logistic vs. modified gamma) and utility values (LMM vs. Lloyd decrement).
- **Committee**: PSM structure accepted without comment. Consistent pattern across TA1013, TA1086, TA975, TA992: PSM structure is never the target of EAG challenge when both arms use the same framework symmetrically.
- **ICER impact**: PSM structure had no direct ICER impact. The "not recommended" outcome was entirely driven by the parametric curve clash (modified gamma imposed on T-DXd arm), not by model architecture.

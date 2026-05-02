---
tags: [method, rwe]
method_family: Weighting
aliases: [AIPW, Augmented IPW, Doubly Robust AIPW]
---

# Augmented Inverse Probability Weighting (AIPW)

A causal inference method that combines propensity score weighting ([[IPTW_Inverse_Probability_Treatment_Weighting]]) with outcome prediction models, achieving **[[Double_Robustness]]** — remaining unbiased if either the propensity score model or the outcome model is correctly specified; gold-standard method in HTA submissions due to dual protection against model misspecification.

## Core Logic

(Condensed from: `/raw/methods/RWE_Logic_06a_AIPW_Full_Audit.md`, Phases 1–5)

AIPW estimates the average treatment effect by combining two independent components:

1. **Weighting Component (IPTW):** Inverse propensity score weights to balance observed covariates
2. **Augmentation Component:** Predicted [[Potential_Outcomes]] from outcome regression models to correct residual bias

**Formula for treated potential outcome:**

$$\hat{Y}_i^{(1)*} = \underbrace{\hat{m}_1(X_i)}_{\text{Outcome Model}} + \underbrace{\frac{D_i(Y_i - \hat{m}_1(X_i))}{\widehat{PS}_i}}_{\text{Weighted Residual}}$$

- **First term** ($\hat{m}_1$): Predicted outcome if treated, from regression on treated subgroup
- **Second term**: Weighting-based correction using actual data and PS

Similarly for control: $\hat{Y}_i^{(0)*} = \hat{m}_0(X_i) + \frac{(1-D_i)(Y_i - \hat{m}_0(X_i))}{1-\widehat{PS}_i}$

**Final ATE:** $\widehat{\text{ATE}} = E[\hat{Y}^{(1)*}] - E[\hat{Y}^{(0)*}]$

(Condensed from: `/raw/methods/RWE_Logic_06a_AIPW_Full_Audit.md`, Phases 3–5)

## When It Appears in HTA Submissions

(Condensed from: `/raw/methods/RWE_Logic_07_IPTW_AIPW_HTA_Advanced.md`, Section 3)

**Use Cases:**
- **First-line evidence synthesis:** When both PS and outcome models are available from data
- **Ultra-rare diseases:** Combined with [[IPTW_Inverse_Probability_Treatment_Weighting]] for maximum efficiency (zero sample loss via weighting + dual robustness)
- **High-confidence HTA submissions:** AIPW is the "gold standard" covariate balance method; EAG expects it when feasible

**Problem Being Solved:** 
Selection bias where single-model approaches (PSM or IPTW alone) are insufficient; AIPW leverages both PS and outcome information for robustness.

(Condensed from: `/raw/methods/RWE_Logic_07_IPTW_AIPW_HTA_Advanced.md`, Section 3)

## Known EAG Challenge Patterns

> ⚠️ Inferred from source documents pending empirical case validation.

(Condensed from: `/raw/methods/RWE_Logic_06a_AIPW_Full_Audit.md`, Sections 2, 6)

1. **Outcome Model Misspecification:** Company claims "doubly robust" but outcome models are severely misspecified (missing interactions, nonlinearity). EAG demands model diagnostics and specification tests.

2. **Extreme Weights Still Present:** Even with outcome augmentation, extreme PS weights drive results. Company must report [[Effective_Sample_Size]] and justify weight distribution.

3. **Variance Estimation Unclear:** EAG asks: "How did you calculate confidence intervals?" If via [[Influence_Functions]], explain assumptions. If via bootstrapping, justify approach for small samples.

4. **Post-Hoc Variable Selection:** Company adds outcome model variables after observing IPTW results. EAG flags as cherry-picking; demands pre-specification.

5. **Outcome Model Only on Treated/Control Subgroup:** If $\hat{m}_1$ fit only to D=1 patients, auditors question: Can predictions for D=0 patients be trusted? Demands justification.

## Distinction from [[IPTW_Inverse_Probability_Treatment_Weighting]]

| Aspect | AIPW | IPTW |
|:---|:---|:---|
| **Models used** | Propensity score + Outcome model | Propensity score only |
| **Robustness** | [[Double_Robustness]]: unbiased if either model correct | Single model: biased if PS is wrong |
| **Augmentation** | Corrects weights with predicted outcomes | No outcome correction |
| **Complexity** | Higher; requires two fitted models | Lower; single PS model |
| **Precision** | Better; outcome model provides auxiliary info | Lower; weights alone carry all information |

## Related Methods & Concepts

- [[IPTW_Inverse_Probability_Treatment_Weighting]] — Base weighting method; AIPW augments it
- [[TMLE_Targeted_Maximum_Likelihood_Estimation]] — Alternative doubly robust method; superior stability under extreme propensity scores
- [[Double_Robustness]] — Core theoretical property of AIPW
- [[Potential_Outcomes]] — Conceptual framework (Y^{(1)}, Y^{(0)})
- [[Outcome_Model]] — Predicted outcomes from regression on treated/control subgroups
- [[Influence_Functions]] — Method for computing valid confidence intervals in AIPW
- [[Propensity_Score]] — Foundation of the weighting component
- [[Pseudo_Population]] — Conceptual result of weighting; augmentation refines estimates
- [[Stabilized_Weights]] — Technique to improve weight stability in base IPTW before augmentation
- [[PSM_Propensity_Score_Matching]] — Alternative covariate balance approach (less flexible)

## HTA Case Records

<!-- Pending: awaiting first NICE case using AIPW to populate this section -->

## Source Anchor

> "In AIPW, the estimator is designed such that **Total Bias is proportional to the product of errors from both models**. You are only biased if you are wrong about how people get treated AND how they perform. This is the **Double Insurance Property**."

(来源：`/raw/methods/RWE_Logic_06a_AIPW_Full_Audit.md`, Phase 1)

## Source Files

- Fundamentals: `/raw/methods/RWE_Logic_06a_AIPW_Full_Audit.md`
- HTA Practice: `/raw/methods/RWE_Logic_07_IPTW_AIPW_HTA_Advanced.md`

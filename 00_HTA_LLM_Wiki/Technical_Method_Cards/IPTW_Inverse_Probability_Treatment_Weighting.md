---
tags: [method, rwe]
method_family: Weighting
aliases: [IPTW, Inverse Probability Weighting, Horvitz-Thompson Weights, IPW]
---

# Inverse Probability Treatment Weighting (IPTW)

A covariate balance method that creates a **pseudo-population** via inverse propensity score weighting, re-weighting the observed sample so that treatment assignment becomes independent of baseline covariates; maintains full sample size unlike matching approaches.

## Core Logic

(Condensed from: `/raw/methods/RWE_Logic_06_IPTW_Fundamentals.md`, Sections 1–3)

Instead of discarding unmatched observations (as in PSM), IPTW assigns each individual a weight inversely proportional to their probability of receiving the treatment they actually received:

$$W_i = \begin{cases} \frac{1}{\text{PS}_i} & \text{if } D_i = 1 \text{ (treated)} \\ \frac{1}{1 - \text{PS}_i} & \text{if } D_i = 0 \text{ (control)} \end{cases}$$

where PS is the propensity score $P(D=1|X)$.

**Intuition**: A patient with high propensity for treatment who is treated gets low weight (common occurrence, little information value). A patient with low propensity for treatment who is treated gets high weight (rare occurrence, high information value). Weighting up these rare cases and weighting down common cases creates a [[Pseudo_Population]] where treatment is independent of baseline covariates.

(Condensed from: `/raw/methods/RWE_Logic_06_IPTW_Fundamentals.md`, Sections 3–4)

## When It Appears in HTA Submissions

(Condensed from: `/raw/methods/RWE_Logic_07_IPTW_AIPW_HTA_Advanced.md`, Section 1)

**Use Cases:**
- **Small or ultra-rare disease populations** where PSM causes unacceptable sample loss (e.g., rare disease with N=100, matching discards 15%)
- **Preserving clinical spectrum**: When matched analysis would exclude severe patients who lack "twins," IPTW retains full population representation
- **Efficiency**: IPTW uses all available data through reweighting, producing narrower confidence intervals than matched analysis

**Problem Being Solved**: Selection bias in observational data, with emphasis on sample preservation; PSM is impossible when common support is very restricted.

(Condensed from: `/raw/methods/RWE_Logic_07_IPTW_AIPW_HTA_Advanced.md`, Section 1)

## Known EAG Challenge Patterns

> ⚠️ Inferred from source documents pending empirical case validation.

(Condensed from: `/raw/methods/RWE_Logic_07_IPTW_AIPW_HTA_Advanced.md`, Section 2)

1. **Extreme Weights**: If propensity scores approach 0 or 1, resulting weights become very large, making estimates unstable and unreliable. EAG demands strategy to handle: [[Stabilized_Weights]] or [[Weight_Trimming]].

2. **Effective Sample Size (ESS) Collapse**: EAG will calculate ESS = $(\sum W_i)^2 / \sum W_i^2$ and flag if it drops significantly (e.g., from 100 to 45), questioning information loss.

3. **Lack of Positivity**: If some covariate combinations have zero probability of treatment (or one), positivity assumption is violated and weights become undefined/infinite.

4. **Weight Specification Unjustified**: Company doesn't report weight distribution or explain strategy for handling extreme values. EAG demands comprehensive weight diagnostics.

5. **Missing Outcome Model**: When used alone (not AIPW), IPTW relies entirely on propensity score model correctness. If PS model misses interactions, estimates remain biased. EAG prefers [[Double_Robustness]] via AIPW.

## Distinction from [[PSM_Propensity_Score_Matching]]

| Aspect | IPTW | PSM |
|:---|:---|:---|
| **Sample Loss** | None; all observations retained via weighting | Significant; unmatched observations deleted |
| **Efficiency** | Higher; uses all data | Lower; only matched pairs used |
| **Extreme Covariates** | Can be problematic (extreme weights) | Automatically excluded via common support restriction |
| **Stability** | Requires weight stabilization/trimming | Inherently more stable |
| **Ease of Implementation** | Straightforward; standard in software | Standard; more intuitive |

## Related Methods & Enhancements

- [[Propensity_Score]] — Foundational concept; PS is the weighting basis
- [[Pseudo_Population]] — Conceptual outcome of IPTW; what we're creating
- [[Double_Robustness]] — Key property of AIPW, which enhances IPTW
- [[AIPW_Augmented_Inverse_Probability_Weighting]] — Augments IPTW with outcome model for robustness
- [[Stabilized_Weights]] — Modification to handle extreme PS values
- [[Weight_Trimming]] — Technique to prune extreme weight outliers
- [[Effective_Sample_Size]] — Metric for assessing weight-induced information loss
- [[PS_Extreme_Values]] — Diagnostic problem that stabilization/trimming address
- [[PSM_Propensity_Score_Matching]] — Alternative covariate balance method
- [[Common_Support]] — Related assumption; IPTW can estimate ATE without strict overlap (unlike PSM)

## HTA Case Records

<!-- Pending: awaiting first NICE case using IPTW to populate this section -->

## Source Anchor

> "Instead of throwing away data, we give each student a **Weight ($W$)**. For Treated: $W = 1/\text{PS}$. For Control: $W = 1/(1-\text{PS})$. This creates a **Pseudo-Population** where treatment and covariates are independent."

(来源：`/raw/methods/RWE_Logic_06_IPTW_Fundamentals.md`, Section 3)

## Source Files

- Fundamentals: `/raw/methods/RWE_Logic_06_IPTW_Fundamentals.md`
- HTA Practice: `/raw/methods/RWE_Logic_07_IPTW_AIPW_HTA_Advanced.md`

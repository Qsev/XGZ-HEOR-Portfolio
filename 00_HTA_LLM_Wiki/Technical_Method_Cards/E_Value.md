---
tags: [hta-concept]
method_family: Sensitivity Analysis
aliases: [E-value, E Value, Unmeasured Confounding Sensitivity, Bias Bound]
---

# E-Value

A quantitative sensitivity analysis metric that **measures the minimum strength (relative risk, odds ratio, or hazard ratio) that an unmeasured confounder must have—simultaneously on both treatment assignment and outcome—to completely explain away an observed treatment effect**; provides a numerical threshold for assessing robustness to unmeasured confounding in observational studies.

## Definition & Formula

(Condensed from: `/raw/methods/RWE_Logic_09_TTE_HTA_Case.md`, Section 3.1)

**Formula (for RR > 1):**

$$E = RR + \sqrt{RR(RR - 1)}$$

Where:
- $RR$ = observed Risk Ratio (or Hazard Ratio, Odds Ratio; the observed treatment effect)
- $E$ = E-value (minimum required strength of unmeasured confounder)

**For Protective Effects (HR < 1):**

First invert to $RR^* = 1/HR$, then apply formula:

$$E = RR^* + \sqrt{RR^*(RR^* - 1)}$$

**Example Calculation:**

Observed HR = 0.65 (35% mortality reduction with Drug X):
1. Invert: $RR^* = 1/0.65 = 1.54$
2. Apply formula: $E = 1.54 + \sqrt{1.54 \times 0.54} = 1.54 + 0.91 = 2.45$
3. **Interpretation:** An unmeasured confounder must have a 2.45-fold (or stronger) association with treatment *and* outcome to fully explain the observed effect.

## Mathematical Foundation

(Condensed from: `/raw/methods/RWE_Logic_09_TTE_HTA_Case.md`, Section 3.2)

**The Bias Factor Model:**

Assume an unmeasured confounder $U$ (e.g., smoking):

- $RR_{EU}$ = relative risk of receiving treatment for those with U (exposure-unmeasured association)
- $RR_{UD}$ = relative risk of the outcome for those with U (unmeasured-disease association)

**Maximum theoretical bias:**

$$\text{Bias} = \frac{RR_{EU} \times RR_{UD}}{RR_{EU} + RR_{UD} - 1}$$

**Finding the critical value:**

For $\text{Bias}$ to completely explain away observed $RR$, we need $\text{Bias} \geq RR$.

The minimum occurs when $RR_{EU} = RR_{UD} = E$ (equal strength on both dimensions):

$$\frac{E^2}{2E - 1} = RR$$

Solving via quadratic formula yields: **$E = RR + \sqrt{RR(RR - 1)}$**

**Key Insight:** The E-value represents the **minimum equal strength required on both treatment assignment and outcome** to overturn the causal conclusion. If the confounder is stronger on one dimension, it must be weaker on the other to maintain the bias threshold (multiplicative tradeoff).

## Interpretation: What E-Value Tells You

(Condensed from: `/raw/methods/RWE_Logic_09_TTE_HTA_Case.md`, Section 3.3)

**E = 2.45 means:**

Any unmeasured confounder capable of overturning the conclusion must satisfy *both* of these conditions simultaneously:

1. **On Treatment Assignment:** People with the confounder must be 2.45× more likely to receive the observed treatment (or 2.45× less likely to receive control)
2. **On Outcome:** People with the confounder must have 2.45× higher risk of the outcome (independent of treatment)

**Dual-Gate Logic:**

Because $E$ is defined by the multiplicative product, confounders with asymmetric effects are constrained:
- If a confounder's effect on treatment is only 1.5×, its effect on outcome must be exponentially stronger (>>2.45×) to achieve the necessary bias
- If a confounder's effect on outcome is only 1.5× (typical for smoking in many diseases), its effect on treatment selection must be >>2.45× to overturn the result

## EAG Application in HTA

(Condensed from: `/raw/methods/RWE_Logic_09_TTE_HTA_Case.md`, Section 3.3–3.4)

**Standard EAG Attack:**

> "Your HES data lacks smoking history. Smoking is a strong prognostic factor for lung cancer survival. Therefore, your drug effect estimate is confounded by smoking and cannot be trusted."

**Quantitative Defense via E-Value:**

1. **Calculate E from observed HR:** If HR = 0.65, then E ≈ 2.45
2. **Literature Search:** Review clinical/epidemiological literature for actual effects of smoking:
   - Effect on treatment assignment (do smokers preferentially receive drug vs. SOC)? Typically 1.2–1.5×
   - Effect on mortality? Typically 1.5–2.0× in lung cancer
3. **Threshold Comparison:** 
   - Observed effects from literature (both ~1.5–2.0×) are **below** the E-value threshold (2.45)
   - Therefore, smoking—even with realistic magnitudes—cannot fully explain away the drug effect
4. **Conclusion:** "Unless an unknown confounder exceeds smoking's real-world impact on both treatment and mortality, the drug effect is robust."

**Audit-Grade Statement:**

> "We calculated the E-value for the primary outcome as 2.45. A literature review of prognostic factors for [disease] in [population] confirms that no known confounder (including smoking, baseline disease severity, comorbidity burden) achieves 2.45-fold associations on both treatment assignment and mortality simultaneously. We therefore conclude the treatment effect is robust to unmeasured confounding of realistic magnitude."

## Limitations & Context

(Condensed from: `/raw/methods/RWE_Logic_09_TTE_HTA_Case.md`, Section 3.2–3.3)

**E-Value Does NOT:**
- Prove the treatment is causal (only shows effect is robust to plausible unmeasured confounders)
- Account for multiple unmeasured confounders acting together
- Adjust for unmeasured confounding (it quantifies how much confounding would be needed to overturn conclusions)

**E-Value Works Best When:**
- Effect size is clear (not borderline significant)
- Literature provides credible estimates of potential confounders' magnitudes
- There are no known unmeasured confounders of obvious severity

## Related Concepts

- [[TTE_Target_Trial_Emulation]] — Framework within which E-values assess robustness
- [[Confounding_by_Indication]] — Type of unmeasured confounding E-values help assess
- [[Residual_Confounding]] — Unmeasured remaining confounding after measured confounder adjustment; E-values quantify needed strength
- [[Treatment_Endogeneity]] — Unmeasured factors affecting treatment choice; E-values set threshold for plausibility
- [[Immortal_Time_Bias]] — Different bias mechanism (temporal, not confounding); E-values do not apply

## Source Anchor

> "E-value (VanderWeele & Ding, 2017) 的核心计算公式如下（针对 $RR > 1$ 的情况）：$$E-value = RR + \sqrt{RR(RR - 1)}$$只要在现实临床中，'吸烟'对死亡风险的影响力 ($Risk Ratio$) 低于 2.5（通常肺癌中吸烟带来的死亡风险比在 1.5 到 2.0 之间），那么无论吸烟在两组之间分布多么不均匀，都**无法**解释我们观察到的 Drug X 的显著疗效。"

(来源：`/raw/methods/RWE_Logic_09_TTE_HTA_Case.md`, Section 3.1, 3.3)

## Source Files

Referenced in: `/raw/methods/RWE_Logic_09_TTE_HTA_Case.md`, Sections 3.1–3.4

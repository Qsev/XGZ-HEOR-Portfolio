# 🛡️ RWE Forensic Audit Checklist: Causal Integrity & Decision-Making Rigour

> **"A statistical estimate is only as strong as its underlying causal assumptions. In HTA, failing to address structural uncertainty leads to flawed investment decisions."**

This checklist serves as the methodological defense for the **Drug X External Control Arm (ECA)**. It ensures that the transition from association to causation is transparent, auditable, and aligned with the **NICE RWE Framework (2022)**.

---

## 📍 1. Positivity Audit (Common Support)
*Can we actually compare these two groups without 'extrapolating into thin air'?*

*   **Audit Question**: Is there sufficient overlap in the Propensity Score (PS) distributions between the Treated and the Synthetic Control Arm?
*   **Visual Evidence**: Refer to `visuals/ps_overlap_plot.png`.
*   **Structural Uncertainty**: If certain patients have zero probability of treatment (Structural Positivity failure), the model is forced to 'hallucinate' treatment effects based on distant data points.
*   **⚠️ Impact on ICER**: A positivity failure means the model is 'borrowing' effects from non-existent patients. This leads to extreme **ICER instability** and results that are highly sensitive to minor changes in the model's functional form.

---

## 📍 2. Exchangeability (No Unmeasured Confounding)
*Is the assignment 'as good as random' after targeted adjustment?*

*   **Audit Question**: Have we captured all major prognostic factors and treatment drivers ($W$) to satisfy the conditional independence assumption?
*   **Strategic Defense**: While "No Unmeasured Confounding" is untestable, we quantify our **Decision-Making Rigour** via:
    1.  **Clinical Mapping**: Alignment with clinical guidelines on disease severity.
    2.  **Sensitivity Safeguards**: Refer to `visuals/evalue_plot.png`.
*   **⚠️ Impact on ICER**: If exchangeability fails, the ICER remains contaminated by 'baseline noise' (e.g., untreated disease severity). In our oncology case, this typically leads to an **underestimation of Drug X's value**, resulting in an artificially inflated ICER that penalizes innovation.

---

## 📍 3. Consistency & Robustness (The Doubly Robust Audit)
*Does the evidence chain hold under multiple mathematical lenses?*

*   **Audit Question**: Do the results from **IPTW (Weighting)** and **TMLE (Targeted Update)** converge?
*   **Data Evidence**: Refer to `visuals/final_audit_summary.csv`.
*   **Strategic Rationale**: 
    *   **IPTW** is the industry baseline but sensitive to PS model misspecification.
    *   **TMLE** provides **semi-parametric efficiency** and double robustness.
*   **⚠️ Impact on ICER**: Convergence between IPTW and TMLE significantly reduces **Structural Uncertainty**. It proves that the survival gain is a biological reality rather than a statistical artifact, providing the necessary rigour for a positive HTA recommendation.

---

## 🕵️‍♂️ Final Verdict for the Committee
The evidence chain for Drug X is **defensible**. By synchronizing the populations via TTE, re-balancing via ATT weighting, and validating via TMLE, we have mitigated the primary risk of **Indication Bias**. The resulting 1-year survival benefit is supported by both statistical efficiency and sensitivity safeguards, ensuring the **reliability of the final ICER** for clinical decision-making.

# TECHNICAL AUDIT MEMO: Structural Remediation of RRMM Economic Model

**TO:** Senior Value & Access Committee / Global Pricing Team  
**FROM:** Xiaoge Zhang, PhD (Senior HEOR Modeller)  
**DATE:** 2nd May 2026  
**SUBJECT:** Forensic Audit and Technical Remediation of the Drug A PartSM for RRMM  

---

## ⚠️ PROJECT DISCLAIMER & CONTEXT

**Simulation Context:** This audit is an independent technical exercise based on a simulated **"Mock Brief"** for Relapsed/Refractory Multiple Myeloma (RRMM). All clinical parameters (Weibull lambdas) and economic inputs are synthetic and designed to test the robustness of HTA auditing protocols. No confidential industry data was used in this reconstruction.

---

## 1. Executive Summary

Following a comprehensive forensic audit of the simulated RRMM Partitioned Survival Model (PartSM), we have successfully remediated critical structural failures that invalidated the initial economic outputs. Post-remediation, the base-case Incremental Cost-Effectiveness Ratio (ICER) has been stabilised at **£53,514 per QALY** ($\Delta C: £34,761; \Delta E: 0.649$).

While the ICER remains above the standard £30,000 threshold, the model now possesses the **biological plausibility** and **numerical stability** required for a formal submission. This report details the remediation of pre-defined "logic traps" and provides strategic recommendations for navigating UK-specific appraisal hurdles (e.g., Severity Weighting).

## 2. Forensic Audit Findings & Structural Remediation

### Bug A: Dimensional Time-Unit Misspecification

* **Identification:** The initial model erroneously applied annualised lambda ($\lambda$) parameters to a monthly cycle structure without scale conversion. This led to an unrealistic "survival collapse" within the first 12 months.
* **Remediation:** All survival functions were recalibrated to a consistent monthly scale ($t/12$). This restored the expected survival trajectory, ensuring that QALY gains are anchored in clinical reality rather than mathematical artifacts.

### Bug B: Misallocation of Subsequent Therapy Costs

* **Identification:** Subsequent therapy costs (PD costs) were incorrectly assigned to the 'Death' state instead of the 'Progressed Disease' (PD) state.
* **Remediation:** Re-aligned the cost-traps to the alive PD cohort. This corrected a massive artificial cost-offset, revealing the true economic burden of long-term survival in RRMM.

### Bug C: Structural Hazard Jumps (The 'Hazard Cliff')

* **Identification:** A naive switch to a 0.70 Hazard Ratio at Month 61 created a discontinuous "Hazard Cliff," which would be rejected by NICE Evidence Assessment Groups (EAG) as biologically implausible.
* **Remediation:** Developed a **Recursive Hazard Chaining** algorithm in R. This anchors the waning phase to the trial’s terminal hazard at Month 60, ensuring a smooth, continuous transition from trial-based data to extrapolated projections.

## 3. Methodological Excellence

The remediated engine demonstrates a sophisticated bridge between raw statistics and decision modeling:

* **R-to-Excel Pipeline:** Automated data ingestion via Power Query ensures that survival parameter updates in R are instantly reflected in the ICER.
* **ONS Synchronicity:** Integrated **UK ONS (2022-2024)** life tables using a `MAX` risk-capture logic to prevent "immortal patient" bias in long-term (30-year) horizons.

## 4. Strategic Recommendations

1. **Severity Weighting:** Given the disease severity and QALY loss, we recommend justifying the application of **NICE Severity Weighting (1.2x or 1.7x)**, which would move the £53k ICER significantly closer to the actionable range.
2. **PSA Insights:** Probabilistic Sensitivity Analysis (1,000 iterations) indicates a **17%** probability of cost-effectiveness at £30k, rising to **51%** at the £50k (Severity-adjusted) threshold.
3. **Subsequent Mix:** A 10% mAb uptake assumption in later lines is critical for ICER stability; any upward shift by the EAG will necessitate deeper PAS discounts.

## 5. Conclusion

The model is now **Audit-Ready**. By resolving the identified structural flaws, we have provided a defensible platform for strategic market access and pricing negotiations.

---
**Approved by:**  
*Xiaoge Zhang, PhD (Independent HEOR Portfolio)*

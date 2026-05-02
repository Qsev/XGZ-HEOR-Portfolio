# Forensic Audit & Technical Remediation: RRMM Partitioned Survival Model

> **Project Summary:** A comprehensive forensic audit and structural remediation of a 3-state Partitioned Survival Model (PartSM) for Relapsed/Refractory Multiple Myeloma (RRMM). This project demonstrates the integration of R-based survival analytics with a high-fidelity, audit-ready Excel calculation engine.

---

## 🔍 Executive Overview
This case study documents the end-to-end technical remediation of a legacy economic model. The project addresses the critical need for biological plausibility and statistical transparency in HTA submissions, moving beyond "black-box" parameterization by implementing a robust **R-to-Excel analytical pipeline**.

## 🛠 Key Audit Findings (Remediation Log)
The forensic audit identified several structural vulnerabilities in the legacy architecture that were systematically remediated:

*   **Time-unit Misspecification**: Identified a mismatch between cycle length and hazard rate scaling that caused non-sensical survival curve crossing in long-term extrapolations.
*   **Cost Misallocation**: Corrected a logic error where Progressed Disease (PD) costs were incorrectly assigned to the 'Death' state, which had previously distorted the incremental cost results.
*   **Audit Trail Integrity**: Replaced legacy, hard-coded Weibull inputs with a dynamic Power Query integration to establish a **Single Source of Truth (SSoT)** for statistical data.

## 🚀 Methodological Innovation: Recursive Hazard Chaining
To resolve the common issue of "Hazard Jumps" at trial-to-extrapolation cut-offs, I implemented a **Recursive Hazard Chaining Algorithm** in R:

*   **Hazard Anchoring**: Captured the instantaneous hazard at the 60-month anchor point to serve as the baseline for long-term extrapolation.
*   **Waning Phase Logic**: Implemented a linear waning period (Months 61-120) where the Treatment Hazard Ratio (HR) gradually reverts to 1.0, ensuring **biological plausibility** by preventing "immortal time bias".
*   **Pipeline Architecture**: R handles complex survival fitting and OS ≥ PFS logical checks; Excel serves as the auditable financial engine for NICE-style submissions.

## 📊 Technical Results (Base Case)

| Metric | Value |
| :--- | :--- |
| **Incremental QALY ($\Delta E$)** | **0.6496** |
| **Incremental Cost ($\Delta C$)** | **£34,761.18** |
| **Base-case ICER** | **£53,514 / QALY** |

> [!IMPORTANT]
> The resulting ICER (£53,514) represents a realistic "High Burden" oncology scenario. This value was used to drive **Threshold Analysis**, demonstrating that the model is highly sensitive to the subsequent therapy mix (e.g., Monoclonal Antibody vs. Chemotherapy shares).

## 📂 Project Components
*   **`RRMM_Survival_Pipeline.R`**: The core statistical engine featuring the Hazard Chaining logic.
*   **`RRMM_Model_Engine.xlsx`**: The remediated Excel engine with automated data ingestion.
*   **`PSA_Validation`**: Probabilistic Sensitivity Analysis (PSA) outputs confirming numerical stability.

---
**Technical Stack:** `R (Survival, Flexsurv)`, `Excel (Advanced Financial Modeling)`, `Power Query (ETL)`, `Markdown`.

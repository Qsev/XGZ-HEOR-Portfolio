# 🏥 01: Oncology Partitioned Survival Model (PartSM) Audit

This project demonstrates a forensic technical audit and remediation of a 3-state oncology economic model (RRMM), focusing on clinical validity, structural integrity, and uncertainty quantification.

## 🔍 Project Scope
- **Indication**: Relapsed/Refractory Multiple Myeloma (RRMM).
- **Core Assets**: Audit Memos and remediated Excel-based PartSM models.
- **Key Challenges**: Survival curve crossovers, proportional hazards violations, and complex treatment waning logic.

## 🛠️ Technical Highlights
- **Hazard Remediation**: Implemented conditional hazard-based waning to replace crude multiplicative scaling.
- **Survival Synthesis**: Reconstruction of KM data and fitting of parametric curves (Gompertz, Weibull, RPS) with AIC/BIC/Clinical plausibility auditing.
- **Uncertainty**: Full PSA implementation with automated Cholesky decomposition for correlated parameters.

---
*For the detailed audit memo, see the files within this directory.*

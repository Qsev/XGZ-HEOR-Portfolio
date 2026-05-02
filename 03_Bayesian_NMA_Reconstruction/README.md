# 03_Bayesian_NMA_Reconstruction: ML-NMR Stress Testing

> **"In HTA, the absence of head-to-head trials forces us to rely on indirect comparisons. When covariate distributions do not overlap, simple matching fails. The solution is Multilevel Network Meta-Regression (ML-NMR)."**

## 🎯 Project Overview

Because proprietary Individual Patient Data (IPD) from actual submissions (e.g., NICE TA1013) is strictly confidential, I reverse-engineered a **Synthetic Evidence Network** to stress-test the ML-NMR algorithmic architecture.

This module bypasses the "black-box" use of R packages, demonstrating a deep, forensic understanding of how **Bayesian Hierarchical Models (Stan/MCMC)** perform numerical integration to bridge micro-level IPD with macro-level Aggregate Data (AgD).

## 🛠️ Key Technical Audits Performed

1. **The Extrapolation Gap:** Deliberately simulated a network with zero covariate overlap (Age & WBC mismatch) to trigger MCMC divergent transitions, then implemented data-alignment strategies to restore R-hat convergence to 1.00.
2. **Joint Likelihood Calibration:** Demonstrated how macroscopic summary data (AgD) acts as a structural constraint, anchoring the patient-level regression coefficients ($\beta$) via Sobol sequence integration.
3. **MCMC Diagnostics:** Bypassed high-level wrapper errors to manually extract and validate trace plots directly from the underlying `rstan` engine.

## 📂 Assets in this Module

- [`Audit_Report_ML_NMR_Convergence.md`](./Audit_Report_ML_NMR_Convergence.md): A step-by-step breakdown of the math, the MCMC failure modes, and the recovery process.
- [`Synthetic_MLNMR_Pipeline.R`](./Synthetic_MLNMR_Pipeline.R): The R code generating the synthetic DGP and executing the Bayesian evidence synthesis.

# 03: Bayesian Evidence Synthesis & ML-NMR Reconstruction

> **"HTA decisions often hinge on the bridge between individual granularities and aggregate summaries. This module demonstrates the mastery of that bridge via Multilevel Network Meta-Regression (ML-NMR)."**

---

## 🎯 Strategic Overview

In high-stakes NICE appraisals (e.g., **TA1013**), indirect treatment comparisons (ITC) are frequently compromised by severe population imbalances between Individual Patient Data (IPD) and literature-based Aggregate Data (AgD).

This repository showcases a **forensic reconstruction** of the ML-NMR framework. Unlike black-box implementations, this project deconstructs the underlying Bayesian hierarchical architecture, proving that technical stability (MCMC convergence) and clinical plausibility (population alignment) are inextricably linked.

---

## 🛠️ Methodological Assets

### 1. [Flagship] ML-NMR Counterfactual Pipeline

* **File:** [`MLNMR_Counterfactual_Pipeline.R`](./MLNMR_Counterfactual_Pipeline.R)
* **Core Implementation:** A fully functional Bayesian pipeline using `multinma` and `rstan` to bridge IPD and AgD.
* **Technical Edge:**
  * **Numerical Integration:** Implemented 64-point **Sobol sequences** to solve the non-linear logit integral.
  * **Correlation Borrowing:** Calculated $\rho$ from the IPD cohort and injected it via **Cholesky Decomposition** into the AgD integration nodes to ensure biological entanglement between covariates.
  * **Likelihood Engineering:** Utilized a Binomial "Iron Pincer" likelihood to lock regression slopes to macroscopic literature observations.

### 2. Forensic Audit & Convergence Report

* **File:** [`MLNMR_Audit_Report.qmd`](./MLNMR_Audit_Report.qmd)
* **Narrative:** A technical white paper documenting the "Extrapolation Gap" failure and subsequent remediation.
* **Key Findings:** Demonstrates the reclamation of **80%+ survival value** by adjusting for population-level age penalties.

### 3. Bayesian Foundations: Manual MCMC Sampling

* **Files:** [`Manual_MH_Sampler.R`](./Manual_MH_Sampler.R) | [`MH_Logic_Fundamentals.md`](./Bayesian_Fundamentals_MH_Logic.md)
* **Purpose:** To demonstrate PhD-level depth, I reverse-engineered a **Metropolis-Hastings (MH)** sampler from scratch in R.
* **Insight:** Proves an understanding of "Conjugate Priors" and why MCMC is required for the high-dimensional mountain-climbing tasks found in complex NMA networks.

---

## 📊 Visual Evidence: MCMC Diagnostics

Statistical inference is only valid if the "Mining Robots" (MCMC chains) have converged. Below is the diagnostic proof from our simulated high-stakes network.

![MCMC Convergence Diagnostics](../visuals/Convergence_Plot.png)
*Figure 1: Trace plots demonstrating perfect chain interweaving (R-hat = 1.00) after correcting for the Extrapolation Gap.*

---

## 🕵️‍♂️ Senior Consultant’s Audit Checklist

This project addresses the following critical "Red Flags" that Evidence Assessment Groups (EAGs) typically target:

* **[x] Positivity Check:** Ensuring every virtual avatar has a non-zero probability of treatment assignment.
* **[x] ESS Monitoring:** Tracking the Effective Sample Size to ensure results are not driven by extreme weights (as seen in failed MAICs).
* **[x] Prior Sensitivity:** Validating that the treatment effect is driven by clinical data, not over-informative priors.

---
**Methodological Alignment:** NICE DSU TSD 18 (Indirect Comparisons)  
**Technical Lead:** Xiaoge Zhang, PhD (York)  
**Portfolio Hub:** [xgzhang.com](http://xgzhang.com)

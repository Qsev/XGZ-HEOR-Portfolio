# 03: Bayesian Evidence Synthesis & ML-NMR Reconstruction

> **"HTA decisions often hinge on the bridge between individual granularities and aggregate summaries. This module demonstrates the mastery of that bridge via Multilevel Network Meta-Regression (ML-NMR)."**

---

## 🎯 Strategic Overview

In high-stakes NICE appraisals (e.g., **TA1013**), indirect treatment comparisons (ITC) are frequently compromised by severe population imbalances between Individual Patient Data (IPD) and literature-based Aggregate Data (AgD).

This repository showcases a **forensic reconstruction** of the ML-NMR framework. Unlike black-box implementations, this project deconstructs the underlying Bayesian hierarchical architecture, proving that technical stability (MCMC convergence) and clinical plausibility (population alignment) are inextricably linked.

---

## 🛠️ Methodological Assets

### 1. [Flagship] ML-NMR Mock Case — Anchored PAIC

* **File:** [`MLNMR_Flagship_Case.qmd`](./MLNMR_Flagship_Case.qmd) — published at [xgzhang.com](https://xgzhang.com/03_Bayesian_NMA_Reconstruction/MLNMR_Flagship_Case.html)
* **Content:** Joint IPD + AgD likelihood, 64-point Sobol integration, two-covariate extension via a Gaussian copula, counterfactual projection, parameter recovery against the known data-generating values, and a structural comparison with NICE TA1013.
* **Note:** Fully synthetic data with known ground-truth parameters — a methodological proof-of-concept, not a clinical result.

### 2. Supporting Pipeline Script

* **File:** [`MLNMR_Counterfactual_Pipeline.R`](./MLNMR_Counterfactual_Pipeline.R)
* **Core Implementation:** A fully functional Bayesian pipeline using `multinma` and `rstan` to bridge IPD and AgD.
* **Technical Edge:**
  * **Numerical Integration:** Implemented 64-point **Sobol sequences** to solve the non-linear logit integral.
  * **Correlation Borrowing:** Calculated $\rho$ from the IPD cohort and injected it via **Cholesky Decomposition** into the AgD integration nodes to ensure biological entanglement between covariates.
  * **Likelihood Engineering:** Utilized a Binomial "Iron Pincer" likelihood to lock regression slopes to macroscopic literature observations.

### 3. Bayesian Foundations: Manual MCMC Sampling

* **File:** [`Manual_MH_Sampler.R`](./Manual_MH_Sampler.R)
* **Purpose:** To demonstrate PhD-level depth, I reverse-engineered a **Metropolis-Hastings (MH)** sampler from scratch in R.
* **Insight:** Proves an understanding of "Conjugate Priors" and why MCMC is required for the high-dimensional mountain-climbing tasks found in complex NMA networks.

---

## 📊 Visual Evidence: MCMC Diagnostics

Statistical inference is only valid if the "Mining Robots" (MCMC chains) have converged. Below is the diagnostic proof from our simulated high-stakes network.

![MCMC trace plots](./visuals/MCMC_Trace_Plot.png)
*Figure 1: Post-warm-up trace plots for the two treatment effects, four chains.*

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

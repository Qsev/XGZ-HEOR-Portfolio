# 03: Bayesian Evidence Synthesis & ML-NMR

> When one trial has individual patient data and the comparator is only a published summary, the two cannot be compared directly. This module works through how multilevel network meta-regression (ML-NMR) bridges them — and where that bridge is load-bearing.

---

## 🎯 Overview

In appraisals such as **NICE TA1013**, indirect treatment comparisons are compromised when the IPD trial and the published comparator enrol different populations. ML-NMR handles this by fitting an individual-level regression to the IPD and integrating it over the aggregate trial's covariate distribution, so that treatment effects can be standardised to a chosen target population.

The material here is a **worked reconstruction** rather than a live analysis: synthetic data with known parameters, so that every estimate can be checked against the value that generated it.

One finding is worth stating up front, because it runs against intuition. **Convergence diagnostics do not detect extrapolation.** In the no-overlap scenario tested here — IPD mean age 25 against an aggregate population at 70 — the sampler produced zero divergent transitions and R-hat ≤ 1.014 across five seeds. Nothing failed. What changed was the width of the credible interval, which roughly doubled. Poor overlap is not a technical failure that the software will surface; it has to be recognised and declared by the analyst.

---

## 🛠️ Contents

### 1. [Flagship] ML-NMR Mock Case — Anchored PAIC

* **File:** [`MLNMR_Flagship_Case.qmd`](./MLNMR_Flagship_Case.qmd) — published at [xgzhang.com](https://xgzhang.com/03_Bayesian_NMA_Reconstruction/MLNMR_Flagship_Case.html)
* **Contents:** the joint IPD + AgD likelihood; 64-point Sobol integration of the aggregate likelihood; a two-covariate extension in which the covariate correlation is borrowed from the IPD through a Gaussian copula; counterfactual projection; recovery of the data-generating parameters; and a structural comparison with TA1013.
* **Data:** fully synthetic, generated from a known model. A methodological proof-of-concept, not a clinical result.

### 2. Two-Covariate Pipeline Script

* **File:** [`MLNMR_Counterfactual_Pipeline.R`](./MLNMR_Counterfactual_Pipeline.R)
* **Contents:** a `multinma` fit over two covariates (age and white cell count), with 64 Sobol integration points and the correlation matrix supplied from the IPD cohort. Standalone version of the two-covariate section of the flagship case.

### 3. Metropolis-Hastings Sampler, Written by Hand

* **File:** [`Manual_MH_Sampler.R`](./Manual_MH_Sampler.R)
* **Contents:** a random-walk Metropolis-Hastings sampler in base R for a Beta-Binomial problem, checked against the conjugate posterior, which is available in closed form. The point is to make the accept/reject step explicit rather than to compete with Stan.
* ⚠ **Known issue:** the script's Stan comparison requires `mosquito.stan`, which is not in this repository, so it does not currently run end to end.

---

## 📌 Scope and limits

What this module does **not** contain, so that nothing here is read as more than it is:

* **No MAIC, and therefore no effective-sample-size diagnostics.** ESS shrinkage under reweighting is a MAIC property; the ML-NMR fits here use the full sample and the relevant quantity is the posterior effective sample size reported alongside R-hat in the results tables. Weight-based diagnostics live in [module 02](../02_RWE_Causal_Inference_Pipeline/).
* **No prior sensitivity analysis.** Priors are weakly informative and stated in the code, but no analysis varying them has been run.
* **No sensitivity analysis on the borrowed covariate correlation.** Borrowing $\rho$ from the IPD assumes the dependence structure transports across populations; that assumption is stated in the flagship case but has not been stress-tested.
* **No time-to-event outcome and no economic model.** The endpoint is binary complete remission throughout. The estimand error that led the TA1013 committee to reject the company's base case occurred downstream of the indirect comparison, and is discussed but not reproduced here.

---

**Methodological reference:** NICE DSU TSD 18; Phillippo et al., multilevel network meta-regression.
**Author:** Xiaoge Zhang, PhD (York) · [xgzhang.com](http://xgzhang.com)

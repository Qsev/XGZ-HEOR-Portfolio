# Methodological Comparison: Naive Cox Model vs. PSM Matched Cox Model

This document outlines the mathematical formulations and operational workflows comparing a Naive Cox Proportional Hazards Model with a Propensity Score Matched (PSM) Cox Model.

---

## 1. Naive Cox Proportional Hazards Model

In a naive analysis of observational data, we model survival time directly on the raw, unadjusted cohort.

### Mathematical Formulation

The crude (unadjusted) Naive Cox model is specified as:

$$h(t \mid D_i) = h_0(t) \exp(\beta_1 D_i)$$

Where:
* $h(t \mid D_i)$ is the hazard of the event (e.g., death) at time $t$ for patient $i$.
* $h_0(t)$ is the baseline hazard function, representing the hazard when all covariates are zero.
* $D_i$ is the treatment indicator ($D_i = 1$ for treatment, $D_i = 0$ for control).
* $\beta_1$ is the regression coefficient. The Hazard Ratio (HR) is estimated as $\text{HR} = \exp(\beta_1)$.

An adjusted Naive Cox model includes baseline confounders directly as regressors:

$$h(t \mid D_i, \mathbf{X}_i) = h_0(t) \exp(\beta_1 D_i + \boldsymbol{\theta}^T \mathbf{X}_i)$$

Where $\mathbf{X}_i$ is a vector of baseline covariates (e.g., Age, ECOG score), and $\boldsymbol{\theta}$ represents their corresponding coefficients.

### Operational Workflow

1. **Cohort Assembly**: Combine all treated and control patients from the database.
2. **Model Fitting**: Fit the Cox proportional hazards regression using maximum partial likelihood.
3. **Inference**: Obtain $\exp(\beta_1)$ as the treatment effect. Standard errors are computed using the default inverse of the observed information matrix (Fisher Information), assuming all patients are independent.

### Methodological Vulnerabilities

1. **Confounding by Indication**: If $\mathbf{X}_i$ is omitted, $\exp(\beta_1)$ is highly biased due to the systematic differences in prognosis between the treatment groups.
2. **Functional Form Assumptions**: Direct covariate adjustment in Cox regression assumes that the log-hazard is linear in continuous covariates (e.g., Age) and that there are no unmodeled interactions.
3. **Extrapolation**: If there is poor common support (non-overlap) in covariate space, the regression model extrapolates across regions where no comparable patients exist, leading to model dependency and potential bias.

---

## 2. Propensity Score Matched (PSM) Cox Model

To overcome the limitations of the naive model, we first balance the cohorts on baseline characteristics using Propensity Score Matching (PSM) and then fit a Cox model to the matched cohort.

### Mathematical Formulation

#### Step 1: Propensity Score Estimation
We estimate the propensity score $e(\mathbf{X}_i) = P(D_i = 1 \mid \mathbf{X}_i)$ using a logistic regression model:

$$\ln\left(\frac{e(\mathbf{X}_i)}{1 - e(\mathbf{X}_i)}\right) = \alpha_0 + \boldsymbol{\alpha}^T \mathbf{X}_i$$

#### Step 2: Propensity Score Matching
Patients are matched on the logit of their propensity score, typically using a caliper constraint:

$$|\text{logit}(e(\mathbf{X}_i)) - \text{logit}(e(\mathbf{X}_j))| \le 0.2 \times \sigma_{\text{logit}(e(\mathbf{X}))}$$

#### Step 3: Downstream Cox Model on Matched Cohort
The Cox model is fit exclusively on the matched sample (retaining only paired treated and control patients). Because matching introduces statistical dependence (clustering) within each pair, standard inference is invalid. We adjust for this using one of two methods:

##### Method A: Marginal Cox Model with Robust Clustered Standard Errors
We fit a marginal Cox model:

$$h(t \mid D_i, \text{Pair}_i) = h_0(t) \exp(\gamma D_i)$$

Where standard errors for $\gamma$ are adjusted using the robust sandwich variance estimator (Lin and Wei, 1989) clustered by matched pair ID:

$$\mathbf{V} = \mathbf{A}^{-1} \mathbf{B} \mathbf{A}^{-1}$$

Here, $\mathbf{A}$ is the standard observed information matrix, and $\mathbf{B}$ is the outer product of the clustered score residuals.

##### Method B: Stratified Cox Model
We stratify the baseline hazard function by matched pair ID:

$$h_i(t \mid \text{Pair}(i)) = h_{0, \text{Pair}(i)}(t) \exp(\gamma D_i)$$

This allows each matched pair to have its own unique baseline hazard function $h_{0, \text{Pair}(i)}(t)$, controlling for the matched baseline characteristics non-parametrically.

---

## 3. Key Differences

| Dimension | Naive Cox Model | PSM Matched Cox Model |
|:---|:---|:---|
| **Data Utilized** | Full raw cohort | Matched sub-cohort (restricted to common support) |
| **Adjustment Level** | Regression adjustment (requires parametric assumptions) | Balancing matching (non-parametric baseline balance) |
| **Statistical Independence** | Assumes all observations are independent | Accounts for clustering/pairing via Robust SEs or Stratification |
| **Estimand** | Conditional Treatment Effect | Average Treatment Effect on the Treated (ATT) |

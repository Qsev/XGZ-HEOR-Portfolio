# 🕸️ 03: Bayesian Network Meta-Analysis (NMA) Reconstruction

Implementation of advanced evidence synthesis models using Bayesian frameworks to support indirect treatment comparisons (ITC) in high-stakes HTA appraisals.

## 🧬 Model Architecture
- **Framework**: Bayesian Hierarchical Models (Fixed and Random Effects).
- **Engine**: `Stan` (via `rstan` or `cmdstanr`) for robust MCMC sampling.
- **Methodology**: Non-centered parameterization to ensure convergence in sparse networks.

## 🎯 Key Outputs
- **Relative Effects**: Odds Ratios (OR), Hazard Ratios (HR), and Probability of being best.
- **Consistency Checks**: Bucher method and Node-splitting for assessing local and global inconsistency.
- **Visualizations**: Network plots, Forest plots, and SUCRA curves.

---
*Focuses on rigorous evidence synthesis for HTA submissions.*

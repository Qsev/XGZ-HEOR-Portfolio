# Xiaoge Zhang — HEOR Technical Portfolio

A professional showcase of health economic modelling, Bayesian evidence synthesis, and real-world causal inference, built to HTA submission standards. Structured as a series of high-fidelity case studies targeting NICE/SMC appraisal contexts.

🌐 **Live site:** [xgzhang.com](https://xgzhang.com)

---

## Project Directory

### [05 — NICE TA975 CAR-T Case Study](./05_TA975_CAR-T_Case/)
Full end-to-end reconstruction of the Tisagenlecleucel (CAR-T) appraisal. Covers decision tree modelling for the ITT population, Partitioned Survival Model with parametric fitting, and ICER calculation via Patient Access Schemes. Built to NICE reference case standards.

### [04 — NMA Technical Library](./04_NMA/05_NMA_Technical_Prep/)
Ten technical guides covering the full spectrum of evidence synthesis methods used in HTA: Standard Bayesian NMA, Network Meta-Regression, Survival NMA, Component NMA, IPD NMA, MAIC, STC, ML-NMR, Flexible Survival Extrapolation, and Bayesian Estimation. Each guide includes worked Stan/R implementations.

### [03 — Bayesian ML-NMR Reconstruction](./03_Bayesian_NMA_Reconstruction/)
Reconstruction and audit of a Multilevel Network Meta-Regression model. Implements 64-point Sobol integration and Cholesky decomposition to bridge IPD and aggregate data in a Bayesian framework. Includes a manual Metropolis-Hastings sampler built from scratch.

### [02 — RWE Causal Inference Pipeline](./02_RWE_Causal_Inference_Pipeline/)
R-based pipeline for real-world evidence analysis. Implements IPTW, AIPW, and TMLE with SuperLearner ensemble learning to address confounding in observational oncology data. Includes E-value sensitivity analysis and full forensic audit checklist.

### [01 — Oncology PartSM Audit](./01_Oncology_PartSM_Audit/)
Forensic audit and technical remediation of a 3-state Partitioned Survival Model in relapsed/refractory multiple myeloma (RRMM). Features hazard-based treatment waning logic and probabilistic sensitivity analysis (PSA) validation.

### [00 — HTA Methodology Wiki](./00_HTA_LLM_Wiki/)
A curated knowledge base of HTA principles, NICE/SMC/AWMSG guidelines, and technical method cards. Covers topics including IPTW, TMLE, cure assumptions, immortal time bias, and target trial emulation.

---

## Tech Stack

| Domain | Tools |
|---|---|
| Economic Modelling | R (HEEMOD), Excel (VBA / PowerQuery) |
| Evidence Synthesis | R (multinma, gemtc), Stan, JAGS |
| Causal Inference | R (SuperLearner, MatchIt, tmle) |
| Survival Analysis | R (flexsurv, survminer) |
| HTA Standards | NICE DSU TSDs, SMC Submission Guidelines |

---

**Contact:** [linkedin.com/in/xgzhang2026](https://www.linkedin.com/in/xgzhang2026) | [xgzhang.com](https://xgzhang.com)

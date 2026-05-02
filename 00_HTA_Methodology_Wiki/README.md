# 🧠 HTA Methodology Wiki: The Auditor’s Intelligence Hub

> **"HTA is not just about building models; it is about building defensible clinical and economic narratives."**

This repository is a structured intelligence hub representing a systematic audit of **20+ NICE appraisals** (Oncology, Rare Diseases, and Chronic Conditions). It serves as a bridge between **high-level econometric theory** and the **pragmatic requirements of industrial Market Access**.

---

## 🌌 The Knowledge Landscape

Below is the high-dimensional relationship map of my HTA methodology audit, visualized via Obsidian. Every node represents a critical technical clashing point identified during my forensic reconstruction of public NICE dossiers.

![HTA Knowledge Graph](./visuals/knowledge_graph.png)
*Figure 1: Cross-appraisal relationship map linking Clinical Evidence, Statistical Synthesis, and Economic Decision Pillars.*

---

## 🛡️ Core Methodological Domains

### 1. Advanced Survival & Economic Architecture

Focusing on the transition from clinical trial data to lifetime horizons while maintaining **biological plausibility**.

* **Key Concepts:** 3-State PartSM, Multi-state Markov, Cure Fractions, and Treatment Waning.
* **Audit Focus:** Identifying "Hazard Jumps" and ensuring smooth transitions using **Recursive Hazard Chaining** algorithms.
* **Standards:** Aligned with **NICE DSU TSD 14 & 21**.

### 2. Bayesian Evidence Synthesis (NMA/NMR)

Deconstructing the statistical backbone of indirect treatment comparisons.

* **Key Concepts:** Fixed vs. Random Effects, **ML-NMR** (Multilevel Network Meta-Regression), and non-centered parameterization for MCMC stability.
* **Audit Focus:** Assessing the impact of heterogeneity ($\tau$) priors and the sensitivity of ICERs to unanchored comparison assumptions.
* **Standards:** Aligned with **NICE DSU TSD 18**.

### 3. Causal Inference & RWE (Target Trial Emulation)

Leveraging econometrics to minimize bias in observational datasets (SACT, CPRD, HES).

* **Key Concepts:** **TTE (Target Trial Emulation)**, **IPTW/IPCW**, and Doubly Robust Estimation (**TMLE/AIPW**).
* **Audit Focus:** Monitoring **ESS (Effective Sample Size)** shrinkage and auditing the **Positivity Assumption** in external control arms.
* **Standards:** Aligned with the **NICE Real-World Evidence Framework (2022)**.

---

## 📖 Featured Briefs (Deep Dives)

| Briefing Note | Strategic Focus | Case Reference |
| :--- | :--- | :--- |
| [The "Success Penalty"](./Methodology_Deep_Dives/Success_Penalty.md) | How long-term survival in PD state drives ICERs. | RRMM Mock Case |
| [Zero-time Alignment](./Methodology_Deep_Dives/TTE_Zero_Time.md) | Mitigating Immortal Time Bias in RWE. | TA1017 / Lung Cancer |
| [The ESS Breakdown](./Methodology_Deep_Dives/MAIC_ESS_Drops.md) | Managing statistical fragility in MAIC weighting. | TA1013 / Quizartinib |

---

## 🕵️‍♂️ The "Auditor’s Mindset"

This Wiki documents my unique approach to HTA: **Forensic Reconstruction**.
Instead of passive learning, I treat every NICE dossier as a "legal case" to be solved. By identifying where manufacturers "stretch" assumptions (e.g., survival long-tails or optimistic utility weights) and where EAGs counter-attack, I have developed a **Defensive Modelling Framework** designed to survive the most rigorous technical scrutiny.

---
**Technical Lead:** Xiaoge Zhang, PhD (York)  
**Methodological Base:** NICE DSU Technical Support Documents (TSDs)  

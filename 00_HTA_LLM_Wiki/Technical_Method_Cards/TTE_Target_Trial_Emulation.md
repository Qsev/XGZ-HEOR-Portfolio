---
tags: [method, rwe]
method_family: Emulation
aliases: [TTE, Target Trial, Emulated Trial]
---

# Target Trial Emulation (TTE)

A study design framework that structures observational research as an emulation of a hypothetical randomized trial by explicitly defining **eligibility criteria, treatment strategies, follow-up timing, and outcome definition** before analyzing data; enforces rigorous temporal alignment and prevents key biases ([[Immortal_Time_Bias]], reverse causality) by synchronizing treatment assignment with the moment clinical equipoise is established.

## Core Philosophy

(Condensed from: `/raw/methods/RWE_Logic_08_TTE_Fundamentals.md`, Sections 1–3)

TTE is **not an algorithm**; it is a **thought constraint**. Rather than asking "What does my data say?", TTE asks "What trial am I trying to emulate?"

**The Problem:** Observational datasets are chaotic. Patients don't all enroll on January 1st; treatment starts at different times; confounders are measured at different time points relative to treatment initiation.

**The Solution:** Define the target trial first (eligibility, treatment strategy, follow-up, outcomes) before touching data. This forces the researcher to make explicit decisions about:
- When does a patient become eligible? (T₀)
- What treatment strategies are being compared?
- When does follow-up begin and end?
- How is the outcome measured?

By answering these upfront, TTE prevents data mining and protects against **reverse causality** (sicker patients quitting treatment and appearing as controls) and **[[Immortal_Time_Bias]]** (treatment groups appearing healthier because they "survived" to treatment initiation).

(Condensed from: `/raw/methods/RWE_Logic_08_TTE_Fundamentals.md`, Sections 1–3)

## The 7 Pillars of Target Trial Definition

(Condensed from: `/raw/methods/RWE_Logic_08_TTE_Fundamentals.md`, Section 1)

Every TTE must explicitly specify:

1. **Eligibility Criteria:** Who would be included in the hypothetical RCT? (e.g., "Patients aged 40-70 with no prior heart disease at T₀")
2. **Treatment Strategies:** What are we comparing? (e.g., "Initiate Drug A" vs. "Standard of care")
3. **Assignment Strategy:** How would we randomize? (e.g., "Propensity score matching to simulate randomization")
4. **Follow-up Timeline:** From when to when? (e.g., "From treatment initiation to event/death/end of data")
5. **Outcome Definition:** What is the primary endpoint? (e.g., "First myocardial infarction")
6. **Causal Contrast:** What effect are we estimating? (e.g., "Intention-to-Treat effect")
7. **Analysis Plan:** How will we estimate the effect? (e.g., "AIPW with covariate adjustment")

(Condensed from: `/raw/methods/RWE_Logic_08_TTE_Fundamentals.md`, Section 1)

## Key Implementation Challenges & Solutions

(Condensed from: `/raw/methods/RWE_Logic_08_TTE_Fundamentals.md`, Sections 1.1–2.3; `/raw/methods/RWE_Logic_09_TTE_HTA_Case.md`, Sections 1–2)

**1. [[New_User_Design]]:** Only include patients initiating treatment at T₀, not prevalent users (already on treatment)

**2. [[Zero_Time_Alignment]]:** Synchronize treatment assignment with the moment eligibility criteria are met; prevent [[Immortal_Time_Bias]]

**3. [[Intention_To_Treat]]:** Analyze patients based on assigned treatment arm regardless of actual adherence

**4. [[Cloning_and_Censoring]]:** At T₀, create virtual copies of each patient assigned to each arm; censor one arm when protocol is violated

**5. [[IPCW_Inverse_Probability_Censoring_Weights]]:** Reweight remaining observations to account for those censored due to treatment non-adherence

(Condensed from: `/raw/methods/RWE_Logic_08_TTE_Fundamentals.md`, Sections 1.1–2.3)

## Why EAG Prefers TTE

(Condensed from: `/raw/methods/RWE_Logic_08_TTE_Fundamentals.md`, Section 3; `/raw/methods/RWE_Logic_09_TTE_HTA_Case.md`, Step 1)

**Transparency:** TTE forces explicit documentation before analysis, preventing hidden decisions.

**Temporal Integrity:** By enforcing [[Zero_Time_Alignment]], TTE prevents the "black box" where it's unclear when confounders were measured relative to treatment.

**Auditability:** The 7-pillar structure makes it obvious where bias could enter. EAG can follow the logic step-by-step.

**NICE DataSAT Requirement:** NICE's Data Suitability Assessment Tool demands **Provenance** — the clear lineage of how raw data becomes study rows. TTE provides this.

(Condensed from: `/raw/methods/RWE_Logic_08_TTE_Fundamentals.md`, Section 3)

## Relation to Other Study Designs

- [[External_Control_Arm]] — TTE is a framework for structuring ECA comparisons rigorously
- [[IPTW_Inverse_Probability_Treatment_Weighting]] — Common estimation method within TTE
- [[AIPW_Augmented_Inverse_Probability_Weighting]] — Alternative doubly robust estimation in TTE
- [[Confounding_by_Indication]] — The selection bias TTE aims to address via propensity adjustment
- [[Immortal_Time_Bias]] — Key bias TTE prevents via zero-time alignment

## Key Operational Concepts

- [[Clinical_Equipoise]] — Defines the moment T₀ occurs
- [[Cloning_and_Censoring]] — Technique for handling protocol violations while preserving ITT
- [[IPCW_Inverse_Probability_Censoring_Weights]] — Maintains balance throughout follow-up post-censoring
- [[E_Value]] — Quantifies robustness to unmeasured confounding in TTE context

## HTA Case Records

<!-- Pending: awaiting first NICE case using TTE to populate this section -->

## Source Anchor

> "TTE is not an algorithm; it is a **mental straitjacket** that prevents you from comparing current users with survivors, including information from the future into the past, and ignoring the moment of decision-making. By emulating a trial, we transform a chaotic database into a structured experiment where **Time** is the most guarded variable."

(来源：`/raw/methods/RWE_Logic_08_TTE_Fundamentals.md`, Summary section)

## Source Files

- Fundamentals: `/raw/methods/RWE_Logic_08_TTE_Fundamentals.md`
- HTA Practice: `/raw/methods/RWE_Logic_09_TTE_HTA_Case.md`

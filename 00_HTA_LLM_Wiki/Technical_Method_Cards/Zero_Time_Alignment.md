---
tags: [hta-concept]
method_family: Emulation
aliases: [T₀ Alignment, Time Zero, T0 Synchronization]
---

# Zero-Time Alignment (T₀ Alignment)

A critical operational requirement in [[TTE_Target_Trial_Emulation]] where **treatment assignment, eligibility determination, and start of follow-up all occur at the same moment (T₀)**; prevents [[Immortal_Time_Bias]] and ensures balanced baseline measurement by preventing use of post-assignment information to define treatment groups.

## Definition & Mechanism

(Condensed from: `/raw/methods/RWE_Logic_08_TTE_Fundamentals.md`, Section 2)

**T₀ is the Anchor Moment:**
- Moment patient meets all eligibility criteria
- Moment treatment assignment is determined (or simulated via propensity score)
- Moment follow-up clock starts
- All three must coincide at a single time point

**The Danger Without T₀ Alignment:**

If you measure events *after* treatment initiation and use that to define the group:

- Patients who die before initiating treatment are automatically removed from the treated group
- Treated group appears artificially healthy (survivor effect)
- This is [[Immortal_Time_Bias]]

(Condensed from: `/raw/methods/RWE_Logic_08_TTE_Fundamentals.md`, Section 2.1–2.2)

## Implementation Challenge: The "Window Period"

(Condensed from: `/raw/methods/RWE_Logic_09_TTE_HTA_Case.md`, Section 1.5)

**Real-world problem:** Patients are diagnosed on Date 1 but may not initiate treatment until Date 20 (due to testing, logistics, or clinical judgment).

**Solution:** [[Cloning_and_Censoring]] — Create virtual copies of the patient assigned to each arm at T₀ (Date 1); censor the "control clone" if the patient actually initiates treatment (Date 20).

This ensures:
- Both treatment and control contribute person-time from Date 1–20
- No patient is "immortal" because clock starts at T₀
- Baseline balance is preserved

(Condensed from: `/raw/methods/RWE_Logic_09_TTE_HTA_Case.md`, Section 1.5)

## EAG Scrutiny Points

> ⚠️ Inferred from source documents pending empirical case validation.

1. **Baseline Contamination:** Company uses covariate measurements *after* treatment initiation as "baseline." EAG flags this as post-T₀ bias.

2. **Vague T₀ Definition:** "Patients who initiated treatment between 2020-2022" is too loose. EAG demands exact T₀ definition.

3. **Misalignment Detection:** EAG checks if treatment assignment was determined *before* follow-up started. If follow-up was pre-defined and treatment assignment post-hoc, T₀ is violated.

## Relationship to [[Immortal_Time_Bias]]

T₀ Alignment directly **prevents** Immortal Time Bias by ensuring no patient gains "free" follow-up time before assignment. The clock doesn't start ticking at an earlier, unmeasured moment; it starts at the exact decision point.

## Related Concepts

- [[TTE_Target_Trial_Emulation]] — Framework requiring T₀ alignment
- [[Immortal_Time_Bias]] — Bias prevented by proper T₀ alignment
- [[Clinical_Equipoise]] — Patient state at T₀ that justifies cloning
- [[Cloning_and_Censoring]] — Technique for handling T₀ window periods
- [[IPCW_Inverse_Probability_Censoring_Weights]] — Reweighting to maintain balance after clone censoring
- [[New_User_Design]] — Complements T₀ by requiring initiation at T₀

## Source Anchor

> "We must **synchronize everyone to a single 'Moment of Eligibility'** ($T_0$). The Anchor: $T_0$ is the moment the patient meets all eligibility criteria **AND** initiates (or doesn't initiate) treatment. No one is 'immortal' because the clock starts ticking the moment they are assigned."

(来源：`/raw/methods/RWE_Logic_08_TTE_Fundamentals.md`, Section 2.2)

## Source Files

Referenced in: `/raw/methods/RWE_Logic_08_TTE_Fundamentals.md`, Sections 2–2.2; `/raw/methods/RWE_Logic_09_TTE_HTA_Case.md`, Sections 1.3–1.5

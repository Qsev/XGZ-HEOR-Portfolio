---
tags: [method, rwe]
method_family: Bias-Taxonomy
aliases: [Immortal Time Bias, ITB, Immortal Time, Survivor Bias, Waiting Period Bias]
---

# Immortal Time Bias (ITB)

A structural survival bias in observational studies where **treatment assignment is defined using information from a future time period**, causing treated patients to accumulate "guaranteed survival" time before treatment actually begins; appears as a spurious treatment benefit in raw analyses despite potential actual harm or neutrality.

## Definition & Core Problem

(Condensed from: `/raw/methods/RWE_Logic_10_Immortal_Time_Fundamentals.md`, Sections 1–2)

**The Fundamental Violation:**

Immortal time bias occurs when the period between study entry ($T_0$) and actual treatment initiation is incorrectly attributed to the treatment group. Patients who meet the definition of "treated" at some future time point must have "survived" until that point—a survival that cannot be attributed to the treatment they haven't yet received.

**Classic Example (Meditation & Longevity):**

If treated patients are defined as "those who completed 12 weeks of meditation," anyone who dies before week 12 is automatically excluded from the treated group (they never completed the program). The treated group is thus guaranteed 0% mortality during weeks 1–12, creating an artificial survival advantage that has nothing to do with meditation efficacy.

**Time-based Mechanism:**

- Patient enters study at Day 0 (eligibility moment, $T_0$)
- Patient initiates treatment at Day 60 (actual treatment start, $T_{treat}$)
- The interval [Day 0, Day 60] is "immortal time"—the patient contributes survival time to the treated group even though they were not treated
- Any patient who dies in this window is automatically removed from the treated group (they never initiated treatment)
- Treated group appears artificially healthy

(Condensed from: `/raw/methods/RWE_Logic_10_Immortal_Time_Fundamentals.md`, Sections 1.1–1.2)

## Violation of Non-anticipatory Constraint

(Condensed from: `/raw/methods/RWE_Logic_10_Immortal_Time_Fundamentals.md`, Section 2)

**Theoretical Breach:**

Causal inference requires that treatment assignment $Z$ be determined based only on information available at $T_0$:

$$P(Z=1 \mid \mathcal{F}_0) \text{ (Assignment depends only on past information)}$$

Immortal time bias violates this by defining $Z$ using post-baseline outcomes or future administrative events:

$$Z = f(Y_{t \in [T_0, T_{treat}]}) \text{ (Future-dependent assignment — VIOLATION)}$$

**Consequence:**

Treatment assignment becomes conditional on "surviving to treatment," making the treated group inherently biased toward better prognosis, even before treatment begins. This is logically equivalent to "time travel"—using future knowledge to define past groups.

## Why It Matters in HTA

(Condensed from: `/raw/methods/RWE_Logic_11_Immortal_Time_HTA_Practice.md`, Section 1)

**EAG Detection Method:**

Auditors examine the Kaplan-Meier curve for a "flat line" at the beginning of the treated arm's follow-up. If the treated group shows zero deaths during an initial period while the control group experiences normal mortality, ITB is suspected.

**Common HTA Scenarios:**

1. **External Control Arm (ECA):** Drug group defined from treatment initiation; control group defined from diagnosis. Gap between diagnosis and treatment initiation creates "immortal time" for the drug group.

2. **Approval Lag:** When real-world data includes administrative delays (insurance approval, IFR process) between diagnosis ($T_0$) and first drug dose ($T_{treat}$), patients are locked into the drug group for that lag period regardless of actual drug exposure.

3. **New User Design Violation:** Patients are defined as "initiators" retroactively—assigned to treatment based on whether they actually initiated, rather than their status at a pre-defined eligibility moment.

## Distinction from [[Confounding_by_Indication]]

| Aspect | Immortal Time Bias | Confounding by Indication |
|:---|:---|:---|
| **Root cause** | Future knowledge used to assign groups at $T_0$ | Patient sickness determines treatment assignment at $T_0$ |
| **Mechanism** | Treated group guaranteed survival during lag period | Treated patients already sicker at baseline |
| **Effect on outcome** | Spurious treatment benefit (survival inflated) | Confounding by baseline severity (direction varies) |
| **Fixability** | Requires temporal realignment (Zero-time alignment) | Requires covariate adjustment (PSM/IPTW) |

## Solutions

(Condensed from: `/raw/methods/RWE_Logic_10_Immortal_Time_Fundamentals.md`, Section 3; `/raw/methods/RWE_Logic_11_Immortal_Time_HTA_Practice.md`, Sections 2–3)

**1. [[Landmark_Analysis]]:** Exclude all patients who don't survive to a pre-defined time point; restart follow-up from that point. Simple but causes information loss and selection bias.

**2. [[Time-dependent_Cox_Model]]:** Use a [[Counting_Process|counting process]] data structure to allow treatment status to change during follow-up; the risk set is updated dynamically as patients initiate treatment. Maintains full information and aligns with reality.

**3. [[Cloning_and_Censoring]]:** Create virtual copies of patients at $T_0$ assigned to each arm; censor one clone when the real patient initiates treatment. Preserves [[Intention_To_Treat]] while eliminating immortal time contribution.

## EAG Scrutiny Points

> ⚠️ Inferred from source documents pending empirical case validation.

(Condensed from: `/raw/methods/RWE_Logic_11_Immortal_Time_HTA_Practice.md`, Section 4)

1. **Lag Not Identified:** Company claims $T_0$ alignment but doesn't explicitly quantify the gap between eligibility (diagnosis) and actual treatment initiation. EAG requests the specific calendar dates.

2. **Visual ITB Red Flag:** Initial segment of KM curve for treated group is flat (zero events) while control group shows normal event rates. EAG immediately flags ITB.

3. **Standard Cox Model with Baseline Assignment:** If analysis used standard Cox regression with treatment as a baseline covariate (not time-dependent), entire HR estimate is invalid under ITB.

4. **Landmark Approach Without Justification:** If company used Landmark to remove "early deaths," EAG questions: "Who is your population? Did you select for survivors, violating ITT?"

5. **Missing Time-dependent Validation:** Company reports results but doesn't show comparison to time-dependent Cox or cloning approach. EAG demands robustness check against ITB-corrected alternatives.

## Related Concepts

- [[TTE_Target_Trial_Emulation]] — Framework preventing ITB via [[Zero_Time_Alignment]]
- [[Zero_Time_Alignment]] — Temporal requirement that prevents ITB
- [[New_User_Design]] — Design requiring initiation at $T_0$, not retroactive assignment
- [[Intention_To_Treat]] — Principle preserved by ITB solutions (cloning, time-dependent Cox)
- [[Cloning_and_Censoring]] — Advanced technique for ITB elimination via virtual copies
- [[Landmark_Analysis]] — Classical (but limited) ITB solution
- [[Time-dependent_Cox_Model]] — Modern statistical solution
- [[Confounding_by_Indication]] — Distinct bias type; both may co-occur
- [[Counting_Process]] — Data structure supporting time-dependent approaches
- [[External_Control_Arm]] — High-risk setting for ITB (historical controls, approval lags)

## Source Anchor

> "不朽时间是指在观察性研究中，**暴露状态被定义之后、但真正的随访（Clock-start）开始之前**的一段观测时间。逻辑荒谬：如果你在计算生存率时，将这段'不朽时间'也算作治疗组的'贡献'，你实际上是在拿一群'被上帝保证前 12 周不死的人'去和一群'随时可能死的人'进行比较。"

(来源：`/raw/methods/RWE_Logic_10_Immortal_Time_Fundamentals.md`, Section 1.2)

## Source Files

- Fundamentals: `/raw/methods/RWE_Logic_10_Immortal_Time_Fundamentals.md`
- HTA Practice: `/raw/methods/RWE_Logic_11_Immortal_Time_HTA_Practice.md`

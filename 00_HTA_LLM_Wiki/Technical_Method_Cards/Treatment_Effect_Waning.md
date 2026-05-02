---
tags: [hta-concept, pharmacoeconomic-modeling]
---
# Treatment Effect Waning (Carry-Over Benefit)

An assumption that a drug's clinical benefit persists for a defined duration *after patients stop taking the drug*, then gradually fades until reaching baseline/comparator level. Common in adjuvant and prevention settings where treatment is not lifelong.

## Why It Exists

In many early-stage cancer trials, patients receive finite therapy (e.g., 3 years of adjuvant treatment), then stop. The question: do benefits continue indefinitely, or do they fade?

**Manufacturer often assumes**: Benefits persist for years post-treatment (e.g., 8–17.5 years), generating additional QALYs long after drug discontinuation.

**EAG often challenges**: No long-term data exists; assumption is speculative; likely overstates benefit.

## The Waning Curve Problem

Two scenarios:
1. **Constant hazard reduction**: Benefit remains constant for X years, then suddenly reverts (unrealistic)
2. **Gradual waning**: Benefit remains constant for Y years, then linearly or exponentially decays until reversing to baseline (slightly more plausible but still speculative)

Choosing Y (waning duration) is discretionary and hugely impacts QALY gains.

## Why Manufacturers Use It

Adjuvant drugs don't work while patients take them only—they're preventing future recurrence. The company argues: "Even after stopping the drug, patients remain protected due to prior tumor cell elimination." This logic extends benefit well beyond treatment duration, inflating QALYs.

## Why EAG Challenges It

- No long-term follow-up data (trial ends when patients stop drug)
- Assumption is arbitrary; could last 5 years or 15 years
- If you assume 15-year waning, you've essentially claimed the patient is *protected for life* despite evidence ending at year 3
- Allows manufacturers to claim long-term benefit despite short trial follow-up

## Committee Judgment Tendencies

Based on [[TA1086]] and [[TA1017]], the committee's pattern is consistent: **neither extreme is accepted**.

**Conditions under which waning assumptions are accepted:**
- Company proposes a specific waning duration with at least partial biological justification (even if indirect)
- ICER remains acceptable across a wide sensitivity range of waning scenarios — not just at the base case
- Waning is modelled as gradual (linear or exponential decay), not an abrupt cliff-edge reversion

**Conditions under which waning assumptions are rejected or modified:**
- Company assumes perpetual constant treatment effect beyond trial follow-up with no supporting evidence
- Waning duration is anchored to data from a different drug class or a different setting (e.g., using ATAC trial for CDK4/6 inhibitors)
- ICER is only acceptable under the company's most optimistic waning scenario and deteriorates significantly under EAG's alternatives

**Key pattern**: When both extremes are rejected (company's perpetual benefit vs. EAG's immediate reversion to null), the committee tends to impose its own explicit waning schedule — typically a gradual decay beginning 3–5 years post-treatment. This committee-imposed schedule becomes the accepted base case.

## Preventive Modelling Guidance for Companies

> ⚠️ The following is inferential guidance derived from case records — not sourced from primary documents. Apply with judgement and revise as further cases are ingested.

1. **Avoid perpetual constant effect assumptions**: Claiming the trial HR holds indefinitely for 30+ years is the single most reliable way to invite EAG rejection. Even if biologically plausible, it will be challenged. Build in a waning schedule from the outset.

2. **Anchor waning duration to disease-specific evidence**: Do not justify waning duration using data from a different drug class or generation (e.g., using hormone therapy legacy data for CDK4/6 inhibitors). Use the same drug class, same setting, or cite clinical expert opinion explicitly documented in the submission.

3. **Run wide sensitivity ranges proactively**: EAG will demand scenarios from 0 years waning to 15+ years. If your ICER is only acceptable at the upper end of waning duration, the model will not survive scrutiny. Demonstrate robustness across the full range before submission.

4. **Propose a gradual decay curve, not a cliff-edge**: A sudden reversion to baseline after a fixed period looks arbitrary. A linear or exponential decay starting at a defined post-treatment timepoint is more clinically defensible and more likely to be accepted.

5. **Expect committee override**: If EAG and company positions are far apart, the committee may impose its own waning schedule independent of both submissions. Design your model to be structurally compatible with a range of externally imposed waning parameters.

## Case Records

### [[TA1086]] ([[Ribociclib]])

**Manufacturer Assumption** (来源：/raw/storyboards/TA1086_Ribociclib_Adjuvant_Early_Breast_Cancer.md, Section 4, Clash 2):
- Ribociclib's benefit remains constant for 8 years post-treatment
- After 8 years, gradually wanes until matching general population mortality
- Justified via legacy data from older hormone therapies ([[ATAC trial]])

**Impact on QALY/ICER**: 
This long carry-over assumption significantly prolongs survival benefits beyond the 2–3 year treatment window, heavily inflating total QALY gains and artificially lowering ICER.

**EAG Challenge**:
> "Arbitrary and not supported by the evidence."
- ATAC trial (decades old, hormone-only therapy) has nothing to do with CDK4/6 inhibitors
- No long-term CDK4/6 data exists; cannot justify 8-year waning
- Demanded sensitivity analysis testing 5 years → 17.5 years waning scenarios

**Committee Verdict**:
- Acknowledged the actual waning effect is "highly uncertain" (no long-term CDK4/6 data)
- **Pragmatically accepted** manufacturer's 8-year constant + waning approach
- **Caveat**: ICER must hold up under EAG's stricter sensitivity scenarios (wider waning range)
- Ultimately recommended, provided ICER remained acceptable even with pessimistic waning assumptions

**Net Impact**: While EAG's challenge reduced projected benefits somewhat, Committee allowed a middle-ground compromise (8-year waning). Result: ICER remained favorable enough for recommendation.

**Lesson**: EAG will demand wide sensitivity ranges on waning assumptions; they won't accept narrow ranges. But Committee may pragmatically accept a middle-ground waning period if the ICER is robust across the broader range. The key: demonstrate sensitivity to waning uncertainty, not just defend a single assumption.

### [[TA1017]] ([[Pembrolizumab]] in [[Resectable_NSCLC]])

**Company Assumption** (来源：/raw/storyboards/TA1017_Pembrolizumab_Resectable_NSCLC.md, Section 4, Conflict 1):
- Pembrolizumab's hazard ratio vs. nivolumab remains constant at its most favorable observed value (end of KEYNOTE-671 trial at 41.4 months)
- Applied indefinitely for remaining 31.7 years of model time horizon
- Justified via "time-varying" HR with no evidence of subsequent decline

**Impact on QALY/ICER**: 
Assuming perpetual constant HR at optimal observed point significantly inflates long-term EFS/OS, overestimating total QALYs and artificially lowering ICER.

**EAG Challenge** (EAG report, Section 6.5):
> "The EAG considers that the company has provided insufficient evidence to apply the HR generated at the end of the KEYNOTE-671 trial follow-up period for the remaining model time frame (31.7 years)."
- Trial follow-up is only ~5 years; extrapolating another 31.7 years is speculative
- No evidence that HR remains constant post-trial; immunotherapy benefits often wane
- Proposed HR = 1.0 (zero benefit) immediately after trial cutoff as alternative

**Committee Resolution**:
- Rejected both company's indefinite constant HR and EAG's immediate reversion to HR = 1.0
- Adopted **gradual treatment effect waning**: HR remains constant until 3.5 years post-surgery, then linearly decays to HR = 1.0 by 5.5 years (TA1017, Section 3.12) (来源：/raw/storyboards/TA1017_Pembrolizumab_Resectable_NSCLC.md, Section 4)

**Net Impact**: Gradual waning (vs. perpetual constant) reduces projected EFS/OS gains, raising ICER moderately. More realistic than either extreme position. Pembrolizumab remained recommended, indicating ICER remained acceptable even with waning applied.

**Key Difference from TA1086**: 
- **TA1086 (Ribociclib)**: Committee accepted manufacturer's proposed waning period (8 years) despite EAG skepticism; pragmatically allowed wider sensitivity range
- **TA1017 (Pembrolizumab)**: Committee imposed explicit waning schedule (3.5–5.5 years) not proposed by either company or EAG; forced compromise between indefinite constant and immediate reversion

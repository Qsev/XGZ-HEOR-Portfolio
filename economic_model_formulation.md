# Economic Model Formulation: Partitioned Survival Model & Decision Tree

This document outlines the mathematical framework, state transition equations, population background mortality constraints, and ITT correction logic used in Phase 4 of the NICE TA975 economic evaluation.

## 1. Partitioned Survival Model (PSM) State Occupancy

The economic model is structured as a Partitioned Survival Model (PSM) consisting of three mutually exclusive health states:
1. **Event-Free Survival (EFS)**: Patients who are alive without disease progression or relapse.
2. **Progressed Disease / Relapsed (PD)**: Patients who have progressed or relapsed but remain alive.
3. **Death (Dead)**: Absorbing state for all-cause mortality.

The proportion of patients in each health state at any given monthly cycle $t$ is directly partitioned from the Event-Free Survival ($S(EFS, t)$) and Overall Survival ($S(OS, t)$) curves:

$$P(EFS, t) = S(EFS, t)$$
$$P(PD, t) = S(OS, t) - S(EFS, t)$$
$$P(Dead, t) = 1 - S(OS, t)$$

## 2. Background Mortality Constraints and Standardised Mortality Ratio (SMR)

The cohort enters the model at a mean age of 12 years. All-cause mortality in the economic model is constrained by the natural mortality of the general population in England and Wales.

### 2.1 General Population Mortality Approximation
Annual general population mortality probability $q(x)$ at age $x$ is approximated using a fitted Gompertz formulation for the UK population:

$$q(x) = a \cdot e^{b \cdot x}$$

where:
- $a = 0.00003$
- $b = 0.09$
- $x = 12 + t/12$ (age in years at monthly cycle $t$)

The monthly probability of natural mortality $q(monthly, t)$ is:

$$q(monthly, t) = 1 - (1 - q(x))^{1/12}$$

### 2.2 SMR Adjustment
For long-term cancer survivors, an excess mortality multiplier is applied. A Standardised Mortality Ratio (SMR) of 4.0 is applied to the background mortality hazard.

The monthly background mortality hazard $h(bg, t)$ is:

$$h(bg, t) = -\ln(1 - q(monthly, t)) = -\ln(1 - q(x))/12$$

Applying the SMR = 4 adjustment, the SMR-adjusted hazard is:

$$h(SMR, t) = 4 \cdot h(bg, t)$$

The SMR-adjusted general population survival probability up to cycle $t$ is:

$$S(bgSMR, t) = \exp\left( - \sum_{\tau=0}^{t-1} h(SMR, \tau) \right)$$

### 2.3 Survival Constraints
To ensure logical consistency and prevent survival from exceeding general population rates:
1. Overall Survival is capped by the SMR-adjusted background survival:
   $$S(OS, constrained, t) = \min\left(S(OS, model, t), S(bgSMR, t)\right)$$
2. Event-Free Survival is constrained to be less than or equal to Overall Survival:
   $$S(EFS, constrained, t) = \min\left(S(EFS, model, t), S(OS, constrained, t)\right)$$

## 3. Event-Free Survival (EFS) Derivation for Comparators

For Blinatumomab and Salvage Chemotherapy, EFS Kaplan-Meier data were not available. EFS is derived from the OS curve by applying a constant cumulative hazard ratio (HR) of 0.83 (based on Parker et al., 2010):

### 3.1 Proportional Hazard Phase (Up to 5 Years)
For $t \le 60$ months (5 years), the EFS cumulative hazard is $H(EFS, t) = H(OS, t)/0.83$. This translates to:

$$S(EFS, t) = S(OS, t)^{1/0.83}$$

### 3.2 Post 5-Year Phase
After 5 years ($t > 60$ months), the event-free survival function is assumed to remain flat until it meets the overall survival curve:

$$S(EFS, t) = \min\left( S(EFS, 60), S(OS, t) \right)$$

## 4. Decision Tree & ITT Correction for CAR-T Cohort

For the Tisagenlecleucel (CAR-T) cohort, a decision tree accounts for patients who do not proceed to infusion. The cohort is split based on three probabilities:
- **$P1 = 81.4\%$**: Successfully proceed to infusion (enters Tisagenlecleucel PSM).
- **$P2 = 11.3\%$**: Discontinue after enrollment/apheresis but before infusion, switching to comparator therapies (assumed 50% Blinatumomab + 50% Salvage Chemotherapy).
- **$P3 = 7.2\%$**: Discontinue and die prior to receiving treatment (modeled as entering the Dead state at cycle 0).

The overall Intent-to-Treat (ITT) state occupancy trace for the CAR-T group is calculated as a weighted average:

$$Trace(CART, t) = P1 \cdot Trace(CART, infused, t) + P2 \cdot (0.5 \cdot Trace(Blina, t) + 0.5 \cdot Trace(Chemo, t)) + P3 \cdot Dead(start, t)$$

where:
- $Trace(cohort, t) = [P(EFS, t), P(PD, t), P(Dead, t)]^T$
- $Dead(start, t) = [0, 0, 1]^T$ for all $t \ge 0$.

## 5. Half-Cycle Correction (Trapezoidal Method)

To adjust for the discrete representation of cycles in a continuous lifetime process, we apply the trapezoidal half-cycle correction to state occupancies for the calculation of life years (and subsequent costs/utilities):

$$StateOccupied(corrected, t) = 0.5 \cdot StateOccupied(t) + 0.5 \cdot StateOccupied(t-1) \quad \text{for } t \ge 1$$
$$StateOccupied(corrected, 0) = 0.5 \cdot StateOccupied(0)$$

## 6. Health State Utilities & Adverse Event Disutilities

### 6.1 Baseline Health State Utilities
Base health state utilities are derived from Kelly et al. (2015):
- Event-Free Survival (EFS): $U(EFS) = 0.91$
- Progressed Disease (PD): $U(PD) = 0.75$

#### 6.1.1 Cure Assumption Utility Recovery
For patients surviving past 5 years ($t > 60$ months), their health state utility for both EFS and PD is restored to the long-term survivor utility of $0.91$:

$$U(base, t) = \begin{cases} 0.91 & \text{for EFS state, or for } t > 60 \\ 0.75 & \text{for PD state and } t \le 60 \end{cases}$$

### 6.2 Age-Related Utility Adjustment
As patients age, baseline utilities are adjusted by multipliers derived from the Health Survey for England (HSE) 2014:

$$U(t, state) = U(base, t, state) \cdot M(age, t)$$

where $M(age, t)$ is the age-related utility multiplier corresponding to the cohort's age $12 + t/12$ at cycle $t$.

### 6.3 Short-Term Adverse Event and Treatment Disutilities
Short-term disutilities are subtracted as one-time QALY decrements in Cycle 1 ($t = 1$). The disutility loss (in QALYs) is calculated as:

$$QALYloss = DisutilityValue \cdot \frac{DurationDays}{365.25} \cdot Incidence$$

#### 6.3.1 Disutility Components
1. **Base Treatment Disutility**: Disutility of $-0.42$ (hospitalization).
   - Tisagenlecleucel: $25.85$ days
   - Blinatumomab: $21.00$ days (swapped value in EAG report; Document B is $9.24$ days)
   - FLAG-IDA: $9.24$ days (swapped value in EAG report; Document B is $21.00$ days)
2. **Severe CRS (ICU stay)**: Disutility of $-0.91$.
   - Tisagenlecleucel: $11.10$ days, incidence $48.10\%$
   - Blinatumomab: $11.10$ days, incidence $5.71\%$
3. **Non-CRS ICU Admission (Tisa only)**: Disutility of $-0.91$, duration $1.74$ days, incidence $100\%$ of infused patients.
4. **Subsequent allo-SCT**: Disutility of $-0.57$, duration $365$ days.
   - Tisagenlecleucel: incidence $22.78\%$
   - Blinatumomab: incidence $34.29\%$
   - FLAG-IDA: incidence $14.75\%$

### 6.4 One-Time Disutility QALY Losses by Active Cohort
The total expected one-time disutility QALY loss in Cycle 1 for a patient actively receiving each treatment is:

$$Loss(infusedTisa) = 0.42 \cdot \frac{25.85}{365.25} + 0.91 \cdot \frac{11.10}{365.25} \cdot 0.4810 + 0.91 \cdot \frac{1.74}{365.25} + 0.57 \cdot \frac{365}{365.25} \cdot 0.2278$$
$$Loss(Blina) = 0.42 \cdot \frac{21.00}{365.25} + 0.91 \cdot \frac{11.10}{365.25} \cdot 0.0571 + 0.57 \cdot \frac{365}{365.25} \cdot 0.3429$$
$$Loss(Chemo) = 0.42 \cdot \frac{9.24}{365.25} + 0.57 \cdot \frac{365}{365.25} \cdot 0.1475$$

For the CAR-T Intent-to-Treat (ITT) cohort, the one-time disutility loss is weighted by the decision tree probabilities:

$$Loss(CART, ITT) = P1 \cdot Loss(infusedTisa) + P2 \cdot (0.5 \cdot Loss(Blina) + 0.5 \cdot Loss(Chemo)) + P3 \cdot 0$$

## 7. Lifetime QALY Calculation

The lifetime Quality-Adjusted Life Years (QALYs) are accumulated over the horizon of $1056$ cycles, discounted at an annual rate of $r = 3.5\%$.
The monthly discount factor for cycle $t$ is:

$$DF(t) = \frac{1}{(1 + r)^{t/12}}$$

The discounted QALYs contributed by the cohort trace in cycle $t$ are:

$$QALYcycle(t) = \left[ P(EFS, t) \cdot U(t, EFS) + P(PD, t) \cdot U(t, PD) \right] \cdot \frac{1}{12} \cdot DF(t)$$

The total lifetime QALYs for the cohort is the sum over all cycles, minus the one-time disutility loss:

$$TotalQALYs = \sum_{t=0}^{1056} QALYcycle(t) - Loss(onetime)$$

## 8. Lifetime Cost Calculation

Lifetime costs are accumulated over $1056$ cycles, discounted at $3.5\%$ annually.
The monthly discount factor is:

$$DF(t) = \frac{1}{(1 + 0.035)^{t/12}}$$

### 8.1 Hospital and Follow-up Costs by Health State
Health state follow-up costs are applied dynamically based on the cycle $t$.

#### 8.1.1 Tisagenlecleucel Follow-up Costs
- **Event-Free Survival (EFS)**:
  $$C(EFS, Tisa, t) = \begin{cases} \text{£}472.58 & \text{for } t \le 12 \\ \text{£}111.87 & \text{for } 12 < t \le 24 \\ \text{£}56.18 & \text{for } 24 < t \le 60 \\ \text{£}27.47 & \text{for } t > 60 \end{cases}$$
- **Progressed Disease (PD)**:
  $$C(PD, Tisa, t) = \begin{cases} \text{£}191.00 & \text{for } t \le 12 \\ \text{£}263.00 & \text{for } 12 < t \le 60 \\ \text{£}27.47 & \text{for } t > 60 \end{cases}$$

#### 8.1.2 Comparators (Blinatumomab & FLAG-IDA) Follow-up Costs
- **Event-Free Survival (EFS)**:
  $$C(EFS, Comp, t) = \begin{cases} \text{£}263.00 & \text{for } t \le 12 \\ \text{£}110.86 & \text{for } 12 < t \le 24 \\ \text{£}55.43 & \text{for } 24 < t \le 60 \\ \text{£}27.47 & \text{for } t > 60 \end{cases}$$
- **Progressed Disease (PD)**:
  $$C(PD, Comp, t) = \begin{cases} \text{£}263.00 & \text{for } t \le 60 \\ \text{£}27.47 & \text{for } t > 60 \end{cases}$$

### 8.2 Terminal Care Costs
Terminal care cost ($\text{£}13,198.42$) is applied to patients who die within the first 5 years ($t \le 60$):

$$ProportionDying(t) = S(OS, t-1) - S(OS, t)$$

- **Comparators**: Terminal care is applied for all deaths where $t \le 60$.
- **Tisagenlecleucel (infused)**: Post-infusion deaths within the first 100 days ($t \le 3$) are excluded (covered by NHS tariff):

  $$TC(Tisa, infused, t) = \begin{cases} 0 & \text{for } t \le 3 \text{ or } t > 60 \\ (S(OS, t-1) - S(OS, t)) \cdot \text{£}13,198.42 & \text{for } 3 < t \le 60 \end{cases}$$

### 8.3 Total Cohort Cost Formulas

#### 8.1.3 Blinatumomab and FLAG-IDA Cohorts

$$Cost(Blina) = Acquisition(Blina) + AE(Blina) + SCT(Blina) \cdot C(SCT) + \sum_{t=1}^{1056} \left[ P(EFS, t) \cdot C(EFS, Comp, t) + P(PD, t) \cdot C(PD, Comp, t) + TC(Blina, t) \right] \cdot DF(t)$$

$$Cost(Chemo) = Acquisition(Chemo) + AE(Chemo) + SCT(Chemo) \cdot C(SCT) + \sum_{t=1}^{1056} \left[ P(EFS, t) \cdot C(EFS, Comp, t) + P(PD, t) \cdot C(PD, Comp, t) + TC(Chemo, t) \right] \cdot DF(t)$$

where $C(SCT) = \text{£}151,227.43$.

#### 8.1.4 Tisagenlecleucel ITT Cohort

$$Cost(CART, ITT, Price) = P1 \cdot Cost(infusedTisa, Price) + P2 \cdot (0.5 \cdot Cost(Blina) + 0.5 \cdot Cost(Chemo) + C(preTx)) + P3 \cdot (C(preTx) + \text{£}13,198.42)$$

where:
- $Cost(infusedTisa, Price) = Price + Tariff + Bridging + 0.96 \cdot Lymphodepleting + IVIg + SCT(Tisa) \cdot C(SCT) + \sum_{t=1}^{1056} \left[ P(EFS, t) \cdot C(EFS, Tisa, t) + P(PD, t) \cdot C(PD, Tisa, t) + TC(Tisa, infused, t) \right] \cdot DF(t)$
- $C(preTx) = Leukapheresis + 0.5 \cdot Bridging + 0.5 \cdot Lymphodepleting = \text{£}2,575.70 + 0.5 \cdot \text{£}1,394.57 + 0.5 \cdot \text{£}404.52 = \text{£}3,475.25$.
- $Tariff = \text{£}41,101$.
- $IVIg = \text{£}11,176.85$.

## 9. Incremental Cost-Effectiveness Ratio (ICER)

The ICER compares Tisagenlecleucel to each comparator:

$$ICER = \frac{\Delta Cost}{\Delta QALYs} = \frac{Cost(CART, ITT) - Cost(comparator)}{QALYs(CART, ITT) - QALYs(comparator)}$$

## 10. Patient Access Scheme (PAS) Price Reverse Engineering

The Patient Access Scheme (PAS) price is the discounted price of Tisagenlecleucel that achieves a specific target ICER compared to Blinatumomab:

$$ICER(Tisa, vs, Blina, Price(PAS)) = \text{£}19,218$$

We solve for $Price(PAS)$ using numerical root-finding:

$$f(Price) = ICER(Tisa, vs, Blina, Price) - 19,218 = 0$$

Using the solved $Price(PAS)$, we then calculate the discount percentage:

$$DiscountPercent = 1 - \frac{Price(PAS)}{ListPrice}$$

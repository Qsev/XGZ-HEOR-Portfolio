# Economic Model Formulation: Partitioned Survival Model & Decision Tree

This document outlines the mathematical framework, state transition equations, population background mortality constraints, and ITT correction logic used in Phase 4 of the NICE TA975 economic evaluation.

## 1. Partitioned Survival Model (PSM) State Occupancy

The economic model is structured as a Partitioned Survival Model (PSM) consisting of three mutually exclusive health states:
1. **Event-Free Survival (EFS)**: Patients who are alive without disease progression or relapse.
2. **Progressed Disease / Relapsed (PD)**: Patients who have progressed or relapsed but remain alive.
3. **Death (Dead)**: Absorbing state for all-cause mortality.

The proportion of patients in each health state at any given monthly cycle $t$ is directly partitioned from the Event-Free Survival ($S_{EFS}(t)$) and Overall Survival ($S_{OS}(t)$) curves:

$$P(EFS_t) = S_{EFS}(t)$$
$$P(PD_t) = S_{OS}(t) - S_{EFS}(t)$$
$$P(Dead_t) = 1 - S_{OS}(t)$$

## 2. Background Mortality Constraints and Standardised Mortality Ratio (SMR)

The cohort enters the model at a mean age of 12 years. All-cause mortality in the economic model is constrained by the natural mortality of the general population in England and Wales.

### 2.1 General Population Mortality Approximation
Annual general population mortality probability $q_x$ at age $x$ is approximated using a fitted Gompertz formulation for the UK population:

$$q_x = a \cdot e^{b \cdot x}$$

where:
- $a = 0.00003$
- $b = 0.09$
- $x = 12 + \frac{t}{12}$ (age in years at monthly cycle $t$)

The monthly probability of natural mortality $q_{monthly}(t)$ is:

$$q_{monthly}(t) = 1 - (1 - q_x)^{1/12}$$

### 2.2 SMR Adjustment
For long-term cancer survivors, an excess mortality multiplier is applied. A Standardised Mortality Ratio (SMR) of 4.0 is applied to the background mortality hazard.

The monthly background mortality hazard $h_{bg}(t)$ is:

$$h_{bg}(t) = -\ln(1 - q_{monthly}(t)) = -\frac{\ln(1 - q_x)}{12}$$

Applying the SMR = 4 adjustment, the SMR-adjusted hazard is:

$$h_{SMR}(t) = 4 \cdot h_{bg}(t)$$

The SMR-adjusted general population survival probability up to cycle $t$ is:

$$S_{bg\_SMR}(t) = \exp\left( - \sum_{\tau=0}^{t-1} h_{SMR}(\tau) \right)$$

### 2.3 Survival Constraints
To ensure logical consistency and prevent survival from exceeding general population rates:
1. Overall Survival is capped by the SMR-adjusted background survival:
   $$S_{OS, constrained}(t) = \min\left(S_{OS, model}(t), S_{bg\_SMR}(t)\right)$$
2. Event-Free Survival is constrained to be less than or equal to Overall Survival:
   $$S_{EFS, constrained}(t) = \min\left(S_{EFS, model}(t), S_{OS, constrained}(t)\right)$$

## 3. Event-Free Survival (EFS) Derivation for Comparators

For Blinatumomab and Salvage Chemotherapy, EFS Kaplan-Meier data were not available. EFS is derived from the OS curve by applying a constant cumulative hazard ratio (HR) of 0.83 (based on Parker et al., 2010):

### 3.1 Proportional Hazard Phase (Up to 5 Years)
For $t \le 60$ months (5 years), the EFS cumulative hazard is $H_{EFS}(t) = \frac{H_{OS}(t)}{0.83}$. This translates to:

$$S_{EFS}(t) = \left( S_{OS}(t) \right)^{1/0.83}$$

### 3.2 Post 5-Year Phase
After 5 years ($t > 60$ months), the event-free survival function is assumed to remain flat until it meets the overall survival curve:

$$S_{EFS}(t) = \min\left( S_{EFS}(60), S_{OS}(t) \right)$$

## 4. Decision Tree & ITT Correction for CAR-T Cohort

For the Tisagenlecleucel (CAR-T) cohort, a decision tree accounts for patients who do not proceed to infusion. The cohort is split based on three probabilities:
- **$P_1 = 81.4\%$**: Successfully proceed to infusion (enters Tisagenlecleucel PSM).
- **$P_2 = 11.3\%$**: Discontinue after enrollment/apheresis but before infusion, switching to comparator therapies (assumed 50% Blinatumomab + 50% Salvage Chemotherapy).
- **$P_3 = 7.2\%$**: Discontinue and die prior to receiving treatment (modeled as entering the Dead state at cycle 0).

The overall Intent-to-Treat (ITT) state occupancy trace for the CAR-T group is calculated as a weighted average:

$$Trace_{CART}(t) = P_1 \cdot Trace_{CART, infused}(t) + P_2 \cdot \left( 0.5 \cdot Trace_{Blina}(t) + 0.5 \cdot Trace_{Chemo}(t) \right) + P_3 \cdot Dead_{start}(t)$$

where:
- $Trace_{cohort}(t) = [P(EFS_t), P(PD_t), P(Dead_t)]^T$
- $Dead_{start}(t) = [0, 0, 1]^T$ for all $t \ge 0$.

## 5. Half-Cycle Correction (Trapezoidal Method)

To adjust for the discrete representation of cycles in a continuous lifetime process, we apply the trapezoidal half-cycle correction to state occupancies for the calculation of life years (and subsequent costs/utilities):

$$State\_Occupied_{corrected}(t) = 0.5 \cdot State\_Occupied(t) + 0.5 \cdot State\_Occupied(t-1) \quad \text{for } t \ge 1$$
$$State\_Occupied_{corrected}(0) = 0.5 \cdot State\_Occupied(0)$$

## 6. Health State Utilities & Adverse Event Disutilities

### 6.1 Baseline Health State Utilities
Base health state utilities are derived from Kelly et al. (2015):
- Event-Free Survival (EFS): $U_{EFS} = 0.91$
- Progressed Disease (PD): $U_{PD} = 0.75$

#### 6.1.1 Cure Assumption Utility Recovery
For patients surviving past 5 years ($t > 60$ months), their health state utility for both EFS and PD is restored to the long-term survivor utility of $0.91$:

$$U_{base}(t) = \begin{cases} 0.91 & \text{for EFS state, or for } t > 60 \\ 0.75 & \text{for PD state and } t \le 60 \end{cases}$$

### 6.2 Age-Related Utility Adjustment
As patients age, baseline utilities are adjusted by multipliers derived from the Health Survey for England (HSE) 2014:

$$U(t, state) = U_{base}(t, state) \cdot M_{age}(t)$$

where $M_{age}(t)$ is the age-related utility multiplier corresponding to the cohort's age $12 + \frac{t}{12}$ at cycle $t$.

### 6.3 Short-Term Adverse Event and Treatment Disutilities
Short-term disutilities are subtracted as one-time QALY decrements in Cycle 1 ($t = 1$). The disutility loss (in QALYs) is calculated as:

$$QALY\_loss = Disutility\_Value \cdot \frac{Duration\_Days}{365.25} \cdot Incidence$$

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

$$Loss_{infused\_Tisa} = 0.42 \cdot \frac{25.85}{365.25} + 0.91 \cdot \frac{11.10}{365.25} \cdot 0.4810 + 0.91 \cdot \frac{1.74}{365.25} + 0.57 \cdot \frac{365}{365.25} \cdot 0.2278$$
$$Loss_{Blina} = 0.42 \cdot \frac{21.00}{365.25} + 0.91 \cdot \frac{11.10}{365.25} \cdot 0.0571 + 0.57 \cdot \frac{365}{365.25} \cdot 0.3429$$
$$Loss_{Chemo} = 0.42 \cdot \frac{9.24}{365.25} + 0.57 \cdot \frac{365}{365.25} \cdot 0.1475$$

For the CAR-T Intent-to-Treat (ITT) cohort, the one-time disutility loss is weighted by the decision tree probabilities:

$$Loss_{CART\_ITT} = P_1 \cdot Loss_{infused\_Tisa} + P_2 \cdot (0.5 \cdot Loss_{Blina} + 0.5 \cdot Loss_{Chemo}) + P_3 \cdot 0$$

## 7. Lifetime QALY Calculation

The lifetime Quality-Adjusted Life Years (QALYs) are accumulated over the horizon of $1056$ cycles, discounted at an annual rate of $r = 3.5\%$.
The monthly discount factor for cycle $t$ is:

$$DF(t) = \frac{1}{(1 + r)^{t/12}}$$

The discounted QALYs contributed by the cohort trace in cycle $t$ are:

$$QALY\_cycle(t) = \left[ P(EFS_t)_{hcc} \cdot U(t, EFS) + P(PD_t)_{hcc} \cdot U(t, PD) \right] \cdot \frac{1}{12} \cdot DF(t)$$

The total lifetime QALYs for the cohort is the sum over all cycles, minus the one-time disutility loss:

$$Total\_QALYs = \sum_{t=0}^{1056} QALY\_cycle(t) - Loss_{one-time}$$

## 8. Lifetime Cost Calculation

Lifetime costs are accumulated over $1056$ cycles, discounted at $3.5\%$ annually.
The monthly discount factor is:

$$DF(t) = \frac{1}{(1 + 0.035)^{t/12}}$$

### 8.1 Hospital and Follow-up Costs by Health State
Health state follow-up costs are applied dynamically based on the cycle $t$.

#### 8.1.1 Tisagenlecleucel Follow-up Costs
- **Event-Free Survival (EFS)**:
  $$C_{EFS, Tisa}(t) = \begin{cases} \text{£}472.58 & \text{for } t \le 12 \\ \text{£}111.87 & \text{for } 12 < t \le 24 \\ \text{£}56.18 & \text{for } 24 < t \le 60 \\ \text{£}27.47 & \text{for } t > 60 \end{cases}$$
- **Progressed Disease (PD)**:
  $$C_{PD, Tisa}(t) = \begin{cases} \text{£}191.00 & \text{for } t \le 12 \\ \text{£}263.00 & \text{for } 12 < t \le 60 \\ \text{£}27.47 & \text{for } t > 60 \end{cases}$$

#### 8.1.2 Comparators (Blinatumomab & FLAG-IDA) Follow-up Costs
- **Event-Free Survival (EFS)**:
  $$C_{EFS, Comp}(t) = \begin{cases} \text{£}263.00 & \text{for } t \le 12 \\ \text{£}110.86 & \text{for } 12 < t \le 24 \\ \text{£}55.43 & \text{for } 24 < t \le 60 \\ \text{£}27.47 & \text{for } t > 60 \end{cases}$$
- **Progressed Disease (PD)**:
  $$C_{PD, Comp}(t) = \begin{cases} \text{£}263.00 & \text{for } t \le 60 \\ \text{£}27.47 & \text{for } t > 60 \end{cases}$$

### 8.2 Terminal Care Costs
Terminal care cost ($\text{£}13,198.42$) is applied to patients who die within the first 5 years ($t \le 60$):

$$Proportion\_Dying(t) = S_{OS}(t-1) - S_{OS}(t)$$

- **Comparators**: Terminal care is applied for all deaths where $t \le 60$.
- **Tisagenlecleucel (infused)**: Post-infusion deaths within the first 100 days ($t \le 3$) are excluded (covered by NHS tariff):

  $$TC_{Tisa\_infused}(t) = \begin{cases} 0 & \text{for } t \le 3 \text{ or } t > 60 \\ (S_{OS}(t-1) - S_{OS}(t)) \cdot \text{£}13,198.42 & \text{for } 3 < t \le 60 \end{cases}$$

### 8.3 Total Cohort Cost Formulas

#### 8.1.3 Blinatumomab and FLAG-IDA Cohorts

$$Cost_{Blina} = Acquisition_{Blina} + AE_{Blina} + SCT_{Blina} \cdot C_{SCT} + \sum_{t=1}^{1056} \left[ P(EFS_t)_{hcc} \cdot C_{EFS, Comp}(t) + P(PD_t)_{hcc} \cdot C_{PD, Comp}(t) + TC_{Blina}(t) \right] \cdot DF(t)$$

$$Cost_{Chemo} = Acquisition_{Chemo} + AE_{Chemo} + SCT_{Chemo} \cdot C_{SCT} + \sum_{t=1}^{1056} \left[ P(EFS_t)_{hcc} \cdot C_{EFS, Comp}(t) + P(PD_t)_{hcc} \cdot C_{PD, Comp}(t) + TC_{Chemo}(t) \right] \cdot DF(t)$$

where $C_{SCT} = \text{£}151,227.43$.

#### 8.1.4 Tisagenlecleucel ITT Cohort

$$Cost_{CART\_ITT}(Price) = P_1 \cdot Cost_{infused\_Tisa}(Price) + P_2 \cdot \left( 0.5 \cdot Cost_{Blina} + 0.5 \cdot Cost_{Chemo} + C_{pre\_tx} \right) + P_3 \cdot \left( C_{pre\_tx} + \text{£}13,198.42 \right)$$

where:
- $Cost_{infused\_Tisa}(Price) = Price + Tariff + Bridging + 0.96 \cdot Lymphodepleting + IVIg + SCT_{Tisa} \cdot C_{SCT} + \sum_{t=1}^{1056} \left[ P(EFS_t)_{hcc} \cdot C_{EFS, Tisa}(t) + P(PD_t)_{hcc} \cdot C_{PD, Tisa}(t) + TC_{Tisa\_infused}(t) \right] \cdot DF(t)$
- $C_{pre\_tx} = Leukapheresis + 0.5 \cdot Bridging + 0.5 \cdot Lymphodepleting = \text{£}2,575.70 + 0.5 \cdot \text{£}1,394.57 + 0.5 \cdot \text{£}404.52 = \text{£}3,475.25$.
- $Tariff = \text{£}41,101$.
- $IVIg = \text{£}11,176.85$.

## 9. Incremental Cost-Effectiveness Ratio (ICER)

The ICER compares Tisagenlecleucel to each comparator:

$$ICER = \frac{\Delta Cost}{\Delta QALYs} = \frac{Cost_{CART\_ITT} - Cost_{comparator}}{QALYs_{CART\_ITT} - QALYs_{comparator}}$$

## 10. Patient Access Scheme (PAS) Price Reverse Engineering

The Patient Access Scheme (PAS) price is the discounted price of Tisagenlecleucel that achieves a specific target ICER compared to Blinatumomab:

$$ICER_{Tisa\_vs\_Blina}(Price_{PAS}) = \text{£}19,218$$

We solve for $Price_{PAS}$ using numerical root-finding:

$$f(Price) = ICER_{Tisa\_vs\_Blina}(Price) - 19,218 = 0$$

Using the solved $Price_{PAS}$, we then calculate the discount percentage:

$$Discount\% = 1 - \frac{Price_{PAS}}{List\_Price}$$

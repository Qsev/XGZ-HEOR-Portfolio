# Interactive Budget Impact Model: Version 1 Blueprint

## 1. Version 1 Goal

Version 1 will be a minimal but professional interactive Budget Impact Analysis (BIA) simulator.

The goal is to demonstrate how a simple HEOR budget model can be translated into a payer-facing market access decision-support tool.

The first version should answer one practical question:

> Under different assumptions about eligible population, uptake, net price, treatment duration, and comparator displacement, what is the expected annual and cumulative 5-year budget impact of adopting Drug B?

This is not intended to be a full reimbursement model, a validated Excel workbook, or a cost-effectiveness analysis.

## 2. Recommended File Type

This blueprint is written as a Markdown file because it is a planning and specification document.

The future interactive portfolio page should be written as a Quarto file:

```text
06_Market_Access_Decision_Tools/01_Interactive_Budget_Impact_Model.qmd
```

Reason:

- Markdown is sufficient for project planning, model specification, and page design.
- Quarto is better for the final portfolio page because it can combine narrative text, formulas, HTML, CSS, JavaScript, and rendered outputs.
- The interactive simulator should eventually live inside a Quarto page, but the first step is to keep the model structure clear and auditable.

## 3. Fictional Scenario

Drug B is a fictional biomarker-targeted therapy for relapsed lymphoma.

It enters an NHS treatment pathway where eligible patients are defined through a population funnel:

```text
incident population
-> diagnosed patients
-> biomarker-positive patients
-> patients eligible for the relevant treatment line
-> clinically suitable patients
-> final eligible population
```

All data are simulated. The purpose is to demonstrate model logic and decision-support design, not to represent a real product.

## 4. Intended User

The first version is designed for a non-technical market access audience, such as:

- NHS payer or commissioner
- medicines optimisation lead
- hospital budget holder
- payer-facing market access team
- HEOR consultant preparing an affordability discussion

The interface should therefore prioritise clear assumptions, simple scenario exploration, and practical interpretation.

## 5. Version 1 Scope

Version 1 includes:

- 5-year time horizon
- population funnel
- annual uptake assumptions
- annual list price
- PAS discount
- treatment duration adjustment
- administration cost
- monitoring cost
- adverse event management cost
- comparator annual cost
- comparator displacement percentage
- annual net budget impact
- cumulative 5-year budget impact

Version 1 excludes:

- QALYs
- ICERs
- probabilistic sensitivity analysis
- detailed Markov or partitioned survival model states
- treatment sequencing
- confidential net prices
- capacity modelling
- regional heterogeneity
- Excel upload or export
- backend server

## 6. Core Inputs

### Population Inputs

| Input | Description | Suggested Default |
|---|---|---:|
| Annual incident population | Number of new patients entering the broad disease population each year | 8,000 |
| Diagnosis rate | Proportion diagnosed and captured in the pathway | 90% |
| Biomarker prevalence | Proportion with the relevant biomarker | 30% |
| Treatment-line eligibility | Proportion reaching the relevant line of therapy | 45% |
| Clinical suitability | Proportion clinically suitable for Drug B | 80% |

### Uptake Inputs

| Input | Description | Suggested Default |
|---|---|---:|
| Year 1 uptake | Share of eligible patients receiving Drug B in Year 1 | 10% |
| Year 2 uptake | Share of eligible patients receiving Drug B in Year 2 | 20% |
| Year 3 uptake | Share of eligible patients receiving Drug B in Year 3 | 30% |
| Year 4 uptake | Share of eligible patients receiving Drug B in Year 4 | 40% |
| Year 5 uptake | Share of eligible patients receiving Drug B in Year 5 | 45% |

### Cost Inputs

| Input | Description | Suggested Default |
|---|---|---:|
| Annual list price | Annual acquisition cost per treated patient before discount | GBP 75,000 |
| PAS discount | Patient Access Scheme discount or net price adjustment | 20% |
| Mean treatment duration | Average treatment duration as a share of one full year | 0.75 |
| Administration cost | Administration cost per treated patient per year | GBP 2,500 |
| Monitoring cost | Monitoring cost per treated patient per year | GBP 1,500 |
| Adverse event cost | Expected adverse event management cost per treated patient per year | GBP 2,000 |
| Comparator annual cost | Annual cost of displaced comparator treatment | GBP 25,000 |
| Comparator displacement | Proportion of Drug B use that displaces comparator treatment cost | 80% |

## 7. Core Calculations

### Eligible Patients

```text
eligible_patients =
annual_incident_population
x diagnosis_rate
x biomarker_prevalence
x treatment_line_eligibility
x clinical_suitability
```

### Treated Patients

For each year:

```text
treated_patients_year_t =
eligible_patients
x uptake_year_t
```

### Net Price After PAS

```text
net_annual_price =
annual_list_price
x (1 - PAS_discount)
```

### New Therapy Drug Cost

```text
drug_b_cost_year_t =
treated_patients_year_t
x net_annual_price
x mean_treatment_duration
```

### Other Drug B Related Costs

```text
other_costs_year_t =
treated_patients_year_t
x (administration_cost + monitoring_cost + adverse_event_cost)
```

### Displaced Comparator Cost

```text
displaced_comparator_cost_year_t =
treated_patients_year_t
x comparator_annual_cost
x comparator_displacement
x mean_treatment_duration
```

### Net Annual Budget Impact

```text
net_budget_impact_year_t =
drug_b_cost_year_t
+ other_costs_year_t
- displaced_comparator_cost_year_t
```

### Cumulative Budget Impact

```text
cumulative_budget_impact_year_t =
sum(net_budget_impact_year_1 to net_budget_impact_year_t)
```

## 8. Headline Outputs

The simulator should display the following headline values:

- final eligible patients
- Year 1 treated patients
- net annual price after PAS
- Year 1 net budget impact
- 5-year cumulative budget impact

These headline values should update immediately when inputs change.

## 9. Main Output Table

The year-by-year table should include:

| Column | Description |
|---|---|
| Year | Years 1 to 5 |
| Eligible patients | Final eligible population |
| Uptake | Annual uptake assumption |
| Treated patients | Eligible patients multiplied by uptake |
| Drug B cost | Net drug acquisition cost |
| Other costs | Administration, monitoring, and adverse event costs |
| Displaced comparator cost | Cost offset from displaced comparator use |
| Net budget impact | Incremental annual budget impact |
| Cumulative budget impact | Running 5-year total |

## 10. Visual Outputs

Version 1 should include four visual elements:

### Population Funnel

Shows how the broad incident population narrows to the final eligible population.

Purpose:

- makes the eligible population assumption transparent
- highlights where payer challenge may occur

### Uptake Curve

Shows annual Drug B uptake from Year 1 to Year 5.

Purpose:

- communicates adoption speed
- links uptake assumptions to affordability pressure

### Annual Net Budget Impact Chart

Shows annual net budget impact by year.

Purpose:

- identifies which year creates the largest budget pressure
- separates annual impact from cumulative impact

### Cumulative Budget Impact Chart

Shows cumulative net budget impact over 5 years.

Purpose:

- communicates total financial exposure over the time horizon
- supports payer-facing affordability discussion

## 11. Page Layout

The first interactive page should use a simple dashboard-like structure.

Suggested layout:

```text
Introductory narrative
Budget impact vs cost-effectiveness distinction
Simulated scenario disclosure

Interactive simulator
  - input controls
  - headline results
  - charts
  - year-by-year table

Commercial interpretation
Technical audit notes
Limitations and extensions
```

The simulator should feel like a working decision tool, not a screenshot of an Excel workbook.

## 12. Commercial Interpretation Logic

The page should help the reader understand what the results mean.

Version 1 can include static interpretation prompts rather than fully automated text.

Recommended questions:

- Is budget pressure mainly driven by eligible population, uptake, or net price?
- Does uptake accelerate faster than the payer may be able to absorb?
- How much does the PAS discount reduce the annual budget impact?
- Are comparator cost offsets large enough to materially reduce affordability pressure?
- Which assumptions would a payer or commissioner most likely challenge?

This section is important because the module should demonstrate decision support, not just calculation.

## 13. Suggested Base-Case Interpretation

The base-case scenario should be designed so that the new therapy is not cost-saving overall.

This is more realistic for many oncology therapies.

The expected story should be:

- Drug B creates additional budget pressure because its net acquisition cost is higher than the displaced comparator cost.
- PAS discount reduces but does not eliminate the budget impact.
- Uptake speed is a key driver of the timing of affordability pressure.
- Comparator displacement provides some cost offset, but the offset is not enough to fully neutralise the new therapy cost.
- The main payer questions are likely to focus on eligible population size, uptake assumptions, treatment duration, and net price.

## 14. Minimum Technical Implementation

The future Quarto page should be static and deployable through GitHub Pages.

Recommended implementation:

- Quarto narrative page
- embedded HTML controls
- vanilla JavaScript calculation engine
- lightweight CSS for dashboard layout
- simple SVG or Chart.js charts

Avoid in Version 1:

- Shiny
- backend APIs
- database
- authentication
- complex package dependencies
- Excel import/export

## 15. Acceptance Criteria

Version 1 is successful if:

- all inputs are visible and understandable
- changing inputs updates outputs immediately
- formulas are transparent and easy to audit
- the page clearly distinguishes BIA from cost-effectiveness analysis
- the tool shows annual and cumulative budget impact
- the tool supports at least one clear commercial interpretation
- the page can run as a static GitHub Pages-compatible Quarto output

Version 1 should be deliberately small. Further complexity should be added only after the core decision logic is clear.

# Interactive Budget Impact Model: V1 Wireframe and Sanity Check

## 1. Purpose of This Document

This document translates the Version 1 Blueprint into a practical page structure and checks whether the proposed default assumptions produce plausible results.

It is not the final Quarto page. It is a pre-build planning document used to answer two questions:

1. What should the user see on the first interactive page?
2. Do the base-case inputs generate a credible budget impact story?

## 2. Page Wireframe

The Version 1 page should feel like a working decision-support tool rather than a long technical article.

Suggested structure:

```text
Page title
Interactive Budget Impact Model: Market Access Decision Tool

1. Introduction
   - explain that this is a simulated static BIA tool
   - position it as payer-facing decision support
   - state that it is not a production reimbursement model

2. Budget Impact vs Cost-Effectiveness
   - budget impact: affordability and short-to-medium-term financial exposure
   - cost-effectiveness: value for money, ICERs, QALYs, and long-term outcomes

3. Simulated Scenario
   - fictional biomarker-targeted therapy
   - relapsed lymphoma pathway
   - all data simulated

4. Interactive Simulator
   4.1 Input Panel
       - Population inputs
       - Uptake inputs
       - Cost inputs

   4.2 Headline Results
       - Eligible patients
       - Year 1 treated patients
       - Net annual price after PAS
       - Year 1 net budget impact
       - 5-year cumulative budget impact

   4.3 Visual Outputs
       - Population funnel
       - Uptake curve
       - Annual net budget impact
       - Cumulative budget impact

   4.4 Year-by-Year Results Table
       - Years 1 to 5
       - treated patients
       - costs
       - displaced comparator costs
       - annual and cumulative net budget impact

5. Commercial Interpretation
   - identify the main budget drivers
   - explain how uptake and PAS discount affect affordability
   - identify assumptions likely to be challenged by payers or commissioners

6. Technical Audit Notes
   - visible assumptions
   - transparent formulas
   - static deployment
   - no hidden workbook logic

7. Limitations and Extensions
   - no QALYs or ICERs
   - no probabilistic sensitivity analysis
   - no detailed capacity modelling in V1
   - possible future extensions
```

## 3. Recommended On-Page Layout

The interactive simulator itself should use a compact dashboard layout.

Desktop layout:

```text
+-------------------------------------------------------------+
| Introductory text and simulated scenario disclosure          |
+---------------------------+---------------------------------+
| Input controls            | Headline result cards           |
|                           |                                 |
| Population                | Eligible patients               |
| Uptake                    | Year 1 treated patients         |
| Costs                     | Net price after PAS             |
|                           | Year 1 net budget impact        |
|                           | 5-year cumulative impact        |
+---------------------------+---------------------------------+
| Population funnel chart   | Uptake curve                    |
+---------------------------+---------------------------------+
| Annual budget chart       | Cumulative budget chart         |
+-------------------------------------------------------------+
| Year-by-year table                                          |
+-------------------------------------------------------------+
| Commercial interpretation                                   |
+-------------------------------------------------------------+
```

Mobile layout:

```text
Intro
Input controls
Headline result cards
Population funnel
Uptake curve
Annual budget impact
Cumulative budget impact
Year-by-year table
Commercial interpretation
```

## 4. Default Base-Case Inputs

### Population Inputs

| Input | Default |
|---|---:|
| Annual incident population | 8,000 |
| Diagnosis rate | 90% |
| Biomarker prevalence | 30% |
| Treatment-line eligibility | 45% |
| Clinical suitability | 80% |

### Uptake Inputs

| Year | Uptake |
|---:|---:|
| Year 1 | 10% |
| Year 2 | 20% |
| Year 3 | 30% |
| Year 4 | 40% |
| Year 5 | 45% |

### Cost Inputs

| Input | Default |
|---|---:|
| Annual list price | GBP 75,000 |
| PAS discount | 20% |
| Mean treatment duration | 0.75 years |
| Administration cost | GBP 2,500 |
| Monitoring cost | GBP 1,500 |
| Adverse event cost | GBP 2,000 |
| Comparator annual cost | GBP 25,000 |
| Comparator displacement | 80% |

## 5. Base-Case Calculation

### Eligible Patients

```text
eligible_patients =
8,000 x 90% x 30% x 45% x 80%
= 777.6
```

Rounded for display:

```text
Eligible patients = 778
```

### Net Price After PAS

```text
net_annual_price =
GBP 75,000 x (1 - 20%)
= GBP 60,000
```

## 6. Year-by-Year Sanity Check

| Year | Uptake | Treated Patients | Drug B Cost | Other Costs | Displaced Comparator Cost | Net Budget Impact | Cumulative Budget Impact |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 10% | 77.8 | GBP 3.50m | GBP 0.47m | GBP 1.17m | GBP 2.80m | GBP 2.80m |
| 2 | 20% | 155.5 | GBP 7.00m | GBP 0.93m | GBP 2.33m | GBP 5.60m | GBP 8.40m |
| 3 | 30% | 233.3 | GBP 10.50m | GBP 1.40m | GBP 3.50m | GBP 8.40m | GBP 16.80m |
| 4 | 40% | 311.0 | GBP 14.00m | GBP 1.87m | GBP 4.67m | GBP 11.20m | GBP 27.99m |
| 5 | 45% | 349.9 | GBP 15.75m | GBP 2.10m | GBP 5.25m | GBP 12.60m | GBP 40.59m |

## 7. Sanity Check Interpretation

The default scenario produces:

- final eligible population of approximately 778 patients
- Year 1 treated population of approximately 78 patients
- Year 5 treated population of approximately 350 patients
- Year 1 net budget impact of approximately GBP 2.8m
- 5-year cumulative net budget impact of approximately GBP 40.6m

This is a plausible simulated oncology budget impact story:

- Drug B creates additional budget pressure because its net acquisition cost remains substantially higher than the displaced comparator cost.
- Comparator displacement offsets part of the cost but does not make the therapy cost-saving.
- The PAS discount reduces the net annual price from GBP 75,000 to GBP 60,000.
- Budget impact rises over time because uptake increases from 10% to 45%.
- The model creates a clear payer-facing discussion around uptake speed, eligible population, treatment duration, and net price.

## 8. Why the Base Case Should Not Be Cost-Saving

For the first version, the simulated base case should not show Drug B as cost-saving overall.

Reason:

- many oncology therapies create additional drug budget pressure even when they are clinically valuable
- a non-cost-saving result makes the affordability discussion more realistic
- the tool can then demonstrate how discounts, phased uptake, and comparator displacement reduce but do not eliminate budget impact

This gives the page a more credible market access interpretation than a simple "new therapy saves money" story.

## 9. Possible Payer or Commissioner Challenges

The page should highlight that a payer or commissioner may challenge:

- whether annual incident population is too high
- whether biomarker prevalence is supported by evidence
- whether treatment-line eligibility reflects real clinical pathways
- whether uptake is too optimistic
- whether treatment duration is underestimated
- whether the PAS discount is sufficient
- whether comparator displacement has been overstated

These challenge points are important because they connect the model to real-world market access discussion.

## 10. Design Implications for the Interactive Prototype

The first interactive prototype should:

- keep all inputs visible
- update outputs immediately when a user changes assumptions
- show both annual and cumulative impact
- distinguish gross Drug B cost from net budget impact
- show comparator displacement as a cost offset
- avoid Excel-like visual clutter
- include short interpretation text beneath the dashboard

## 11. Next Build Step

After this sanity check, the next step is to create a draft Quarto prototype in a non-rendered scratch or draft location.

The prototype should implement:

- static narrative text
- input controls
- JavaScript calculation logic
- headline result cards
- four visual outputs
- year-by-year table

Only after the prototype is reviewed should the module be moved into the formal portfolio structure and added to `_quarto.yml`.

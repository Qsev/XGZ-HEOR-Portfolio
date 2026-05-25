# Interactive Budget Impact Model: Concept Note

## Purpose

This project demonstrates how a conventional Budget Impact Analysis (BIA) can be translated into a static, interactive market access decision-support tool.

The purpose is not to replace a fully validated Excel-based budget impact model. Instead, the tool shows how core HEOR model logic can be made transparent, auditable, and accessible for payer-facing or commercial-facing stakeholders.

The simulator focuses on a fictional oncology therapy and estimates the short-to-medium-term affordability impact of adoption over a 5-year horizon.

## Decision Problem

A fictional biomarker-targeted therapy, Drug B, is being introduced into an NHS treatment pathway for relapsed lymphoma.

The key decision question is:

> What is the expected annual and cumulative budget impact of adopting Drug B under different assumptions about eligible population size, uptake, net price, treatment duration, and displaced comparator costs?

This is a budget impact question, not a cost-effectiveness question. The tool does not estimate QALYs, ICERs, or net monetary benefit. Instead, it focuses on affordability, implementation planning, and short-term financial exposure.

## Intended Users

The tool is designed for stakeholders who need to understand the practical resource implications of adopting a new therapy, including:

- NHS medicines optimisation leads
- payer-facing market access teams
- HEOR consultants preparing affordability narratives
- hospital or regional budget holders
- pricing and reimbursement strategy teams

The interface should therefore prioritise interpretability, scenario exploration, and clear commercial implications over methodological complexity.

## Analytical Perspective

The model takes an NHS payer / commissioner perspective.

It estimates direct healthcare costs associated with introducing Drug B into the treatment pathway, including:

- drug acquisition costs
- administration costs
- monitoring costs
- adverse event management costs
- displaced comparator treatment costs

Broader system impacts, such as workforce capacity, diagnostic bottlenecks, clinic slots, infusion capacity, or training requirements, are acknowledged as relevant resource impact considerations but are outside the first version of the simulator.

## Comparison

The model compares two simplified worlds:

- **Current world:** eligible patients receive the existing comparator treatment mix.
- **Future world:** a proportion of eligible patients receive Drug B according to assumed uptake rates over 5 years.

The net budget impact is calculated as the incremental cost of the future world compared with the current world.

Conceptually:

```text
Net budget impact =
Drug B treatment costs
+ administration costs
+ monitoring costs
+ adverse event costs
- displaced comparator costs
```

## Population Funnel

The eligible patient population is estimated using a transparent funnel:

```text
Eligible patients =
incident population
x diagnosis rate
x biomarker prevalence
x treatment-line eligibility
x clinical suitability
```

This structure reflects how market access and HEOR teams often move from broad epidemiology to the reimbursable or treatable population.

The user can adjust each funnel parameter to explore how eligibility assumptions affect budget impact.

## Uptake Assumptions

The model allows the user to specify annual uptake rates for Years 1 to 5.

This reflects the fact that budget impact depends not only on the size of the eligible population, but also on the speed of adoption after launch.

Base-case uptake should be gradual rather than immediate, because real-world adoption may be shaped by:

- local pathway readiness
- clinician familiarity
- formulary access
- diagnostic capacity
- payer restrictions
- commercial access agreements

## Cost Inputs

The first version of the simulator includes the following cost inputs:

- annual list price of Drug B
- patient access scheme (PAS) discount or net price adjustment
- mean treatment duration
- administration cost per treated patient
- monitoring cost per treated patient
- adverse event management cost per treated patient
- annual comparator cost
- comparator displacement percentage

These inputs are deliberately simple. The objective is to make budget logic visible rather than reproduce every detail of a full submission model.

## Outputs

The simulator will report:

- estimated eligible patients
- treated patients by year
- net price after PAS discount
- annual gross Drug B cost
- annual administration, monitoring, and adverse event costs
- annual displaced comparator cost
- annual net budget impact
- cumulative 5-year budget impact

Optional later outputs may include:

- per-member-per-month impact
- local population scaling
- scenario comparison tables
- threshold discount required to meet a target budget impact

## Visualisations

The first version should include:

- a population funnel chart
- an uptake curve
- an annual net budget impact bar chart
- a cumulative budget impact line chart
- a cost component breakdown
- a simple one-way sensitivity chart

The visual design should feel like a working decision tool rather than a static technical article.

## Scenario Analysis

At minimum, the tool should include the following scenarios:

- Base case
- Low uptake
- High uptake
- Higher eligible population
- PAS discount scenario
- Shorter treatment duration
- Higher comparator displacement

The goal of scenario analysis is to show how different commercial or payer assumptions change affordability pressure.

## Commercial Interpretation

The page should translate model outputs into practical market access questions:

- Which assumptions drive most of the budget impact?
- Does rapid uptake create a short-term affordability challenge?
- How much does a PAS discount reduce net budget impact?
- Are comparator cost offsets material or relatively small?
- Would a payer be more likely to challenge population size, uptake, price, or duration?
- Does the scenario suggest the need for phased adoption or additional access management?

This section is essential because the module is intended to demonstrate decision support, not only calculation.

## Technical Positioning

The simulator will be implemented as a static Quarto page using HTML, CSS, and JavaScript.

It should be deployable through GitHub Pages and should not require:

- Shiny server
- Python backend
- database connection
- user authentication
- Excel upload
- confidential pricing data

All assumptions should be visible on the page, and calculations should be reproducible from the displayed inputs.

## Relationship to the Existing Portfolio

This module complements the existing HEOR Technical Portfolio by adding a market access decision-support layer.

Existing modules demonstrate:

- technical evidence generation through NMA, MAIC, STC, ML-NMR, and RWE causal inference
- applied economic modelling through survival extrapolation, partitioned survival modelling, ICERs, and PAS logic

This module demonstrates:

- affordability modelling
- payer-facing scenario analysis
- commercial interpretation of model assumptions
- translation of HEOR logic into an interactive decision tool

It therefore helps bridge technical modelling capability with practical market access application.

## Limitations

This is a simulated proof-of-capability model. It is not a validated reimbursement model and should not be interpreted as advice for a real product.

The first version deliberately excludes:

- QALYs and ICERs
- probabilistic sensitivity analysis
- detailed Markov state transitions
- real-world treatment sequencing
- confidential net prices
- local NHS capacity constraints
- regional uptake heterogeneity
- detailed adverse event profiles

These limitations are intentional. The first version prioritises clarity, transparency, and decision relevance.

## Future Extensions

Potential future extensions include:

- local NHS population scaling
- per-member-per-month outputs
- probabilistic scenario ranges
- launch delay assumptions
- logistic diffusion uptake curves
- regional adoption heterogeneity
- capacity and workforce resource impact
- threshold analysis for discount or uptake constraints
- downloadable scenario summary

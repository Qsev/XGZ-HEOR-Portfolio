# TA1092 NotebookLM Extraction Prompt

Notebook name: `TA1092`

Purpose: use the existing NotebookLM sources for NICE TA1092 to extract the concrete modelling workflow, parameter set, EAG critique, and feasibility issues for an independent Quarto/R case-study replication.

## Source Checklist

Before running the prompt, make sure the notebook contains the most important NICE sources:

- NICE TA1092 recommendations: `https://www.nice.org.uk/guidance/ta1092/chapter/1-Recommendations`
- NICE TA1092 information about pembrolizumab: `https://www.nice.org.uk/guidance/ta1092/chapter/2-Information-about-pembrolizumab`
- NICE TA1092 committee discussion: `https://www.nice.org.uk/guidance/ta1092/chapter/committee-discussion`
- NICE TA1092 evidence page: `https://www.nice.org.uk/guidance/ta1092/evidence`
- Final draft guidance committee papers PDF
- Draft guidance consultation committee papers PDF
- Evaluation report, if available as a separate source
- Resource impact summary report
- Resource impact template, if useful for eligible population and budget impact context

## Main Prompt

You are assisting with an independent HEOR technical portfolio case study based on NICE TA1092: pembrolizumab with carboplatin and paclitaxel for untreated primary advanced or recurrent endometrial cancer.

The output must be detailed enough to support a Quarto/R reconstruction of the model logic. Do not give a high-level summary only. Extract concrete modelling steps, assumptions, parameters, table numbers, section references, and page references wherever available. If a value is confidential, redacted, not reported, or only qualitatively described, state that explicitly.

Structure the answer exactly as follows.

## 1. Case Identification

Extract:

- NICE TA number
- full intervention name
- company
- indication
- marketing authorisation wording
- comparator or comparators
- final recommendation
- stopping rule
- publication date
- whether the decision is for the full population or restricted to subgroups
- all molecular subgroups used in the appraisal, including dMMR/MSI-H and pMMR/MSS terminology

For each item, include the source document and section/page reference.

## 2. Evidence Base

Extract the full clinical evidence package used in the appraisal:

- pivotal trial name
- trial design
- randomisation ratio
- population eligibility
- intervention regimen
- comparator regimen
- treatment duration rules
- endpoints
- follow-up duration and data cut-off dates
- sample sizes overall and by subgroup
- subgroup definitions
- baseline characteristics relevant to economic modelling
- adverse event evidence used in the model
- any indirect comparison, network meta-analysis, or external evidence used

For PFS and OS, extract all reported HRs, confidence intervals, medians, event counts, maturity percentages, Kaplan-Meier comments, and subgroup-specific results.

## 3. Economic Model Overview

Describe the submitted economic model step by step. Include:

- model type
- health states
- cycle length
- time horizon
- discount rates
- half-cycle correction
- perspective
- population split or subgroup structure
- how patients enter the model
- how treatment discontinuation is modelled
- how adverse events enter the model
- how subsequent treatments enter the model
- whether costs and effects are modelled separately for dMMR/MSI-H and pMMR/MSS
- whether the model uses PFS/OS curves directly, transition probabilities, or another structure

Give the modelling sequence as an algorithm that could be implemented in R.

## 4. Survival Modelling: Company Base Case

Extract the company base-case survival modelling in maximum detail:

- PFS source data
- OS source data
- whether survival was modelled by subgroup
- whether independent or jointly fitted models were used
- whether proportional hazards assumptions were tested
- whether treatment-specific curves or hazard ratios were used
- all candidate distributions considered
- all selected base-case distributions
- all selected scenario distributions
- spline models, if used, including scale, number of knots, and knot placement if available
- cure assumptions, if any
- general population mortality adjustment, if any
- restrictions to prevent OS/PFS crossing
- extrapolation time points used for validation
- clinical expert validation comments

Create a table with one row per endpoint, subgroup, treatment arm, and scenario. Columns:

- endpoint
- subgroup
- arm
- model/distribution
- parameter values
- data source
- rationale for selection
- source page/table

## 5. Survival Modelling: EAG Critique and Preferred Assumptions

Extract every EAG criticism of the company's survival modelling. For each issue, include:

- exact modelling issue
- company approach
- EAG concern
- EAG preferred approach
- committee conclusion
- direction of ICER impact
- whether the issue affects dMMR/MSI-H, pMMR/MSS, or both
- why the issue matters for decision-making
- source page/table

Pay special attention to:

- OS extrapolation
- PFS extrapolation
- immature OS
- curve crossing
- spline model choice
- proportional hazards
- treatment effect waning
- waning start and end points
- treatment stopping rule versus persistence of treatment effect
- subgroup heterogeneity
- long-term survival plausibility

## 6. Treatment Effect Waning

Extract all details on treatment effect waning:

- whether the company applied waning
- whether the EAG applied waning
- start time
- end time
- whether waning applies to OS, PFS, or both
- whether waning is applied using HRs, survival blending, hazards, or another method
- rationale used by company
- rationale used by EAG
- committee's preferred assumption
- scenario analyses and ICER impact

Translate the preferred waning method into implementable R pseudocode.

## 7. Treatment Costs and Resource Use

Extract all cost and resource-use parameters:

- pembrolizumab dose and schedule
- carboplatin dose and schedule
- paclitaxel dose and schedule
- maximum pembrolizumab duration
- administration costs
- drug acquisition costs
- vial sharing or wastage assumptions
- body weight or body surface area assumptions
- monitoring costs
- disease management costs by health state
- terminal care costs
- adverse event costs
- subsequent treatment costs
- any confidential discount or commercial arrangement statements

Create a parameter table with:

- parameter name
- value
- unit
- distribution, if PSA parameter
- source
- page/table
- whether public, redacted, or confidential

## 8. Utilities and QALYs

Extract all utility assumptions:

- utility source
- EQ-5D instrument and tariff
- whether utilities are trial-based or literature-based
- health-state utilities
- time-to-death utilities, if used
- progression status utilities, if used
- subgroup-specific utilities
- age adjustment
- adverse event disutilities
- duration of disutilities
- EAG critique
- committee preferred approach

Create a complete utility parameter table with source references.

## 9. Adverse Events

Extract:

- adverse event inclusion threshold
- grade threshold
- AE rates by arm
- AE costs
- AE disutilities
- AE duration
- whether AEs are one-off or recurring
- company approach
- EAG critique
- committee conclusion

## 10. Subsequent Treatments

Extract:

- subsequent treatment types
- proportions by arm and subgroup
- duration assumptions
- costs
- whether subsequent therapy affects OS interpretation
- company assumptions
- EAG concerns
- committee conclusion

## 11. Base-Case and Scenario Results

Extract all reported results:

- company base-case costs, QALYs, incremental costs, incremental QALYs, ICERs
- EAG corrected base case
- EAG preferred base case
- committee preferred ICERs
- subgroup-specific ICERs
- scenario analyses
- deterministic sensitivity analyses
- PSA results
- cost-effectiveness acceptability results
- severity modifier discussion, if any
- threshold range used by committee

If values are redacted or confidential, state the redaction and extract the qualitative conclusion.

## 12. Full Parameter Inventory

Create a consolidated parameter inventory for replication. Use this exact table structure:

| Domain | Parameter | Value | Unit | Arm | Subgroup | Distribution/SE | Source | Page/Table | Public status | Needed for R replication? |
|---|---|---:|---|---|---|---|---|---|---|---|

Domains should include:

- cohort
- model structure
- survival
- treatment duration
- treatment effect waning
- drug costs
- administration costs
- health-state costs
- adverse event costs
- utilities
- adverse event disutilities
- subsequent treatment
- mortality
- discounting
- scenario assumptions

## 13. Reproducible R Implementation Plan

Convert the appraisal into a concrete R build plan. Include:

- required input tables
- required functions
- survival curve generation steps
- PSM state occupancy calculation
- treatment cost calculation
- QALY calculation
- discounting
- ICER calculation
- scenario analysis framework
- curve crossing checks
- treatment effect waning function
- output plots and tables

Write this as step-by-step pseudocode, not general prose.

## 14. Replication Feasibility Assessment

Assess what can and cannot be reproduced from public documents.

Create this table:

| Component | Fully reproducible? | Barrier | Workaround for portfolio case | Importance |
|---|---|---|---|---|

Consider:

- exact survival parameters
- KM digitisation
- confidential prices
- company model workbook
- individual patient data
- covariance/PSA distributions
- subgroup survival models
- subsequent treatment assumptions
- utility estimates
- EAG scenario ICERs

## 15. Recommended Portfolio Strategy

Recommend how to turn this into a polished Quarto case study. Include:

- what to replicate exactly
- what to replicate approximately
- what to discuss qualitatively
- what to avoid because it is too confidential or too complex
- where to place the EAG critique
- which plots to include
- which tables to include
- which R code chunks to build first

The recommendation should be specific to an HEOR consulting portfolio for an academic-to-consulting transition. It should show technical modelling competence, but also demonstrate how an EAG thinks.

## Quality Rules

- Use British English.
- Preserve technical terms such as PSM, OS, PFS, ICER, QALY, EAG, treatment effect waning, spline extrapolation, pMMR/MSS, dMMR/MSI-H.
- Do not invent missing parameter values.
- Distinguish company, EAG, and committee positions clearly.
- Every extracted value must have a source reference.
- If there are multiple committee paper versions, separate draft guidance, final draft guidance, and final guidance positions.
- End with a short list of the top 10 modelling facts that must be checked manually before coding.

## Follow-Up Prompt: Parameter QA

After the main extraction, run this follow-up:

Review your previous answer as if you were the EAG checking a company model. Identify missing parameters, ambiguous values, inconsistent assumptions, and any places where a modeller could accidentally double count costs, apply waning incorrectly, or violate the PSM constraint that OS must be greater than or equal to PFS. Return a QA checklist for the R implementation.

## Follow-Up Prompt: R Skeleton

After parameter QA, run this follow-up:

Using only the public and non-confidential parameters you extracted, draft an R implementation skeleton for the TA1092 case study. Do not attempt exact confidential replication. Include data frame structures, function names, and placeholder fields where values are missing. The skeleton should support company base case, EAG preferred case, and committee preferred case scenarios.

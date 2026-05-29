# TA1092 Parametric Survival Fitting

This folder contains the first-pass parametric survival fitting workflow for the TA1092 case study.

## Input

The script reads:

- `../survival_inputs/survival_ipd_long.csv`

This is reconstructed pseudo-IPD from public KEYNOTE-868 / NRG-GY018 subgroup KM curves.

## Script

- `fit_parametric_survival.R`

The script fits separate intercept-only parametric survival models for each:

- subgroup: `dMMR`, `pMMR`
- endpoint: `PFS`, `OS`
- treatment: `pembro_chemo`, `placebo_chemo`

Candidate distributions:

- exponential
- Weibull
- Gompertz
- log-normal
- log-logistic
- gamma
- generalized gamma

## Outputs

- `parametric_fit_summary.csv`: AIC/BIC/log-likelihood for all candidate fits.
- `top3_fit_summary_by_curve.csv`: top 3 distributions by AIC for each curve.
- `parametric_fit_parameters.csv`: fitted distribution parameters.
- `best_fit_extrapolated_survival.csv`: AIC-selected extrapolated survival curves to 360 months.
- `plots/*_best_fit_diagnostic.png`: reconstructed KM plus AIC-selected extrapolation to 120 months.

## Interpretation Caveat

This is a first-pass technical fit. AIC selection is not the final model choice.

For an HTA/EAG-style review, the next step is to assess whether the extrapolated tails are clinically plausible and whether curve choices align with NICE/EAG assumptions. This is especially important for immature OS curves, where small event counts can make long-term extrapolation unstable.

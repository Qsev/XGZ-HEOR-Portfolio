# TA1092 Survival Input Dataset

This folder contains analysis-ready pseudo-IPD survival inputs for the TA1092 pembrolizumab + chemotherapy case study.

## Main file

- `survival_ipd_long.csv`: combined long-format dataset for R survival fitting.

## Endpoint-specific files

- `dMMR_PFS_pseudo_ipd.csv`
- `pMMR_PFS_pseudo_ipd.csv`
- `dMMR_OS_pseudo_ipd.csv`
- `pMMR_OS_pseudo_ipd.csv`

## Key fields

- `subgroup`: `dMMR` or `pMMR`
- `endpoint`: `PFS` or `OS`
- `treatment`: `pembro_chemo` or `placebo_chemo`
- `time_months`: reconstructed event/censor time in months
- `status`: `1` event, `0` censored
- `reconstruction_method`: PFS uses event-drop cleaning; OS uses censor-informed reconstruction from risk table + cumulative censored values.

## Caveat

These are reconstructed pseudo-IPD datasets from public KM curves, not original trial IPD. Subgroup OS is based on interim supplementary OS figures and may not match the later NICE model data cut.

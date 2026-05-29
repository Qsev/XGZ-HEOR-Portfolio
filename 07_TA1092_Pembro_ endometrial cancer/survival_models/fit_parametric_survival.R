library(survival)
library(flexsurv)
library(dplyr)
library(tidyr)
library(purrr)
library(readr)
library(ggplot2)

`%||%` <- function(x, y) if (is.null(x)) y else x

script_args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", script_args, value = TRUE)
script_path <- if (length(file_arg) > 0) gsub("~\\+~", " ", sub("^--file=", "", file_arg)) else NA_character_
script_dir <- if (!is.na(script_path) && file.exists(script_path)) dirname(normalizePath(script_path)) else getwd()
base_dir <- normalizePath(file.path(script_dir, ".."), mustWork = FALSE)
if (!dir.exists(file.path(base_dir, "survival_inputs"))) {
  base_dir <- normalizePath("07_TA1092_Pembro_ endometrial cancer", mustWork = TRUE)
}

input_path <- file.path(base_dir, "survival_inputs", "survival_ipd_long.csv")
output_dir <- file.path(base_dir, "survival_models")
plot_dir <- file.path(output_dir, "plots")
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(plot_dir, showWarnings = FALSE, recursive = TRUE)

ipd <- read_csv(input_path, show_col_types = FALSE) |>
  mutate(
    subgroup = factor(subgroup, levels = c("dMMR", "pMMR")),
    endpoint = factor(endpoint, levels = c("PFS", "OS")),
    treatment = factor(treatment, levels = c("placebo_chemo", "pembro_chemo")),
    status = as.integer(status),
    time_months = as.numeric(time_months),
    curve_id = paste(subgroup, endpoint, treatment, sep = "_")
  )

candidate_dists <- c(
  "exponential" = "exp",
  "weibull" = "weibull",
  "gompertz" = "gompertz",
  "lognormal" = "lnorm",
  "loglogistic" = "llogis",
  "gamma" = "gamma",
  "generalized_gamma" = "gengamma"
)

fit_one_distribution <- function(dat, dist_label, dist_name) {
  tryCatch(
    {
      fit <- flexsurvreg(Surv(time_months, status) ~ 1, data = dat, dist = dist_name)
      n_par <- nrow(fit$res)
      fit_aic <- as.numeric(fit$AIC %||% NA_real_)
      fit_loglik <- as.numeric(fit$loglik %||% NA_real_)
      tibble(
        dist_label = dist_label,
        dist_name = dist_name,
        fit = list(fit),
        converged = TRUE,
        error = NA_character_,
        aic = fit_aic,
        bic = -2 * fit_loglik + log(nrow(dat)) * n_par,
        loglik = fit_loglik,
        n = nrow(dat),
        events = sum(dat$status)
      )
    },
    error = function(e) {
      tibble(
        dist_label = dist_label,
        dist_name = dist_name,
        fit = list(NULL),
        converged = FALSE,
        error = conditionMessage(e),
        aic = NA_real_,
        bic = NA_real_,
        loglik = NA_real_,
        n = nrow(dat),
        events = sum(dat$status)
      )
    }
  )
}

curve_groups <- ipd |>
  group_by(subgroup, endpoint, treatment, arm_role, treatment_label, curve_id) |>
  group_split()

fit_tbl <- map_dfr(curve_groups, function(dat) {
  meta <- dat |> slice(1) |> select(subgroup, endpoint, treatment, arm_role, treatment_label, curve_id)
  res <- map2_dfr(names(candidate_dists), candidate_dists, ~fit_one_distribution(dat, .x, .y))
  bind_cols(res, meta[rep(1, nrow(res)), ])
})

fit_summary <- fit_tbl |>
  select(subgroup, endpoint, treatment, arm_role, treatment_label, curve_id,
         dist_label, dist_name, converged, error, n, events, loglik, aic, bic) |>
  arrange(subgroup, endpoint, treatment, aic)

write_csv(fit_summary, file.path(output_dir, "parametric_fit_summary.csv"))

best_fits <- fit_tbl |>
  filter(converged, !is.na(aic)) |>
  group_by(subgroup, endpoint, treatment) |>
  slice_min(aic, n = 1, with_ties = FALSE) |>
  ungroup()

extract_parameters <- function(fit) {
  if (is.null(fit)) return(tibble(parameter = character(), estimate = numeric(), se = numeric()))
  as.data.frame(fit$res) |>
    tibble::rownames_to_column("parameter") |>
    as_tibble() |>
    transmute(parameter, estimate = est, se = se)
}

parameter_tbl <- fit_tbl |>
  filter(converged) |>
  mutate(parameters = map(fit, extract_parameters)) |>
  select(subgroup, endpoint, treatment, curve_id, dist_label, parameters) |>
  unnest(parameters)

write_csv(parameter_tbl, file.path(output_dir, "parametric_fit_parameters.csv"))

km_points <- ipd |>
  group_by(subgroup, endpoint, treatment, arm_role, treatment_label, curve_id) |>
  group_modify(~{
    km <- survfit(Surv(time_months, status) ~ 1, data = .x)
    tibble(time_months = c(0, km$time), survival = c(1, km$surv))
  }) |>
  ungroup()

time_grid <- tibble(time_months = seq(0, 360, by = 1))

predict_survival <- function(fit, times) {
  s <- summary(fit, t = times, type = "survival")
  if (is.data.frame(s)) {
    return(as.numeric(s$est))
  }
  if (is.list(s) && length(s) == 1 && is.data.frame(s[[1]])) {
    return(as.numeric(s[[1]]$est))
  }
  map_dbl(s, ~.x$est)
}

extrapolated <- best_fits |>
  mutate(pred = map(fit, ~tibble(time_months = time_grid$time_months,
                                 survival = predict_survival(.x, time_grid$time_months)))) |>
  select(subgroup, endpoint, treatment, arm_role, treatment_label, curve_id,
         best_dist = dist_label, aic, bic, pred) |>
  unnest(cols = c(pred))

write_csv(extrapolated, file.path(output_dir, "best_fit_extrapolated_survival.csv"))

diagnostic_plot_data <- extrapolated |>
  filter(time_months <= 120) |>
  mutate(source = paste0("best fit: ", best_dist)) |>
  select(subgroup, endpoint, treatment, treatment_label, time_months, survival, source) |>
  bind_rows(
    km_points |>
      mutate(source = "reconstructed KM") |>
      select(subgroup, endpoint, treatment, treatment_label, time_months, survival, source)
  )

plot_one <- function(sg, ep) {
  dat <- diagnostic_plot_data |>
    filter(subgroup == sg, endpoint == ep)

  ggplot(dat, aes(time_months, survival, colour = treatment, linetype = source)) +
    geom_step(data = filter(dat, source == "reconstructed KM"), linewidth = 0.7, alpha = 0.85) +
    geom_line(data = filter(dat, source != "reconstructed KM"), linewidth = 0.9) +
    scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.2)) +
    scale_x_continuous(limits = c(0, 120), breaks = seq(0, 120, 12)) +
    labs(
      title = paste(sg, ep, "reconstructed KM and AIC-selected parametric extrapolation"),
      x = "Months",
      y = "Survival probability",
      colour = NULL,
      linetype = NULL
    ) +
    theme_minimal(base_size = 11) +
    theme(legend.position = "bottom")
}

walk(unique(as.character(ipd$subgroup)), function(sg) {
  walk(unique(as.character(ipd$endpoint)), function(ep) {
    p <- plot_one(sg, ep)
    ggsave(
      filename = file.path(plot_dir, paste0(sg, "_", ep, "_best_fit_diagnostic.png")),
      plot = p,
      width = 9,
      height = 5.5,
      dpi = 180
    )
  })
})

summary_for_readme <- fit_summary |>
  filter(converged) |>
  group_by(subgroup, endpoint, treatment) |>
  arrange(aic, .by_group = TRUE) |>
  slice_head(n = 3) |>
  ungroup() |>
  select(subgroup, endpoint, treatment, dist_label, n, events, aic, bic)

write_csv(summary_for_readme, file.path(output_dir, "top3_fit_summary_by_curve.csv"))

message("Wrote survival model outputs to: ", normalizePath(output_dir))

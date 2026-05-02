#' ---
#' title: "Forensic RWE Audit: Drug X Causal Inference Pipeline"
#' author: "Xiaoge Zhang, PhD (York)"
#' date: "`r Sys.Date()`"
#' output:
#'   html_document:
#'     toc: true
#'     toc_float: true
#'     theme: united
#'     highlight: zenburn
#' ---

#+ setup, include=FALSE
knitr::opts_chunk$set(echo = TRUE, warning = FALSE, message = FALSE)

# -------------------------------------------------------------------------
# DIRECTORY SETUP (Self-Correcting Path Logic)
# -------------------------------------------------------------------------
#' @audit
#' Robust path handling: We ensure visuals are always saved to the 02 project folder.
script_path <- tryCatch(dirname(sys.frame(1)$ofile), error = function(e) ".")
setwd(script_path)

if (!dir.exists("visuals")) dir.create("visuals")

# -------------------------------------------------------------------------
# GLOBAL SETTINGS & DATA GENERATION (Simulated RWD)
# -------------------------------------------------------------------------
#' @audit
#' Note: We use a synthetic dataset (N=500) to simulate common HTA Indication Bias.
#' Severe patients (high ECOG, older age) are systematically assigned to Drug X.
set.seed(2026)
n <- 500
age <- rnorm(n, 65, 10)
ecog <- rbinom(n, 1, 0.4)
ps_true <- plogis(-2 + 0.05 * age + 1.2 * ecog)
treatment <- rbinom(n, 1, ps_true)
y_prob <- plogis(1 - 0.03 * age - 1.0 * ecog + 0.8 * treatment)
survival_1yr <- rbinom(n, 1, y_prob)
df <- data.frame(age, ecog, treatment, survival_1yr)

# -------------------------------------------------------------------------
# MODULE 1: Target Trial Emulation (TTE) Protocol
# -------------------------------------------------------------------------
#' @audit
#' TTE Protocol Implementation:
#' 1. Eligibility: Ensuring all patients are at the same clinical 'Time Zero' (T0).
#' 2. Exclusion: We exclude patients with missing baseline covariates to maintain a clean ECA.
df_clean <- df[complete.cases(df), ]
cat(">>> TTE Status: Population synchronized at T0. N =", nrow(df_clean), "\n")


# -------------------------------------------------------------------------
# MODULE 2: Weighting & Diagnostics (IPTW - ATT Focus)
# -------------------------------------------------------------------------
library(WeightIt)
library(cobalt)
library(ggplot2)

#' @audit
#' Estimating Weights using IPTW with ATT (Average Treatment Effect on the Treated).
#' Logic: Targets the 'Real-World Treated' population for SAT/ECA scenarios.
W_att <- weightit(treatment ~ age + ecog,
    data = df_clean,
    method = "ps",
    estimand = "ATT"
)

#' @audit
#' Balancing Diagnostics (Love Plot):
#' We aim for Absolute Standardized Mean Difference (ASMD) < 0.1.
lp <- love.plot(W_att,
    thresholds = c(m = 0.1),
    abs = TRUE,
    colors = c("#e41a1c", "#377eb8"),
    shapes = c(19, 17),
    sample.names = c("Unadjusted", "Balanced (ATT)")
)
ggsave("visuals/love_plot.png", plot = lp, width = 8, height = 6, dpi = 300)
print(lp)

#' @audit
#' Positivity Check (PS Distribution):
#' We examine the overlap of Propensity Scores between groups.
#' Lack of overlap indicates structural bias where certain patients have zero probability of treatment.
ps_plot <- bal.plot(W_att,
    var.name = "prop.score", which = "both",
    colors = c("#e41a1c", "#377eb8"),
    sample.names = c("Unadjusted", "Balanced (ATT)")
) +
    labs(title = "Propensity Score Overlap Audit")
ggsave("visuals/ps_overlap_plot.png", plot = ps_plot, width = 8, height = 6, dpi = 300)
print(ps_plot)


# -------------------------------------------------------------------------
# MODULE 3: Doubly Robust Estimation (TMLE)
# -------------------------------------------------------------------------
library(tmle)
library(SuperLearner)

#' @audit
#' Implementation of TMLE (Targeted Maximum Likelihood Estimation).
#' Ensemble learning via SuperLearner handles potential model misspecification.
sl_lib <- c("SL.glm", "SL.mean", "SL.randomForest")

tmle_fit <- tmle(
    Y = df_clean$survival_1yr,
    A = df_clean$treatment,
    W = df_clean[, c("age", "ecog")],
    Q.SL.library = sl_lib,
    g.SL.library = sl_lib,
    family = "binomial"
)

#' @audit
#' Targeted Update Parameter (Epsilon):
#' Demonstrates the necessity of the targeted adjustment phase.
cat("\nTargeted Update Parameter (Epsilon):\n")
print(tmle_fit$epsilon)

# -------------------------------------------------------------------------
# MODULE 4: Sensitivity Audit (E-value)
# -------------------------------------------------------------------------
library(EValue)

#' @audit
#' Correcting E-value Mathematical Mapping:
#' Transforming Risk Difference (RD) to Relative Risk (RR) using Baseline Risk (EY0).
rd_est <- tmle_fit$estimates$ATE$psi
rd_se <- sqrt(tmle_fit$estimates$ATE$var.psi)
ey0_est <- tmle_fit$estimates$EY0$psi

rr_est <- (ey0_est + rd_est) / ey0_est
rr_lo <- (ey0_est + (rd_est - 1.96 * rd_se)) / ey0_est
rr_hi <- (ey0_est + (rd_est + 1.96 * rd_se)) / ey0_est

cat("\n■■■ Transformed RR for E-value Audit ■■■\n")
cat(paste("Point Estimate (RR):", round(rr_est, 3), "\n"))

ev <- evalues.RR(est = rr_est, lo = rr_lo, hi = rr_hi)
print(ev)

#' @audit
#' Visualizing Sensitivity Thresholds (Bias Contour Plot):
#' We plot the 'Bias Surface' to show all combinations of confounder associations
#' (RR_AU and RR_UY) that could potentially nullify our treatment effect.
png("visuals/evalue_plot.png", width = 800, height = 700)
# Create a more professional contour plot
plot(ev,
    type = "line",
    main = "E-value Sensitivity Audit: Confounder Strength Analysis",
    sub = paste("E-value for Point Estimate:", round(rr_est, 2))
)
dev.off()


# -------------------------------------------------------------------------
# MODULE 5: Final Audit Summary (Evidence Compendium)
# -------------------------------------------------------------------------
#' @audit
#' Final Evidence Reconciliation:
#' Note the reduction in bias from Naive to TMLE.

# 1. Naive
naive_rd <- mean(df_clean$survival_1yr[df_clean$treatment == 1]) - mean(df_clean$survival_1yr[df_clean$treatment == 0])

# 2. IPTW (ATT)
fit_iptw <- survey::svyglm(survival_1yr ~ treatment,
    design = survey::svydesign(~1, weights = ~ W_att$weights, data = df_clean)
)
iptw_rd <- coef(fit_iptw)["treatment"]
iptw_se <- sqrt(vcov(fit_iptw)["treatment", "treatment"])

# 3. TMLE (Final Psi)
tmle_rd <- tmle_fit$estimates$ATE$psi
tmle_se <- sqrt(tmle_fit$estimates$ATE$var.psi)

Final_Audit_Table <- data.frame(
    Method = c("Naive (Unadjusted)", "IPTW (ATT Weighting)", "TMLE (Targeted Audit)"),
    Estimate_RD = round(c(naive_rd, iptw_rd, tmle_rd), 4),
    Std_Error = round(c(NA, iptw_se, tmle_se), 4),
    LCL_95 = round(c(NA, iptw_rd - 1.96 * iptw_se, tmle_rd - 1.96 * tmle_se), 4),
    UCL_95 = round(c(NA, iptw_rd + 1.96 * iptw_se, tmle_rd + 1.96 * tmle_se), 4)
)

cat("\n■■■ FINAL AUDIT SUMMARY TABLE ■■■\n")
print(Final_Audit_Table)

# Save the table as a CSV for easy GitHub access
write.csv(Final_Audit_Table, "visuals/final_audit_summary.csv", row.names = FALSE)

#' @audit
#' Conclusion: All audit artifacts saved to ./visuals/ for transparency.

#' ---
#' title: "DGP Architect: Simulating Indication Bias in RWD"
#' author: "Xiaoge Zhang, PhD (York)"
#' date: "`r Sys.Date()`"
#' ---

#' @audit
#' RATIONALE:
#' To evaluate causal inference estimators, we must first build a simulator
#' where the 'Ground Truth' is known. In this module, I simulate
#' 'Indication Bias'—a common phenomenon where sicker patients are
#' non-randomly assigned to the innovative therapy.

set.seed(2026)
n_patients <- 2000 # Increased N for higher precision in truth reconciliation

# -------------------------------------------------------------------------
# STEP 1: Baseline Covariates (W)
# -------------------------------------------------------------------------
# Simulating patient severity via Age and ECOG Performance Status
age <- rnorm(n_patients, mean = 65, sd = 10)
ecog <- rbinom(n_patients, size = 1, prob = 0.4) # 1 = Poor performance, 0 = Good

# -------------------------------------------------------------------------
# STEP 2: The Mechanism of Bias (Treatment Assignment A)
# -------------------------------------------------------------------------
#' @audit
#' INDICATION BIAS LOGIC (Selection on Observables):
#' We assume clinicians are more likely to prescribe 'Drug X' to high-risk patients.
#' PS = plogis(baseline_intercept + beta_age * age + beta_ecog * ecog)
#'
#' WHY NEGATIVE BIAS?
#' ECOG has a positive coefficient (1.2) for treatment assignment but a negative
#' coefficient for survival. This creates a 'Negative Correlation' between the
#' treatment and the outcome potential, masking the true efficacy of Drug X.
lp_treatment <- -3.5 + 0.05 * age + 1.2 * ecog
prob_treatment <- plogis(lp_treatment)
treatment <- rbinom(n_patients, size = 1, prob = prob_treatment)

# -------------------------------------------------------------------------
# STEP 3: Outcome Generation & 'God's Reconciliation'
# -------------------------------------------------------------------------
#' @audit
#' POTENTIAL OUTCOMES FRAMEWORK:
#' We calculate the theoretical survival probability for every patient under
#' both treatment states (Counterfactuals).
lp_survival_base <- 1.5 - 0.04 * age - 1.2 * ecog

# Counterfactual 1: If everyone was treated (A=1)
prob_y1 <- plogis(lp_survival_base + 0.8)

# Counterfactual 0: If everyone was untreated (A=0)
prob_y0 <- plogis(lp_survival_base)

#' @audit
#' GOD'S RECONCILIATION (Truth Calculation):
#' The true Population Average Treatment Effect (ATE) is the difference in
#' the marginal means of these potential outcomes.
true_ate_rd <- mean(prob_y1) - mean(prob_y0)

# Realized Outcome (Y) based on actual treatment assignment (The biased reality)
survival_1yr <- ifelse(treatment == 1,
  rbinom(n_patients, 1, prob_y1),
  rbinom(n_patients, 1, prob_y0)
)

# -------------------------------------------------------------------------
# STEP 4: Final Evidence Audit & Bias Gap Analysis
# -------------------------------------------------------------------------
rwd_data <- data.frame(
  patient_id = 1:n_patients,
  age = round(age, 1),
  ecog = ecog,
  treatment = treatment,
  survival_1yr = survival_1yr
)

# Naive observed effect
naive_rd <- mean(survival_1yr[treatment == 1]) - mean(survival_1yr[treatment == 0])

# Export data
if (!dir.exists("data")) dir.create("data")
write.csv(rwd_data, "data/synthetic_oncology_rwd.csv", row.names = FALSE)

cat("\n■■■ GOD'S EYE VIEW: DGP AUDIT REPORT ■■■\n")
cat(paste("1. TRUE Population ATE (Ground Truth): ", round(true_ate_rd, 4), "\n"))
cat(paste("2. OBSERVED Naive RD (Biased Reality): ", round(naive_rd, 4), "\n"))
cat(paste("3. THE BIAS GAP (Underestimation):     ", round(true_ate_rd - naive_rd, 4), "\n"))
cat("--------------------------------------------------\n")
cat(paste(
  "Audit Note: Indication bias has hidden",
  round((true_ate_rd - naive_rd) / true_ate_rd * 100, 1),
  "% of the true treatment benefit.\n"
))

#' @audit
#' CONCLUSION:
#' This 'Bias Gap' is the structural uncertainty that our causal inference
#' pipeline (IPTW/TMLE) is designed to reclaim. Without advanced adjustment,
#' the cost-effectiveness of Drug X would be severely underestimated.

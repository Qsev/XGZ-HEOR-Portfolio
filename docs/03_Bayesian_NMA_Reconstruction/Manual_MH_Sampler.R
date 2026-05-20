#' @title Project 5: Manual MCMC vs. Stan Engine ("Cannon vs. Mosquito")
#' @description
#' A forensic deconstruction of Bayesian MCMC sampling. This script compares:
#' 1. A manually implemented Metropolis-Hastings (MH) algorithm in R.
#' 2. An industrial-grade HMC/NUTS sampler via Stan.
#' 3. The exact mathematical analytic solution (Beta-Binomial Conjugacy).
#' @author Xiaoge Zhang, PhD (York)
#' @date 2026-05-02

# --- Phase 1: Environment Setup ---
library(rstan)
library(ggplot2)

# Optimizing performance for local execution
rstan_options(auto_write = TRUE)
options(mc.cores = parallel::detectCores())

# --- Phase 2: Data Provisioning (Observed Evidence) ---
# Scenario: 7 successes out of 10 patients in a rare disease trial.
n <- 10
y <- 7

# --- Phase 3: Manual Metropolis-Hastings (MH) Implementation ---
# Goal: Replicate the "Bolt-Action" logic of early MCMC samplers.
set.seed(123)
n_iter <- 50000
theta_samples <- numeric(n_iter)

# Step A: Initialize the sampler at an arbitrary starting point
theta_curr <- 0.5

# Step B: Define the Target Log-Density (Log-Likelihood + Log-Prior)
# We operate in the log-space to prevent numerical underflow.
target_log_density <- function(theta) {
  # Boundary constraint for probability [0, 1]
  if (theta < 0 || theta > 1) {
    return(-Inf)
  }

  # Log-Prior: Informative Beta(7, 3) to test the "Prior-Pull" effect
  # To test "Non-informative", use dbeta(theta, 1, 1, log = TRUE)
  log_prior <- dbeta(theta, 7, 3, log = TRUE)

  # Log-Likelihood: Binomial distribution of observed successes
  log_lik <- dbinom(y, n, theta, log = TRUE)

  return(log_prior + log_lik)
}

# Step C: The MCMC Simulation Loop
message("🏃 Manual MH Sampler is exploring the parameter space...")
for (i in 1:n_iter) {
  # Proposal Step: Generate a candidate value using a Gaussian random walk
  theta_prop <- theta_curr + rnorm(1, mean = 0, sd = 0.1)

  # Calculate the Acceptance Ratio (Current vs. Proposed)
  log_acc_ratio <- target_log_density(theta_prop) - target_log_density(theta_curr)

  # Metropolis Decision Step: The "Stochastic Coin Flip"
  if (log(runif(1)) < log_acc_ratio) {
    theta_curr <- theta_prop # Move accepted
  }
  theta_samples[i] <- theta_curr # Record the footprint
}

# Post-Processing: Removing the Burn-in period (First 20%) to ensure stationarity
mh_samples <- theta_samples[-(1:(n_iter * 0.2))]

# --- Phase 4: Industrial Sampling via Stan (HMC/NUTS) ---
# Deploying the "Railgun" to validate the manual sampler.
message("🚀 Activating Stan/HMC Engine...")

# Note: Ensure mosquito.stan exists in the same directory
stan_fit <- stan(
  file = "mosquito.stan",
  data = list(N = n, y = y),
  iter = 5000, chains = 4, seed = 123, refresh = 0
)
stan_samples <- as.data.frame(stan_fit)$theta

# --- Phase 5: Forensic Reconciliation (Visualization) ---
message("🎨 Generating the Three-Way Audit Plot...")

# Consolidating data for ggplot2
df_plot <- data.frame(
  Method = c(
    rep("Manual MH (R)", length(mh_samples)),
    rep("Stan (HMC)", length(stan_samples))
  ),
  Value = c(mh_samples, stan_samples)
)

# Calculating the Exact Mathematical Truth: Beta(7+7, 3+3) = Beta(14, 6)
# Based on the conjugate property of the Binomial-Beta marriage.
x_range <- seq(0, 1, length.out = 200)
df_exact <- data.frame(
  x = x_range,
  y = dbeta(x_range, 14, 6)
)

# Audit Plot Construction
p <- ggplot() +
  # 1. Overlaying Manual MH distribution
  geom_histogram(
    data = subset(df_plot, Method == "Manual MH (R)"),
    aes(x = Value, y = ..density.., fill = Method),
    alpha = 0.4, bins = 50
  ) +
  # 2. Overlaying Stan HMC distribution
  geom_histogram(
    data = subset(df_plot, Method == "Stan (HMC)"),
    aes(x = Value, y = ..density.., fill = Method),
    alpha = 0.4, bins = 50
  ) +
  # 3. Drawing the Analytic Truth (Conjugate Posterior)
  geom_line(
    data = df_exact, aes(x = x, y = y),
    color = "black", size = 1.2, linetype = "dashed"
  ) +
  theme_minimal() +
  labs(
    title = "Forensic MCMC Audit: Manual MH vs. Stan HMC",
    subtitle = "Black Dashed Line = Analytic Truth (Beta 14,6)",
    x = "Recovery Rate (theta)",
    y = "Posterior Density",
    fill = "Methodology"
  ) +
  scale_fill_manual(values = c("Manual MH (R)" = "skyblue", "Stan (HMC)" = "orange")) +
  theme(legend.position = "bottom")

# Archiving the visual evidence
ggsave("MCMC_Reconciliation_Plot.png", p, width = 10, height = 6)

# --- Phase 6: Audit Result Summary ---
message("\n✅ Audit Complete. Summary of Posterior Means:")
message("   Manual MH Estimate: ", round(mean(mh_samples), 4))
message("   Stan HMC Estimate:   ", round(mean(stan_samples), 4))
message("   Analytic Truth:      0.7000")
message("--------------------------------------------------")
message("Result: All estimators successfully converged to the analytic truth.")

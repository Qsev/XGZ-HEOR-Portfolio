library(rjags)
options(width = 300)

# Prepare the data
data_list <- list(
    r = matrix(c(20, 40, 10, 30, 15, 20), nrow = 3, byrow = TRUE),
    n = matrix(c(100, 100, 100, 100, 100, 100), nrow = 3, byrow = TRUE)
)

# Initialize the model
jags_model <- jags.model(
    file = "/Users/xiaogezhang/AntigravityLocal/CareerShowcaseGithub/HEOR-Technical-Portfolio/scratch/CareerTransferZXG/08_Practice_Drafts/05_NMA_Technical_Prep/nma_model.txt",
    data = data_list,
    n.chains = 3,
    n.adapt = 1000
)

# Sample from the posterior
samples <- coda.samples(
    model = jags_model,
    variable.names = c("d_AB", "d_AC", "OR_AB", "OR_AC", "OR_BC"),
    n.iter = 10000
)

summary(samples)
print(summary(samples))
capture.output(summary(samples), file = "/Users/xiaogezhang/AntigravityLocal/CareerShowcaseGithub/HEOR-Technical-Portfolio/scratch/CareerTransferZXG/08_Practice_Drafts/05_NMA_Technical_Prep/jags_output.txt")


library(rstan)

# Prepare data
stan_data <- list(
    J = 3,
    r = matrix(c(20, 40, 10, 30, 15, 20), nrow = 3, byrow = TRUE),
    n = matrix(c(100, 100, 100, 100, 100, 100), nrow = 3, byrow = TRUE)
)

# Run the model
fit <- stan(
    file = "/Users/xiaogezhang/AntigravityLocal/CareerShowcaseGithub/HEOR-Technical-Portfolio/scratch/CareerTransferZXG/08_Practice_Drafts/05_NMA_Technical_Prep/nma_model.stan", # Assumes the Stan code above is saved in this file
    data = stan_data,
    chains = 3,
    iter = 2000,
    warmup = 1000
)

# Extract results
print(fit, pars = c("d_AB", "d_AC", "OR_AB", "OR_AC", "OR_BC"))

# Save output to text file
capture.output(print(fit), file = "/Users/xiaogezhang/AntigravityLocal/CareerShowcaseGithub/HEOR-Technical-Portfolio/scratch/CareerTransferZXG/08_Practice_Drafts/05_NMA_Technical_Prep/stan_output.txt")
# , pars = c("d_AB", "d_AC", "OR_AB", "OR_AC", "OR_BC")

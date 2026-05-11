data {
  int<lower=1> N;                // Total number of individual patients
  int<lower=0,upper=1> y[N];     // Binary outcome (1 = Response, 0 = No Response)
  int<lower=1> NS;               // Number of studies
  int<lower=1> study[N];         // Study ID for each patient
  int<lower=1> NT;               // Number of treatments
  int<lower=1> trt[N];           // Treatment ID for each patient
  vector[N] x;                   // Patient-level covariate (e.g., Baseline Severity)
}

transformed data {
  // Center covariate within each study to avoid ecological bias
  vector[N] x_centered;
  for (j in 1:NS) {
    real sum_x = 0;
    int n_j = 0;
    for (i in 1:N) {
      if (study[i] == j) {
        sum_x += x[i];
        n_j += 1;
      }
    }
    real mean_x_j = sum_x / n_j;
    for (i in 1:N) {
      if (study[i] == j) {
        x_centered[i] = x[i] - mean_x_j;
      }
    }
  }
}

parameters {
  vector[NS] mu;                 // Study-specific baselines (fixed effects for simplicity)
  vector[NT-1] delta_raw;        // Treatment effects for trt 2, 3, ..., NT
  real beta;                     // Prognostic effect of the covariate
}

transformed parameters {
  vector[NT] delta;              // Full treatment effect vector including reference
  delta[1] = 0.0;                // Reference treatment (Placebo) fixed to 0
  for (k in 2:NT) {
    delta[k] = delta_raw[k-1];
  }
}

model {
  // Priors
  mu ~ normal(0, 5);             // Weakly informative prior for baselines
  delta_raw ~ normal(0, 5);      // Weakly informative prior for relative effects
  beta ~ normal(0, 5);           // Weakly informative prior for covariate effect

  // Likelihood (One-Stage Hierarchical Logistic Regression)
  vector[N] logit_p;
  for (i in 1:N) {
    logit_p[i] = mu[study[i]] + delta[trt[i]] + beta * x_centered[i];
  }
  y ~ bernoulli_logit(logit_p);
}

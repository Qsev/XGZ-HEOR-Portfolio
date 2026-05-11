data {
  int<lower=1> J; // Number of studies
  int r[J, 2];    // Events
  int n[J, 2];    // Total patients
}

parameters {
  real mu[J];     // Study baselines
  real d_AB;      // Effect of B vs A
  real d_AC;      // Effect of C vs A
}

transformed parameters {
  real delta[J, 2];
  
  // Study 1: A vs B
  delta[1, 1] = 0;
  delta[1, 2] = d_AB;
  
  // Study 2: A vs C
  delta[2, 1] = 0;
  delta[2, 2] = d_AC;
  
  // Study 3: B vs C
  delta[3, 1] = 0;
  delta[3, 2] = d_AC - d_AB; // Consistency constraint
}

model {
  // Priors (Stan uses standard deviation, so 100 means variance 10000)
  mu ~ normal(0, 100);
  d_AB ~ normal(0, 100);
  d_AC ~ normal(0, 100);
  
  // Likelihood
  for (j in 1:J) {
    for (k in 1:2) {
      r[j, k] ~ binomial_logit(n[j, k], mu[j] + delta[j, k]);
    }
  }
}

generated quantities {
  real OR_AB = exp(d_AB);
  real OR_AC = exp(d_AC);
  real OR_BC = exp(d_AC - d_AB);
}
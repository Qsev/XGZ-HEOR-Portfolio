data {
  int<lower=1> NS; // Number of studies
  int<lower=1> NT; // Number of treatments
  int r[NS, 2];    // Responders
  int n[NS, 2];    // Sample size
  int t[NS, 2];    // Treatment index for each arm
  real cov1[NS];   // Covariate 1
  real cov2[NS];   // Covariate 2
}

transformed data {
  real mean_cov1 = mean(cov1);
  real mean_cov2 = mean(cov2);
}

parameters {
  real mu[NS];          
  real d[NT];           // Global treatment effects
  real<lower=0> tau;    // Between-study heterogeneity
  real z[NS, 2];        // Standard normal noise for non-centered RE
  real beta1;
  real beta2;
  real omega;           // Inconsistency parameter for Study 4 (B vs C)
}

transformed parameters {
  real theta[NS, 2];
  for (j in 1:NS) {
    theta[j, 1] = 0;
    for (k in 2:2) {
      // Add inconsistency parameter omega to Study 4 (B vs C)
      real inc = (j == 4) ? omega : 0.0;
      theta[j, k] = (d[t[j, k]] - d[t[j, 1]]) + inc + tau * z[j, k];
    }
  }
}

model {
  // Priors
  mu ~ normal(0, 100);
  for (k in 2:NT) {
    d[k] ~ normal(0, 100);
  }
  d[1] ~ normal(0, 0.001); // Fix reference to 0
  
  tau ~ uniform(0, 5);
  beta1 ~ normal(0, 100);
  beta2 ~ normal(0, 100);
  omega ~ normal(0, 100); // Prior for inconsistency
  
  for (j in 1:NS) {
    for (k in 2:2) {
      z[j, k] ~ std_normal(); // Draw noise
    }
  }

  // Likelihood
  for (j in 1:NS) {
    for (k in 1:2) {
      real is_active = (t[j, k] != t[j, 1]) ? 1.0 : 0.0;
      real linpred = mu[j] + theta[j, k] + 
                     beta1 * (cov1[j] - mean_cov1) * is_active + 
                     beta2 * (cov2[j] - mean_cov2) * is_active;
      r[j, k] ~ binomial_logit(n[j, k], linpred);
    }
  }
}

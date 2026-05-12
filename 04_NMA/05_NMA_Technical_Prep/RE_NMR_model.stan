data {
  int<lower=1> NS; // <lower=1> is a constraint (data check): must be >= 1
  int<lower=1> NT; // <lower=1> is a constraint (data check): must be >= 1
  int r[NS, 2];    
  int n[NS, 2];    
  int t[NS, 2];    // Treatment index for each arm
  real cov1[NS];
  real cov2[NS];
}

transformed data {
  real mean_cov1 = mean(cov1);
  real mean_cov2 = mean(cov2);
}

parameters {
  real mu[NS];          
  real d[NT];           // Global treatment effects
  real<lower=0> tau;    // <lower=0> constraint stops sampler from guessing invalid negative SD
  real z[NS, 2];        // Standard normal noise for non-centered RE
  real beta1;
  real beta2;
}

transformed parameters {
  real theta[NS, 2];
  for (j in 1:NS) {
    theta[j, 1] = 0;
    for (k in 2:2) {
      // Non-centered parameterization: mean + sd * standard_normal
      theta[j, k] = (d[t[j, k]] - d[t[j, 1]]) + tau * z[j, k];
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
  
  for (j in 1:NS) {
    for (k in 2:2) {
      z[j, k] ~ std_normal(); // Draw noise
    }
  }

  // Likelihood
  for (j in 1:NS) {
    for (k in 1:2) {
      // Ternary operator (三元运算符): 表达式 ? 真值 : 假值。
      // 如果是治疗组则为 1.0，对照组则为 0.0。是 if-else 的简写。
      real is_active = (t[j, k] != t[j, 1]) ? 1.0 : 0.0;
      real linpred = mu[j] + theta[j, k] + 
                     beta1 * (cov1[j] - mean_cov1) * is_active + 
                     beta2 * (cov2[j] - mean_cov2) * is_active;
      r[j, k] ~ binomial_logit(n[j, k], linpred);
    }
  }
}

// Random effects model for the Blocker example, following NICE DSU TSD 2 Program 1(c)
data {
  int<lower=1> S;                        // number of trials
  array[S] int<lower=0> n_C;             // patients, control arm
  array[S] int<lower=0> r_C;             // deaths, control arm
  array[S] int<lower=0> n_T;             // patients, beta-blocker arm
  array[S] int<lower=0> r_T;             // deaths, beta-blocker arm
}

parameters {
  vector[S] mu;                          // trial baselines, log odds of death on control
  real d;                                // mean log OR, beta-blocker vs control
  real<lower=0, upper=5> sigma;          // between-trial SD; TSD 2: Uniform(0, 5)
  vector[S] z;                           // standardised trial deviations
}

transformed parameters {
  vector[S] delta = d + sigma * z;       // trial-specific log OR (non-centred)
}

model {
  mu ~ normal(0, 100);                   // TSD 2: vague N(0, 100^2)
  d ~ normal(0, 100);
  z ~ std_normal();                      // implies delta ~ normal(d, sigma)

  r_C ~ binomial_logit(n_C, mu);
  r_T ~ binomial_logit(n_T, mu + delta);
}

generated quantities {
  real OR = exp(d);
  real OR_new = exp(normal_rng(d, sigma)); // OR in a new trial setting
  vector[S] fit_C;                       // expected deaths, control arm
  vector[S] fit_T;                       // expected deaths, treatment arm
  real dev = 0;                          // residual deviance, this draw

  for (i in 1:S) {
    fit_C[i] = n_C[i] * inv_logit(mu[i]);
    fit_T[i] = n_T[i] * inv_logit(mu[i] + delta[i]);
    dev += 2 * (r_C[i] * log(r_C[i] / fit_C[i])
                + (n_C[i] - r_C[i]) * log((n_C[i] - r_C[i]) / (n_C[i] - fit_C[i])));
    dev += 2 * (r_T[i] * log(r_T[i] / fit_T[i])
                + (n_T[i] - r_T[i]) * log((n_T[i] - r_T[i]) / (n_T[i] - fit_T[i])));
  }
}

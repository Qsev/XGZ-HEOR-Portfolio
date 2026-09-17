data {
  int<lower=1> S;                        // number of studies
  array[S] int<lower=0> n_A;             // patients on A
  array[S] int<lower=0> r_A;             // responders on A
  array[S] int<lower=0> n_B;             // patients on B
  array[S] int<lower=0> r_B;             // responders on B
}

parameters {
  vector[S] mu;                          // baseline log odds on A, one per study
  real d;                                // pooled log OR, B vs A
  real<lower=0> tau;                     // between-study SD of the log OR
  vector[S] z;                           // standardised study-level deviations
}

transformed parameters {
  vector[S] delta = d + tau * z;         // study-specific log OR (non-centred)
}

model {
  mu ~ normal(0, 10);
  d ~ normal(0, 10);
  tau ~ normal(0, 1);                    // half-normal, since tau >= 0
  z ~ std_normal();

  r_A ~ binomial_logit(n_A, mu);
  r_B ~ binomial_logit(n_B, mu + delta);
}

generated quantities {
  real OR = exp(d);                      // pooled OR
  real OR_new = exp(normal_rng(d, tau)); // OR in a new study setting
}

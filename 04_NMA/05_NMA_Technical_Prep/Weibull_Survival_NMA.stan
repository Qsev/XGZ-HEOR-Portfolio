data {
  int<lower=1> N;
  int<lower=1> NS;
  int<lower=1> NT;
  real time[N];
  int event[N];
  int study[N];
  int treatment[N];
}
parameters {
  real mu[NS];
  real d[NT];
  real<lower=0> shape;
}
transformed parameters {
  real log_scale[N];
  for (i in 1:N) {
    log_scale[i] = mu[study[i]] + d[treatment[i]];
  }
}
model {
  mu ~ normal(0, 5);
  d[1] ~ normal(0, 0.001);
  d[2] ~ normal(0, 5);
  d[3] ~ normal(0, 5);
  shape ~ exponential(1);

  for (i in 1:N) {
    real lambda = exp(log_scale[i]);
    if (event[i] == 1) {
      target += log_scale[i] + log(shape) + (shape - 1) * log(time[i]) - lambda * pow(time[i], shape);
    } else {
      target += - lambda * pow(time[i], shape);
    }
  }
}

data {
  int<lower=1> NS;
  real y[NS];
  real<lower=0> se[NS];
  int t1[NS];
  int t2[NS];
}
parameters {
  real d[3]; // 3 treatments
}
model {
  d[1] ~ normal(0, 0.001); // Reference
  d[2] ~ normal(0, 5);
  d[3] ~ normal(0, 5);
  
  for (i in 1:NS) {
    y[i] ~ normal(d[t2[i]] - d[t1[i]], se[i]);
  }
}

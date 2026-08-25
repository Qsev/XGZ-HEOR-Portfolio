// ===========================================================================
// multinomial_nma_fe.stan
//
// 台阶 2:固定效应多项式 NMA —— 论文实际跑的那个模型,移植到 Stan。
//
// 和台阶 1 的差别只有一处:每个臂不再是「CR / 非CR」两格,
// 而是「CR / PR / <PR」三格。于是
//     d 从 vector[nt] 变成 matrix[nt, 2]     每个治疗两个参数,对应 k=2,3
//     mu 从 vector[ns] 变成 matrix[ns, 2]    每个试验两个基线
// 结构完全不变,还是 mu[study] + d[trt] - d[base]。
//
// WinBUGS 原文(Appendix A):
//     r[i,j,1:ne] ~ dmulti(p[i,j,1:ne], n[i,j])
//     log(lambda[i,j,k]) <- a[i,k] + d[Tx[i,j],k] - d[Tx[i,1],k]
//     p[i,j,k] <- lambda[i,j,k]/(1+slam[i,j])
//     p[i,j,1] <- 1-sum(p[i,j,2:ne])
//
// 那四行在 Stan 里就是一个 softmax:参照类别 CR 的 logit 钉成 0,
// 另外两个类别的 logit 是 a + d 差。softmax 会自己归一化。
//     softmax([0, e2, e3])[1] = 1/(1+exp(e2)+exp(e3))   ← 正是 p[i,j,1]
//     softmax([0, e2, e3])[k] = exp(ek)/(1+...)         ← 正是 p[i,j,k]
// ===========================================================================

data {
  int<lower=1> ns;                              // 试验数 = 17
  int<lower=1> nt;                              // 治疗数 = 16
  int<lower=1> na;                              // 臂数   = 34
  int<lower=1> ns_ref;                          // 含参照治疗的试验数 = 6

  array[na] int<lower=1> study;
  array[na] int<lower=1> trt;
  array[na] int<lower=1> base;
  array[na, 3] int<lower=0> r;                  // 每臂三格:CR / PR / <PR

  real<lower=0> prior_sd_mu;
  real<lower=0> prior_sd_d;
}

parameters {
  matrix[ns, 2] mu;                             // 每个试验两个基线(k=2,3)
  matrix[nt - 1, 2] d_free;                     // 除参照外每个治疗两个效应
}

transformed parameters {
  // 参照治疗两个类别的效应都钉死为 0
  matrix[nt, 2] d = append_row(rep_row_vector(0.0, 2), d_free);
}

model {
  // ---- TODO ------------------------------------------------------------
  // 三段,和台阶 1 一一对应。
  //
  // 1) 先验。mu 和 d_free 现在是矩阵,不是向量。Stan 里给矩阵整体加先验
  //    要先摊平:  to_vector(mu) ~ normal(0, prior_sd_mu);
  to_vector(mu) ~ normal(0, prior_sd_mu);
  to_vector(d_free) ~ normal(0, prior_sd_d);
  // 2) 每个臂的两个 logit(k=2,3):
  //        eta[k-1] = mu[study[i], k-1] + d[trt[i], k-1] - d[base[i], k-1]
  //    写成一行:  row_vector[2] eta = mu[study[i]] + d[trt[i]] - d[base[i]];
  //    (矩阵按行取出来是 row_vector,直接相加减就行)
  for (i in 1:na) {
  row_vector[2] eta = mu[study[i]] + d[trt[i]] - d[base[i]];
  r[i] ~ multinomial_logit(append_row(0.0, eta'));
  }
  // 3) 似然。参照类别 CR 的 logit 是 0,接在前面凑成长度 3 的向量:
  //        r[i] ~ multinomial_logit(append_row(0.0, eta'));
  //    注意 eta 是 row_vector,append_row 要 vector —— 加个撇号 ' 转置。
  //for (i in 1:na) {
  //    r[i] ~ multinomial_logit(append_row(0.0, eta'));
  //}
  //    这次没法向量化,要写 for 循环:  for (i in 1:na) { ... }
  //    因为 multinomial_logit 一次只吃一个臂。
  // ----------------------------------------------------------------------

}

generated quantities {
  // 照抄 WinBUGS 的 a_av / p_av / p_or / rk 段落。
  row_vector[2] a_av;
  for (k in 1:2) a_av[k] = mean(mu[1:ns_ref, k]);

  matrix[nt, 3] p_av;                           // 每个治疗三个类别的绝对概率
  vector[nt] crr;                               // 完全缓解率      = p_av[,1]
  vector[nt] orr;                               // 客观缓解率 CR+PR = p_av[,1]+p_av[,2]
  for (t in 1:nt) {
    vector[3] logits = append_row(0.0, (a_av + d[t])');
    p_av[t] = softmax(logits)';
    crr[t] = p_av[t, 1];
    orr[t] = p_av[t, 1] + p_av[t, 2];
  }

  // 名次与最优概率,CRR 和 ORR 各一套 —— 论文的卖点就是这两套会不一样
  array[nt] int rk_crr;
  array[nt] int rk_orr;
  array[nt] int best_crr;
  array[nt] int best_orr;
  for (t in 1:nt) {
    int b1 = 0;
    int b2 = 0;
    for (s in 1:nt) {
      if (crr[s] > crr[t]) b1 += 1;
      if (orr[s] > orr[t]) b2 += 1;
    }
    rk_crr[t] = b1 + 1;
    rk_orr[t] = b2 + 1;
    best_crr[t] = (rk_crr[t] == 1);
    best_orr[t] = (rk_orr[t] == 1);
  }
}

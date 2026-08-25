// ===========================================================================
// binomial_nma_fe.stan
//
// 固定效应二分类 Bayesian NMA —— 结局是完全缓解(CR)。
// 这是 van Beurden-Tan 2022 那个多项式模型的「一个类别」版本:
// 把 WinBUGS 代码里的 k = 2,3 两个类别砍成一个,其余结构原样保留。
//
// Stan 文件分块,每块回答一个问题:
//   data                 我要喂进去什么?
//   parameters           要估的未知数是哪些?
//   transformed parameters   由未知数直接算出来的中间量
//   model                数据和参数怎么连起来?(似然 + 先验)
//   generated quantities 抽完样之后想顺便算什么?
// ===========================================================================

data {
  int<lower=1> ns;                              // 试验数 = 17
  int<lower=1> nt;                              // 治疗数 = 16
  int<lower=1> na;                              // 臂数   = 34
  int<lower=1> ns_ref;                          // 含参照治疗的试验数 = 6

  array[na] int<lower=1> study;                 // 每个臂属于哪个试验
  array[na] int<lower=1> trt;                   // 这个臂用的是哪个治疗
  array[na] int<lower=1> base;                  // 该试验的基线治疗(arm 1 的治疗)
  array[na] int<lower=0> r;                     // 达到 CR 的人数
  array[na] int<lower=1> n;                     // 该臂的 ITT 人数

  // 先验宽度从外面传进来,这样换先验不用改模型、不用重编译。
  // 先验是建模决定,不是技术细节 —— 放在 data 块里,它就必须被显式声明。
  real<lower=0> prior_sd_mu;
  real<lower=0> prior_sd_d;
}

parameters {
  vector[ns] mu;                                // 每个试验自己的基线 log-odds
  vector[nt - 1] d_free;                        // 除参照外每个治疗的效应
}

transformed parameters {
  // 参照治疗的效应钉死为 0 —— 这是定标,不是假设。
  // append_row 把标量 0 接在 d_free 前面,凑成长度 nt 的向量。
  vector[nt] d = append_row(0.0, d_free);
}

model {
  // 先验。注意 WinBUGS 的 dnorm(0, .001) 第二个参数是**精度**(1/方差),
  // Stan 的 normal() 第二个参数是**标准差** —— 同一个符号,含义不同。
  mu     ~ normal(0, prior_sd_mu);
  d_free ~ normal(0, prior_sd_d);

  // 似然:  r[i] ~ Binomial(n[i], p[i]),  logit(p[i]) = mu[study] + d[trt] - d[base]
  // binomial_logit 直接吃 logit 尺度的参数,内部做 inv_logit,比手写更稳;
  // 而且是向量化的,34 个臂一次算完,不用 for 循环。
  r ~ binomial_logit(n, mu[study] + d[trt] - d[base]);
}

generated quantities {
  // 这一块我写好了 —— 它把 d(相对效应)变成绝对 CR 率,再算排名。
  // 做法照抄 WinBUGS 的 a_av / p_av / rk 那几段。

  // 参照治疗的合并基线 = 含参照治疗的那 ns_ref 个试验的基线平均。
  // 数据是按试验排好序的,前 ns_ref 个就是含 Dex 的那些。
  real a_av = mean(mu[1:ns_ref]);

  // 每个治疗的绝对 CR 率
  vector[nt] p_av;
  for (t in 1:nt) p_av[t] = inv_logit(a_av + d[t]);

  // 名次:CR 率最高的排第 1
  array[nt] int rk;
  for (t in 1:nt) {
    int better = 0;
    for (s in 1:nt) if (p_av[s] > p_av[t]) better += 1;
    rk[t] = better + 1;
  }

  // 每一次抽样里,治疗 t 是不是第一名 —— 对所有抽样取平均就是「最优概率」
  array[nt] int is_best;
  for (t in 1:nt) is_best[t] = (rk[t] == 1);
}

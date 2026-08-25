# ===========================================================================
# 07_jags_original.R  ·  用论文自己的代码、先验、init 和迭代设定跑一遍
#
# 运行:  Rscript R/07_jags_original.R
#
# 目的只有一个:排除「是我移植错了」。
# 模型逐行照抄 Appendix A 的 WinBUGS 代码,先验 dnorm(0,.001) 原样保留,
# 3 条链 · 25000 burn-in · 80000 迭代,和论文 Methods 写的一致。
# JAGS 与 WinBUGS 同属 BUGS 家族,都用 Gibbs 类采样,是最接近的可得替代。
#
# 两处偏离,都不影响后验:
#   1. 去掉 deviance 那几行 —— 纯派生量,且 r=0 时 log(r/rhat) 会产生 NaN
#   2. 排名不在 JAGS 里算 —— WinBUGS 的 rank(v,k) 与 JAGS 的 rank(v) 语义不同,
#      改在 R 里从抽样算,结果相同
# ===========================================================================

root <- "."
suppressPackageStartupMessages(library(rjags))

node <- c("Dex", "Bor/BorDex", "LenDex", "PomDex", "PomBorDex", "CarLenDex",
          "EloLenDex", "IxaLenDex", "CarDex", "PanoBorDex", "Thal/ThalDex",
          "BorThalDex", "DaraBorDex", "DaraLenDex", "OblDex", "PLDBor")

model_code <- "
model{
  for(i in 1:ns){
    for(k in 2:ne){ a[i,k] ~ dnorm(0, .001) }
    for(j in 1:2){
      r[i,j,1:ne] ~ dmulti(p[i,j,1:ne], n[i,j])
      p[i,j,1] <- 1 - sum(p[i,j,2:ne])
      slam[i,j] <- sum(lambda[i,j,2:ne])
      for(k in 2:ne){
        p[i,j,k] <- lambda[i,j,k] / (1 + slam[i,j])
        log(lambda[i,j,k]) <- a[i,k] + d[Tx[i,j],k] - d[Tx[i,1],k]
      }
    }
  }
  for(k in 2:ne){
    d[1,k] <- 0
    for(t in 2:nt){ d[t,k] ~ dnorm(0, .001) }
  }
  for(k in 2:ne){ a_av[k] <- mean(a[1:ns1,k]) }
  p_av[1,1] <- 1/(1 + exp(a_av[2]) + exp(a_av[3]))
  for(k in 2:ne){ p_av[1,k] <- p_av[1,1] * exp(a_av[k]) }
  for(t in 2:nt){
    p_av[t,1] <- 1/(1 + exp(a_av[2] + d[t,2]) + exp(a_av[3] + d[t,3]))
    for(k in 2:ne){ p_av[t,k] <- p_av[t,1] * exp(a_av[k] + d[t,k]) }
  }
}
"

# --- 数据:含参照治疗的 6 个试验排前面,对应 WinBUGS 的 ns1 = 6 --------------
arms <- read.csv(file.path(root, "data", "rrmm_arms_indexed.csv"), stringsAsFactors = FALSE)
has_ref   <- tapply(arms$tx_index, arms$trial, function(x) 1 %in% x)
ref_first <- c(names(has_ref)[has_ref], names(has_ref)[!has_ref])
arms$study <- match(arms$trial, ref_first)
arms <- arms[order(arms$study, arms$arm), ]

ns <- length(ref_first); nt <- 16; ne <- 3
r <- array(NA_integer_, c(ns, 2, ne)); n <- matrix(NA_integer_, ns, 2)
Tx <- matrix(NA_integer_, ns, 2)
for (i in seq_len(nrow(arms))) {
  s <- arms$study[i]; j <- arms$arm[i]
  r[s, j, ] <- c(arms$cr_group[i], arms$pr_group[i], arms$lt_pr_group[i])
  n[s, j] <- arms$n_itt[i]; Tx[s, j] <- arms$tx_index[i]
}
stopifnot(all(apply(r, c(1, 2), sum) == n))

jags_data <- list(ns = ns, nt = nt, ne = ne, ns1 = sum(has_ref),
                  r = r, n = n, Tx = Tx)

# Appendix A 的 init:所有自由参数为 0,受约束的位置留 NA
a_init <- matrix(0, ns, ne); a_init[, 1] <- NA
d_init <- matrix(0, nt, ne); d_init[, 1] <- NA; d_init[1, ] <- NA
inits <- lapply(1:3, function(ch) list(a = a_init, d = d_init))

cat(sprintf("%d 试验 · %d 治疗 · ns1 = %d (%s)\n",
            ns, nt, jags_data$ns1, paste(ref_first[1:jags_data$ns1], collapse = ", ")))
cat("先验 dnorm(0, .001) · 3 链 · burn-in 25000 · 迭代 80000  —— 与论文 Methods 一致\n\n")

set.seed(20260825)
m <- jags.model(textConnection(model_code), data = jags_data, inits = inits,
                n.chains = 3, n.adapt = 1000, quiet = TRUE)
update(m, 25000)                                    # burn-in
# thin = 10 只为控制内存,不改变后验
s <- coda.samples(m, c("p_av", "d", "a_av"), n.iter = 80000, thin = 10)

# --- 结果 ------------------------------------------------------------------
mat <- as.matrix(s)
crr_cols <- paste0("p_av[", 1:nt, ",1]")
crr <- mat[, crr_cols]
colnames(crr) <- node

pub <- read.csv(file.path(root, "data", "published_fig2_crr.csv"), stringsAsFactors = FALSE)
ours <- data.frame(treatment = node,
                   crr = 100 * colMeans(crr),
                   lo  = 100 * apply(crr, 2, quantile, .025),
                   hi  = 100 * apply(crr, 2, quantile, .975),
                   stringsAsFactors = FALSE)
cmp <- merge(ours, pub, by = "treatment"); cmp <- cmp[order(cmp$rank), ]

cat("JAGS 跑论文原始代码 vs 论文 Figure 2\n\n")
print(data.frame(rank = cmp$rank, treatment = cmp$treatment,
                 jags  = sprintf("%5.1f [%4.1f,%5.1f]", cmp$crr, cmp$lo, cmp$hi),
                 paper = sprintf("%5.1f [%4.1f,%5.1f]", cmp$crr_pct, cmp$crr_lo_pct, cmp$crr_hi_pct),
                 diff  = sprintf("%+6.1f pp", cmp$crr - cmp$crr_pct)), row.names = FALSE)

# 收敛诊断:论文报的就是这个(BGR = Gelman-Rubin)
gd <- gelman.diag(s[, crr_cols], multivariate = FALSE)$psrf
cat(sprintf("\nGelman-Rubin(论文报的 BGR):最大 point est. %.3f · 最大上界 %.3f\n",
            max(gd[, 1]), max(gd[, 2])))
cat("论文只看这个图,判定「收敛」。\n")

# 基线跑没跑掉
a_av <- mat[, c("a_av[2]", "a_av[3]")]
cat(sprintf("\na_av[2] 后验均值 %.2f (sd %.2f) · a_av[3] %.2f (sd %.2f)\n",
            mean(a_av[, 1]), sd(a_av[, 1]), mean(a_av[, 2]), sd(a_av[, 2])))

saveRDS(s, file.path(root, "data", "jags_original_samples.rds"))
write.csv(ours, file.path(root, "data", "jags_original_crr.csv"), row.names = FALSE)
cat("\n结果已存:data/jags_original_crr.csv\n")

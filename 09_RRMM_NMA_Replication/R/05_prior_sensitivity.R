# ===========================================================================
# 05_prior_sensitivity.R  ·  换先验,看结论动不动
#
# 运行:  Rscript R/05_prior_sensitivity.R
#
# 04 证明了 vague 先验下有两个治疗的后验就是先验。这里把先验收窄,
# 看三件事:
#   1. 后验收缩是否回来了
#   2. 绝对 CR 率是否还塌
#   3. **排序会不会因此改变** —— 如果会,那排序本身就不是数据说的
# ===========================================================================

root <- "."
suppressPackageStartupMessages(library(rstan))
options(mc.cores = min(4, parallel::detectCores()))
rstan_options(auto_write = TRUE)

node <- c("Dex", "Bor/BorDex", "LenDex", "PomDex", "PomBorDex", "CarLenDex",
          "EloLenDex", "IxaLenDex", "CarDex", "PanoBorDex", "Thal/ThalDex",
          "BorThalDex", "DaraBorDex", "DaraLenDex", "OblDex", "PLDBor")

# --- 数据准备(和 03 相同) ------------------------------------------------
arms <- read.csv(file.path(root, "data", "rrmm_arms_indexed.csv"),
                 stringsAsFactors = FALSE)
has_ref   <- tapply(arms$tx_index, arms$trial, function(x) 1 %in% x)
ref_first <- c(names(has_ref)[has_ref], names(has_ref)[!has_ref])
arms$study <- match(arms$trial, ref_first)
arms <- arms[order(arms$study, arms$arm), ]
base_of <- tapply(arms$tx_index[arms$arm == 1], arms$study[arms$arm == 1], identity)
arms$base <- as.integer(base_of[as.character(arms$study)])

base_data <- list(ns = length(unique(arms$study)), nt = 16, na = nrow(arms),
                  ns_ref = sum(has_ref), study = arms$study, trt = arms$tx_index,
                  base = arms$base, r = arms$cr_group, n = arms$n_itt)

# --- 三套先验 --------------------------------------------------------------
# vague  : 论文 WinBUGS 的设定,换算成标准差
# weak   : 弱信息。d ~ N(0, 2.5) 把 95% 的先验质量放在 OR 约 [0.007, 134],
#          仍然比这批数据里见过的最大 OR(MM-009 的 18.5)宽得多,不是在压数据
# tight  : 更紧,用来看结论对先验有多敏感
settings <- list(
  vague = c(mu = 100, d = 100),
  weak  = c(mu =   5, d = 2.5),
  tight = c(mu =   3, d = 1.0))

fits <- list()
for (nm in names(settings)) {
  s <- settings[[nm]]
  cat(sprintf("\n=== %s: mu ~ N(0,%g), d ~ N(0,%g) ===\n", nm, s["mu"], s["d"]))
  fits[[nm]] <- stan(file = file.path(root, "stan", "binomial_nma_fe.stan"),
                     data = c(base_data, list(prior_sd_mu = unname(s["mu"]),
                                              prior_sd_d  = unname(s["d"]))),
                     chains = 4, iter = 6000, warmup = 2000,
                     seed = 20260825, refresh = 0)
  f <- fits[[nm]]
  sm  <- summary(f, pars = c("mu", "d", "p_av"))$summary
  div <- sum(sapply(get_sampler_params(f, inc_warmup = FALSE),
                    function(x) sum(x[, "divergent__"])))
  dr <- rstan::extract(f)
  contraction <- 1 - apply(dr$d, 2, sd) / unname(s["d"])
  cat(sprintf("Rhat %.3f · n_eff %.0f · 发散点 %3d · 最低收缩 %.3f (%s) · 参照 CR 率 %.2f%%\n",
              max(sm[, "Rhat"], na.rm = TRUE), min(sm[, "n_eff"], na.rm = TRUE), div,
              min(contraction[-1]), node[-1][which.min(contraction[-1])],
              100 * plogis(mean(dr$a_av))))
}

# --- 三套先验下的绝对率与排名 ---------------------------------------------
summarise <- function(f) {
  dr <- rstan::extract(f)
  data.frame(treatment = node,
             crr  = 100 * apply(dr$p_av, 2, mean),
             lo   = 100 * apply(dr$p_av, 2, quantile, .025),
             hi   = 100 * apply(dr$p_av, 2, quantile, .975),
             best = 100 * colMeans(dr$is_best),
             rank = 100 * colMeans(dr$rk == 1) * 0 + apply(dr$rk, 2, median),
             stringsAsFactors = FALSE)
}
res <- lapply(fits, summarise)
pub <- read.csv(file.path(root, "data", "published_fig2_crr.csv"), stringsAsFactors = FALSE)

out <- data.frame(treatment = node, stringsAsFactors = FALSE)
for (nm in names(res)) {
  out[[paste0(nm, "_crr")]]  <- sprintf("%5.1f [%4.1f,%5.1f]", res[[nm]]$crr, res[[nm]]$lo, res[[nm]]$hi)
  out[[paste0(nm, "_best")]] <- sprintf("%5.1f%%", res[[nm]]$best)
}
out <- merge(out, pub[, c("treatment", "crr_pct", "crr_lo_pct", "crr_hi_pct")], by = "treatment")
out$paper <- sprintf("%5.1f [%4.1f,%5.1f]", out$crr_pct, out$crr_lo_pct, out$crr_hi_pct)
out <- out[order(-res$weak$crr[match(out$treatment, node)]), ]

cat("\n\n绝对 CR 率 %，按 weak 先验的点估计排序\n\n")
print(out[, c("treatment", "vague_crr", "weak_crr", "tight_crr", "paper")], row.names = FALSE)
cat("\n\n最优概率 —— 先验一换,谁是第一就变了吗?\n\n")
print(out[, c("treatment", "vague_best", "weak_best", "tight_best")], row.names = FALSE)

saveRDS(fits, file.path(root, "data", "fits_prior_sensitivity.rds"))
write.csv(out, file.path(root, "data", "prior_sensitivity.csv"), row.names = FALSE)
cat("\n结果已存:data/prior_sensitivity.csv\n")

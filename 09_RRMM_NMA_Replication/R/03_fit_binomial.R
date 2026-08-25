# ===========================================================================
# 03_fit_binomial.R  ·  跑台阶 1 的二分类 NMA,并对靶
#
# 运行:  Rscript R/03_fit_binomial.R
#
# 这个脚本我写完了 —— 这一轮要你写的是 stan/binomial_nma_fe.stan 的
# model 块。这里只负责:准备数据 → 交给 Stan → 把结果和靶子对上。
# ===========================================================================

root <- "."
suppressPackageStartupMessages({ library(rstan) })
options(mc.cores = min(4, parallel::detectCores()))
rstan_options(auto_write = TRUE)

arms <- read.csv(file.path(root, "data", "rrmm_arms_indexed.csv"),
                 stringsAsFactors = FALSE)
node_name <- c("Dex", "Bor/BorDex", "LenDex", "PomDex", "PomBorDex",
               "CarLenDex", "EloLenDex", "IxaLenDex", "CarDex", "PanoBorDex",
               "Thal/ThalDex", "BorThalDex", "DaraBorDex", "DaraLenDex",
               "OblDex", "PLDBor")

# --- 试验排序:含参照治疗(Dex)的排前面 -----------------------------------
# generated quantities 里的 a_av 取的是前 ns_ref 个试验的基线平均,
# 所以顺序不是无所谓的。WinBUGS 的 ns1=6 就是这个意思。
has_ref  <- tapply(arms$tx_index, arms$trial, function(x) 1 %in% x)
ref_first <- c(names(has_ref)[has_ref], names(has_ref)[!has_ref])
ns_ref <- sum(has_ref)

arms$study <- match(arms$trial, ref_first)
arms <- arms[order(arms$study, arms$arm), ]

# 每个臂所属试验的基线治疗 = 该试验 arm 1 的治疗
base_of <- tapply(arms$tx_index[arms$arm == 1], arms$study[arms$arm == 1], identity)
arms$base <- as.integer(base_of[as.character(arms$study)])

stan_data <- list(ns = length(unique(arms$study)), nt = 16, na = nrow(arms),
                  ns_ref = ns_ref, study = arms$study, trt = arms$tx_index,
                  base = arms$base, r = arms$cr_group, n = arms$n_itt)

cat(sprintf("%d 试验 · %d 臂 · %d 治疗 · 含参照的试验 %d 个 (%s)\n\n",
            stan_data$ns, stan_data$na, stan_data$nt, ns_ref,
            paste(ref_first[1:ns_ref], collapse = ", ")))

# --- 抽样 -----------------------------------------------------------------
fit <- stan(file = file.path(root, "stan", "binomial_nma_fe.stan"),
            data = stan_data, chains = 4, iter = 6000, warmup = 2000,
            seed = 20260825, refresh = 0)

# --- 收敛诊断:先看这个,再看结果 ------------------------------------------
sm <- summary(fit, pars = c("mu", "d", "p_av"))$summary
cat(sprintf("收敛:最大 Rhat %.4f · 最小有效样本量 %.0f\n\n",
            max(sm[, "Rhat"], na.rm = TRUE), min(sm[, "n_eff"], na.rm = TRUE)))

# --- 靶 1:绝对 CR 率 vs 论文 Figure 2 ------------------------------------
draws <- rstan::extract(fit)
p <- draws$p_av
ours <- data.frame(
  treatment = node_name,
  crr  = round(100 * apply(p, 2, mean), 1),
  lo   = round(100 * apply(p, 2, quantile, 0.025), 1),
  hi   = round(100 * apply(p, 2, quantile, 0.975), 1),
  best = round(100 * colMeans(draws$is_best), 1),
  stringsAsFactors = FALSE)

pub <- read.csv(file.path(root, "data", "published_fig2_crr.csv"),
                stringsAsFactors = FALSE)
cmp <- merge(ours, pub[, c("treatment", "crr_pct", "crr_lo_pct", "crr_hi_pct", "sucra_pct")],
             by = "treatment", all.x = TRUE)
cmp <- cmp[order(-cmp$crr), ]

cat("绝对 CR 率:二分类(我们) vs 多项式(论文 Fig 2)\n")
cat("注意:这不是同一个模型,数字本来就不该完全一致 —— 看的是排序和量级\n\n")
print(data.frame(
  treatment = cmp$treatment,
  ours = sprintf("%5.1f%% [%4.1f, %4.1f]", cmp$crr, cmp$lo, cmp$hi),
  paper = sprintf("%5.1f%% [%4.1f, %4.1f]", cmp$crr_pct, cmp$crr_lo_pct, cmp$crr_hi_pct),
  width_ours = round(cmp$hi - cmp$lo, 1),
  width_paper = cmp$crr_hi_pct - cmp$crr_lo_pct,
  p_best = sprintf("%.1f%%", cmp$best)), row.names = FALSE)

# --- 靶 2:直接比较 —— 模型必须贴着试验自己报的数 --------------------------
direct <- read.csv(file.path(root, "data", "rrmm_direct_evidence_cr.csv"),
                   stringsAsFactors = FALSE)
lor <- draws$d[, direct$tx2] - draws$d[, direct$tx1]
direct$model_or <- round(exp(apply(lor, 2, mean)), 2)
direct$model_lo <- round(exp(apply(lor, 2, quantile, 0.025)), 2)
direct$model_hi <- round(exp(apply(lor, 2, quantile, 0.975)), 2)

cat("\n\n直接证据对账:每一条有试验数据的比较\n\n")
print(data.frame(
  trial = direct$trial, comparison = direct$comparison,
  crude = sprintf("%6.2f [%5.2f, %6.2f]", direct$or, direct$lo, direct$hi),
  model = sprintf("%6.2f [%5.2f, %6.2f]", direct$model_or, direct$model_lo, direct$model_hi),
  zero = ifelse(direct$zero_cell, "*", "")), row.names = FALSE)
cat("\n* = 两臂皆零事件,粗 OR 是 0.5 校正凑的,不能当靶\n")

saveRDS(fit, file.path(root, "data", "fit_binomial_fe.rds"))
write.csv(ours, file.path(root, "data", "our_binomial_crr.csv"), row.names = FALSE)
cat("\n结果已存:data/our_binomial_crr.csv\n")

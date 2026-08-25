# ===========================================================================
# 06_fit_multinomial.R  ·  台阶 2:跑多项式 NMA,对上论文 Figure 2
#
# 运行:  Rscript R/06_fit_multinomial.R
#
# 先验用和台阶 1 的 weak 设定完全相同的一套 —— 这是刻意的:
# 两个模型只在**似然**上不同,先验不变,差出来的才是方法本身的差。
# ===========================================================================

root <- "."
suppressPackageStartupMessages(library(rstan))
options(mc.cores = min(4, parallel::detectCores()))
rstan_options(auto_write = TRUE)

node <- c("Dex", "Bor/BorDex", "LenDex", "PomDex", "PomBorDex", "CarLenDex",
          "EloLenDex", "IxaLenDex", "CarDex", "PanoBorDex", "Thal/ThalDex",
          "BorThalDex", "DaraBorDex", "DaraLenDex", "OblDex", "PLDBor")
PRIOR_MU <- 5
PRIOR_D  <- 2.5

arms <- read.csv(file.path(root, "data", "rrmm_arms_indexed.csv"),
                 stringsAsFactors = FALSE)
has_ref   <- tapply(arms$tx_index, arms$trial, function(x) 1 %in% x)
ref_first <- c(names(has_ref)[has_ref], names(has_ref)[!has_ref])
arms$study <- match(arms$trial, ref_first)
arms <- arms[order(arms$study, arms$arm), ]
base_of <- tapply(arms$tx_index[arms$arm == 1], arms$study[arms$arm == 1], identity)
arms$base <- as.integer(base_of[as.character(arms$study)])

stan_data <- list(
  ns = length(unique(arms$study)), nt = 16, na = nrow(arms), ns_ref = sum(has_ref),
  study = arms$study, trt = arms$tx_index, base = arms$base,
  r = as.matrix(arms[, c("cr_group", "pr_group", "lt_pr_group")]),
  prior_sd_mu = PRIOR_MU, prior_sd_d = PRIOR_D)

stopifnot(all(rowSums(stan_data$r) == arms$n_itt))   # 三格必须加总到 ITT
cat(sprintf("%d 试验 · %d 臂 · 三类计数校验通过 · 先验 mu N(0,%g) d N(0,%g)\n\n",
            stan_data$ns, stan_data$na, PRIOR_MU, PRIOR_D))

fit <- stan(file = file.path(root, "stan", "multinomial_nma_fe.stan"),
            data = stan_data, chains = 4, iter = 6000, warmup = 2000,
            seed = 20260825, refresh = 0)

sm  <- summary(fit, pars = c("mu", "d", "crr", "orr"))$summary
div <- sum(sapply(get_sampler_params(fit, inc_warmup = FALSE),
                  function(x) sum(x[, "divergent__"])))
cat(sprintf("收敛:最大 Rhat %.3f · 最小 n_eff %.0f · 发散点 %d\n\n",
            max(sm[, "Rhat"], na.rm = TRUE), min(sm[, "n_eff"], na.rm = TRUE), div))

dr <- rstan::extract(fit)

# --- 后验收缩:零事件的两个治疗这次还死不死? ------------------------------
d_sd <- apply(dr$d, c(2, 3), sd)                      # nt x 2
contr <- 1 - d_sd / PRIOR_D
cat("后验收缩(两个类别分别算,越接近 1 = 数据说得越多):\n\n")
print(data.frame(treatment = node,
                 k2_PR   = sprintf("%.3f", contr[, 1]),
                 k3_ltPR = sprintf("%.3f", contr[, 2])), row.names = FALSE)

# --- 对上论文 Figure 2 -----------------------------------------------------
pub <- read.csv(file.path(root, "data", "published_fig2_crr.csv"), stringsAsFactors = FALSE)
ours <- data.frame(
  treatment = node,
  crr  = 100 * apply(dr$crr, 2, mean),
  lo   = 100 * apply(dr$crr, 2, quantile, .025),
  hi   = 100 * apply(dr$crr, 2, quantile, .975),
  orr  = 100 * apply(dr$orr, 2, mean),
  best_crr = 100 * colMeans(dr$best_crr),
  best_orr = 100 * colMeans(dr$best_orr),
  stringsAsFactors = FALSE)
cmp <- merge(ours, pub, by = "treatment")
cmp <- cmp[order(-cmp$crr), ]

cat("\n\n完全缓解率:我们的多项式 vs 论文 Figure 2\n\n")
print(data.frame(
  treatment = cmp$treatment,
  ours  = sprintf("%5.1f [%4.1f,%5.1f]", cmp$crr, cmp$lo, cmp$hi),
  paper = sprintf("%5.1f [%4.1f,%5.1f]", cmp$crr_pct, cmp$crr_lo_pct, cmp$crr_hi_pct),
  diff  = sprintf("%+5.1f pp", cmp$crr - cmp$crr_pct),
  paper_rank = cmp$rank), row.names = FALSE)

cat("\n\n最优概率:CRR 排序 vs ORR 排序 —— 论文的卖点\n\n")
top <- cmp[order(-cmp$best_crr), ][1:6, ]
print(data.frame(treatment = top$treatment,
                 CRR = sprintf("%5.1f%%", top$crr),
                 p_best_CRR = sprintf("%5.1f%%", top$best_crr),
                 ORR = sprintf("%5.1f%%", top$orr),
                 p_best_ORR = sprintf("%5.1f%%", top$best_orr)), row.names = FALSE)

saveRDS(fit, file.path(root, "data", "fit_multinomial_fe.rds"))
write.csv(ours, file.path(root, "data", "our_multinomial_rates.csv"), row.names = FALSE)
cat("\n结果已存:data/our_multinomial_rates.csv\n")

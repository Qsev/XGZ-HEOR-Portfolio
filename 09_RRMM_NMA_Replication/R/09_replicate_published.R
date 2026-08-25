# ===========================================================================
# 09_replicate_published.R  ·  复现论文 Figure 2 与 Appendix C 的 SUCRA
#
# 运行:  Rscript R/09_replicate_published.R
#
# 关键在于用**对的数据**。Appendix A 那个 "data file" 里是未校正的原始计数
# (GMY302 那行 0+19+95 = 114,和 n 严丝合缝),而 Methods 明确写了:
#
#   "In case there were zero responders in at least one category within an RCT,
#    a zero-correction factor of k = 1 was added to all the fields in the data
#    table of that specific trial to properly run the NMA"
#
# 三个试验适用:MM-003、GMY302、Hjorth 2012。加了校正,发表结果就复现出来;
# 不加,同一份代码给出的 CRR 差一个数量级。
# ===========================================================================

root <- "."
suppressPackageStartupMessages(library(rstan))
options(mc.cores = min(4, parallel::detectCores()))
rstan_options(auto_write = TRUE)

node <- c("Dex", "Bor/BorDex", "LenDex", "PomDex", "PomBorDex", "CarLenDex",
          "EloLenDex", "IxaLenDex", "CarDex", "PanoBorDex", "Thal/ThalDex",
          "BorThalDex", "DaraBorDex", "DaraLenDex", "OblDex", "PLDBor")

arms <- read.csv(file.path(root, "data", "rrmm_arms_indexed.csv"), stringsAsFactors = FALSE)
has_ref   <- tapply(arms$tx_index, arms$trial, function(x) 1 %in% x)
ref_first <- c(names(has_ref)[has_ref], names(has_ref)[!has_ref])
arms$study <- match(arms$trial, ref_first)
arms <- arms[order(arms$study, arms$arm), ]
base_of <- tapply(arms$tx_index[arms$arm == 1], arms$study[arms$arm == 1], identity)
arms$base <- as.integer(base_of[as.character(arms$study)])

# --- 零校正:某个试验只要有一格是零,该试验数据表**所有格子**加 1 -----------
cells <- c("cr_group", "pr_group", "lt_pr_group")
zero_trial <- unique(arms$trial[rowSums(arms[, cells] == 0) > 0])
cat("适用零校正的试验:", paste(zero_trial, collapse = ", "), "\n")
cat("(论文 Results 点名的正是 MM-003、GMY302、Hjorth 2012)\n\n")

r_raw <- as.matrix(arms[, cells])
r_adj <- r_raw
hit <- arms$trial %in% zero_trial
r_adj[hit, ] <- r_adj[hit, ] + 1

cat("校正前后对照(受影响的臂):\n")
print(data.frame(trial = arms$trial[hit], arm = arms$arm[hit],
                 raw = apply(r_raw[hit, ], 1, paste, collapse = "/"),
                 n_raw = rowSums(r_raw[hit, ]),
                 adjusted = apply(r_adj[hit, ], 1, paste, collapse = "/"),
                 n_adj = rowSums(r_adj[hit, ])), row.names = FALSE)
cat("\nAppendix A 数据块里 n 写的是校正前的值 —— 那份数据不是产生发表结果的数据。\n\n")

ref_use <- which(ref_first %in% names(has_ref)[has_ref])   # 论文的 ns1 = 6

fit_one <- function(r, tag) {
  f <- stan(file = file.path(root, "stan", "multinomial_nma_fe.stan"),
            data = list(ns = length(ref_first), nt = 16, na = nrow(arms),
                        study = arms$study, trt = arms$tx_index, base = arms$base, r = r,
                        n_ref_use = length(ref_use), ref_use = ref_use,
                        prior_sd_mu = 31.62, prior_sd_d = 31.62),   # WinBUGS dnorm(0,.001)
            chains = 4, iter = 6000, warmup = 2000, seed = 20260825, refresh = 0)
  sm  <- summary(f, pars = "crr")$summary
  div <- sum(sapply(get_sampler_params(f, inc_warmup = FALSE),
                    function(x) sum(x[, "divergent__"])))
  cat(sprintf("%-14s Rhat %.3f · n_eff %5.0f · 发散点 %d\n", tag,
              max(sm[, "Rhat"]), min(sm[, "n_eff"]), div))
  f
}

fit_adj <- fit_one(r_adj, "零校正后")
fit_raw <- fit_one(r_raw, "Appendix A 原样")

sucra <- function(rk, nt = 16) colMeans((nt - rk) / (nt - 1))
grab <- function(f) {
  dr <- rstan::extract(f)
  data.frame(treatment = node,
             crr = 100 * colMeans(dr$crr),
             lo  = 100 * apply(dr$crr, 2, quantile, .025),
             hi  = 100 * apply(dr$crr, 2, quantile, .975),
             sucra = round(100 * sucra(dr$rk_crr)),
             best  = 100 * colMeans(dr$best_crr), stringsAsFactors = FALSE)
}
a <- grab(fit_adj); b <- grab(fit_raw)
pub <- read.csv(file.path(root, "data", "published_fig2_crr.csv"), stringsAsFactors = FALSE)
m <- merge(merge(a, b, by = "treatment", suffixes = c("_adj", "_raw")), pub, by = "treatment")
m <- m[order(m$rank), ]

cat("\n完全缓解率 % —— 零校正后 / Appendix A 原样 / 论文\n\n")
print(data.frame(rank = m$rank, treatment = m$treatment,
                 corrected = sprintf("%5.1f [%4.1f,%5.1f]", m$crr_adj, m$lo_adj, m$hi_adj),
                 appendixA  = sprintf("%5.1f", m$crr_raw),
                 published  = sprintf("%5.1f [%4.1f,%5.1f]", m$crr_pct, m$crr_lo_pct, m$crr_hi_pct),
                 SUCRA = sprintf("%3d / %3d", m$sucra_adj, m$sucra_pct)), row.names = FALSE)

cat(sprintf("\n零校正后:CRR 平均绝对偏差 %.2f pp · SUCRA 平均绝对偏差 %.1f 分\n",
            mean(abs(m$crr_adj - m$crr_pct)), mean(abs(m$sucra_adj - m$sucra_pct))))
cat(sprintf("Appendix A 原样:CRR 平均绝对偏差 %.1f pp\n",
            mean(abs(m$crr_raw - m$crr_pct))))

saveRDS(fit_adj, file.path(root, "data", "fit_published_replication.rds"))
write.csv(m, file.path(root, "data", "published_replication.csv"), row.names = FALSE)
cat("\n结果已存:data/published_replication.csv\n")

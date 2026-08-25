# ===========================================================================
# 08_baseline_definition.R  ·  合并参照基线怎么取,结论差多少
#
# 运行:  Rscript R/08_baseline_definition.R
#
# 07 已经把病灶定位到 WinBUGS 的这一行:
#     a_av[k] <- mean( a[1:ns1,k] )
# 六个含参照治疗的试验里,有两个的参照臂 CR = 0,它们的基线不可识别。
#
# 这里跑一个 2x2:先验(论文 vague / 弱信息) x 基线(全部6个 / 只用可识别的)。
# 「可识别」不是我挑的名单,是一条能写出来的规则:
#     参照臂在三个类别上都至少有一个事件
# 这条规则事先声明、机械执行,不看结果。
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

ref_studies <- which(ref_first %in% names(has_ref)[has_ref])

# --- 规则:参照臂三个类别都要有事件 -----------------------------------------
counts <- arms[arms$arm == 1 & arms$study %in% ref_studies,
               c("study", "trial", "cr_group", "pr_group", "lt_pr_group")]
counts$identified <- with(counts, cr_group > 0 & pr_group > 0 & lt_pr_group > 0)
cat("含参照治疗的试验,参照臂的三类计数:\n\n")
print(data.frame(trial = counts$trial,
                 CR = counts$cr_group, PR = counts$pr_group, ltPR = counts$lt_pr_group,
                 identified = ifelse(counts$identified, "yes", "NO  <-- 基线不可识别")),
      row.names = FALSE)
clean <- counts$study[counts$identified]
cat(sprintf("\n可识别的 %d 个:%s\n\n", length(clean),
            paste(counts$trial[counts$identified], collapse = ", ")))

base_data <- list(
  ns = length(ref_first), nt = 16, na = nrow(arms),
  study = arms$study, trt = arms$tx_index, base = arms$base,
  r = as.matrix(arms[, c("cr_group", "pr_group", "lt_pr_group")]))

grid <- expand.grid(prior = c("vague", "weak"), baseline = c("all6", "clean"),
                    stringsAsFactors = FALSE)
prior_sd <- list(vague = c(mu = 31.62, d = 31.62), weak = c(mu = 5, d = 2.5))
ref_set  <- list(all6 = ref_studies, clean = clean)

res <- list()
for (i in seq_len(nrow(grid))) {
  pr <- grid$prior[i]; bl <- grid$baseline[i]; tag <- paste(pr, bl, sep = "/")
  s <- prior_sd[[pr]]; ru <- ref_set[[bl]]
  fit <- stan(file = file.path(root, "stan", "multinomial_nma_fe.stan"),
              data = c(base_data, list(n_ref_use = length(ru), ref_use = ru,
                                       prior_sd_mu = unname(s["mu"]),
                                       prior_sd_d  = unname(s["d"]))),
              chains = 4, iter = 6000, warmup = 2000, seed = 20260825, refresh = 0)
  sm  <- summary(fit, pars = c("crr", "orr"))$summary
  div <- sum(sapply(get_sampler_params(fit, inc_warmup = FALSE),
                    function(x) sum(x[, "divergent__"])))
  dr <- rstan::extract(fit)
  res[[tag]] <- dr
  cat(sprintf("%-12s Rhat %.3f · n_eff %5.0f · 发散点 %3d · Dex CRR %5.2f%%\n",
              tag, max(sm[, "Rhat"]), min(sm[, "n_eff"]), div, 100 * mean(dr$crr[, 1])))
}

# --- 对上论文 -------------------------------------------------------------
pub <- read.csv(file.path(root, "data", "published_fig2_crr.csv"), stringsAsFactors = FALSE)
out <- data.frame(treatment = node, stringsAsFactors = FALSE)
for (tag in names(res)) {
  cr <- res[[tag]]$crr
  out[[tag]] <- sprintf("%5.1f [%4.1f,%5.1f]", 100 * colMeans(cr),
                        100 * apply(cr, 2, quantile, .025), 100 * apply(cr, 2, quantile, .975))
}
out <- merge(out, pub[, c("treatment", "rank", "crr_pct", "crr_lo_pct", "crr_hi_pct", "sucra_pct")],
             by = "treatment")
out$paper <- sprintf("%5.1f [%4.1f,%5.1f]", out$crr_pct, out$crr_lo_pct, out$crr_hi_pct)
out <- out[order(out$rank), ]

cat("\n\n完全缓解率 %,四种设定 vs 论文,按论文名次排\n\n")
print(out[, c("rank", "treatment", names(res), "paper")], row.names = FALSE)

# --- 排序稳定性:发现层 ① -------------------------------------------------
cat("\n\n最优概率 %,四种设定\n\n")
best <- data.frame(treatment = node, stringsAsFactors = FALSE)
for (tag in names(res)) best[[tag]] <- sprintf("%5.1f", 100 * colMeans(res[[tag]]$best_crr))
best$paper_rank <- pub$rank[match(node, pub$treatment)]
print(best[order(best$paper_rank), ][1:8, ], row.names = FALSE)

# SUCRA:名次分布的曲线下面积,和论文 Appendix C 报的是同一个量
sucra <- function(rk, nt = 16) colMeans((nt - rk) / (nt - 1))
cat("\n\nSUCRA %,我们(weak/clean) vs 论文\n\n")
sc <- data.frame(treatment = node,
                 ours = round(100 * sucra(res[["weak/clean"]]$rk_crr), 0),
                 paper = pub$sucra_pct[match(node, pub$treatment)])
sc$diff <- sc$ours - sc$paper
print(sc[order(-sc$paper), ], row.names = FALSE)

saveRDS(res, file.path(root, "data", "baseline_grid_draws.rds"))
write.csv(out, file.path(root, "data", "baseline_definition_grid.csv"), row.names = FALSE)
cat("\n结果已存:data/baseline_definition_grid.csv\n")

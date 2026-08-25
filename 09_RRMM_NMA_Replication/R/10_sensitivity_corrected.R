# ===========================================================================
# 10_sensitivity_corrected.R  ·  在**正确的数据**上重做敏感性分析
#
# 运行:  Rscript R/10_sensitivity_corrected.R
#
# 09 证明了发表结果可以复现,但复现依赖一个常数:零校正 k = 1。
# 这个常数没有被讨论过,也没有被做过敏感性分析。而 NICE DSU TSD 2 §6.3
# 给的建议是另一个数(分母加 1、分子加 0.5),并且明确说
# 「两臂皆零的试验不提供处理效应证据,可以排除」。
#
# 所以这里问三件事:
#   1. 换 k,发表结论还成立吗
#   2. 换先验,排序还成立吗
#   3. 校正之后,那几个治疗的后验里到底有多少是数据
# ===========================================================================

root <- "."
suppressPackageStartupMessages(library(rstan))
options(mc.cores = min(4, parallel::detectCores()))
rstan_options(auto_write = TRUE)

node <- c("Dex", "Bor/BorDex", "LenDex", "PomDex", "PomBorDex", "CarLenDex",
          "EloLenDex", "IxaLenDex", "CarDex", "PanoBorDex", "Thal/ThalDex",
          "BorThalDex", "DaraBorDex", "DaraLenDex", "OblDex", "PLDBor")
cells <- c("cr_group", "pr_group", "lt_pr_group")

arms <- read.csv(file.path(root, "data", "rrmm_arms_indexed.csv"), stringsAsFactors = FALSE)
has_ref   <- tapply(arms$tx_index, arms$trial, function(x) 1 %in% x)
ref_first <- c(names(has_ref)[has_ref], names(has_ref)[!has_ref])
arms$study <- match(arms$trial, ref_first)
arms <- arms[order(arms$study, arms$arm), ]
base_of <- tapply(arms$tx_index[arms$arm == 1], arms$study[arms$arm == 1], identity)
arms$base <- as.integer(base_of[as.character(arms$study)])
ref_use <- which(ref_first %in% names(has_ref)[has_ref])
zero_trial <- unique(arms$trial[rowSums(arms[, cells] == 0) > 0])

make_data <- function(k, prior_sd) {
  r <- as.matrix(arms[, cells])
  r[arms$trial %in% zero_trial, ] <- r[arms$trial %in% zero_trial, ] + k
  list(ns = length(ref_first), nt = 16, na = nrow(arms),
       study = arms$study, trt = arms$tx_index, base = arms$base, r = r,
       n_ref_use = length(ref_use), ref_use = ref_use,
       prior_sd_mu = prior_sd, prior_sd_d = prior_sd)
}

sucra <- function(rk, nt = 16) colMeans((nt - rk) / (nt - 1))

# k 只能取整数:multinomial 的观测必须是整数计数,所以 TSD 2 §6.3 那个
# 「分子加 0.5」的惯例在多项式似然下根本表达不了。这本身值得一提 ——
# 论文引的是 Ades 等人的连续性校正传统,但它用的似然不接受半个病人。
grid <- expand.grid(k = c(0, 1, 2, 3), prior = c(31.62, 2.5))
res <- list()
cat("先验     k     Rhat   n_eff  发散  Dex CRR   最低收缩(治疗)\n")
for (i in seq_len(nrow(grid))) {
  k <- grid$k[i]; ps <- grid$prior[i]
  tag <- sprintf("%s/k=%g", ifelse(ps > 10, "vague", "weak"), k)
  d0 <- make_data(k, ps)
  f <- stan(file = file.path(root, "stan", "multinomial_nma_fe.stan"), data = d0,
            chains = 4, iter = 6000, warmup = 2000, seed = 20260825, refresh = 0)
  sm <- summary(f, pars = "crr")$summary
  div <- sum(sapply(get_sampler_params(f, inc_warmup = FALSE),
                    function(x) sum(x[, "divergent__"])))
  dr <- rstan::extract(f)
  contr <- 1 - apply(dr$d, c(2, 3), sd)[, 1] / ps
  res[[tag]] <- dr
  cat(sprintf("%-9s %-4g %.3f %7.0f %5d  %5.2f%%   %.3f (%s)\n",
              ifelse(ps > 10, "vague", "weak"), k, max(sm[, "Rhat"]), min(sm[, "n_eff"]),
              div, 100 * mean(dr$crr[, 1]), min(contr[-1]), node[-1][which.min(contr[-1])]))
}

pub <- read.csv(file.path(root, "data", "published_fig2_crr.csv"), stringsAsFactors = FALSE)
ord <- pub$treatment[order(pub$rank)]

cat("\n\n1. 零校正常数换掉,绝对缓解率怎么动(vague 先验,即论文设定)\n\n")
tab <- data.frame(treatment = node, stringsAsFactors = FALSE)
for (tag in grep("^vague", names(res), value = TRUE))
  tab[[tag]] <- sprintf("%5.1f", 100 * colMeans(res[[tag]]$crr))
tab$published <- pub$crr_pct[match(node, pub$treatment)]
print(tab[match(ord, tab$treatment), ], row.names = FALSE)

cat("\n\n2. SUCRA:六种设定 vs 论文\n\n")
sc <- data.frame(treatment = node, stringsAsFactors = FALSE)
for (tag in names(res)) sc[[tag]] <- round(100 * sucra(res[[tag]]$rk_crr))
sc$paper <- pub$sucra_pct[match(node, pub$treatment)]
print(sc[match(ord, sc$treatment), ], row.names = FALSE)

cat("\n\n3. 夺冠概率 %:排序结论稳不稳\n\n")
bs <- data.frame(treatment = node, stringsAsFactors = FALSE)
for (tag in names(res)) bs[[tag]] <- sprintf("%5.1f", 100 * colMeans(res[[tag]]$best_crr))
print(bs[match(ord[1:6], bs$treatment), ], row.names = FALSE)

cat("\n\n4. 后验收缩(vague/k=1,即论文的设定)—— 校正之后还剩多少是先验\n\n")
dr <- res[["vague/k=1"]]
ct <- data.frame(treatment = node,
                 k2 = 1 - apply(dr$d, c(2, 3), sd)[, 1] / 31.62,
                 k3 = 1 - apply(dr$d, c(2, 3), sd)[, 2] / 31.62,
                 crr_width = 100 * (apply(dr$crr, 2, quantile, .975) -
                                    apply(dr$crr, 2, quantile, .025)))
ct <- ct[order(ct$k2), ]
print(data.frame(treatment = ct$treatment, contraction_PR = sprintf("%.3f", ct$k2),
                 contraction_ltPR = sprintf("%.3f", ct$k3),
                 CrI_width = sprintf("%4.1f pp", ct$crr_width)), row.names = FALSE)

cat("\n\n5. CRR 与 ORR 的第一名,以及前三名挤成什么样(vague/k=1)\n\n")
top <- data.frame(treatment = node,
                  crr = 100 * colMeans(dr$crr), best_crr = 100 * colMeans(dr$best_crr),
                  orr = 100 * colMeans(dr$orr), best_orr = 100 * colMeans(dr$best_orr))
top <- top[order(-top$best_crr), ][1:5, ]
print(data.frame(treatment = top$treatment,
                 CRR = sprintf("%5.1f%%", top$crr), p_best_CRR = sprintf("%5.1f%%", top$best_crr),
                 ORR = sprintf("%5.1f%%", top$orr), p_best_ORR = sprintf("%5.1f%%", top$best_orr)),
      row.names = FALSE)

saveRDS(res, file.path(root, "data", "sensitivity_corrected_draws.rds"))
write.csv(sc, file.path(root, "data", "sensitivity_corrected_sucra.csv"), row.names = FALSE)
cat("\n结果已存:data/sensitivity_corrected_sucra.csv\n")

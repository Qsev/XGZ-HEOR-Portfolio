# ===========================================================================
# 04_diagnose_binomial.R  ·  把「崩在哪里」量化出来
#
# 运行:  Rscript R/04_diagnose_binomial.R
#
# 03 跑出来的结果里,Rhat 1.002、有效样本量 3714,按常规判准是「收敛良好」,
# 而绝对 CR 率是废的。这个脚本回答:常规诊断为什么没抓到,什么能抓到。
#
# 核心指标是**后验收缩**(posterior contraction):
#     contraction = 1 - 后验标准差 / 先验标准差
# 接近 1 = 数据把这个参数钉住了;接近 0 = 数据什么也没说,后验就是先验。
# 它不看链之间是否一致(那是 Rhat 的事),只看**有没有学到东西**。
# ===========================================================================

root <- "."
suppressPackageStartupMessages(library(rstan))

fit <- readRDS(file.path(root, "data", "fit_binomial_fe.rds"))
node <- c("Dex", "Bor/BorDex", "LenDex", "PomDex", "PomBorDex", "CarLenDex",
          "EloLenDex", "IxaLenDex", "CarDex", "PanoBorDex", "Thal/ThalDex",
          "BorThalDex", "DaraBorDex", "DaraLenDex", "OblDex", "PLDBor")
prior_sd <- 100                      # stan 文件里 d_free ~ normal(0, 100)

dr <- rstan::extract(fit)
d  <- dr$d                           # 抽样数 x 16
p  <- dr$p_av

# --- 1. 常规诊断怎么说 -----------------------------------------------------
sm  <- summary(fit, pars = c("mu", "d", "p_av"))$summary
div <- sum(sapply(get_sampler_params(fit, inc_warmup = FALSE),
                  function(x) sum(x[, "divergent__"])))
cat(sprintf("常规诊断:最大 Rhat %.3f · 最小 n_eff %.0f · 发散点 %d\n",
            max(sm[, "Rhat"], na.rm = TRUE), min(sm[, "n_eff"], na.rm = TRUE), div))
cat("按 Rhat < 1.01 与 n_eff > 400 的常规判准,这个拟合是「通过」的。\n\n")

# --- 2. 后验收缩:数据到底钉住了哪些参数 -----------------------------------
tab <- data.frame(
  treatment   = node,
  post_sd     = apply(d, 2, sd),
  contraction = 1 - apply(d, 2, sd) / prior_sd,
  crr         = 100 * apply(p, 2, mean),
  ci_width    = 100 * (apply(p, 2, quantile, .975) - apply(p, 2, quantile, .025)),
  p_best      = 100 * colMeans(dr$is_best),
  stringsAsFactors = FALSE)
tab <- tab[order(tab$contraction), ]

cat("后验收缩(越接近 0 = 数据越没说话):\n\n")
print(data.frame(
  treatment   = tab$treatment,
  post_sd     = sprintf("%7.2f", tab$post_sd),
  contraction = sprintf("%.3f", tab$contraction),
  CRR         = sprintf("%5.1f%%", tab$crr),
  CI_width    = sprintf("%5.1f pp", tab$ci_width),
  p_best      = sprintf("%5.1f%%", tab$p_best)), row.names = FALSE)

dead <- tab[tab$contraction < 0.9, ]
cat(sprintf("\n%d 个治疗的收缩 < 0.9 —— 后验标准差仍在先验的十分之一以上:%s\n",
            nrow(dead), paste(dead$treatment, collapse = ", ")))
cat(sprintf("这 %d 个治疗拿走了 %.1f%% 的「最优概率」—— 全部来自先验的形状,不是数据。\n\n",
            nrow(dead), sum(dead$p_best)))

# --- 3. 参照基线为什么塌了 -------------------------------------------------
mu <- dr$mu
ref <- 1:6                          # 含 Dex 的前 6 个试验(03 里排好的顺序)
ref_names <- c("APEX", "GMY302", "MM-003", "MM-009", "MM-010", "OPTIMUM")
cat("含参照治疗的 6 个试验,各自的基线 mu:\n\n")
print(data.frame(
  trial = ref_names,
  mu    = sprintf("%7.2f", apply(mu[, ref], 2, mean)),
  sd    = sprintf("%6.2f", apply(mu[, ref], 2, sd)),
  implied_CR = sprintf("%6.3f%%", 100 * plogis(apply(mu[, ref], 2, mean)))),
  row.names = FALSE)
cat(sprintf("\n合并基线 a_av = 上面六个的平均 = %.2f,对应 CR 率 %.4f%%\n",
            mean(dr$a_av), 100 * plogis(mean(dr$a_av))))
cat("零事件的两个试验(GMY302、MM-003)把平均拖到地下,\n")
cat("于是全网络的绝对 CR 率一起塌掉 —— 相对效应 d 没错,错的是参照点。\n\n")

# --- 4. 图:先验 vs 后验 ----------------------------------------------------
dir.create(file.path(root, "visuals"), showWarnings = FALSE)
png(file.path(root, "visuals", "binomial_breakdown.png"),
    width = 1800, height = 700, res = 150)
par(mfrow = c(1, 3), mar = c(4, 4, 3, 1))

show <- c("CarLenDex", "PomDex", "OblDex")
for (nm in show) {
  i <- match(nm, node)
  xs <- seq(-250, 250, length.out = 600)
  hist(d[, i], breaks = 80, freq = FALSE, border = NA, col = "#94a3b8",
       xlim = c(-250, 250), main = sprintf("d[%s]", nm),
       xlab = "log odds ratio vs Dex", ylab = "density")
  lines(xs, dnorm(xs, 0, prior_sd), col = "#c2410c", lwd = 2)
  legend("topright", c("posterior", "prior N(0,100)"),
         fill = c("#94a3b8", NA), border = NA, lty = c(NA, 1),
         col = c(NA, "#c2410c"), lwd = c(NA, 2), bty = "n", cex = 0.9)
}
dev.off()
cat("图已存到 visuals/binomial_breakdown.png\n")

write.csv(tab, file.path(root, "data", "binomial_contraction.csv"), row.names = FALSE)
cat("表已存到 data/binomial_contraction.csv\n")

# ===========================================================================
# 11_rankogram.R  ·  排名概率矩阵 —— 这个 case 的主视觉
#
# 运行:  Rscript R/11_rankogram.R
#
# 论文 Appendix C 的 Fig 7/8 报的是同一个量,但只有图、没有数,而且 CRR 和
# ORR 分在两张图上,没法直接比。这里把两者并排,并且把「第 1 名的概率」
# 这一列显式标出来 —— 委员会读 SUCRA 排名时,真正该看的是这一列。
#
# 用论文自己的设定跑出来的后验:vague 先验 + 零校正 k = 1。
# 图上任何一个数都不是我们换参数换出来的。
# ===========================================================================

root <- "."
suppressPackageStartupMessages(library(rstan))

node <- c("Dex", "Bor/BorDex", "LenDex", "PomDex", "PomBorDex", "CarLenDex",
          "EloLenDex", "IxaLenDex", "CarDex", "PanoBorDex", "Thal/ThalDex",
          "BorThalDex", "DaraBorDex", "DaraLenDex", "OblDex", "PLDBor")
nt <- length(node)

fit <- readRDS(file.path(root, "data", "fit_published_replication.rds"))
dr  <- rstan::extract(fit)

# P(treatment t sits at rank h),两个结局各一张
rank_matrix <- function(rk) {
  m <- t(sapply(1:nt, function(t) tabulate(rk[, t], nbins = nt) / nrow(rk)))
  dimnames(m) <- list(node, 1:nt)
  m
}
P_crr <- rank_matrix(dr$rk_crr)
P_orr <- rank_matrix(dr$rk_orr)
sucra <- function(P) as.vector(P %*% ((nt - (1:nt)) / (nt - 1)))
s_crr <- sucra(P_crr); s_orr <- sucra(P_orr)

ord <- order(-s_crr)                       # 两个面板用同一个顺序,才看得出移动

pal <- colorRampPalette(c("#f8fafc", "#cbd5e1", "#7c93ad", "#2f4a68", "#152a42"))(100)

panel <- function(P, s, ord, title, show_ylab) {
  m <- P[ord, ]
  par(mar = c(4.2, if (show_ylab) 9.5 else 1.2, 3.4, 3.6))
  plot(NA, xlim = c(0.5, nt + 0.5), ylim = c(nt + 0.5, 0.5), axes = FALSE,
       xlab = "", ylab = "", xaxs = "i", yaxs = "i")
  for (i in 1:nt) for (j in 1:nt) {
    v <- m[i, j]
    rect(j - .5, i - .5, j + .5, i + .5, col = pal[max(1, ceiling(100 * v / 0.6))],
         border = "white", lwd = 0.6)
    if (v >= 0.05)
      text(j, i, sprintf("%.0f", 100 * v), cex = 0.62,
           col = if (v > 0.30) "white" else "#1f2937")
  }
  axis(1, at = 1:nt, labels = 1:nt, tick = FALSE, line = -0.7, cex.axis = 0.72)
  mtext("rank  (1 = best)", side = 1, line = 1.7, cex = 0.78)
  if (show_ylab)
    axis(2, at = 1:nt, labels = rownames(m), tick = FALSE, las = 1,
         line = -0.6, cex.axis = 0.78)
  # 右侧 SUCRA
  axis(4, at = 1:nt, labels = sprintf("%2.0f", 100 * s[ord]), tick = FALSE,
       las = 1, line = -0.9, cex.axis = 0.72)
  mtext("SUCRA", side = 4, line = 1.6, cex = 0.72, las = 0)
  mtext(title, side = 3, line = 1.1, adj = 0, cex = 0.95, font = 2)
  # 第 1 名那一列框出来
  rect(0.5, 0.5, 1.5, nt + 0.5, border = "#c2410c", lwd = 1.8)
}

dir.create(file.path(root, "visuals"), showWarnings = FALSE)
png(file.path(root, "visuals", "rank_probability_matrix.png"),
    width = 2200, height = 1150, res = 150)
layout(matrix(1:2, nrow = 1), widths = c(1.30, 1))
panel(P_crr, s_crr, ord, "Complete response  (CRR)", TRUE)
panel(P_orr, s_orr, ord, "Objective response  (ORR)", FALSE)
dev.off()

cat("图已存到 visuals/rank_probability_matrix.png\n\n")

# --- 图上读不到的那两个数,单独打出来 --------------------------------------
cat("第 1 名的后验概率(论文自己的设定):\n\n")
tab <- data.frame(treatment = node[ord],
                  P_rank1_CRR = sprintf("%5.1f%%", 100 * P_crr[ord, 1]),
                  SUCRA_CRR   = sprintf("%3.0f", 100 * s_crr[ord]),
                  P_rank1_ORR = sprintf("%5.1f%%", 100 * P_orr[ord, 1]),
                  SUCRA_ORR   = sprintf("%3.0f", 100 * s_orr[ord]))
print(head(tab, 6), row.names = FALSE)

# 前三名之间到底分得开吗
top3 <- ord[1:3]
cat(sprintf("\nCRR:第 1 名与第 3 名的 SUCRA 差 %.0f 分,而排名第 1 的后验概率只有 %.0f%%\n",
            100 * (s_crr[top3[1]] - s_crr[top3[3]]), 100 * P_crr[top3[1], 1]))
cat(sprintf("ORR:同样三个治疗,第 1 名换成 %s(%.0f%%)\n",
            node[which.max(P_orr[, 1])], 100 * max(P_orr[, 1])))

# 有多少概率质量落在「前三名」这个集合里,但分不清是谁
cat(sprintf("\n三者合计占据第 1 名的概率 %.0f%% (CRR) / %.0f%% (ORR)\n",
            100 * sum(P_crr[top3, 1]), 100 * sum(P_orr[top3, 1])))

write.csv(cbind(treatment = node, round(100 * P_crr, 2)),
          file.path(root, "data", "rank_probabilities_crr.csv"), row.names = FALSE)
write.csv(cbind(treatment = node, round(100 * P_orr, 2)),
          file.path(root, "data", "rank_probabilities_orr.csv"), row.names = FALSE)
cat("\n矩阵已存:data/rank_probabilities_crr.csv / _orr.csv\n")

# ===========================================================================
# 15_psa.R  ·  cost-effectiveness plane and acceptability curve
#
# ⚠ NOT a replication. The paper reports distribution FAMILIES (normal for
# costs, beta for probabilities and rates) but no standard deviations and no
# shape parameters, so its Figures 5 and 6 cannot be reproduced. The spreads
# below are mine, chosen so each parameter's 95% interval matches the range the
# paper itself used in its one-way analysis. Stated, not hidden.
# ===========================================================================
Sys.setlocale("LC_CTYPE", "en_US.UTF-8")
source("R/00_eval.R")
set.seed(20260826)

N <- 1000                     # the paper's stated number of simulations
z <- 1.96
sd_cost <- function(m) m * 0.25 / z     # one-way range was +/- 25%
sd_util <- function(m) m * 0.10 / z     # +/- 10%
sd_prob <- function(m) m * 0.10 / z     # +/- 10%

draw <- function() {
  drug  <- c(amlodipine = rnorm(1, COST_DRUG[["amlodipine"]], sd_cost(COST_DRUG[["amlodipine"]])),
             hctz       = rnorm(1, COST_DRUG[["hctz"]],       sd_cost(COST_DRUG[["hctz"]])))
  event <- c(MI     = rnorm(1, COST_EVENT[["MI"]],     sd_cost(COST_EVENT[["MI"]])),
             Stroke = rnorm(1, COST_EVENT[["Stroke"]], sd_cost(COST_EVENT[["Stroke"]])))
  u <- UTIL
  for (k in c("EventFree", "MI", "Stroke")) {
    ab <- beta_ab(UTIL[[k]], sd_util(UTIL[[k]])); u[[k]] <- rbeta(1, ab[["a"]], ab[["b"]])
  }
  tpm <- TPM_PUBLISHED
  for (a in names(tpm)) {
    p <- tpm[[a]]
    for (k in c("EM", "ES", "ED", "MD", "SD")) {
      ab <- beta_ab(p[[k]], sd_prob(p[[k]])); p[[k]] <- rbeta(1, ab[["a"]], ab[["b"]])
    }
    tpm[[a]] <- renorm(p)
  }
  e <- run_model(tpm, pmax(drug, 0), pmax(event, 0), u)
  c(d_cost = e$d_cost, d_qaly = e$d_qaly)
}
sim <- t(replicate(N, draw()))

INK <- "#1f2937"; MUTED <- "#6b7280"; SURF <- "#fcfcfb"; GRID <- "#e8e8e6"
CA <- "#2a78d6"; CH <- "#eb6834"; SLATE <- "#6d8aa5"

png("visuals/psa.png", width = 2400, height = 1150, res = 200)
par(mfrow = c(1, 2), oma = c(4.4, 5.2, 5.6, 1.0), bg = SURF)

# --- cost-effectiveness plane ---------------------------------------------
par(mar = c(0.4, 0.4, 2.6, 3.4))
xl <- range(c(sim[, "d_qaly"], 0)) * 1.12; yl <- range(c(sim[, "d_cost"], 0)) * 1.12
plot(NA, xlim = xl, ylim = yl, axes = FALSE, xlab = "", ylab = "", xaxs = "i", yaxs = "i")
abline(h = 0, v = 0, col = "#c9c9c4", lwd = 1)
abline(a = 0, b = WTP, col = INK, lty = 2, lwd = 1.4)
points(sim[, "d_qaly"], sim[, "d_cost"], pch = 19, cex = 0.42,
       col = adjustcolor(SLATE, 0.45))
points(mean(sim[, "d_qaly"]), mean(sim[, "d_cost"]), pch = 21, bg = INK,
       col = SURF, cex = 1.5, lwd = 2.4)
axis(1, tick = FALSE, line = -0.9, cex.axis = 0.9, col.axis = MUTED)
axis(2, tick = FALSE, las = 1, line = -0.6, cex.axis = 0.9, col.axis = MUTED)
ytop <- yl[2] * 0.92
text(ytop / WTP + 0.012, ytop, "willingness to pay\n80,976 CNY per QALY",
     adj = c(0, 1), cex = 0.84, col = INK)
text(xl[1] * 0.92, yl[1] * 0.86,
     sprintf("%.0f%% of draws fall in the\nsouth-east quadrant:\ncheaper and more effective",
             100 * mean(sim[, "d_qaly"] > 0 & sim[, "d_cost"] < 0)),
     adj = c(0, 0), cex = 0.88, col = INK)
mtext("Cost-effectiveness plane", side = 3, line = 0.6, adj = 0, cex = 1.02, col = INK, font = 2)
mtext("incremental QALY, amlodipine vs hydrochlorothiazide", side = 1, line = 2.0,
      cex = 0.9, col = MUTED)
mtext("incremental cost (CNY)", side = 2, line = 3.4, cex = 0.9, col = MUTED)

# --- acceptability curve ---------------------------------------------------
par(mar = c(0.4, 3.4, 2.6, 0.4))
wtps <- seq(0, 200000, length.out = 200)
pa <- sapply(wtps, function(w) mean(w * sim[, "d_qaly"] - sim[, "d_cost"] > 0))
plot(NA, xlim = c(0, 200000), ylim = c(0, 100), axes = FALSE, xlab = "", ylab = "",
     xaxs = "i", yaxs = "i")
abline(h = seq(0, 100, 25), col = GRID, lwd = 1)
abline(v = WTP, col = "#c9c9c4", lty = 2, lwd = 1.2)
lines(wtps, 100 * pa, col = CA, lwd = 2.8)
lines(wtps, 100 * (1 - pa), col = CH, lwd = 2.8)
axis(1, at = seq(0, 200000, 50000), labels = paste0(seq(0, 200, 50), "k"),
     tick = FALSE, line = -0.9, cex.axis = 0.9, col.axis = MUTED)
axis(2, at = seq(0, 100, 25), labels = paste0(seq(0, 100, 25), "%"), tick = FALSE,
     las = 1, line = -0.6, cex.axis = 0.9, col.axis = MUTED)
text(WTP + 4000, 46, "the paper's threshold", adj = 0, cex = 0.84, col = MUTED, srt = 90)
text(150000, 100 * pa[length(pa)] - 7, "amlodipine", col = CA, font = 2, cex = 0.94)
text(150000, 100 * (1 - pa[length(pa)]) + 7, "hydrochlorothiazide", col = CH, font = 2, cex = 0.94)
mtext("Acceptability curve", side = 3, line = 0.6, adj = 0, cex = 1.02, col = INK, font = 2)
mtext("willingness to pay (CNY per QALY)", side = 1, line = 2.0, cex = 0.9, col = MUTED)
mtext("probability cost-effective", side = 2, line = 2.4, cex = 0.9, col = MUTED)

mtext("Probabilistic sensitivity analysis", side = 3, outer = TRUE, line = 3.1,
      adj = 0, cex = 1.34, font = 2, col = INK)
mtext("Run here from scratch, not reproduced: the paper's Figures 5 and 6 need distribution parameters it does not report.",
      side = 3, outer = TRUE, line = 2.0, adj = 0, cex = 0.95, col = MUTED)
mtext("Each spread is set so its 95% interval matches the one-way range the paper itself used.",
      side = 3, outer = TRUE, line = 0.6, adj = 0, cex = 0.95, col = MUTED)
mtext(sprintf("1000 simulations, as the paper states. Mean incremental cost %+.0f CNY, mean incremental QALY %+.3f.",
              mean(sim[, "d_cost"]), mean(sim[, "d_qaly"])),
      side = 1, outer = TRUE, line = 3.2, adj = 0, cex = 0.8, col = MUTED)
invisible(dev.off())
cat(sprintf("visuals/psa.png written  |  SE quadrant %.1f%%  |  P(CE at WTP) %.3f\n",
            100 * mean(sim[, "d_qaly"] > 0 & sim[, "d_cost"] < 0),
            mean(WTP * sim[, "d_qaly"] - sim[, "d_cost"] > 0)))
saveRDS(sim, "data/psa_draws.rds")

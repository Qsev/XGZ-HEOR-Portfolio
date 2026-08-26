# ===========================================================================
# 14_figure_trace.R  ·  the cohort over time — reproduces the paper's Fig 2 & 3
#
# States are ordered by severity, so they take a sequential ramp rather than
# categorical hues; the categorical blue/orange stay reserved for the arms.
# ===========================================================================
Sys.setlocale("LC_CTYPE", "en_US.UTF-8")
source("R/01_markov_engine.R")

RAMP <- c(EventFree = "#dbe4ec", MI = "#9db2c6", Stroke = "#5b7governed", Dead = "#2f4a68")
RAMP <- c(EventFree = "#dde6ee", MI = "#a8bccd", Stroke = "#6d8aa5", Dead = "#2f4a68")
INK <- "#1f2937"; MUTED <- "#6b7280"; SURF <- "#fcfcfb"; ARM <- c(amlodipine="#2a78d6", hctz="#eb6834")

png("visuals/cohort_trace.png", width = 2400, height = 1150, res = 200)
par(mfrow = c(1, 2), oma = c(4.4, 4.8, 5.6, 1.0), bg = SURF)

for (i in seq_along(ARM)) {
  a  <- names(ARM)[i]
  tr <- run_markov(a)$trace[, c("EventFree", "MI", "Stroke", "Dead")] * 100
  cum <- t(apply(tr, 1, cumsum))

  par(mar = c(0.4, if (i == 1) 0.4 else 3.0, 2.6, if (i == 1) 3.0 else 0.4))
  plot(NA, xlim = c(0, 10), ylim = c(0, 100), axes = FALSE, xlab = "", ylab = "",
       xaxs = "i", yaxs = "i")
  lo <- rep(0, 11)
  for (k in seq_len(4)) {
    polygon(c(0:10, 10:0), c(cum[, k], rev(lo)), col = RAMP[k], border = SURF, lwd = 0.8)
    lo <- cum[, k]
  }
  axis(1, at = 0:10, tick = FALSE, line = -0.9, cex.axis = 0.92, col.axis = MUTED)
  if (i == 1) axis(2, at = seq(0, 100, 25), labels = paste0(seq(0, 100, 25), "%"),
                   tick = FALSE, las = 1, line = -0.6, cex.axis = 0.92, col.axis = MUTED)

  # direct labels inside each band, where the band is thick enough to hold one
  mid <- function(k, x) (if (k == 1) 0 else cum[x + 1, k - 1]) + tr[x + 1, k] / 2
  text(5, mid(1, 5), "event-free", cex = 0.95, col = INK)
  text(8.4, mid(4, 8), "dead", cex = 0.95, col = "#ffffff", font = 2)
  text(9.9, mid(2, 9) , sprintf("MI %.1f%%", tr[11, 2]), cex = 0.86, col = INK, adj = 1)
  text(9.9, mid(3, 9) + 2.6, sprintf("stroke %.1f%%", tr[11, 3]), cex = 0.86, col = INK, adj = 1)

  mtext(c("Amlodipine + benazepril", "Hydrochlorothiazide + benazepril")[i],
        side = 3, line = 0.6, adj = 0, cex = 1.02, col = ARM[[a]], font = 2)
}
mtext("Where the cohort is, cycle by cycle", side = 3, outer = TRUE,
      line = 3.1, adj = 0, cex = 1.34, font = 2, col = INK)
mtext("The model as published. Reproduces Figures 2 and 3 of the paper; the cycle-10 split is stated in its Results text.",
      side = 3, outer = TRUE, line = 1.2, adj = 0, cex = 0.98, col = MUTED)
mtext("model cycle (years)", side = 1, outer = TRUE, line = 2.0, cex = 0.98, col = MUTED)
mtext("Independent rebuild in R from the transition matrix in Table 6.",
      side = 1, outer = TRUE, line = 3.2, adj = 0, cex = 0.8, col = MUTED)
invisible(dev.off())
cat("visuals/cohort_trace.png written\n")

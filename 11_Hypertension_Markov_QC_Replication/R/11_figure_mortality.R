# ===========================================================================
# 11_figure_mortality.R  ·  the case's main visual
#
# The model can be asked a question with a known answer: what mortality does
# it produce over the trial's own length? Everything to the right of the
# trial's follow-up is extrapolation; everything to the left can be refereed.
#
# Run:  Rscript R/11_figure_mortality.R
# ===========================================================================
# Base R writes non-ASCII to the graphics device as <U+XXXX> unless the
# session is in a UTF-8 locale, and this machine's R defaults to C.
Sys.setlocale("LC_CTYPE", "en_US.UTF-8")
source("R/01_markov_engine.R")

TRIAL <- list(
  amlodipine = c(death = 0.041, mi = 0.022, stroke = 0.019, months = 35.7),
  hctz       = c(death = 0.045, mi = 0.028, stroke = 0.023, months = 35.6))

corr_tpm <- function(a) {
  t <- TRIAL[[a]]
  mi <- 1 - (1 - t[["mi"]])^(12 / t[["months"]])
  st <- 1 - (1 - t[["stroke"]])^(12 / t[["months"]])
  dt <- 1 - (1 - t[["death"]])^(12 / t[["months"]])
  ed <- dt - mi * 0.0611 - st * 0.2381
  c(EE = 1 - mi - st - ed, EM = mi, ES = st, ED = ed,
    MM = 0.9389, MD = 0.0611, SS = 0.7619, SD = 0.2381)
}
dead <- function(p) {
  m <- make_tpm(p)
  tr <- matrix(0, 11, 4, dimnames = list(0:10, STATES)); tr[1, "EventFree"] <- 1
  for (t in 1:10) tr[t + 1, ] <- tr[t, ] %*% m
  100 * tr[, "Dead"]
}

# Colour convention, used throughout the case: hue = arm, line style = version.
ARM  <- c(amlodipine = "#2a78d6", hctz = "#eb6834")
INK  <- "#1f2937"; MUTED <- "#6b7280"; GRID <- "#e8e8e6"; SURF <- "#fcfcfb"

png("visuals/mortality_validity.png", width = 2400, height = 1150, res = 200)
par(mfrow = c(1, 2), oma = c(4.4, 4.8, 5.6, 1.0), bg = SURF)

for (i in seq_along(TRIAL)) {
  a  <- names(TRIAL)[i]
  yr <- TRIAL[[a]][["months"]] / 12
  pu <- dead(TPM_PUBLISHED[[a]]); co <- dead(corr_tpm(a))
  obs <- 100 * TRIAL[[a]][["death"]]

  par(mar = c(0.4, if (i == 1) 0.4 else 3.0, 2.6, if (i == 1) 3.0 else 0.4))
  plot(NA, xlim = c(0, 10.5), ylim = c(0, 47), axes = FALSE, xlab = "", ylab = "",
       xaxs = "i", yaxs = "i")

  # the only stretch the trial can referee; everything right of it is extrapolation
  rect(0, 0, yr, 47, col = "#f1f1ee", border = NA)
  segments(yr, 0, yr, 41.4, col = "#c9c9c4", lwd = 1, lty = 2)
  text(yr / 2, 43.6, "trial follow-up", col = MUTED, cex = 0.8)
  text(yr + 0.22, 43.6, "extrapolation", col = MUTED, cex = 0.8, adj = 0)

  abline(h = seq(0, 40, 10), col = GRID, lwd = 1)
  axis(1, at = 0:10, labels = 0:10, tick = FALSE, line = -0.9,
       cex.axis = 0.92, col.axis = MUTED)
  if (i == 1) axis(2, at = seq(0, 40, 10), labels = paste0(seq(0, 40, 10), "%"),
                   tick = FALSE, las = 1, line = -0.6, cex.axis = 0.92, col.axis = MUTED)

  cl <- ARM[[a]]
  lines(0:10, pu, col = cl, lwd = 2.8, lty = 1)
  lines(0:10, co, col = cl, lwd = 2.5, lty = 2)

  # direct labels beside their own curve; the chip carries the line style, so
  # the two versions are told apart without relying on colour
  lab <- function(x, y, txt, lty) {
    segments(x - 0.62, y, x + 0.18, y, col = cl, lwd = 2.5, lty = lty)
    text(x + 0.40, y, txt, adj = 0, cex = 0.94, col = INK)
  }
  lab(4.60, pu[6] + 5.2, "as published", 1)
  lab(4.60, co[6] - 3.4, "annualised over 36 months", 2)

  text(10, pu[11] + 2.6, sprintf("%.1f%%", pu[11]), cex = 0.94, font = 2, col = INK)
  text(10, co[11] + 2.6, sprintf("%.1f%%", co[11]), cex = 0.94, font = 2, col = INK)

  # the referee, drawn last so it sits above both curves
  segments(yr, obs, yr, pu[4], col = INK, lwd = 1.2)
  segments(yr - 0.09, c(obs, pu[4]), yr + 0.09, c(obs, pu[4]), col = INK, lwd = 1.2)
  text(yr - 0.22, (obs + pu[4]) / 2, sprintf("%.1f\u00d7", pu[4] / obs),
       adj = 1, cex = 1.02, col = INK, font = 2)
  points(yr, obs, pch = 21, bg = INK, col = SURF, cex = 1.6, lwd = 2.6)
  text(yr + 0.26, obs - 2.4, sprintf("trial observed  %.1f%%", obs),
       adj = 0, cex = 0.9, col = INK)

  mtext(c("Amlodipine + benazepril", "Hydrochlorothiazide + benazepril")[i],
        side = 3, line = 0.6, adj = 0, cex = 1.02, col = INK, font = 2)
}

mtext("Cumulative all-cause death in the modelled cohort", side = 3, outer = TRUE,
      line = 3.1, adj = 0, cex = 1.34, font = 2, col = INK)
mtext(paste("The model runs at about 2.9 times the annual event rate the trial observed.",
            "At the one horizon the trial can referee, it sits 2.7 times above it."),
      side = 3, outer = TRUE, line = 1.2, adj = 0, cex = 0.98, col = MUTED)
mtext("model cycle (years)", side = 1, outer = TRUE, line = 2.0, cex = 0.98, col = MUTED)
mtext("Sources: Feng et al. 2023 Table 6; Jamerson et al. 2008 Table 2. Independent rebuild in R.",
      side = 1, outer = TRUE, line = 3.2, adj = 0, cex = 0.8, col = MUTED)
invisible(dev.off())
cat("visuals/mortality_validity.png written\n")

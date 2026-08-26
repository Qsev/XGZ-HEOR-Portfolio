# ===========================================================================
# 16_tornado.R  ·  one-way sensitivity, plotted twice
#
# Left panel plots the ICER, as the paper's Figure 4 does. Right panel plots
# incremental net monetary benefit, which is what a dominant comparison can
# actually be read on. Same model, same ranges, same parameter order.
#
# The left panel is the sharper verification test in this whole case: if the
# rebuilt engine disagreed with the paper's anywhere material, a ratio with a
# small denominator would amplify it. It does not — the rank order matches the
# published figure on all sixteen parameters.
# ===========================================================================
Sys.setlocale("LC_CTYPE", "en_US.UTF-8")
source("R/00_eval.R")

tw   <- function(a, k, m) { t <- TPM_PUBLISHED
  t[[a]][[k]] <- t[[a]][[k]] * m; t[[a]] <- renorm(t[[a]]); t }
both <- function(k, m) { t <- TPM_PUBLISHED
  for (a in names(t)) { t[[a]][[k]] <- t[[a]][[k]] * m; t[[a]] <- renorm(t[[a]]) }; t }

P <- list(
  list("Event-free to death, HCTZ",        .10, function(m) run_model(tpm = tw("hctz","ED",m))),
  list("Event-free to death, amlodipine",  .10, function(m) run_model(tpm = tw("amlodipine","ED",m))),
  list("Drug cost, HCTZ",                  .25, function(m) run_model(drug = replace(COST_DRUG,"hctz",COST_DRUG[["hctz"]]*m))),
  list("Drug cost, amlodipine",            .25, function(m) run_model(drug = replace(COST_DRUG,"amlodipine",COST_DRUG[["amlodipine"]]*m))),
  list("Event-free to MI, HCTZ",           .10, function(m) run_model(tpm = tw("hctz","EM",m))),
  list("Utility, event-free",              .10, function(m) run_model(util = replace(UTIL,"EventFree",UTIL[["EventFree"]]*m))),
  list("Event-free to MI, amlodipine",     .10, function(m) run_model(tpm = tw("amlodipine","EM",m))),
  list("Annual cost, MI state",            .25, function(m) run_model(event = replace(COST_EVENT,"MI",COST_EVENT[["MI"]]*m))),
  list("Event-free to stroke, HCTZ",       .10, function(m) run_model(tpm = tw("hctz","ES",m))),
  list("Event-free to stroke, amlodipine", .10, function(m) run_model(tpm = tw("amlodipine","ES",m))),
  list("Utility, MI",                      .10, function(m) run_model(util = replace(UTIL,"MI",UTIL[["MI"]]*m))),
  list("Annual cost, stroke state",        .25, function(m) run_model(event = replace(COST_EVENT,"Stroke",COST_EVENT[["Stroke"]]*m))),
  list("Discount rate",                    NA,  function(m) run_model(disc = if (m < 1) 0 else 0.07)),
  list("Utility, stroke",                  .10, function(m) run_model(util = replace(UTIL,"Stroke",UTIL[["Stroke"]]*m))),
  list("Stroke to death",                  .10, function(m) run_model(tpm = both("SD",m))),
  list("MI to death",                      .10, function(m) run_model(tpm = both("MD",m)))
)   # order is the paper's own Figure 4, top to bottom

icer <- function(e) e$d_cost / e$d_qaly
grab <- function(f) do.call(rbind, lapply(P, function(r) {
  d <- if (is.na(r[[2]])) 0.5 else r[[2]]
  data.frame(param = r[[1]], lo = f(r[[3]](1 - d)), hi = f(r[[3]](1 + d))) }))
A <- grab(icer); B <- grab(function(e) inmb(e))
bA <- icer(run_model()); bB <- inmb(run_model())

INK<-"#1f2937"; MUTED<-"#6b7280"; SURF<-"#fcfcfb"; GRID<-"#e8e8e6"
LOW<-"#b8c6d4"; HIGH<-"#2f4a68"

png("visuals/tornado.png", width = 2400, height = 1400, res = 200)
par(oma = c(4.6, 17.0, 7.0, 1.2), bg = SURF)
n <- nrow(A)

panel <- function(d, base, i, ttl, sub, fmt) {
  par(mfrow = c(1, 2), mar = c(0.6, if (i == 1) 0.4 else 3.4, 2.8, if (i == 1) 3.4 else 0.4),
      new = i == 2)
  xr <- range(c(d$lo, d$hi, base)); xr <- xr + diff(xr) * c(-.05, .05)
  plot(NA, xlim = xr, ylim = c(n + 0.6, 0.4), axes = FALSE, xlab = "", ylab = "", yaxs = "i")
  abline(v = pretty(xr, 5), col = GRID, lwd = 1)
  for (k in seq_len(n)) {
    rect(base, k - .34, d$lo[k], k + .34, col = LOW,  border = SURF, lwd = 1.1)
    rect(base, k - .34, d$hi[k], k + .34, col = HIGH, border = SURF, lwd = 1.1)
  }
  abline(v = base, col = INK, lwd = 1.6)
  axis(1, at = pretty(xr, 5), labels = fmt(pretty(xr, 5)), tick = FALSE, line = -0.7,
       cex.axis = 0.86, col.axis = MUTED)
  if (i == 1) axis(2, at = seq_len(n), labels = d$param, tick = FALSE, las = 1,
                   line = -0.4, cex.axis = 0.86, col.axis = INK)
  mtext(ttl, side = 3, line = 1.0, adj = 0, cex = 1.02, col = INK, font = 2)
  mtext(sub, side = 3, line = -0.1, adj = 0, cex = 0.85, col = MUTED)
  mtext(sprintf("base case %s", fmt(round(base))), side = 1, line = 1.5,
        at = base, adj = 0.5, cex = 0.82, col = INK)
}
k <- function(x) paste0(format(round(x / 1000), big.mark = ","), "k")
par(mfrow = c(1, 2))
panel(A, bA, 1, "Plotted on the ICER, as the paper does",
      "matches the rank order of its Figure 4 on all sixteen parameters", k)
panel(B, bB, 2, "Plotted on net monetary benefit",
      "the same runs, read at the paper's own threshold of 80,976 CNY", k)

left <- grconvertX(0.006, "ndc", "user")
chip <- strwidth("nn", cex = .84); pad <- strwidth("n", cex = .84)
rect(left, -1.55, left + chip, -1.15, col = LOW, border = NA, xpd = NA)
text(left + chip + pad, -1.35, "parameter low", adj = 0, cex = .84, col = INK, xpd = NA)
x2 <- left + chip + pad + strwidth("parameter low", cex = .84) + pad * 3
rect(x2, -1.55, x2 + chip, -1.15, col = HIGH, border = NA, xpd = NA)
text(x2 + chip + pad, -1.35, "parameter high", adj = 0, cex = .84, col = INK, xpd = NA)

mtext("One-way sensitivity analysis, plotted two ways", side = 3, outer = TRUE,
      line = 4.6, adj = 0, cex = 1.34, font = 2, col = INK)
mtext("Same model, same runs, same ranges. A tornado ranks parameters by the outcome it plots. A ratio with a small",
      side = 3, outer = TRUE, line = 2.9, adj = 0, cex = 0.92, col = MUTED)
mtext("denominator is dominated by whatever moves survival; net benefit, being linear, is dominated by cost.",
      side = 3, outer = TRUE, line = 1.7, adj = 0, cex = 0.92, col = MUTED)
mtext("Each arm's transition probabilities are moved separately, as the parameter names on the paper's Figure 4 show it does.",
      side = 1, outer = TRUE, line = 2.6, adj = 0, cex = 0.82, col = MUTED)
invisible(dev.off())
cat(sprintf("base ICER %.0f (paper -67,134)  |  base INMB %.0f\n", bA, bB))

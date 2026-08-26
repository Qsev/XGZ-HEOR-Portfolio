# ---------------------------------------------------------------------------
# 08_discount_recovery.R
# The paper never states a base-case discount rate. Five percent appears only
# in the sensitivity-analysis sentence. Sweep the rate and see which value the
# published totals actually imply.
# ---------------------------------------------------------------------------
source("R/01_markov_engine.R")

rates <- c(0, 0.01, 0.02, 0.03, 0.035, 0.04, 0.05, 0.06, 0.07)
out <- do.call(rbind, lapply(rates, function(r) {
  x <- run_both(discount = r, drug_in = "event_free", event_cost = "prevalent")
  x <- x[match(TARGET$arm, x$arm), ]
  data.frame(rate = sprintf("%.1f%%", 100 * r),
             cost_a = x$cost[1], cost_h = x$cost[2],
             qaly_a = x$qaly[1], qaly_h = x$qaly[2],
             err = max(abs(100 * (x$cost - TARGET$cost) / TARGET$cost),
                       abs(100 * (x$qaly - TARGET$qaly) / TARGET$qaly)))
}))
cat("\n=== which discount rate reproduces Table 7? ===\n\n")
print(format(out, digits = 6), row.names = FALSE)
cat("\npublished: cost 66196.97 / 74588.50   QALY 6.59 / 6.46\n")

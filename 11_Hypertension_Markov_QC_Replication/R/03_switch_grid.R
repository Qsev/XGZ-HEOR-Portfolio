# ---------------------------------------------------------------------------
# 03_switch_grid.R
#
# The base case reproduces QALYs but not costs. The paper does not state its
# cycle-payoff timing, its discount indexing, or which states carry which cost,
# so the implementation has to be recovered rather than assumed. This sweeps
# every combination of those choices and scores each against Table 6.
# ---------------------------------------------------------------------------

source("R/01_markov_engine.R")

grid <- expand.grid(
  payoff_at     = c("start", "end", "hcc"),
  discount_from = c(0, 1),
  drug_in       = c("alive", "event_free"),
  event_cost    = c("incident", "prevalent"),
  normalise     = c(FALSE, TRUE),
  stringsAsFactors = FALSE
)

score <- function(i) {
  g <- grid[i, ]
  r <- run_both(payoff_at = g$payoff_at, discount_from = g$discount_from,
                drug_in = g$drug_in, event_cost = g$event_cost,
                normalise = g$normalise)
  r <- r[match(TARGET$arm, r$arm), ]
  data.frame(
    g,
    cost_a = r$cost[1], cost_h = r$cost[2],
    qaly_a = r$qaly[1], qaly_h = r$qaly[2],
    err_cost = max(abs(100 * (r$cost - TARGET$cost) / TARGET$cost)),
    err_qaly = max(abs(100 * (r$qaly - TARGET$qaly) / TARGET$qaly))
  )
}

out <- do.call(rbind, lapply(seq_len(nrow(grid)), score))
out$err_max <- pmax(out$err_cost, out$err_qaly)
out <- out[order(out$err_max), ]

cat("\n=== all 48 implementations, ranked by worst-cell error ===\n\n")
print(format(out[, c("payoff_at", "discount_from", "drug_in", "event_cost",
                     "normalise", "cost_a", "cost_h", "qaly_a", "qaly_h",
                     "err_cost", "err_qaly", "err_max")],
             digits = 5), row.names = FALSE)

write.csv(out, "data/switch_grid.csv", row.names = FALSE)
cat("\nTarget:  cost 66196.97 / 74588.50   QALY 6.59 / 6.46\n")

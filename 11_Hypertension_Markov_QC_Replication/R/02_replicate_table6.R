# ---------------------------------------------------------------------------
# 02_replicate_table6.R
#
# Step 1 of the replication: run the most literal reading of the paper and
# compare against Table 6. No half-cycle correction (the paper does not
# mention one), transition matrix left exactly as printed.
# ---------------------------------------------------------------------------

source("R/01_markov_engine.R")

base <- run_both(payoff_at = "start", discount_from = 0,
                 drug_in = "alive", event_cost = "incident",
                 normalise = FALSE)

cmp <- merge(TARGET, base, by = "arm", suffixes = c("_pub", "_rep"))
cmp <- cmp[match(c("amlodipine", "hctz"), cmp$arm), ]

cmp$cost_diff_pct <- 100 * (cmp$cost_rep - cmp$cost_pub) / cmp$cost_pub
cmp$qaly_diff_pct <- 100 * (cmp$qaly_rep - cmp$qaly_pub) / cmp$qaly_pub

cat("\n=== BASE CASE: most literal reading =====================\n")
print(format(cmp[, c("arm", "cost_pub", "cost_rep", "cost_diff_pct",
                     "qaly_pub", "qaly_rep", "qaly_diff_pct")],
             digits = 6), row.names = FALSE)

cat("\n--- component split, amlodipine -------------------------\n")
r <- run_markov("amlodipine")
print(round(r$cycle, 5), row.names = FALSE)

cat("\n--- Markov trace, amlodipine ----------------------------\n")
print(round(r$trace, 5))

cat("\n--- discounted life-years -------------------------------\n")
for (a in c("amlodipine", "hctz")) {
  x <- run_markov(a)
  cat(sprintf("%-12s LY(disc) = %.4f   QALY(disc) = %.4f   cost = %.2f\n",
              a, x$ly, x$qaly, x$cost))
}

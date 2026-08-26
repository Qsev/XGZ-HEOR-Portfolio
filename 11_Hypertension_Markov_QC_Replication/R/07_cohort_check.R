# ---------------------------------------------------------------------------
# 07_cohort_check.R
# The Results text reports the cycle-10 state distribution for both cohorts.
# That is an independent check on the transition engine: it constrains the
# trace without going through any cost or utility value.
# ---------------------------------------------------------------------------
source("R/01_markov_engine.R")

published <- data.frame(
  arm    = c("amlodipine", "hctz"),
  dead   = c(38.0, 41.0),
  stroke = c(4.5, 5.1),
  mi     = c(11.6, 13.8)
)

rows <- lapply(c("amlodipine", "hctz"), function(a) {
  tr <- run_markov(a)$trace
  data.frame(arm = a,
             dead = 100 * tr["10", "Dead"],
             stroke = 100 * tr["10", "Stroke"],
             mi = 100 * tr["10", "MI"])
})
rebuilt <- do.call(rbind, rows)

cat("\n=== cycle-10 state distribution: paper text vs rebuild ===\n\n")
for (i in 1:2) {
  cat(sprintf("%-11s  published  dead %4.1f%%  stroke %4.1f%%  MI %4.1f%%\n",
              published$arm[i], published$dead[i], published$stroke[i], published$mi[i]))
  cat(sprintf("%-11s  rebuilt    dead %4.1f%%  stroke %4.1f%%  MI %4.1f%%\n\n",
              "", rebuilt$dead[i], rebuilt$stroke[i], rebuilt$mi[i]))
}
cat("full HCTZ trace:\n")
print(round(run_markov("hctz")$trace, 5))

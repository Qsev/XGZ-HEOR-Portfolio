# ---------------------------------------------------------------------------
# 06_rounding_envelope.R
#
# Table 5 prints transition probabilities to four decimals, and the event-free
# row sums to 1.0001 (amlodipine) / 0.9999 (HCTZ) — so the printed matrix is
# not the matrix that was run. Sample the set of true matrices consistent with
# those printed digits AND with rows summing to one, and see how wide the
# resulting cost and QALY are. If the residual falls inside that envelope, the
# rebuild agrees with the paper to the precision the paper published.
# ---------------------------------------------------------------------------
source("R/01_markov_engine.R")
set.seed(20260826)

HALF <- 0.00005   # rounding half-width at four decimals

sample_row <- function(p) {          # p: named vector, must sum to 1 afterwards
  repeat {
    v <- p + runif(length(p), -HALF, HALF)
    v[length(v)] <- 1 - sum(v[-length(v)])
    if (abs(v[length(v)] - p[length(p)]) <= HALF) return(v)
  }
}

sample_tpm <- function(arm) {
  p <- TPM_PUBLISHED[[arm]]
  e <- sample_row(c(p[["EE"]], p[["EM"]], p[["ES"]], p[["ED"]]))
  m <- sample_row(c(p[["MM"]], p[["MD"]]))
  s <- sample_row(c(p[["SS"]], p[["SD"]]))
  c(EE = e[1], EM = e[2], ES = e[3], ED = e[4],
    MM = m[1], MD = m[2], SS = s[1], SD = s[2])
}

run_from <- function(p, arm) {
  m  <- make_tpm(p)
  tr <- matrix(0, N_CYCLES + 1, 4, dimnames = list(0:N_CYCLES, STATES))
  tr[1, "EventFree"] <- 1
  for (t in 1:N_CYCLES) tr[t + 1, ] <- tr[t, ] %*% m
  st <- tr[1:N_CYCLES, , drop = FALSE]
  df <- 1 / (1 + DISCOUNT)^(seq_len(N_CYCLES) - 1)
  c(cost = sum(st[, "EventFree"] * df) * COST_DRUG[[arm]] +
           sum(st[, "MI"] * df) * COST_EVENT[["MI"]] +
           sum(st[, "Stroke"] * df) * COST_EVENT[["Stroke"]],
    qaly = sum(as.vector(st %*% UTIL[STATES]) * df))
}

N <- 20000
sim <- lapply(c("amlodipine", "hctz"), function(a)
  t(replicate(N, run_from(sample_tpm(a), a))))
names(sim) <- c("amlodipine", "hctz")

cat("\n=== envelope implied by four-decimal rounding (", N, "draws) ===\n\n", sep = "")
for (i in seq_along(sim)) {
  a <- names(sim)[i]
  q <- apply(sim[[a]], 2, quantile, c(0, 0.025, 0.5, 0.975, 1))
  cat(sprintf("%-11s cost  min %.2f  2.5%% %.2f  med %.2f  97.5%% %.2f  max %.2f\n",
              a, q[1,1], q[2,1], q[3,1], q[4,1], q[5,1]))
  cat(sprintf("%-11s       published %.2f   %s\n", "",
              TARGET$cost[i],
              if (TARGET$cost[i] >= q[1,1] && TARGET$cost[i] <= q[5,1])
                "INSIDE envelope" else "OUTSIDE envelope"))
  cat(sprintf("%-11s qaly  min %.4f  med %.4f  max %.4f   published %.2f\n\n",
              "", q[1,2], q[3,2], q[5,2], TARGET$qaly[i]))
}

w <- sapply(sim, function(x) diff(range(x[, "cost"])))
cat("cost envelope width:  amlodipine", round(w[1], 1),
    " HCTZ", round(w[2], 1), "CNY\n")
cat("residual to explain:  amlodipine 255.3   HCTZ -72.8 CNY\n")

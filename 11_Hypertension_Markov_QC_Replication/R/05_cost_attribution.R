# ---------------------------------------------------------------------------
# 05_cost_attribution.R
#
# QALYs pin the cycle timing: only payoff-at-cycle-start with the first cycle
# undiscounted reproduces 6.59 / 6.46. Holding that fixed, enumerate every way
# the three unit costs could be attached to states and events.
# ---------------------------------------------------------------------------
source("R/01_markov_engine.R")

basis <- function(arm) {
  m  <- make_tpm(TPM_PUBLISHED[[arm]])
  tr <- matrix(0, N_CYCLES + 1, 4, dimnames = list(0:N_CYCLES, STATES))
  tr[1, "EventFree"] <- 1
  for (t in 1:N_CYCLES) tr[t + 1, ] <- tr[t, ] %*% m
  st <- tr[1:N_CYCLES, , drop = FALSE]
  df <- 1 / (1 + DISCOUNT)^(seq_len(N_CYCLES) - 1)
  c(EF = sum(st[, "EventFree"] * df),
    MI = sum(st[, "MI"] * df),
    S  = sum(st[, "Stroke"] * df),
    MIi = sum(st[, "EventFree"] * m["EventFree", "MI"] * df),
    Si  = sum(st[, "EventFree"] * m["EventFree", "Stroke"] * df))
}
b <- list(amlodipine = basis("amlodipine"), hctz = basis("hctz"))

drug_sets <- list(EF = c("EF"), `EF+MI` = c("EF", "MI"),
                  `EF+S` = c("EF", "S"), all_alive = c("EF", "MI", "S"))
acct <- list(incident = "i", prevalent = "p", both = "b")

pick <- function(bb, state, how) {
  inc <- bb[[paste0(substr(state, 1, 2), "i")]]
  switch(how, i = inc, p = bb[[state]], b = inc + bb[[state]])
}

res <- list()
for (ds in names(drug_sets)) for (am in names(acct)) for (as_ in names(acct)) {
  cost <- sapply(c("amlodipine", "hctz"), function(a) {
    bb <- b[[a]]
    sum(bb[drug_sets[[ds]]]) * COST_DRUG[[a]] +
      COST_EVENT[["MI"]]     * pick(bb, "MI", acct[[am]]) +
      COST_EVENT[["Stroke"]] * pick(bb, "S",  acct[[as_]])
  })
  res[[length(res) + 1]] <- data.frame(
    drug = ds, mi_cost = am, stroke_cost = as_,
    cost_a = cost[1], cost_h = cost[2],
    err_a = 100 * (cost[1] - TARGET$cost[1]) / TARGET$cost[1],
    err_h = 100 * (cost[2] - TARGET$cost[2]) / TARGET$cost[2])
}
out <- do.call(rbind, res)
out$err_max <- pmax(abs(out$err_a), abs(out$err_h))
out <- out[order(out$err_max), ]

cat("\n=== 36 cost attributions, ranked (QALY timing held at start/undisc-first) ===\n\n")
print(format(head(out, 12), digits = 5), row.names = FALSE)
cat("\nTarget cost: 66196.97 (amlodipine) / 74588.50 (HCTZ)\n")
write.csv(out, "data/cost_attribution.csv", row.names = FALSE)

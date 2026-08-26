# ---------------------------------------------------------------------------
# 13_cost_composition.R
#
# How much of the total cost is the annual event-state charge, and what happens
# to the comparison if those figures are first-year costs rather than annual
# ones. The paper's source for them could not be obtained, so this is a
# structural sensitivity, not a correction.
# ---------------------------------------------------------------------------
source("R/01_markov_engine.R")

sy <- function(arm) {
  m  <- make_tpm(TPM_PUBLISHED[[arm]])
  tr <- matrix(0, 11, 4, dimnames = list(0:10, STATES)); tr[1, "EventFree"] <- 1
  for (t in 1:10) tr[t + 1, ] <- tr[t, ] %*% m
  st <- tr[1:10, , drop = FALSE]; d <- 1 / (1 + DISCOUNT)^(0:9)
  c(EF = sum(st[, "EventFree"] * d), MI = sum(st[, "MI"] * d),
    S  = sum(st[, "Stroke"] * d),
    MIi = sum(st[, "EventFree"] * m["EventFree", "MI"] * d),
    Si  = sum(st[, "EventFree"] * m["EventFree", "Stroke"] * d))
}
b <- lapply(c(amlodipine = "amlodipine", hctz = "hctz"), sy)

cat("=== what the total cost is made of (as published, annual event costs) ===\n\n")
comp <- do.call(rbind, lapply(names(b), function(a) {
  z <- b[[a]]
  drug <- COST_DRUG[[a]] * z[["EF"]]
  mi   <- COST_EVENT[["MI"]] * z[["MI"]]
  st   <- COST_EVENT[["Stroke"]] * z[["S"]]
  tot  <- drug + mi + st
  data.frame(arm = a, drug = drug, mi = mi, stroke = st, total = tot,
             drug_pct = 100*drug/tot, event_pct = 100*(mi+st)/tot)
}))
print(format(comp, digits = 6), row.names = FALSE)

cat("\n=== if the event figures are one-off first-year costs instead ===\n\n")
alt <- do.call(rbind, lapply(names(b), function(a) {
  z <- b[[a]]
  tot <- COST_DRUG[[a]] * z[["EF"]] +
         COST_EVENT[["MI"]] * z[["MIi"]] + COST_EVENT[["Stroke"]] * z[["Si"]]
  data.frame(arm = a, total = tot)
}))
print(format(alt, digits = 6), row.names = FALSE)

cat(sprintf("\nincremental cost, as published        %8.0f CNY\n", diff(comp$total)))
cat(sprintf("incremental cost, event costs one-off %8.0f CNY  (%.0f%% of the published gap)\n",
            diff(alt$total), 100 * diff(alt$total) / diff(comp$total)))
cat(sprintf("\nMI-state years accrued per patient:   amlodipine %.2f   HCTZ %.2f\n",
            b$amlodipine[["MI"]], b$hctz[["MI"]]))
cat(sprintf("so the MI charge of %.1f CNY is levied, on average, %.1f times over\n",
            COST_EVENT[["MI"]], b$amlodipine[["MI"]] / b$amlodipine[["MIi"]]))

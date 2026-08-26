# ---------------------------------------------------------------------------
# 04_decompose.R
# The grid points to one implementation. Decompose it into its cost components
# and quantify what is left over, so the residual can be named rather than
# absorbed into a "close enough".
# ---------------------------------------------------------------------------
source("R/01_markov_engine.R")

basis <- function(arm) {
  m <- make_tpm(TPM_PUBLISHED[[arm]])
  tr <- matrix(0, N_CYCLES + 1, 4, dimnames = list(0:N_CYCLES, STATES))
  tr[1, "EventFree"] <- 1
  for (t in 1:N_CYCLES) tr[t + 1, ] <- tr[t, ] %*% m
  st <- tr[1:N_CYCLES, , drop = FALSE]
  df <- 1 / (1 + DISCOUNT)^(seq_len(N_CYCLES) - 1)
  c(EF_yrs   = sum(st[, "EventFree"] * df),
    MI_yrs   = sum(st[, "MI"] * df),
    S_yrs    = sum(st[, "Stroke"] * df),
    MI_inc   = sum(st[, "EventFree"] * m["EventFree", "MI"] * df),
    S_inc    = sum(st[, "EventFree"] * m["EventFree", "Stroke"] * df))
}

b <- rbind(amlodipine = basis("amlodipine"), hctz = basis("hctz"))
cat("\n=== discounted state-years / incident cases (per patient) ===\n")
print(round(b, 6))

drug <- COST_DRUG[c("amlodipine", "hctz")]
recon <- data.frame(
  arm       = rownames(b),
  drug_EF   = drug * b[, "EF_yrs"],
  MI_prev   = COST_EVENT[["MI"]]     * b[, "MI_yrs"],
  S_prev    = COST_EVENT[["Stroke"]] * b[, "S_yrs"],
  total     = drug * b[, "EF_yrs"] +
              COST_EVENT[["MI"]] * b[, "MI_yrs"] +
              COST_EVENT[["Stroke"]] * b[, "S_yrs"],
  published = TARGET$cost
)
recon$residual     <- recon$total - recon$published
recon$residual_pct <- 100 * recon$residual / recon$published

cat("\n=== winning implementation: drug in EventFree only, event costs annual ===\n")
print(format(recon, digits = 7), row.names = FALSE)

cat("\n=== incremental ===\n")
cat(sprintf("rebuilt    incremental cost = %10.2f   incremental QALY = %+.4f\n",
            diff(recon$total),
            diff(run_both(drug_in = "event_free", event_cost = "prevalent")$qaly)))
cat(sprintf("published  incremental cost = %10.2f   incremental QALY = %+.4f\n",
            diff(TARGET$cost), diff(TARGET$qaly)))

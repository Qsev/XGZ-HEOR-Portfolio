# ---------------------------------------------------------------------------
# 10_load_bearing.R
#
# Two questions the checklist needs numbers for.
#  (1) The cost result rests on hydrochlorothiazide being the dearer of two
#      generics. How far would that price have to fall to overturn it?
#  (2) External validity: what mortality does the model imply, as published
#      and after correcting the annualisation, against what the trial observed?
# ---------------------------------------------------------------------------
source("R/01_markov_engine.R")

state_years <- function(p) {
  m  <- make_tpm(p)
  tr <- matrix(0, N_CYCLES + 1, 4, dimnames = list(0:N_CYCLES, STATES))
  tr[1, "EventFree"] <- 1
  for (t in 1:N_CYCLES) tr[t + 1, ] <- tr[t, ] %*% m
  st <- tr[1:N_CYCLES, , drop = FALSE]
  df <- 1 / (1 + DISCOUNT)^(seq_len(N_CYCLES) - 1)
  list(EF = sum(st[, "EventFree"] * df), MI = sum(st[, "MI"] * df),
       S = sum(st[, "Stroke"] * df), trace = tr)
}

y <- lapply(TPM_PUBLISHED, state_years)
event_cost <- function(z) COST_EVENT[["MI"]] * z$MI + COST_EVENT[["Stroke"]] * z$S
cost_a <- COST_DRUG[["amlodipine"]] * y$amlodipine$EF + event_cost(y$amlodipine)

# --- (1) the price at which the two arms cost the same ---------------------
p_switch <- (cost_a - event_cost(y$hctz)) / y$hctz$EF

cat("=== what would overturn the cost result? ===\n")
cat(sprintf("amlodipine price                       %8.2f CNY/year\n", COST_DRUG[["amlodipine"]]))
cat(sprintf("HCTZ price as published                %8.2f CNY/year\n", COST_DRUG[["hctz"]]))
cat(sprintf("HCTZ price at which arms cost the same  %8.2f CNY/year\n", p_switch))
cat(sprintf("required fall                          %8.2f CNY/year  (%.1f%%)\n",
            COST_DRUG[["hctz"]] - p_switch,
            100 * (COST_DRUG[["hctz"]] - p_switch) / COST_DRUG[["hctz"]]))
cat(sprintf("note: the threshold sits %.1f%% BELOW the amlodipine price, so the arms\n",
            100 * (COST_DRUG[["amlodipine"]] - p_switch) / COST_DRUG[["amlodipine"]]))
cat("      would have to cost the same only after HCTZ became the cheaper drug\n")

# --- (2) mortality: model vs trial -----------------------------------------
TRIAL <- list(amlodipine = c(death = 0.041, mi = 0.022, stroke = 0.019, months = 35.7),
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

cat("\n=== cumulative mortality: model vs what ACCOMPLISH observed ===\n")
cat("                 cycle 3 (~trial length)      cycle 10\n")
for (a in c("amlodipine", "hctz")) {
  pub <- state_years(TPM_PUBLISHED[[a]])$trace
  cor <- state_years(corr_tpm(a))$trace
  cat(sprintf("%-11s pub %5.1f%%  corr %5.1f%%   |  pub %5.1f%%  corr %5.1f%%   trial %.1f%%\n",
              a, 100 * pub["3", "Dead"], 100 * cor["3", "Dead"],
              100 * pub["10", "Dead"], 100 * cor["10", "Dead"],
              100 * TRIAL[[a]][["death"]]))
}

# ---------------------------------------------------------------------------
# 00_eval.R  ·  a parameterised evaluator, for sensitivity work
#
# run_markov() reads the published inputs from the engine's globals. The
# sensitivity analyses need to move those inputs, so this takes them all as
# arguments instead. Same accounting as the recovered specification: drug cost
# only while event-free, event figures charged annually, payoffs at cycle start,
# first cycle undiscounted.
# ---------------------------------------------------------------------------
source("R/01_markov_engine.R")

run_model <- function(tpm = TPM_PUBLISHED, drug = COST_DRUG,
                     event = COST_EVENT, util = UTIL, disc = DISCOUNT) {
  out <- sapply(c("amlodipine", "hctz"), function(a) {
    m  <- make_tpm(tpm[[a]])
    tr <- matrix(0, 11, 4, dimnames = list(0:10, STATES)); tr[1, "EventFree"] <- 1
    for (t in 1:10) tr[t + 1, ] <- tr[t, ] %*% m
    st <- tr[1:10, , drop = FALSE]; d <- 1 / (1 + disc)^(0:9)
    c(cost = sum(st[, "EventFree"] * d) * drug[[a]] +
             sum(st[, "MI"] * d) * event[["MI"]] +
             sum(st[, "Stroke"] * d) * event[["Stroke"]],
      qaly = sum(as.vector(st %*% util[STATES]) * d))
  })
  # incremental of amlodipine relative to hydrochlorothiazide
  list(cost = out["cost", ], qaly = out["qaly", ],
       d_cost = out["cost", "amlodipine"] - out["cost", "hctz"],
       d_qaly = out["qaly", "amlodipine"] - out["qaly", "hctz"])
}

WTP <- 80976            # 1x GDP per capita, 2021 — the paper's own threshold
inmb <- function(e, wtp = WTP) wtp * e$d_qaly - e$d_cost

# beta parameters from a mean and a standard deviation
beta_ab <- function(m, s) {
  v <- min(s^2, m * (1 - m) * 0.999)
  a <- m * (m * (1 - m) / v - 1); c(a = a, b = a * (1 - m) / m)
}

# rescale the event-free row so it sums to one after a parameter is moved
renorm <- function(p) {
  s <- p[["EM"]] + p[["ES"]] + p[["ED"]]
  p[["EE"]] <- 1 - s
  p[["MM"]] <- 1 - p[["MD"]]; p[["SS"]] <- 1 - p[["SD"]]
  p
}

# --- ACCOMPLISH as reported, and the matrix implied by annualising it properly
# The trial percentages are cumulative over the follow-up actually observed.
# corr_tpm() spreads them across that period instead of treating them as annual.
TRIAL <- list(
  amlodipine = c(death = 0.041, mi = 0.022, stroke = 0.019, months = 35.7),
  hctz       = c(death = 0.045, mi = 0.028, stroke = 0.023, months = 35.6))

corr_tpm <- function(arm) {
  t  <- TRIAL[[arm]]
  ann <- function(p) 1 - (1 - p)^(12 / t[["months"]])
  mi <- ann(t[["mi"]]); st <- ann(t[["stroke"]])
  ed <- ann(t[["death"]]) - mi * 0.0611 - st * 0.2381
  c(EE = 1 - mi - st - ed, EM = mi, ES = st, ED = ed,
    MM = 0.9389, MD = 0.0611, SS = 0.7619, SD = 0.2381)
}

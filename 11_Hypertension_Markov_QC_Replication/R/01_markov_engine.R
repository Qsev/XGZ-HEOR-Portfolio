# ---------------------------------------------------------------------------
# 01_markov_engine.R
#
# Four-state annual Markov cohort engine for:
#   Feng et al. Pharmacoeconomic evaluation of stroke and myocardial infarction
#   prevention in hypertensive patients. J Int Med Res. 2023;51(12):1-15.
#
# States: 1 EventFree  2 MI (non-fatal)  3 Stroke (non-fatal)  4 Dead (absorbing)
#
# The engine is deliberately switched, not hard-wired. The paper does not state
# its cycle-payoff timing, discount indexing, or which states incur drug cost;
# each is an implementation choice that has to be recovered by testing, not
# assumed. Every switch defaults to the most literal reading of the paper.
# ---------------------------------------------------------------------------

STATES <- c("EventFree", "MI", "Stroke", "Dead")

# --- Inputs, exactly as printed in the paper -------------------------------

# Table 5. Row sums are 1.0001 (amlodipine) and 0.9999 (HCTZ) as published.
TPM_PUBLISHED <- list(
  amlodipine = c(EE = 0.9251, EM = 0.0218, ES = 0.0188, ED = 0.0344,
                 MM = 0.9389, MD = 0.0611,
                 SS = 0.7619, SD = 0.2381),
  hctz       = c(EE = 0.9127, EM = 0.0276, ES = 0.0227, ED = 0.0369,
                 MM = 0.9389, MD = 0.0611,
                 SS = 0.7619, SD = 0.2381)
)

COST_DRUG  <- c(amlodipine = 5494.53, hctz = 5926.76)   # CNY per year
COST_EVENT <- c(MI = 48874.2, Stroke = 28023.8)         # CNY, one-off
UTIL       <- c(EventFree = 0.98, MI = 0.87, Stroke = 0.77, Dead = 0)

N_CYCLES <- 10
DISCOUNT <- 0.05

# Table 6, the replication target.
TARGET <- data.frame(
  arm  = c("amlodipine", "hctz"),
  cost = c(66196.97, 74588.50),
  qaly = c(6.59, 6.46),
  cer  = c(10045.06, 11546.21)
)

# --- Engine ----------------------------------------------------------------

make_tpm <- function(p, normalise = FALSE) {
  m <- matrix(0, 4, 4, dimnames = list(STATES, STATES))
  m["EventFree", ] <- c(p[["EE"]], p[["EM"]], p[["ES"]], p[["ED"]])
  m["MI",        ] <- c(0, p[["MM"]], 0, p[["MD"]])
  m["Stroke",    ] <- c(0, 0, p[["SS"]], p[["SD"]])
  m["Dead",      ] <- c(0, 0, 0, 1)
  if (normalise) m <- m / rowSums(m)
  m
}

#' Run the cohort.
#'
#' @param payoff_at  "start" cycle payoffs use occupancy at cycle start;
#'                   "end"   use occupancy at cycle end;
#'                   "hcc"   half-cycle correction (trapezoidal mean of the two).
#' @param discount_from  0 = first cycle undiscounted; 1 = first cycle discounted.
#' @param drug_in    "alive" drug cost accrues in all three living states;
#'                   "event_free" drug cost accrues only while event-free.
#' @param event_cost "incident"  charged once, on transition into the state;
#'                   "prevalent" charged every cycle spent in the state.
run_markov <- function(arm,
                       n_cycles      = N_CYCLES,
                       discount      = DISCOUNT,
                       payoff_at     = "start",
                       discount_from = 0,
                       drug_in       = "alive",
                       event_cost    = "incident",
                       normalise     = FALSE) {

  m <- make_tpm(TPM_PUBLISHED[[arm]], normalise)

  # Markov trace: row t+1 is occupancy at the start of cycle t+1, t = 0..n
  trace <- matrix(0, n_cycles + 1, 4, dimnames = list(0:n_cycles, STATES))
  trace[1, "EventFree"] <- 1
  for (t in 1:n_cycles) trace[t + 1, ] <- trace[t, ] %*% m

  start <- trace[1:n_cycles, , drop = FALSE]
  end   <- trace[2:(n_cycles + 1), , drop = FALSE]
  occ <- switch(payoff_at,
                start = start,
                end   = end,
                hcc   = (start + end) / 2,
                stop("unknown payoff_at: ", payoff_at))

  # Incident events: people leaving EventFree into MI / Stroke during the cycle.
  incident_mi     <- start[, "EventFree"] * m["EventFree", "MI"]
  incident_stroke <- start[, "EventFree"] * m["EventFree", "Stroke"]

  drug_pop <- if (drug_in == "alive") rowSums(occ[, c("EventFree", "MI", "Stroke")])
              else occ[, "EventFree"]

  cost_cycle <- drug_pop * COST_DRUG[[arm]] +
    if (event_cost == "incident") {
      incident_mi * COST_EVENT[["MI"]] + incident_stroke * COST_EVENT[["Stroke"]]
    } else {
      occ[, "MI"] * COST_EVENT[["MI"]] + occ[, "Stroke"] * COST_EVENT[["Stroke"]]
    }

  qaly_cycle <- as.vector(occ %*% UTIL[STATES])
  ly_cycle   <- rowSums(occ[, c("EventFree", "MI", "Stroke")])

  t_idx <- seq_len(n_cycles) - 1 + discount_from
  df    <- 1 / (1 + discount)^t_idx

  list(
    arm   = arm,
    trace = trace,
    cycle = data.frame(cycle = seq_len(n_cycles), df = df,
                       cost = cost_cycle, qaly = qaly_cycle, ly = ly_cycle),
    cost  = sum(cost_cycle * df),
    qaly  = sum(qaly_cycle * df),
    ly    = sum(ly_cycle * df),
    cost_undisc = sum(cost_cycle),
    qaly_undisc = sum(qaly_cycle)
  )
}

#' Both arms under one set of switches, returned as a one-row-per-arm frame.
run_both <- function(...) {
  res <- lapply(c("amlodipine", "hctz"), function(a) {
    r <- run_markov(a, ...)
    data.frame(arm = a, cost = r$cost, qaly = r$qaly, cer = r$cost / r$qaly)
  })
  do.call(rbind, res)
}

# ---------------------------------------------------------------------------
# 09_annualisation.R
#
# Recover the derivation chain from ACCOMPLISH to Table 6, then re-run it with
# the observation period the trial actually had.
#
# ACCOMPLISH Table 2 (verified in the source PDF):
#   Death from any cause              236 (4.1%)   262 (4.5%)
#   Fatal and nonfatal MI             125 (2.2%)   159 (2.8%)
#   Fatal and nonfatal stroke         112 (1.9%)   133 (2.3%)
#   Mean follow-up 35.7 / 35.6 months
# ---------------------------------------------------------------------------
source("R/01_markov_engine.R")

TRIAL <- list(
  amlodipine = c(death = 0.041, mi = 0.022, stroke = 0.019, months = 35.7),
  hctz       = c(death = 0.045, mi = 0.028, stroke = 0.023, months = 35.6)
)
PM_D <- 0.0611   # from "MI-related death 6.3%"      — provenance unverified
PS_D <- 0.2381   # from "stroke-related death 27.2%" — provenance unverified

# --- Step 1: reproduce the paper's own conversion --------------------------
# The paper's formula is r = -ln(1-P1)/t1 ; P2 = 1-exp(-r*t2).
# Setting t1 = t2 = 1 reduces it to P2 = 1-exp(-P1): the trial percentage is
# treated as if it were an annual instantaneous rate.
as_published <- function(p) 1 - exp(-p)

cat("=== does 1-exp(-p) reproduce the published annual probabilities? ===\n")
for (a in names(TRIAL)) {
  t <- TRIAL[[a]]; p <- TPM_PUBLISHED[[a]]
  cat(sprintf("%-11s  MI %.4f vs %.4f | stroke %.4f vs %.4f | death %.4f vs %.4f\n",
              a, as_published(t[["mi"]]), p[["EM"]],
              as_published(t[["stroke"]]), p[["ES"]],
              as_published(t[["death"]]), 0.0402 + (a == "hctz") * 0.0038))
}

# --- Step 2: reproduce PH-D by subtraction ---------------------------------
cat("\n=== is PH-D = total death - MI deaths - stroke deaths? ===\n")
for (a in names(TRIAL)) {
  t <- TRIAL[[a]]; p <- TPM_PUBLISHED[[a]]
  d_tot <- as_published(t[["death"]])
  phd   <- d_tot - as_published(t[["mi"]]) * PM_D - as_published(t[["stroke"]]) * PS_D
  cat(sprintf("%-11s  derived %.6f   published %.4f\n", a, phd, p[["ED"]]))
}

# --- Step 3: annualise over the period the trial actually observed ---------
correct <- function(p, months) 1 - (1 - p)^(12 / months)

TPM_CORRECTED <- lapply(names(TRIAL), function(a) {
  t <- TRIAL[[a]]; yrs <- t[["months"]]
  mi <- correct(t[["mi"]], yrs); st <- correct(t[["stroke"]], yrs)
  dt <- correct(t[["death"]], yrs)
  ed <- dt - mi * PM_D - st * PS_D
  c(EE = 1 - mi - st - ed, EM = mi, ES = st, ED = ed,
    MM = 1 - PM_D, MD = PM_D, SS = 1 - PS_D, SD = PS_D)
})
names(TPM_CORRECTED) <- names(TRIAL)

cat("\n=== annual probabilities: as published vs annualised over ~3 years ===\n")
for (a in names(TRIAL)) {
  p <- TPM_PUBLISHED[[a]]; q <- TPM_CORRECTED[[a]]
  cat(sprintf("%-11s  MI %.4f -> %.4f (%.2fx)   stroke %.4f -> %.4f (%.2fx)   PH-D %.4f -> %.4f\n",
              a, p[["EM"]], q[["EM"]], p[["EM"]] / q[["EM"]],
              p[["ES"]], q[["ES"]], p[["ES"]] / q[["ES"]],
              p[["ED"]], q[["ED"]]))
}

# --- Step 4: what does it do to the result? --------------------------------
TPM_PUBLISHED <- TPM_CORRECTED   # swap in, engine is otherwise untouched
corr <- run_both(drug_in = "event_free", event_cost = "prevalent")
corr <- corr[match(TARGET$arm, corr$arm), ]

cat("\n=== result under corrected annualisation ===\n")
cat(sprintf("%-11s cost %9.2f   QALY %.4f\n", corr$arm, corr$cost, corr$qaly))
cat(sprintf("\nincremental cost %+.2f   incremental QALY %+.4f\n",
            diff(corr$cost), diff(corr$qaly)))
cat(sprintf("published:       %+.2f              %+.4f\n",
            diff(TARGET$cost), diff(TARGET$qaly)))
cat(sprintf("\namlodipine still cheaper: %s   still more effective: %s\n",
            diff(corr$cost) > 0, diff(corr$qaly) < 0))

# ---------------------------------------------------------------------------
# 18_drug_cost_discrepancy.R
#
# Every range printed on the paper's Figure 4 back-solves to the value in
# Tables 2 and 3 — except one. C_Event_Amlodipine (4094.6 to 6824.4) implies a
# base of 5459.50, where Table 2 prints 5494.53. This tests whether the model
# ran on the figure's value, using the residual that the rebuild could not
# otherwise explain.
# ---------------------------------------------------------------------------
source("R/00_eval.R")
set.seed(20260826)

FIG <- (4094.6 + 6824.4) / 2
cat(sprintf("Table 2 prints            %10.2f CNY/year\n", COST_DRUG[["amlodipine"]]))
cat(sprintf("Figure 4's range implies  %10.2f CNY/year   (difference %+.2f)\n\n",
            FIG, FIG - COST_DRUG[["amlodipine"]]))

for (v in c(COST_DRUG[["amlodipine"]], FIG)) {
  e <- run_model(drug = replace(COST_DRUG, "amlodipine", v))
  cat(sprintf("drug cost %8.2f  ->  amlodipine total %10.2f   vs published 66196.97   %+8.2f  (%+.3f%%)\n",
              v, e$cost[["amlodipine"]], e$cost[["amlodipine"]] - 66196.97,
              100 * (e$cost[["amlodipine"]] - 66196.97) / 66196.97))
}

# does the published total now sit inside the four-decimal rounding envelope?
HALF <- 0.00005
srow <- function(p) repeat { v <- p + runif(length(p), -HALF, HALF)
  v[length(v)] <- 1 - sum(v[-length(v)])
  if (abs(v[length(v)] - p[length(p)]) <= HALF) return(v) }
one <- function(drug) {
  p <- TPM_PUBLISHED$amlodipine
  e <- srow(c(p[["EE"]], p[["EM"]], p[["ES"]], p[["ED"]]))
  m <- srow(c(p[["MM"]], p[["MD"]])); s <- srow(c(p[["SS"]], p[["SD"]]))
  q <- c(EE=e[1], EM=e[2], ES=e[3], ED=e[4], MM=m[1], MD=m[2], SS=s[1], SD=s[2])
  t <- TPM_PUBLISHED; t$amlodipine <- q
  run_model(tpm = t, drug = replace(COST_DRUG, "amlodipine", drug))$cost[["amlodipine"]]
}
cat("\nrounding envelope for the amlodipine arm (4000 draws):\n")
for (v in c(COST_DRUG[["amlodipine"]], FIG)) {
  env <- replicate(4000, one(v))
  cat(sprintf("  drug %8.2f  ->  %10.2f to %10.2f   published 66196.97 is %s\n",
              v, min(env), max(env),
              if (66196.97 >= min(env) && 66196.97 <= max(env)) "INSIDE" else "outside"))
}

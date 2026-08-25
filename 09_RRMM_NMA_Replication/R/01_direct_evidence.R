# Step 1 of the binomial arm: collapse the three response categories to
# CR vs not-CR, and write down what the direct trial evidence says BEFORE any
# model is fitted. Every one of these 16 comparisons is a target the NMA has to
# reproduce closely -- a model that disagrees with its own direct evidence is
# wired wrong, whatever the published paper says.

# Run from the case root: Rscript R/01_direct_evidence.R
root <- "."
stopifnot(dir.exists(file.path(root, "data")))

arms <- read.csv(file.path(root, "data", "rrmm_arms_indexed.csv"),
                 stringsAsFactors = FALSE, check.names = FALSE)

# The paper's own abbreviations, so the output reads like its figures.
short <- function(x) {
  for (p in list(c("Pegylated Liposomal Doxorubicin", "PLD"),
                 c("Dexamethasone", "Dex"), c("Bortezomib", "Bor"),
                 c("Lenalidomide", "Len"), c("Thalidomidet", "Thal"),
                 c("Thalidomide", "Thal"), c("Pomalidomide", "Pom"),
                 c("Carfilzomib", "Car"), c("Daratumumab", "Dara"),
                 c("Elotuzumab", "Elo"), c("Ixazomib", "Ixa"),
                 c("Panobinostat", "Pano"), c("Oblimersen", "Obl"))) {
    x <- gsub(p[1], p[2], x, fixed = TRUE)
  }
  gsub("\\s*\\+\\s*", "", x)
}

# CR vs not-CR. This is the binomial reduction: one number per arm, not three.
arms$tx <- short(arms$treatment)
arms$r  <- arms$cr_group
arms$n  <- arms$n_itt

binom <- arms[, c("trial", "arm", "tx", "tx_index", "r", "n")]
write.csv(binom, file.path(root, "data", "rrmm_binomial_cr.csv"), row.names = FALSE)

# One row per trial: the crude odds ratio the trial itself reports.
trials <- unique(binom$trial)
direct <- do.call(rbind, lapply(trials, function(tr) {
  d <- binom[binom$trial == tr, ]
  a <- d[d$arm == 1, ]; b <- d[d$arm == 2, ]
  zero <- a$r == 0 || b$r == 0 || a$r == a$n || b$r == b$n
  # Haldane-Anscombe: add 0.5 to every cell so a zero cell still yields a
  # finite estimate. It is a device for looking at the data, not an analysis
  # choice -- the Bayesian model handles zeros without it.
  adj <- if (zero) 0.5 else 0
  or <- ((b$r + adj) / (b$n - b$r + adj)) / ((a$r + adj) / (a$n - a$r + adj))
  se <- sqrt(1/(b$r+adj) + 1/(b$n-b$r+adj) + 1/(a$r+adj) + 1/(a$n-a$r+adj))
  data.frame(trial = tr,
             comparison = paste(b$tx, "vs", a$tx),
             tx1 = a$tx_index, tx2 = b$tx_index,
             cr1 = sprintf("%d/%d", a$r, a$n), cr2 = sprintf("%d/%d", b$r, b$n),
             pct1 = round(100 * a$r / a$n, 1), pct2 = round(100 * b$r / b$n, 1),
             log_or = round(log(or), 3), se = round(se, 3),
             or = round(or, 2),
             lo = round(exp(log(or) - 1.96 * se), 2),
             hi = round(exp(log(or) + 1.96 * se), 2),
             zero_cell = zero, stringsAsFactors = FALSE)
}))

write.csv(direct, file.path(root, "data", "rrmm_direct_evidence_cr.csv"), row.names = FALSE)

cat(sprintf("%d trials, %d arms, %d treatment nodes\n\n",
            length(trials), nrow(binom), length(unique(binom$tx_index))))
cat("Direct evidence on complete response (arm 2 vs arm 1)\n\n")
print(direct[, c("trial", "comparison", "cr1", "cr2", "pct1", "pct2",
                 "or", "lo", "hi", "zero_cell")], row.names = FALSE)

z <- direct[direct$zero_cell, ]
if (nrow(z)) {
  cat(sprintf("\n%d trial(s) carry a zero CR count: %s\n",
              nrow(z), paste(z$trial, collapse = ", ")))
  cat("Their odds ratios above use a 0.5 continuity correction and are\n")
  cat("descriptive only -- they are not what the NMA will estimate.\n")
}

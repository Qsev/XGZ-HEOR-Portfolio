# ===========================================================================
# 17_tornado_icer.R  ·  the same one-way analysis, plotted the paper's way
#
# A direct test: if this engine agrees with the paper's, then plotting the ICER
# should reproduce the shape of its Figure 4 — including the long left tails,
# which are what a ratio does when its denominator approaches zero.
# ===========================================================================
source("R/00_eval.R")
icer <- function(e) e$d_cost / e$d_qaly          # same ratio either orientation
base <- icer(run_model())

tw <- function(arm, key, m) { t <- TPM_PUBLISHED
  t[[arm]][[key]] <- t[[arm]][[key]] * m; t[[arm]] <- renorm(t[[arm]]); t }
both <- function(key, m) { t <- TPM_PUBLISHED
  for (a in names(t)) { t[[a]][[key]] <- t[[a]][[key]] * m; t[[a]] <- renorm(t[[a]]) }; t }

runs <- list(
  list("P_HEvent_freetoDeath",       .10, function(m) run_model(tpm = tw("hctz","ED",m))),
  list("P_AEvent_freetoDeath",       .10, function(m) run_model(tpm = tw("amlodipine","ED",m))),
  list("C_Event_Hydrochlorothiazide",.25, function(m) run_model(drug = replace(COST_DRUG,"hctz",COST_DRUG[["hctz"]]*m))),
  list("C_Event_Amlodipine",         .25, function(m) run_model(drug = replace(COST_DRUG,"amlodipine",COST_DRUG[["amlodipine"]]*m))),
  list("P_HEvent_freetoNonfatal_MI", .10, function(m) run_model(tpm = tw("hctz","EM",m))),
  list("U_Event_free",               .10, function(m) run_model(util = replace(UTIL,"EventFree",UTIL[["EventFree"]]*m))),
  list("P_AEvent_freetoNonfatal_MI", .10, function(m) run_model(tpm = tw("amlodipine","EM",m))),
  list("C_Nonfatal_MI",              .25, function(m) run_model(event = replace(COST_EVENT,"MI",COST_EVENT[["MI"]]*m))),
  list("P_HEvent_freetoNonfatal_stroke",.10, function(m) run_model(tpm = tw("hctz","ES",m))),
  list("P_AEvent_freetoNonfatal_stroke",.10, function(m) run_model(tpm = tw("amlodipine","ES",m))),
  list("U_Nonfatal_MI",              .10, function(m) run_model(util = replace(UTIL,"MI",UTIL[["MI"]]*m))),
  list("C_Nonfatal_stroke",          .25, function(m) run_model(event = replace(COST_EVENT,"Stroke",COST_EVENT[["Stroke"]]*m))),
  list("U_Nonfatal_stroke",          .10, function(m) run_model(util = replace(UTIL,"Stroke",UTIL[["Stroke"]]*m))),
  list("P_Nonfatal_stroketoDeath",   .10, function(m) run_model(tpm = both("SD",m))),
  list("P_Nonfatal_MItoDeath",       .10, function(m) run_model(tpm = both("MD",m)))
)
res <- do.call(rbind, lapply(runs, function(r)
  data.frame(param = r[[1]], lo = icer(r[[3]](1 - r[[2]])), hi = icer(r[[3]](1 + r[[2]])))))
res <- rbind(res, data.frame(param = "dis",
                             lo = icer(run_model(disc = 0)), hi = icer(run_model(disc = 0.07))))
res$span <- abs(res$hi - res$lo)
res <- res[order(-res$span), ]

cat(sprintf("\nbase ICER from this rebuild: %10.2f      paper's Figure 4 EV: -67,133.56\n\n", base))
cat("ranking on the ICER axis, widest first  (paper's own order in brackets)\n\n")
paper <- c("P_HEvent_freetoDeath","P_AEvent_freetoDeath","C_Event_Hydrochlorothiazide",
           "C_Event_Amlodipine","P_HEvent_freetoNonfatal_MI","U_Event_free",
           "P_AEvent_freetoNonfatal_MI","C_Nonfatal_MI","P_HEvent_freetoNonfatal_stroke",
           "P_AEvent_freetoNonfatal_stroke","U_Nonfatal_MI","C_Nonfatal_stroke","dis",
           "U_Nonfatal_stroke","P_Nonfatal_stroketoDeath","P_Nonfatal_MItoDeath")
for (i in seq_len(nrow(res))) {
  pr <- match(res$param[i], paper)
  cat(sprintf("%2d [%2s]  %-32s  %12.0f  to %12.0f\n", i,
              ifelse(is.na(pr), "-", pr), res$param[i],
              min(res$lo[i], res$hi[i]), max(res$lo[i], res$hi[i])))
}

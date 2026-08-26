# ===========================================================================
# 12_figure_states.R  ·  the state-transition diagram
#
# Drawn rather than listed because two facts do not survive a list of eight
# probabilities: the self-loops hold most of the cohort, and the two arms
# differ on exactly three edges.
#
# Colour convention, used throughout the case:  hue = arm.
#   amlodipine #2a78d6   ·   hydrochlorothiazide #eb6834
#
# Run:  Rscript R/12_figure_states.R
# ===========================================================================
Sys.setlocale("LC_CTYPE", "en_US.UTF-8")
source("R/01_markov_engine.R")

pc <- function(x) sprintf("%.1f%%", 100 * x)
A <- TPM_PUBLISHED$amlodipine; H <- TPM_PUBLISHED$hctz

INK <- "#1f2937"; MUTED <- "#6b7280"; SURF <- "#fcfcfb"
BOX <- "#ffffff"; EDGE <- "#94a3b8"
CA  <- "#2a78d6"   # amlodipine
CH  <- "#eb6834"   # hydrochlorothiazide

png("visuals/state_diagram.png", width = 2200, height = 1250, res = 200)
par(mar = c(0, 0, 0, 0), bg = SURF)
plot(NA, xlim = c(0, 100), ylim = c(0, 100), axes = FALSE, xlab = "", ylab = "",
     xaxs = "i", yaxs = "i")
asp <- par("pin")[2] / par("pin")[1]        # y-units per x-unit, for circles

rrect <- function(x, y, w, h, r = 1.7, border = EDGE, lwd = 1.5) {
  t <- seq(0, pi / 2, length.out = 14); rx <- r * asp
  polygon(c(x + w/2 - rx + rx*cos(t),      x - w/2 + rx + rx*cos(t + pi/2),
            x - w/2 + rx + rx*cos(t + pi), x + w/2 - rx + rx*cos(t + 3*pi/2)),
          c(y + h/2 - r + r*sin(t),        y + h/2 - r + r*sin(t + pi/2),
            y - h/2 + r + r*sin(t + pi),   y - h/2 + r + r*sin(t + 3*pi/2)),
          col = BOX, border = border, lwd = lwd)
}
arw <- function(x0, y0, x1, y1, col = INK, lwd = 1.6)
  arrows(x0, y0, x1, y1, length = 0.075, angle = 21, col = col, lwd = lwd)

# A compact self-loop: a small circle tangent to the node at (ax, ay), opening
# back towards it, so the arrow starts and finishes in the same place.
selfloop <- function(ax, ay, ang, ry = 7.2) {
  rx  <- ry * asp
  cx  <- ax + rx * cos(ang) * 0.72; cy <- ay + ry * sin(ang) * 0.72
  gap <- 0.30 * pi
  t   <- seq(ang + pi + gap, ang + 3 * pi - gap, length.out = 90)
  lines(cx + rx * cos(t), cy + ry * sin(t), col = INK, lwd = 1.6)
  n <- length(t)
  arw(cx + rx*cos(t[n-1]), cy + ry*sin(t[n-1]), cx + rx*cos(t[n]), cy + ry*sin(t[n]))
  c(cx + rx * cos(ang) * 1.35, cy + ry * sin(ang) * 1.35)   # where a label goes
}

# two figures, one per arm, coloured so identity never depends on position
pair <- function(x, y, k, adj = 0.5, cex = 0.94) {
  a <- pc(A[[k]]); h <- pc(H[[k]])
  wa <- strwidth(a, cex = cex, font = 2); ws <- strwidth("  ", cex = cex)
  wh <- strwidth(h, cex = cex, font = 2); x0 <- x - adj * (wa + ws + wh)
  text(x0, y, a, adj = 0, cex = cex, col = CA, font = 2)
  text(x0 + wa + ws, y, h, adj = 0, cex = cex, col = CH, font = 2)
}
mask <- function(x, y, w, h) rect(x - w/2, y - h/2, x + w/2, y + h/2,
                                  col = SURF, border = NA)

# --- nodes -----------------------------------------------------------------
EFx <- 50; EFy <- 71; MIx <- 27; MIy <- 42; STx <- 73; STy <- 42
DEx <- 50; DEy <- 16; W <- 27; Wm <- 24; Hh <- 12

rrect(EFx, EFy, W, Hh, border = EDGE)
text(EFx, EFy + 2.0, "Hypertensive,", cex = 1.0, col = INK)
text(EFx, EFy - 2.2, "event-free",    cex = 1.0, col = INK, font = 2)
rrect(MIx, MIy, Wm, Hh); text(MIx, MIy + 2.0, "Non-fatal", cex = 1.0, col = INK)
text(MIx, MIy - 2.2, "MI", cex = 1.0, col = INK, font = 2)
rrect(STx, STy, Wm, Hh); text(STx, STy + 2.0, "Non-fatal", cex = 1.0, col = INK)
text(STx, STy - 2.2, "stroke", cex = 1.0, col = INK, font = 2)
rrect(DEx, DEy, Wm, Hh); text(DEx, DEy + 2.0, "Death", cex = 1.0, col = INK, font = 2)
text(DEx, DEy - 2.3, "(absorbing)", cex = 0.86, col = MUTED)

# --- the three transitions the treatments move -----------------------------
arw(EFx - W/2 + 1.0, EFy - Hh/2 - 0.4, MIx + Wm/2 - 4, MIy + Hh/2 + 0.8)
pair(33.0, 58.5, "EM", adj = 1)
arw(EFx + W/2 - 1.0, EFy - Hh/2 - 0.4, STx - Wm/2 + 4, STy + Hh/2 + 0.8)
pair(67.0, 58.5, "ES", adj = 0)
arw(EFx, EFy - Hh/2 - 0.4, DEx, DEy + Hh/2 + 0.8)
mask(EFx, 52, 15, 4.4); pair(EFx, 52, "ED")

# --- and the two that are identical in both arms ---------------------------
arw(MIx + Wm/2 - 3, MIy - Hh/2 - 0.4, DEx - Wm/2 + 2.0, DEy + Hh/2 + 0.8)
text(33.5, 26.5, pc(A[["MD"]]), cex = 0.94, col = INK, font = 2, adj = 1)
arw(STx - Wm/2 + 3, STy - Hh/2 - 0.4, DEx + Wm/2 - 2.0, DEy + Hh/2 + 0.8)
text(66.5, 26.5, pc(A[["SD"]]), cex = 0.94, col = INK, font = 2, adj = 0)

# --- self-loops ------------------------------------------------------------
p <- selfloop(EFx, EFy + Hh/2, pi/2);   pair(p[1], p[2] + 1.4, "EE")
p <- selfloop(MIx - Wm/2, MIy, pi)
text(p[1] - 1.4, p[2], pc(A[["MM"]]), cex = 0.94, col = INK, font = 2, adj = 1)
p <- selfloop(STx + Wm/2, STy, 0)
text(p[1] + 1.4, p[2], pc(A[["SS"]]), cex = 0.94, col = INK, font = 2, adj = 0)
p <- selfloop(DEx + Wm/2, DEy, 0)
text(p[1] + 1.4, p[2], "100%", cex = 0.94, col = INK, font = 2, adj = 0)

# --- legend ----------------------------------------------------------------
ly <- 95.5
rect(2.5, ly - 1.0, 5.3, ly + 1.0, col = CA, border = NA)
text(6.3, ly, "amlodipine", adj = 0, cex = 0.9, col = INK, font = 2)
rect(21.0, ly - 1.0, 23.8, ly + 1.0, col = CH, border = NA)
text(24.8, ly, "hydrochlorothiazide", adj = 0, cex = 0.9, col = INK, font = 2)
text(2.5, 91.0, "Two figures mean the arms differ there, which happens only on",
     adj = 0, cex = 0.86, col = MUTED)
text(2.5, 87.6, "the three transitions out of the event-free state.",
     adj = 0, cex = 0.86, col = MUTED)
invisible(dev.off())
cat("visuals/state_diagram.png written\n")

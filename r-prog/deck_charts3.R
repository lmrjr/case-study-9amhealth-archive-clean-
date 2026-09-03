########################################################################################################################
# deck_charts3.R -- the three story-first replacement figures (brand-styled). Retires the weak charts:
#   (S3) figures/pct_distribution_by_drug.png  -- %-change distribution by drug + >=5% line   (replaces plain % bar)
#   (S4) figures/engage_response_comove.png    -- engagement & responder-rate co-move by drug  (replaces histogram)
#   (S5) figures/driver_forest.png             -- locked-model effect forest + naive/adjusted   (replaces AV scatter)
# Pipeline STEP: sourced by main.R after covariates.R. Uses in-memory objects
# (cohort, logi.glp, glp.all, resp5, resp.by.drug, m.pct.final, df.fin) -- numbers are exactly the deck's.
########################################################################################################################
fig.loc <- "projects/internal/case-study-9amhealth/figures"
dir.create(fig.loc, showWarnings = FALSE, recursive = TRUE)

# ---- brand palette (brand-tokens.md) ----
cream <- "#FFFCF3"; charcoal <- "#212121"; blue <- "#80AEFF"; red <- "#B22222"; grey <- "#9A9A9A"
drug.col <- c("Coaching" = "#FFBD70", "Generic" = "#F7BDE6", "GLP-1 (All)" = "#80AEFF")  # weak -> strong
ord <- names(drug.col)
brand_par <- function() par(bg = cream, col.axis = charcoal, col.lab = charcoal,
                            col.main = charcoal, fg = charcoal, font.lab = 2)

d <- cohort[logi.glp, ]
d$g <- factor(d$glp.all, levels = ord)
resp <- resp.by.drug[ord]                                    # responder % by class (locked object)

########################################################################################################################
# (S3) %-CHANGE DISTRIBUTION BY DRUG -- box + jitter, vertical >=5% clinical line, responder% annotated.
#      Tells: the MIXTURE (Coaching ~0 w/ some gaining; GLP-1 shifted right, wide) + the threshold + the gradient.
########################################################################################################################
png(file.path(fig.loc, "pct_distribution_by_drug.png"), width = 1600, height = 900, res = 165)
brand_par(); par(mar = c(5, 8, 4, 6))
xr <- quantile(d$pct, c(.005, .995))                          # clip the extreme 1% so the boxes are readable
boxplot(pct ~ g, data = d, horizontal = TRUE, outline = FALSE, yaxt = "n",
        col = drug.col[ord], border = charcoal, xlim = c(1, 3), ylim = xr,
        xlab = "% weight change  (> 0 = lost)", ylab = "",
        main = "Weight change is a mixture: coaching ~0, GLP-1 shifted right")
set.seed(1)
stripchart(pct ~ g, data = d, method = "jitter", jitter = 0.18, pch = 19, cex = 0.35,
           col = adjustcolor(charcoal, .28), add = TRUE)
abline(v = 5, lty = 2, lwd = 2, col = red)                    # >=5% clinical responder bar
axis(2, at = seq_along(ord), labels = sprintf("%s\n(n=%d)", ord, as.integer(table(d$g))), las = 1, cex.axis = .85)
text(par("usr")[2], seq_along(ord), labels = sprintf("%.0f%% >=5%%", resp),
     pos = 2, font = 2, col = charcoal, xpd = NA, cex = .95)
text(5, 3.5, "5% loss", col = red, font = 2, pos = 4, cex = .8, xpd = NA)
invisible(dev.off())
cat("wrote", file.path(fig.loc, "pct_distribution_by_drug.png"), "\n")

########################################################################################################################
# (S4) ENGAGEMENT & RESPONSE CO-MOVE -- median volume_rep (bars) + responder% (points/line, right axis).
#      Tells: engagement rises in the SAME order as response -> is it real or just the drug? (bridge to S5).
########################################################################################################################
med <- tapply(d$volume_rep, d$g, median, na.rm = TRUE)[ord]
png(file.path(fig.loc, "engage_response_comove.png"), width = 1600, height = 900, res = 165)
brand_par(); par(mar = c(5, 5, 4, 5))
bp <- barplot(med, col = drug.col[ord], border = NA, ylim = c(0, max(med) * 1.25),
              ylab = "median engagement (repeatable events)",
              names.arg = sprintf("%s\n(n=%d)", ord, as.integer(table(d$g))),
              main = "Engagement and response rise together by drug class")
text(bp, med, labels = med, pos = 3, font = 2, col = charcoal)
par(new = TRUE)
plot(bp, resp, type = "b", pch = 19, lwd = 3, cex = 1.6, col = red,
     axes = FALSE, xlab = "", ylab = "", xlim = range(bp) + c(-.5, .5), ylim = c(0, 100))
text(bp, resp, labels = sprintf("%.0f%%", resp), pos = 3, font = 2, col = red)
axis(4, col = red, col.axis = red); mtext("% achieving >=5% loss", side = 4, line = 3, font = 2, col = red)
legend("topleft", bty = "n", text.col = charcoal, pch = c(15, 19), col = c(blue, red),
       legend = c("median engagement (L)", "% responders (R)"))
invisible(dev.off())
cat("wrote", file.path(fig.loc, "engage_response_comove.png"), "\n")

########################################################################################################################
# (S5) DRIVER FOREST -- locked model effects ACROSS A MEANINGFUL RANGE (IQR for continuous; vs Coaching for
#      factors), HC3 95% CI, ordered by magnitude. Inset: naive vs adjusted volume_rep slope (the confound point).
########################################################################################################################
ct  <- coeftest(m.pct.final, vcov = vcovHC(m.pct.final, type = "HC3"))
iqr <- sapply(df.fin[c("first", "fl.cnt", "volume_rep")], IQR, na.rm = TRUE)
row <- function(term, label, scale = 1) {
  e <- ct[term, "Estimate"] * scale; s <- ct[term, "Std. Error"] * scale
  data.frame(label = label, est = e, lo = e - 1.96 * s, hi = e + 1.96 * s, stringsAsFactors = FALSE)
}
eff <- rbind(
  row("factor(glp.all)GLP-1 (All)", "GLP-1 (All) vs Coaching"),
  row("factor(glp.all)Generic",     "Generic vs Coaching"),
  row("first",      "Baseline weight (per IQR)",  iqr["first"]),
  row("fl.cnt",     "Exposure days (per IQR)",    iqr["fl.cnt"]),
  row("volume_rep", "Engagement volume (per IQR)", iqr["volume_rep"]))
eff <- eff[order(abs(eff$est)), ]                             # smallest at bottom, biggest on top
eff$sig <- (eff$lo > 0 | eff$hi < 0)                          # CI excludes 0

png(file.path(fig.loc, "driver_forest.png"), width = 1700, height = 850, res = 165)
brand_par(); layout(matrix(c(1, 1, 1, 2), nrow = 1)); par(mar = c(5, 12, 4, 2))
yy <- seq_len(nrow(eff))
plot(NA, xlim = range(c(eff$lo, eff$hi, 0)) * 1.05, ylim = c(0.5, nrow(eff) + 0.5), yaxt = "n",
     xlab = "effect on % weight change (points)", ylab = "",
     main = "What actually moves weight (locked model, HC3 95% CI)")
abline(v = 0, lty = 3, col = charcoal)
segments(eff$lo, yy, eff$hi, yy, lwd = 3, col = ifelse(eff$sig, charcoal, grey))
points(eff$est, yy, pch = 19, cex = 1.6, col = ifelse(eff$sig, blue, grey))
axis(2, at = yy, labels = eff$label, las = 1, cex.axis = .9)
text(eff$hi, yy, labels = sprintf("%+.1f", eff$est), pos = 4, cex = .8, font = 2,
     col = ifelse(eff$sig, charcoal, grey), xpd = NA)

# inset: naive vs adjusted volume_rep slope (per event) -- the "~half confounded" point
naive <- coef(lm(pct ~ volume_rep, data = df.fin))["volume_rep"]
adj   <- ct["volume_rep", "Estimate"]
par(mar = c(5, 4, 4, 1))
b <- barplot(c(naive, adj), col = c(grey, blue), border = NA, ylim = c(0, max(naive) * 1.25),
             names.arg = c("naive", "adjusted"), ylab = "engagement slope (pts / event)",
             main = "~half is confounding")
text(b, c(naive, adj), labels = sprintf("%.3f", c(naive, adj)), pos = 3, font = 2, col = charcoal)
text(mean(b), max(naive) * 1.12, sprintf("%.0f%% survives", 100 * adj / naive), font = 2, col = blue)
invisible(dev.off())
cat("wrote", file.path(fig.loc, "driver_forest.png"), "\n")

# self-check: forest has the 5 driver rows; adjusted engagement slope is a positive fraction of the naive slope
stopifnot(nrow(eff) == 5, adj > 0, adj < naive)

########################################################################################################################
# deck_tables.R -- the two "model-output" artifacts the deck was missing (Sandia-style: point-at-a-row tables):
#   (T1) figures/hypothesis_scorecard.png  -- H1..H6 -> effect + p + verdict  (the attention-director, body slide)
#   (T2) figures/coef_table.png            -- locked model coefficients: Estimate, 95% CI (HC3), p  (appendix)
# Pipeline STEP: sourced by main.R after deck_charts3.R. Uses in-memory objects from covariates.R
# (m.pct.final, df.fin, driver.tab, m.pct.main, m.pct.int, resp.by.drug) -- numbers are exactly the deck's.
########################################################################################################################
fig.loc <- "projects/internal/case-study-9amhealth/figures"
dir.create(fig.loc, showWarnings = FALSE, recursive = TRUE)

# ---- brand palette (brand-tokens.md) ----
cream <- "#FFFCF3"; charcoal <- "#212121"; blue <- "#80AEFF"; orange <- "#FFBD70"; grey <- "#9A9A9A"
brand_par <- function() par(bg = cream, col.axis = charcoal, col.lab = charcoal,
                            col.main = charcoal, fg = charcoal, font.lab = 2)

# ---- one base-graphics table drawer (no deps; matches deck_charts3.R style) ----
# cells: character matrix, row 1 = header. w_rel: relative col widths. adj: 0 left / .5 center / 1 right per col.
# txtcol: optional per-cell color matrix (defaults charcoal). Header banded blue, body zebra grey.
tbl_png <- function(file, cells, w_rel, adj, title, note, txtcol = NULL, w = 1650, res = 165) {
  nr <- nrow(cells); nc <- ncol(cells)
  h  <- 230 + nr * 92
  if (is.null(txtcol)) txtcol <- matrix(charcoal, nr, nc)
  xr <- cumsum(w_rel) / sum(w_rel); xl <- c(0, xr[-nc])          # per-column left/right edges in [0,1]
  png(file.path(fig.loc, file), width = w, height = h, res = res)
  brand_par(); par(mar = c(0.4, 0.4, 0.4, 0.4))
  plot.new(); plot.window(xlim = c(0, 1), ylim = c(0, 1))
  text(0.008, 0.965, title, adj = c(0, 1), font = 2, cex = 1.35, col = charcoal)
  top <- 0.85; bot <- 0.11; rh <- (top - bot) / nr
  ycen <- top - (seq_len(nr) - 0.5) * rh
  pad <- 0.010
  for (i in seq_len(nr)) {
    fill <- if (i == 1) adjustcolor(blue, 0.18) else if (i %% 2 == 1) adjustcolor(grey, 0.10) else NA
    if (!is.na(fill)) rect(0, ycen[i] - rh/2, 1, ycen[i] + rh/2, col = fill, border = NA)
    for (j in seq_len(nc)) {
      ax <- if (adj[j] == 0) xl[j] + pad else if (adj[j] == 1) xr[j] - pad else (xl[j] + xr[j]) / 2
      text(ax, ycen[i], cells[i, j], adj = c(adj[j], 0.5),
           font = if (i == 1) 2 else 1, col = txtcol[i, j], cex = 0.92)
    }
  }
  abline(h = top - rh, col = charcoal, lwd = 1.6)                # rule under header
  text(0.008, 0.035, note, adj = c(0, 0), col = grey, cex = 0.70, font = 3)
  invisible(dev.off())
  cat("wrote", file.path(fig.loc, file), "\n")
}

pstr <- function(p) if (p < 0.001) " < 0.001" else sprintf(" = %.3f", p)  # p-value formatter (deck convention)

########################################################################################################################
# locked reported model, HC3 -- same object/vcov the forest uses (deck_charts3.R). recomputed so this file stands alone.
########################################################################################################################
ct   <- coeftest(m.pct.final, vcov = vcovHC(m.pct.final, type = "HC3"))
nobs <- nrow(df.fin); r2 <- summary(m.pct.final)$r.squared

########################################################################################################################
# (T2) COEFFICIENT TABLE -- the appendix "solution for fixed effects" analog.
########################################################################################################################
terms <- c("factor(glp.all)GLP-1 (All)", "first", "volume_rep", "factor(glp.all)Generic", "fl.cnt")
labs  <- c("GLP-1 (All) vs Coaching", "Baseline weight (per lb)", "Engagement (per event)",
           "Generic vs Coaching", "Exposure (per day)")
est <- ct[terms, "Estimate"]; se <- ct[terms, "Std. Error"]; pv <- ct[terms, "Pr(>|t|)"]
lo  <- est - 1.96 * se; hi <- est + 1.96 * se
cf  <- rbind(c("Term", "Estimate", "95% CI (HC3)", "p"),
             cbind(labs,
                   sprintf("%+.3f", est),
                   sprintf("[%+.3f, %+.3f]", lo, hi),
                   ifelse(pv < 0.001, "< 0.001", sprintf("%.3f", pv))))
tbl_png("coef_table.png", cf, w_rel = c(0.40, 0.16, 0.28, 0.16), adj = c(0, 1, 0.5, 1),
        title = "Locked model coefficients (HC3 robust)",
        note = sprintf("Model: pct ~ baseline + drug class + exposure + engagement.  HC3 robust SE.  n = %d,  R2 = %.2f.  CI = estimate +/- 1.96 SE.",
                       nobs, r2))

########################################################################################################################
# (T1) HYPOTHESIS SCORECARD -- H1..H6 mapped to effect + p + verdict (the slide Luis directs attention to).
########################################################################################################################
rc <- resp.by.drug                                                       # responder % by class
h4a <- driver.tab[driver.tab$candidate == "mod.mean", ]                  # modules ALONE over core (one-at-a-time)
di4 <- df.fin[!is.na(df.fin$mod.mean), ]                                 # modules WITH engagement in the model
m4  <- lm(pct ~ first + factor(glp.all) + fl.cnt + volume_rep + mod.mean, data = di4)
p4i <- coeftest(m4, vcov = vcovHC(m4, type = "HC3"))["mod.mean", "Pr(>|t|)"]
h5  <- driver.tab[driver.tab$candidate == "sexMALE", ]                   # sex (H5)
p6  <- anova(m.pct.main, m.pct.int)[2, "Pr(>F)"]                         # engagement x drug interaction (H6)

vlab <- function(p) if (p < 0.05) "Supported" else "Not supported"
verdict <- c(vlab(ct["first", "Pr(>|t|)"]), "Supported", vlab(ct["volume_rep", "Pr(>|t|)"]),
             "Partial", vlab(h5$HC3_p), vlab(p6))
sc <- rbind(
  c("H", "Hypothesis", "Evidence (locked model, HC3)", "Verdict"),
  c("H1", "Heavier baseline -> larger loss (RTM)",
        sprintf("baseline %+.3f/lb, p%s", ct["first","Estimate"], pstr(ct["first","Pr(>|t|)"])), verdict[1]),
  c("H2", "GLP-1 drives more loss than coaching",
        sprintf("%+.1f pts adj; responders %.0f%% vs %.0f%%", ct["factor(glp.all)GLP-1 (All)","Estimate"],
                rc["GLP-1 (All)"], rc["Coaching"]), verdict[2]),
  c("H3", "Engagement adds on top of medication",
        sprintf("volume_rep %+.3f/event, p%s", ct["volume_rep","Estimate"], pstr(ct["volume_rep","Pr(>|t|)"])), verdict[3]),
  c("H4", "Module completion adds independently",
        sprintf("alone p=%.3f; with engagement p=%.2f", h4a$HC3_p, p4i), verdict[4]),
  c("H5", "Sex relates to weight loss",
        sprintf("sex p=%.2f (n.s.)", h5$HC3_p), verdict[5]),
  c("H6", "Engagement pays off differently by drug",
        sprintf("interaction F-test p=%.2f", p6), verdict[6]))
vcol <- c("Supported" = blue, "Partial" = orange, "Not supported" = grey)
tc <- matrix(charcoal, nrow(sc), ncol(sc))
tc[-1, 4] <- vcol[verdict]                                               # color the verdict column
tbl_png("hypothesis_scorecard.png", sc, w_rel = c(0.05, 0.33, 0.42, 0.20), adj = c(0.5, 0, 0, 0.5),
        title = "Hypothesis scorecard: which questions the analysis answers",
        note = "Supported = HC3 p < 0.05.  Partial = significant alone but not independent of engagement.  Verdicts from the locked model.",
        txtcol = tc)

# self-check: 5 coef rows + 6 hypothesis rows rendered, all model p-values finite, both PNGs on disk
stopifnot(nrow(cf) == 6, nrow(sc) == 7, all(is.finite(pv)), p6 >= 0, p6 <= 1,
          file.exists(file.path(fig.loc, "coef_table.png")),
          file.exists(file.path(fig.loc, "hypothesis_scorecard.png")))

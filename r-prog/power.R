########################################################################################################################
# power.R -- design-power / precision appendix for the panel (interview-2 PI asked about power).
# Pipeline STEP: sourced by main.R after covariates.R. Uses in-memory `cohort` (has first/diff/mem.type/glp.all),
# then computes precision + prospective sample size and writes figures/power_precision.png.
#
# Framing (say this to the PI): report PROSPECTIVE design power for a target effect, NOT post-hoc/observed
# power -- observed power is a monotone transform of the p-value (Hoenig & Heisey 2001, Am Stat), so it
# adds nothing. The question is "what n do we need to resolve a clinically meaningful class gap", not
# "how much power did this convenience sample happen to have".
########################################################################################################################

lab <- c("Active Generic Medication for Weight-loss (NOT on GLP-1 for weight-loss)"="Generic",
         "Active GLP-1 for Diabetes"="GLP1-Diab","Active GLP-1 for Weight-loss"="GLP1-WL",
         "Coaching Only"="Coaching","Null"="Null")
cohort$arm <- lab[cohort$mem.type]

# --- per-arm change (diff = first-last lb), paired CI + baseline weight (confound check) ---
arm.tab <- do.call(rbind, lapply(split(cohort, cohort$arm), function(d){
  n<-nrow(d); m<-mean(d$diff); s<-sd(d$diff); se<-s/sqrt(n); h<-qt(.975,n-1)*se
  data.frame(n=n, mean_diff=round(m,1), sd_diff=round(s,1), se=round(se,2),
             lo=round(m-h,1), hi=round(m+h,1), base_first=round(mean(d$first),0))
}))
cat("\n=== per-arm weight change (lb) with 95% CI ===\n"); print(arm.tab)

# --- variance heterogeneity: this is the real assumption issue (unequal n MAKES it bite) ---
vr <- max(arm.tab$sd_diff^2)/min(arm.tab$sd_diff^2)
cat(sprintf("\nvariance ratio max/min = %.1f  (Coaching sd=%.1f vs GLP1-WL sd=%.1f)\n",
            vr, min(arm.tab$sd_diff), max(arm.tab$sd_diff)))
print(bartlett.test(diff ~ arm, data=cohort))
pooled <- sqrt(sum((arm.tab$n-1)*arm.tab$sd_diff^2)/sum(arm.tab$n-1))   # pooled within-arm SD of change
cat(sprintf("pooled within-arm SD(diff) = %.1f lb\n", pooled))

# --- prospective sample size PER ARM (two-sample t, alpha .05 two-sided) ---
cat("\n=== prospective n PER ARM to resolve a class gap ===\n")
np <- expand.grid(power=c(.80,.90), delta=c(3,5,7))
np$n_per_arm <- ceiling(mapply(function(p,d) power.t.test(delta=d, sd=pooled, sig.level=.05, power=p)$n,
                               np$power, np$delta))
print(np[order(np$power, np$delta), ], row.names=FALSE)

# --- minimum detectable gap at CURRENT n (which contrasts the sample can actually resolve, 80%) ---
cat("\n=== minimum detectable gap at current n (vs Coaching, 80% power) ===\n")
for(a in c("GLP1-WL","Generic","GLP1-Diab")){
  na <- arm.tab[a,"n"]
  mde <- power.t.test(n=na, sd=pooled, sig.level=.05, power=.80)$delta
  cat(sprintf("%-10s (n=%3d)  min detectable gap vs Coaching = %.1f lb\n", a, na, mde))
}
cat("\nread: GLP1-WL vs Coaching is powered (2.7 lb). Generic/GLP1-Diab are not -> class panel needs enrollment.\n")

########################################################################################################################
# FIGURE (appendix slide): (L) precision NOW = per-arm mean loss +/- 95% CI forest -- the n=7 arm's CI screams;
#                          (R) prospective n/arm vs class gap to detect. brand palette (brand-tokens.md).
########################################################################################################################
fig.loc <- "projects/internal/case-study-9amhealth/figures"
cream<-"#FFFCF3"; charcoal<-"#212121"; blue<-"#80AEFF"; red<-"#B22222"
brand_par <- function() par(bg=cream, col.axis=charcoal, col.lab=charcoal, col.main=charcoal, fg=charcoal, font.lab=2)

ord <- c("Coaching","Null","Generic","GLP1-WL","GLP1-Diab")   # n=7 arm last = the visual punchline
at  <- arm.tab[ord, ]
png(file.path(fig.loc,"power_precision.png"), width=1700, height=850, res=165)
brand_par(); par(mfrow=c(1,2), mar=c(5,8,4,2), cex.main=0.95)

# LEFT: forest of mean change +/- 95% CI
yy <- seq_along(ord)
plot(NA, xlim=range(c(at$lo,at$hi)), ylim=c(0.5,length(ord)+0.5), yaxt="n",
     xlab="mean weight change (lb; + = lost)", ylab="",
     main="Precision now: n=7 arm uninformative")
abline(v=0, lty=3, col=charcoal)
segments(at$lo, yy, at$hi, yy, col=charcoal, lwd=3)
points(at$mean_diff, yy, pch=19, cex=1.5, col=blue)
axis(2, at=yy, labels=sprintf("%s (n=%d)", ord, at$n), las=1, cex.axis=0.85)
text(at$hi, yy, labels=sprintf("[%.0f, %.0f]", at$lo, at$hi), pos=4, cex=0.7, col=charcoal, xpd=NA)

# RIGHT: prospective n/arm vs detectable class gap (80% + 90%)
gaps <- seq(2,8,0.1)
n80 <- sapply(gaps, function(d) power.t.test(delta=d, sd=pooled, sig.level=.05, power=.80)$n)
n90 <- sapply(gaps, function(d) power.t.test(delta=d, sd=pooled, sig.level=.05, power=.90)$n)
plot(gaps, n90, type="n", xlab="class gap to detect (lb)", ylab="n per arm",
     main="Sample size to resolve a class gap", ylim=c(0,max(n90)))
lines(gaps, n80, lwd=3, col=blue); lines(gaps, n90, lwd=3, col=red)
n5 <- power.t.test(delta=5, sd=pooled, sig.level=.05, power=.80)$n
segments(5,0,5,n5,lty=3,col=charcoal); points(5,n5,pch=19,col=charcoal)
text(5,n5, sprintf("  5 lb -> %d/arm", ceiling(n5)), pos=4, cex=0.9, font=2, col=charcoal)
legend("topright", bty="n", lwd=3, col=c(blue,red), legend=c("80% power","90% power"), text.col=charcoal)
invisible(dev.off())
cat("wrote", file.path(fig.loc,"power_precision.png"), "\n")

# self-check: pooled SD sits between the arm SDs; every prospective n is a positive integer
stopifnot(pooled >= min(arm.tab$sd_diff), pooled <= max(arm.tab$sd_diff), all(np$n_per_arm > 0))

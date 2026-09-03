########################################################################################################################
# covariates.R  -- covariate investigation on the LOCKED cohort
#
########################################################################################################################

########################################################################################################################
# Residual Diagnostics
########################################################################################################################
# number of fitted models -> resid_diag(m.cs, m.un)  or  resid_diag(m.cs, m.un, m.3, ...). One plot-row
# per model: [ QQ of normalized residuals | normalized residual vs fitted ]. It uses
# resid(type="normalized") so the fitted covariance structure (CS vs UN) is divided out -- that is the
# correct residual to check normality/homoscedasticity for a gls/lme, not the raw residual.
#
# The actual CALL lives at the BOTTOM of this file (after m.cs/m.un are built). Move that call up into
# your Variable-selection block once the models you want to check exist there.

# this function takes in multiple model objects and compares them.
resid_diag <- function(..., normality = TRUE) {
    
    # waiting for all models listed in the function
    models <- list(...)
    
    # logic test just incase there is no model passed through.
    if (length(models) == 0L) stop("Bro.... resid_diag(): pass at least one fitted model!")
    
    # capture arg names: m.cs, m.un...or lm.whatevs
    nm <- vapply(substitute(list(...))[-1L], deparse, character(1))
    
    # This is the parameter window for the plots. models has at least 2 so a 2 by 2 or 3 by 2 depends on models entered.
    op <- par(mfrow = c(length(models), 2), mar = c(4, 4, 2.5, 1))
    on.exit(par(op))

    # my loop and logic
    for (i in seq_along(models)) {
        
        # getting the normalized residuals
        mdl <- models[[i]]
        
        # gls/lme -> normalized...not possible for lm
        r <- tryCatch(resid(mdl, type = "normalized"), error=function(e) resid(mdl))
        f <- fitted(mdl)

        # getting everything for the qqnorm plots.
        qqnorm(r, main = paste0("QQ norm. resid: ", nm[i])); qqline(r, col = "red")
        plot(f, r, xlab = "fitted", ylab = "norm. resid", pch = 20, col = "grey40",
            main = paste0("resid vs fitted: ", nm[i]))
        abline(h = 0, lty = 3)

        # logic for normality and loglikihood. 
        if (normality) {
            sw <- if (length(r) <= 5000L) shapiro.test(r)$p.value else NA_real_   # shapiro caps at n=5000
            cat(sprintf("%-10s n=%d  logLik=%.1f  AIC=%.1f  Shapiro p=%s\n",
                nm[i], length(r), as.numeric(logLik(mdl)), AIC(mdl),
                if (is.na(sw)) "n>5000 skip" else formatC(sw, format = "e", digits = 2)))
        }
    }
    invisible(NULL)
}

########################################################################################################################
# vikunja:
# task 3: `http://192.168.1.30:3456/tasks/105`  Is Readable ID the same as User Id.
# task 7: `http://192.168.1.30:3456/tasks/109`  Demographics + subscription/churn profile
# [please understand this code] the join itself now lives in merging.R (-> `analytic` -> `cohort`);
# here we just describe + model the demographics that rode along.
# okay I am keeping Sex and ethnicity because we should always report this in demographics but I only want to keep
# Sex as a factor in the model
########################################################################################################################
# Task 7:
table(cohort$sex)

# Claude: Look here
table(cohort$ethnicity, cohort$sex)

#################################################
# basic analysis of character strings and dates   (task 7: subscription / churn profile)
#################################################
# there are two groups and 2 people who have paused their participation: in the cohort data set this needs to be a selection criteria value.
table(cohort$status)

# 60 null who and what is going on here? 7 for GLP-1 for diabetes.
table(cohort$mem.type)

# these are just Feburary and all in 2025.
table(cohort$start.date)

# there is a time value but I am not sure if this is necessary. All 2025 and from Jan to Sept.  a total of 798 still active or paused.
table(cohort$cancel.date)

# this shows an active member with a cancellation date.
table(cohort$status, cohort$cancel.date)

########################################################################################################################
# ETHNICITY weight-change model.  indicators (eth_*) were built in explore.R; here they get USED.
# eth_hispanic:eth_white = the Andrew-vs-family access axis (proxy for SES/food access).
# this is the evidence for not including the other ethnicity factors.
########################################################################################################################
# weight-difference column; diff = first - last, so POSITIVE = weight lost. Keeping the bw_change alias for readability.
cohort$bw_change <- cohort$diff

# --- first cut: which designations move weight. eth_hispanic:eth_white = access axis. ---
m <- lm(bw_change ~ eth_hispanic * eth_white + eth_black + eth_asian + eth_amind_pacisl, data = cohort)
print(summary(m))

# descriptive companion: mean weight change per Latino-access bucket
cat("\nmean bw_change by latino_access:\n")
print(tapply(cohort$bw_change, cohort$latino_access, mean, na.rm = TRUE))


########################################################################################################################
# looking into weight lost patterns and trends
# what is the pattern with weight loss:
# what is happening with days and diff
#
# claude: SAS -> nlme map here
#################################################################################################
# SAS TYPE=     #  nlme
#################################################################################################
#     CS        #  correlation = corCompSymm(form = ~ 1 | id)  # == lme(random = ~1|id)
#     AR(1)     #  correlation = corAR1(form = ~ occ | id)
#     UN        #  correlation = corSymm(form = ~ occ | id) + weights = varIdent(form = ~1|occ)
#     CSH       #  corCompSymm + varIdent(~1|occ)
#     ARH(1)    #  corAR1      + varIdent(~1|occ)
#     GROUP=g   #  weights = varIdent(form = ~1 | g)
#################################################################################################
# t=2 reality (we only have first/last): corSymm == corAR1 == corCompSymm (1 off-diagonal).
# AR(1) is meaningless here (needs >=3 ordered times, e.g. HW3 CO2-over-day).
#
# Only real choice: CS (var[first]=var[last]) vs UN/CSH (unequal pre/post variance).
## lol; okay AI aside we need to do both CS and UN/CSH these are the required testing for building these models.
# i am positive it is this model so I am going to build on to this data structure. I am sure all diagnositics will show. 
########################################################################################################################
# plot(x=cohort$fl.cnt, y=cohort$diff)

#################################################
# going from wide to long format
# [please understand this code] switched bw_detail -> cohort so the reshape uses the inclusion-locked
# population. N here = nrow(cohort), not 827.
#################################################
long <- data.frame(
    user.id = rep(cohort$readable.id, 2),
    bw_measure = c(cohort$first, cohort$last),

    # 0=first and 1=last: basic t-test set up
    time = rep(c(0L, 1L), each = nrow(cohort)),
    mem.type = rep(cohort$mem.type, 2),
    fl.cnt = rep(cohort$fl.cnt, 2)
)

# occasion index for R-side matrix: this is matrix stuff...refer to the SAS proc mixed guide for the notation.
long$occ <- factor(long$time)

#################################################
# baseline: paired t (== SAS proc ttest; paired last*first). sanity anchor.
# this says we do not have equal variances.
#################################################
print(t.test(cohort$last, cohort$first, paired = TRUE))   # print() so it shows under source(main.R)

#################################################
# CS: equal pre/post variance (== random intercept == plain paired-t)
#################################################
m.cs <- gls(bw_measure ~ time + factor(mem.type),
            data=long,
            correlation=corCompSymm(form=~1 | user.id))

#################################################
# UN/CSH: unequal first-vs-last variance (heteroscedastic paired)
#################################################
m.un <- gls(bw_measure ~ time + factor(mem.type),
            data = long,
            correlation=corSymm(form=~as.integer(occ) | user.id),
            weights=varIdent(form=~1 | occ))

# LRT, 1 df: does unequal pre/post variance pay off?
# this is the test and we see that we do not have equal variances.
# so the unstructured covariance matrix is the way to go.
print(anova(m.cs, m.un))

## so just like written below we do have covariates in both between and within subjects.
##
# mem.type / fl.cnt are between-subject (constant within user.id).
# informative forms are the interactions: time:factor(mem.type), time:fl.cnt (does group/gap change the loss).

#################################################
# LOG REFIT: weight is right-skewed (log-normal), so refit the chosen UN model on log(weight).
#################################################
m.un.log <- gls(log(bw_measure) ~ time + factor(mem.type),
                data = long,
                correlation = corSymm(form = ~ as.integer(occ) | user.id),
                weights     = varIdent(form = ~ 1 | occ))
print(summary(m.un.log))

########################################################################################################################
# Residual Diagnostics -- THE CALL (engine defined at top). Add/remove models freely; it scales.
########################################################################################################################
#################################################
# distribution of the outcome (weight). right-skewed -> log-normal is the standard model for body weight
# (gamma is the alt). raw QQ curves up; log QQ should straighten if log-normal holds.
#################################################
w <- long$bw_measure
op <- par(mfrow = c(1, 3), mar = c(4, 4, 2.5, 1))
hist(w, breaks = 40, freq = FALSE, main = "weight (lbs)", xlab = "lbs")
lines(density(w), col = "red", lwd = 2)
qqnorm(w,      main = "QQ: raw weight");  qqline(w,      col = "red")
qqnorm(log(w), main = "QQ: log weight");  qqline(log(w), col = "red")
par(op)

# m.un vs m.un.log = the transform check: does the QQ straighten on the log scale?
resid_diag(m.cs, m.un, m.un.log)

########################################################################################################################
# so my mixed models approach is not going to work. we will have to go with a feed approach.. 
# WHY THE TAILS ARE HEAVY: outliers vs grouping vs a missing condition (the evidence trail)
# next model choice is evidence-based, not a guess. Three checks, each printed.
########################################################################################################################
# check 1: is this a data artifact that we can trim?
# flag members with a large normalized residual, then LOOK at their actual weights.
r_norm <- resid(m.un.log, type = "normalized")

# this gets me the list of members with huge variation
bad <- unique(long$user.id[abs(r_norm) > 4])

# quick script for printing out the number of members and a percentage. 
cat("\n[check 1] suspect ids (|norm resid|>4):", length(bad), "of", nrow(cohort),
    "->", round(100*length(bad)/nrow(cohort)), "% of the sample\n")

# let me get some of the bad members and print them out. 
susp <- cohort[cohort$readable.id %in% bad, c("readable.id","first","last","diff","fl.cnt","mem.type")]
print(head(susp[order(-abs(susp$diff)), ], 12), row.names = FALSE)

# nothing seems weird here. I have family who could have been one of these data points. 
# this looks real. I can not trim there is heterogeneity here.

# check 2: MISSING CONDITION? is weight loss tied to baseline weight?
# the stacked bw_measure model predicts a population-average weight, ignoring who the member is, so a
# heavy member sits ~+100 lb from fitted at BOTH occasions -> that is the +/-15-20 residual scale.
cat("\n[check 2] does baseline weight (first) explain the change (diff)?\n")

# slope + R^2 = strength of the missing condition
print(summary(lm(diff ~ first, data = cohort)))
plot(cohort$first, cohort$diff, pch = 20, col = "grey40",
     xlab = "baseline weight (first, lbs)", ylab = "diff = first - last (lbs)",
     main = "loss vs baseline weight")
abline(lm(diff ~ first, data = cohort), col = "red", lwd = 2)
abline(h = 0, lty = 3)

# check 3: GROUPING? does the loss cluster by the observed group (mem.type)? ---
cat("\n[check 3] loss by member type (grouping):\n")
print(t(sapply(split(cohort$diff, cohort$mem.type),
               function(x) c(n = length(x), mean = round(mean(x),1), sd = round(sd(x),1)))))
boxplot(diff ~ mem.type, data = cohort, las = 2, cex.axis = 0.7,
        ylab = "diff (lbs)", main = "loss by member type")

########################################################################################################################
# CONCLUSION (from the 3 checks):
#   - not outliers to trim (check 1);
#   - the dominant issue is a MISSING CONDITION = baseline weight (check 2 slope);
#   - mem.type adds some observed grouping (check 3).
# FIX = pivot the driver model to the paired difference (one row/member), baseline-adjusted:
#     diff ~ first + factor(mem.type) + fl.cnt + <engagement> + <modules>
#   modeling `diff` differences-out baseline; `first` on the RHS catches regression-to-mean. This is Task 8.
########################################################################################################################

########################################################################################################################
# Variable selection
# this block I will develop but it will be where I select which variables to pass into the residual diagnostic block.
# this gives us all of the potential variables to check. This hsould match the breifing document. 
########################################################################################################################
cohort <- cohort[,c("readable.id","sex","ethnicity","first","diff","fl.cnt","day.total","mem.type","breadth","volume_rep","tenure_days","volume_rep_rate","mod.core","mod.mindset",
                    "mod.nutrition","mod.phys","mod.mean","mod.sum")]
cohort$glp.all <- "delete"
cohort$glp.all <- ifelse(cohort$mem.type == "Active Generic Medication for Weight-loss (NOT on GLP-1 for weight-loss)", "Generic", cohort$glp.all)
cohort$glp.all <- ifelse(cohort$mem.type == "Active GLP-1 for Diabetes" , "GLP-1 (All)", cohort$glp.all)
cohort$glp.all <- ifelse(cohort$mem.type == "Active GLP-1 for Weight-loss", "GLP-1 (All)", cohort$glp.all)
cohort$glp.all <- ifelse(cohort$mem.type == "Coaching Only", "Coaching", cohort$glp.all)

cohort$wl.only <- cohort$glp.all
cohort$wl.only <- ifelse(cohort$mem.type == "Active GLP-1 for Diabetes", "delete", cohort$wl.only)

table(cohort$glp.all)
table(cohort$wl.only)

########################################################################################################################
# difference and percent change approach.
# wide format now (one row/member). pick the OUTCOME SCALE first: absolute lbs (diff) vs percent (pct).
# same RHS on both so the only thing changing is the scale -> resid_diag compares them head to head.
########################################################################################################################
cohort$pct <- 100 * cohort$diff / cohort$first          # clinical standard; >=5% = meaningful. pct>0 = % lost.
bad_pct <- which(abs(cohort$pct) > 100)
if (length(bad_pct)) {
  cat(sprintf("\n[guard] %d members with |pct| > 100%% (physically impossible -> likely bad `first`) - inspect:\n", length(bad_pct)))
  print(cohort[bad_pct, c("readable.id","first","last","diff","pct")])
} else {
  cat("\n[guard] no members with |pct| > 100% (no exploded outcomes).\n")
}

logi.glp <- !cohort$glp.all == "delete"
logi.wl <- !cohort$wl.only == "delete"
logi.null <- !cohort$mem.type == "Null"

# outcome in pounds:
m.abs.norm <- lm(diff ~ first + factor(mem.type) + fl.cnt, data = cohort)
m.abs.nnull <- lm(diff ~ first + factor(mem.type) + fl.cnt, data = cohort[logi.null,])
m.abs.glp1 <- lm(diff ~ first + factor(glp.all) + fl.cnt, data = cohort[logi.glp,])
m.abs.wl <- lm(diff ~ first + factor(wl.only) + fl.cnt, data = cohort[logi.wl, ])

summary(m.abs.norm)
summary(m.abs.nnull)
summary(m.abs.glp1)
summary(m.abs.wl)

# outcome in percent
m.pct.norm <- lm(pct ~ first + factor(mem.type) + fl.cnt, data = cohort)
m.pct.nnull <- lm(pct ~ first + factor(mem.type) + fl.cnt, data = cohort[logi.null,])
m.pct.glp1 <- lm(pct ~ first + factor(glp.all) + fl.cnt, data = cohort[logi.glp,])
m.pct.wl <- lm(pct ~ first + factor(wl.only) + fl.cnt, data = cohort[logi.wl, ])

print(summary(m.pct.norm))
print(summary(m.pct.nnull))
print(summary(m.pct.glp1))
print(summary(m.pct.wl))

resid_diag(m.pct.norm,m.pct.nnull, m.pct.glp1, m.pct.wl)

# robuts standard errors for reporting
print(coeftest(m.pct.glp1, vcov=vcovHC(m.pct.glp1, type="HC3")))

########################################################################################################################
# Data-driven feature selection: LASSO on top of the m.pct.glp1 core
#
# m.pct.glp1 is the confirmed base: pct ~ first + glp.all + fl.cnt  (R2 ~ .33).
# Now the data driven part: which engagement/module/demographic features earn their place ON TOP of that core.
# LASSO because of the collinearity: basically the moduls and the egagement columns.
#
# the core (first, glp.all, fl.cnt) is FORCED IN via penalty.factor=0 so LASSO only chooses among the
# candidates -- it can never drop the terms we already proved matter. RF stays a confirmatory slide later.
#
# candidate granularity (domain-reduced BEFORE handing to LASSO, so the pick is interpretable):
# engagement : breadth, volume_rep, tenure_days, volume_rep_rate
# modules    : mod.mean (one engagement-depth scalar). mod.sum dropped -- identical to mod.mean
#                (sum = mean * ntracks), and the 4 track props are collinear with the mean -> pick one.
# demographics: sex only. ethnicity is reporting-only (Table 1), NOT a model candidate.
########################################################################################################################
# m.pct.glp1 subset data
dat.glp <- cohort[logi.glp, ]

# one formula drives both the response and the design matrix so complete-case rows always line up
# (some members have NA engagement -> model.frame drops them from BOTH X and Y together, no length mismatch).
# I am just adding everything I think. 
f.cand <- pct ~ first + fl.cnt + glp.all +
    day.total +
    breadth + volume_rep +
    mod.core + mod.mindset + mod.nutrition + mod.phys + mod.sum +
    sex
# dropped: tenure_days (exact dup of day.total, r=1.0) and volume_rep_rate (r=0.955 w/ volume_rep,
# rate=volume/tenure) -- both inflate the joint LASSO design; see collinearity check in journal.

# creating the model frame.
mf <- model.frame(f.cand, data = dat.glp, na.action = na.omit)

# geting the reponse.
Y  <- model.response(mf)

# this is my design matrix but we are removing the first column
X  <- model.matrix(f.cand, mf)[, -1]

# summary of the run
cat(sprintf("LASSO design: n=%d  p=%d (candidates only, core forced in)\n", nrow(X), ncol(X)))

# penalty.factor = 0 -> unpenalized -> ALWAYS retained. core = first, fl.cnt, and the glp.all dummies.
pf <- ifelse(colnames(X) %in% c("first", "fl.cnt") | startsWith(colnames(X), "glp.all"), 0, 1)

# CV folds are random; seed = reproducible lambda
set.seed(1)
cv.las <- cv.glmnet(X, Y, alpha = 1, penalty.factor = pf, nfolds = 10, standardize = TRUE)

# lambda.1se = the parsimonious choice (sparsest model within 1 SE of the min CV error) -> report this.
# lambda.min = the min-CV-error choice -> printed too so you can see what the looser penalty would add.
cat("lambda.1se coefficients (report this one):\n");  print(coef(cv.las, s = "lambda.1se"))
cat("lambda.min coefficients (looser):\n");           print(coef(cv.las, s = "lambda.min"))

# which candidates survived at lambda.1se -> rebuild an lm on {core + survivors} for interpretable HC3 SE.
b.1se     <- coef(cv.las, s = "lambda.1se")
sel.names <- rownames(b.1se)[as.numeric(b.1se) != 0]

# exact-name match 
cand.cont <- c("day.total","breadth","volume_rep","mod.core","mod.mindset","mod.nutrition","mod.phys","mod.sum")
cand.fac  <- c("sex")
keep.cont <- cand.cont[cand.cont %in% sel.names]
keep.fac  <- cand.fac[vapply(cand.fac, function(v) any(startsWith(sel.names, v)), logical(1))]

# refit selected set as OLS -> signed coefs + HC3 robust SE (coeftest), and check it against m.pct.glp1
m.pct.lasso <- lm(reformulate(c("first","glp.all","fl.cnt", keep.cont, keep.fac), "pct"), data = dat.glp)
print(summary(m.pct.lasso))
print(coeftest(m.pct.lasso, vcov = vcovHC(m.pct.lasso, type = "HC3")))
resid_diag(m.pct.glp1, m.pct.lasso)

########################################################################################################################
# Which candidates are REAL independent drivers?  (incremental inference -- the complement to LASSO)
# [please understand this code]
#   the LASSO above is a PREDICTION-parsimony screen: lambda.1se zeroes small-but-precise coefficients. that
#   is NOT a significance test -- reading "LASSO dropped it" as "not a driver" is a mistake. so here we test
#   each candidate's INCREMENTAL effect on top of the core (first + glp.all + fl.cnt), one at a time, with
#   HC3-robust SE: estimate + p + added R2. finding: engagement/education ARE significant (just small in R2);
#   sex/tenure are not. THIS table is the evidence behind the driver slide, not the LASSO alone.
########################################################################################################################
core.rhs <- "first + glp.all + fl.cnt"
cands <- c("volume_rep","volume_rep_rate","breadth","tenure_days","mod.mean","mod.core",
           "mod.mindset","mod.nutrition","mod.phys","sex")
base.r2 <- summary(lm(as.formula(paste("pct ~", core.rhs)), data = dat.glp))$r.squared

driver.tab <- do.call(rbind, lapply(cands, function(v) {
    di <- dat.glp[!is.na(dat.glp[[v]]), ]                              # complete cases for this candidate
    m0 <- lm(as.formula(paste("pct ~", core.rhs)),         data = di)  # core on the SAME rows (fair R2 delta)
    m1 <- lm(as.formula(paste("pct ~", core.rhs, "+", v)), data = di)
    ct <- coeftest(m1, vcov = vcovHC(m1, type = "HC3"))
    rn <- grep(paste0("^", v), rownames(ct), value = TRUE)[1]          # factor -> first dummy (sex -> sexMALE)
    r2.0 <- summary(m0)$r.squared; r2.1 <- summary(m1)$r.squared
    data.frame(candidate  = rn,
               estimate   = round(ct[rn, "Estimate"], 4),
               HC3_p      = signif(ct[rn, "Pr(>|t|)"], 3),
               addl_R2    = round(r2.1 - r2.0, 4),                     # squared SEMI-partial (share of TOTAL var)
               partial_R2 = round((r2.1 - r2.0) / (1 - r2.0), 4),      # squared PARTIAL (share of core-UNEXPLAINED var)
               row.names  = NULL)
}))
driver.tab$sig <- ifelse(driver.tab$HC3_p < 0.05, "*", "")            # flag the significant ones
cat(sprintf("\nINCREMENTAL DRIVERS over core (%s), HC3; core R2=%.3f:\n", core.rhs, base.r2))
print(driver.tab[order(driver.tab$HC3_p), ])
cat(sprintf("Bonferroni alpha = %.4f across %d tests (only p below this clears multiplicity)\n",
            0.05 / length(cands), length(cands)))


# isn't ther supposed to be a final model here? Shouldn't this go into a model that I report?
# 1       volume_rep   0.0375 9.55e-06  0.0254     0.0377   *
# 5         mod.mean   0.6036 8.93e-03  0.0086     0.0128   *
# 3          breadth   0.1632 1.11e-02  0.0028     0.0042   *
# 2  volume_rep_rate   6.7959 2.21e-02  0.0170     0.0253   *
# 6         mod.core   0.2149 3.46e-02  0.0060     0.0090   *

########################################################################################################################
# FINAL reported driver model: clinical+exposure core + the ONE engagement lever that stays independently
# significant when the collinear survivors are entered together.
# [please understand this code]
#   driver.tab tested each candidate ALONE over the core. entered TOGETHER the survivors are collinear (all
#   scale with engagement), so it is NOT the sum of the one-at-a-times: with volume_rep in the model, mod.mean
#   and breadth collapse to ~0 (p>0.8). volume_rep is the only term that survives AND clears Bonferroni
#   (p=5e-4). so the reported model is parsimonious:
#     core (first + glp.all + fl.cnt) + volume_rep
#   volume_rep_rate, mod.core, mod.mean, breadth stay in driver.tab as documented one-at-a-time evidence, but
#   none add independently over volume_rep -> kept OUT of the reported model.
#   core is refit on the SAME complete-case rows so delta R2 is fair.
########################################################################################################################
final.cols <- c("first","glp.all","fl.cnt","volume_rep")     # for complete-case filter
final.rhs  <- "first + factor(glp.all) + fl.cnt + volume_rep" # model terms (matches core's factor())
df.fin <- dat.glp[complete.cases(dat.glp[, final.cols]), ]
m.pct.final <- lm(as.formula(paste("pct ~", final.rhs)), data = df.fin)
m.pct.core  <- lm(pct ~ first + factor(glp.all) + fl.cnt, data = df.fin)   # core carries fl.cnt (exposure window) so delta R2 isolates the engagement/education lift
cat("\nFINAL reported model (core + non-redundant engagement/education drivers), HC3:\n")
print(coeftest(m.pct.final, vcov = vcovHC(m.pct.final, type = "HC3")))
cat(sprintf("FINAL R2 = %.3f | core R2 (same rows) = %.3f | delta R2 = %.3f | n = %d\n",
            summary(m.pct.final)$r.squared, summary(m.pct.core)$r.squared,
            summary(m.pct.final)$r.squared - summary(m.pct.core)$r.squared, nrow(df.fin)))
resid_diag(m.pct.core, m.pct.final)


########################################################################################################################
# Interaction test: does engagement pay off DIFFERENTLY by drug class?
# [please understand this code]
#   LASSO killed volume_rep as a MAIN effect -> "more logging helps everyone equally" is false. but the
#   actionable question is the INTERACTION: "does logging move the needle for GLP-1 members differently than
#   for Coaching members?" that's glp.all:volume_rep. a significant interaction is the recommendation lever
#   (target engagement where it actually pays). we test it two ways:
#     (1) anova nested F: main-effects model vs interaction model, on IDENTICAL rows (anova needs same data);
#     (2) HC3-robust coeftest for the signed interaction terms.
########################################################################################################################
di <- dat.glp[!is.na(dat.glp$volume_rep), ]                # complete volume_rep so both models share rows
m.pct.main <- lm(pct ~ first + glp.all + volume_rep + fl.cnt, data = di)
m.pct.int  <- lm(pct ~ first + glp.all * volume_rep + fl.cnt, data = di)

print(anova(m.pct.main, m.pct.int))                        # single F test on the glp.all:volume_rep block
print(coeftest(m.pct.int, vcov = vcovHC(m.pct.int, type = "HC3")))
resid_diag(m.pct.main, m.pct.int)

########################################################################################################################
# OBJECTIVE 1 (Brief): patterns & trends in WEIGHT CHANGE -- clinical responder framing.
# [please understand this code] this is DESCRIPTIVE, not the model. pct = % of baseline weight lost (>0 = lost).
#   >=5% is the accepted clinical threshold for MEANINGFUL weight loss. a clinical/business panel expects
#   responder RATES, not just mean lbs. this turns the continuous outcome into the number leadership acts on.
########################################################################################################################
cohort$resp5 <- as.integer(cohort$pct >= 5)                    # 1 = clinically meaningful loss (>=5% of baseline)

cat(sprintf("\nWEIGHT CHANGE overall: mean %%loss=%.1f  median %%loss=%.1f  >=5%% responders=%.0f%% (%d/%d)\n",
            mean(cohort$pct, na.rm = TRUE), median(cohort$pct, na.rm = TRUE),
            100 * mean(cohort$resp5, na.rm = TRUE), sum(cohort$resp5, na.rm = TRUE), nrow(cohort)))

# by member type (full granularity: shows Null=60 and GLP-1 diabetes=7 for honesty)
by.type <- data.frame(
    mem.type   = levels(factor(cohort$mem.type)),
    n          = as.integer(table(cohort$mem.type)),
    median_pct = round(tapply(cohort$pct,   factor(cohort$mem.type), median, na.rm = TRUE), 1),
    resp5_rate = round(100 * tapply(cohort$resp5, factor(cohort$mem.type), mean, na.rm = TRUE), 1),
    row.names  = NULL)
cat("\nresponder rate & median %loss by mem.type:\n"); print(by.type)

# deck version: collapsed drug class (Coaching / Generic / GLP-1 (All)), Null dropped via logi.glp
resp.by.drug <- round(100 * tapply(cohort$resp5[logi.glp], cohort$glp.all[logi.glp], mean, na.rm = TRUE), 1)
cat("\n>=5% responder rate by drug class (glp.all):\n"); print(resp.by.drug)

op <- par(mar = c(4, 4, 2.5, 1))                               # visual: the money chart
barplot(resp.by.drug, col = "steelblue", ylim = c(0, 100), ylab = "% achieving >=5% loss",
        main = ">=5% weight-loss responders by drug class")
par(op)

########################################################################################################################
# OBJECTIVE 2 (Brief): patterns & trends in ENGAGEMENT ACTIVITIES -- DESCRIPTIVE, not a model.
# [please understand this code] the LASSO answers "does engagement PREDICT weight loss" (Objective 3, answer=no).
#   THIS block answers "what does engagement LOOK LIKE" (Objective 2): how much members log, how broad, whether
#   it differs by drug class. describing engagement is a separate deliverable from regressing it -- feature
#   selection dropping volume_rep does NOT describe engagement, it only says it isn't a driver.
########################################################################################################################
cat(sprintf("\nENGAGEMENT coverage: %d of %d cohort members have engagement data\n",
            sum(!is.na(cohort$volume_rep)), nrow(cohort)))

cat("\nengagement volume / breadth / tenure / rate (distribution):\n")
print(summary(cohort[, c("volume_rep","breadth","tenure_days","volume_rep_rate")]))

# do GLP-1 members engage more than coaching-only? (median is robust to the volume skew)
cat("\nmedian engagement by drug class (glp.all):\n")
print(aggregate(cbind(volume_rep, breadth, tenure_days, volume_rep_rate) ~ glp.all,
                data = cohort[logi.glp, ], FUN = median))

cat("\nmean module completion (mod.mean) by drug class:\n")
print(round(tapply(cohort$mod.mean[logi.glp], cohort$glp.all[logi.glp], mean, na.rm = TRUE), 3))

op <- par(mfrow = c(1, 2), mar = c(4, 4, 2.5, 1))             # visuals: volume distribution + by drug class
hist(cohort$volume_rep, breaks = 30, col = "grey80",
     main = "Engagement volume (all members)", xlab = "repeatable events (volume_rep)")
boxplot(volume_rep ~ glp.all, data = cohort[logi.glp, ], col = "grey80",
        main = "Engagement by drug class", xlab = "", ylab = "volume_rep")
par(op)


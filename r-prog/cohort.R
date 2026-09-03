########################################################################################################################
# cohort.R  -- inclusion / attrition waterfall -> LOCKED cohort
#
# Lock the population HERE, before modeling / feature selection. covariates.R depends on `cohort`.
# Depends on `analytic` from merging.R.
########################################################################################################################

# this is just a print of status. the option to print missing data as well. 
# levels are UPPERCASE: ACTIVE / FINISHED / PAUSED
print(table(analytic$status, useNA = "ifany"))

# SET: which subscription statuses stay in
# incl_status <- c("ACTIVE", "FINISHED", "PAUSED")
incl_status <- c("ACTIVE", "FINISHED")

step <- function(label, keep, prev_n) data.frame(step = label, n = sum(keep), dropped = prev_n - sum(keep))

keep_bw   <- analytic$has_bw == 1
keep_type <- keep_bw   & analytic$has_type == 1
keep_stat <- keep_type & analytic$status %in% incl_status
n_universe <- nrow(analytic)
waterfall <- rbind(
  data.frame(step = "0. enrolled universe (demographics)", n = n_universe, dropped = 0L),
  step("1. has BW outcome (first + last)",   keep_bw,   n_universe),
  step("2. has member type",                 keep_type, sum(keep_bw)),
  step("3. eligible subscription status",    keep_stat, sum(keep_type))
)

# THE TABLE WE WANT
print(waterfall)

# This is the output table we will be using. 
cohort <- analytic[keep_stat, ]
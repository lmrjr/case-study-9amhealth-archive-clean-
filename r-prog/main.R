########################################################################################################################
# SETTING UP MY PATH
########################################################################################################################
dir.main <- "projects/"
dir.loc <- "internal/"
dir.prj <- "case-study-9amhealth-archive/"
dir.data <- "data/"
dir.prog <- "r-prog"

# top folder for this project
prj.loc <- paste0(dir.main,dir.loc,dir.prj)

# where the data is located
data.loc <- paste0(dir.main,dir.loc,dir.prj,dir.data)

# where this file is located...as well as other files that will be included
prog.loc <- paste0(dir.main,dir.loc,dir.prj,dir.prog)

########################################################################################################################
# includes -- ONE entry point: `source("main.R")` runs the whole pipeline + regenerates every deck artifact.
# [please understand this code] run order matters: each file uses objects the previous one leaves in the
# environment. functions -> explore -> merging -> cohort -> demo_table -> covariates -> deck_charts3 -> power.
########################################################################################################################
# functions.R  : helper defs (ipak, read_case, sanitize_names, rename_keep_label). no side effects.
source(paste0(prog.loc, "/functions.R"))

# load/attach packages ONCE, before any file that uses sqldf/nlme. readODS = write Table-1 .ods.
ipak(c("sqldf","nlme","sandwich","lmtest","glmnet","readODS"))

# explore.R    : load 4 CSVs (UTF-16 fix) + build member-level features.
source(paste0(prog.loc, "/explore.R"))

# merging.R    : left-join features onto the 865 spine -> `analytic` + presence flags.
source(paste0(prog.loc, "/merging.R"))

# cohort.R     : inclusion waterfall (CONSORT) -> locks `cohort`.
source(paste0(prog.loc, "/cohort.R"))

# demo_table.R : Table-1 by member type -> figures/demo-table.ods. MUST precede covariates.R (which
# strips the columns this table needs: status, eth_* indicators, last).
source(paste0(prog.loc, "/demo_table.R"))

# covariates.R : covariate investigation + locked driver model (ethnicity lm, CS/UN gls, %-change + LASSO/HC3).
source(paste0(prog.loc, "/covariates.R"))

# deck_charts3.R : the 3 story figures (pct distribution, engagement co-move, driver forest).
source(paste0(prog.loc, "/deck_charts3.R"))

# deck_tables.R : the 2 model-output tables (hypothesis scorecard + coefficient table).
source(paste0(prog.loc, "/deck_tables.R"))

# power.R      : design-power appendix + figures/power_precision.png.
source(paste0(prog.loc, "/power.R"))

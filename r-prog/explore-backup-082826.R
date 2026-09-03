########################################################################################################################
# 9amHealth Data Analyst Case Study - exploration scaffold (R).
# Key Business Question: 
# What are the key drivers of clinical improvement in body weight among 9amHealth members?
#
# Context: 
#  At 9amHealth, understanding what drives meaningful clinical improvements is essential to tailoring effective care 
# and support strategies. This case study focuses on identifying which factors correlate most with body weight reduction
# over time, and how these insights can shape program enhancements. 
#
# You are provided with a de-identified dataset containing demographics, body weight changes, engagement activity, and
# progress in health education modules from a sample of members.
#
# You will use this data to explore the impact of engagement, demographics, educational program involvement, and 
# behavior change on weight change outcomes. 
#
# Objective: 
#  Analyze the provided datasets and present a concise, strategic narrative that: 
#  - Identifies key patterns and trends in weight change.  
#  - Identifies key patterns and trends in engagement activities.  
#  - Determines which engagement activities or member characteristics most strongly correlate with weight loss success. 
#  - Provides actionable recommendations for leadership. 
#
# Candidate Responsibilities: 
# You are expected to:  
# 1. Break down the key question into sub-questions and formulate hypotheses.
# 2. Determine which data columns are most relevant and how to structure your analysis.
# 3. Perform the analysis using a tool of your choice.
# 4. Use visuals to support your conclusions.  
# 5. Clearly communicate implications to senior leadership.
########################################################################################################################

########################################################################################################################
# SETTING UP MY PATH
########################################################################################################################
dir.main <- "projects/"
dir.loc <- "internal/"
dir.prj <- "case-study-9amhealth/"
dir.data <- "data/"
dir.prog <- "r-prog"

# top folder for this project
prj.loc <- paste0(dir.main,dir.loc,dir.prj)

# where the data is located
data.loc <- paste0(dir.main,dir.loc,dir.prj,dir.data)

# where this file is located...as well as other files that will be included
prog.loc <- paste0(dir.main,dir.loc,dir.prj,dir.prog)

########################################################################################################################
# functions
########################################################################################################################
############################################################################################
# function for installing packages and loading them. 
ipak <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dependencies = TRUE)
  sapply(pkg, require, character.only = TRUE)
}

# list of packages to install
#packages <- c("sqldf","nlme")
#ipak(packages)

############################################################################################
# fix fo the utf-16 encoding...idk I'm on linux and this was the solution according to claude.
read_case <- function(path) {
  read.delim(path, fileEncoding = "UTF-16", check.names = FALSE,
             stringsAsFactors = FALSE)
}

############################################################################################
# sanitize_names: strip spaces from every column name (sqldf/base-friendly),
# stash each original name in a "label" attribute (SAS name-vs-label idea).
#   - make.names() : "Readable Id" -> "Readable.Id"; also fixes leading digits + dup names.
#   - label written only if none exists yet, so re-running won't overwrite the first original.
#   - read back:  attr(df$Readable.Id, "label")   or   sapply(df, attr, "label")
#   - caveat: labels are per-column attrs; merge()/rbind() can drop them -> re-check after joins.
sanitize_names <- function(df) {
  for (nm in names(df)) if (is.null(attr(df[[nm]], "label"))) attr(df[[nm]], "label") <- nm
  names(df) <- make.names(tolower(names(df)), unique = TRUE)
  df
}

############################################################################################
# just incase I mess up and need to do a quick rename
# rename a single column, keep the old name as its label:
rename_keep_label <- function(df, old, new) {
  lab <- attr(df[[old]], "label")
  if (is.null(lab)) lab <- old
  names(df)[names(df) == old] <- new
  attr(df[[new]], "label") <- lab
  df
}

########################################################################################################################
# Datasets Provided: 
# 1. Demographics.csv: Includes age, sex, ethnicity, subscription status, and cancellation date. 
# 2. BW_Detail.csv: Contains first and last recorded body weight measurements over the defined period, weight difference, time between measurements, and total time in program. 
# 3. Engagement Data.csv: Tracks member activities and engagement events over time (e.g., registration, medical questionnaire answered, subscription events). 
# 4. Module Progress.csv: Records each member’s completion of educational health modules, including goal setting, physical activity, emotional eating, and mindset topics. 

########################################################################################################################
# reading in my data
####################################
# reading in the modules & removing empty column (this was verified) & created formatted date column
modules <- read_case(file.path(data.loc, "Data Analyst Case Study Doc 1 - 12 Weeks Weight Loss Modules Completion.csv"))
modules <- modules[, 1:3]
modules$`Day of Answered At (All Questionnaire Records)` <- as.Date(modules$`Day of Answered At (All Questionnaire Records)`, format = "%d %B %Y")

# changing names: two need to be picked and one can be automated. 
modules <- rename_keep_label(modules, old = "Day of Answered At (All Questionnaire Records)", new = "date.answer")
modules <- rename_keep_label(modules, old = "Questionnaire Title (All Questionnaire Records)", new = "mod.title")
modules <- sanitize_names(modules)

####################################
# reading in demographics, drop empty column, format dates (Claude read the csv provided the format defintions)
demographics <- read_case(file.path(data.loc, "Data Analyst Case Study Doc 2 - Demographics.csv"))
demographics <- demographics[, 1:6]
demographics$`Day of Start Date` <- as.Date(demographics$`Day of Start Date`, format = "%B %d, %Y")
demographics$cancellation_date <- as.Date(demographics$cancellation_date, format = "%m/%d/%Y")

# changing names
demographics <- rename_keep_label(demographics, old="Day of Start Date", new="start.date")
demographics <- rename_keep_label(demographics, old="Status (Subscriptions)", new="status")
demographics <- rename_keep_label(demographics, old="cancellation_date", new="cancel.date")
demographics <- sanitize_names(demographics)

####################################
# reading in engagement
engagement <- read_case(file.path(data.loc, "Data Analyst Case Study Doc 3 - Engagement Data.csv"))
engagement <- engagement[, 1:3]
engagement$`Day of Activity Timestamp` <- as.Date(engagement$`Day of Activity Timestamp`, format = "%B %d, %Y")

# changing names
engagement <- rename_keep_label(engagement, old="Day of Activity Timestamp", new="engagement.date")
engagement <- sanitize_names(engagement)

####################################
# reading in bw details
bw_detail <- read_case(file.path(data.loc, "Data Analyst Case Study Doc 4 - BW_Detail.csv"))
bw_detail$`Day of BW First Measurement Effective` <- as.Date(bw_detail$`Day of BW First Measurement Effective`, format = "%B %d, %Y")
bw_detail$`Day of BW Last Measurement Effective` <- as.Date(bw_detail$`Day of BW Last Measurement Effective`, format = "%B %d, %Y")

# changing names
tmp.lst <- names(bw_detail)
bw_detail <- rename_keep_label(bw_detail, old=tmp.lst[2], new="mem.type")
bw_detail <- rename_keep_label(bw_detail, old=tmp.lst[3], new="fist.date")
bw_detail <- rename_keep_label(bw_detail, old=tmp.lst[4], new="last.date")
bw_detail <- rename_keep_label(bw_detail, old=tmp.lst[8], new="fl.cnt")
bw_detail <- rename_keep_label(bw_detail, old=tmp.lst[9], new="day.total")
bw_detail <- sanitize_names(bw_detail)

# cleaning global environment
rm(tmp.lst)

####################################
# creating list to loop through: 
sets <- list(
  # data is in long format
  modules = modules,
  
  # wide format
  demographics = demographics,
  
  # long format
  engagement = engagement,
  
  # wide format
  bw_detail = bw_detail)

# printing: name, dimensions, column names and first 3 rows of data
for (nm in names(sets)) {
  df <- sets[[nm]]
  cat("\n===== ", nm, " =====\n", sep = "")
  cat("shape: ", nrow(df), " x ", ncol(df), "\n", sep = "")
  cat("cols : ", paste(names(df), collapse = " | "), "\n", sep = "")
  print(utils::head(df, 3))
  print(str(df))
}

# sanity check: every file loaded with rows + cols (catches an encoding regression)
stopifnot(all(vapply(sets, function(x) nrow(x) > 0 && ncol(x) > 1, logical(1))))
cat("\nOK - all 4 datasets loaded.\n")

#cleaning global environment
rm(sets, nm, df)

########################################################################################################################
# Key Business Question: 
# What are the key drivers of clinical improvement in body weight among 9amHealth members?
# 1. Break down the key question into sub-questions and formulate hypotheses.
# 2. Determine which data columns are most relevant and how to structure your analysis.
# 
# great a I need to remove the last column of some of these tables. 
# 
########################################################################################################################
# checking ID uniqueness and blah blah... at least I know I can join to a top number of 865 theoretically. 
# tables in wide format: unique IDs
length(demographics$readable.id)
length(bw_detail$user.id)

# these are in long format: repeating IDs
length(unique(modules$readable.id))
length(unique(engagement$readable.id))

# checking to see if there are any unique IDs
# lets check the tables with the most IDs: demographics and unique-engagement
sum(unique(engagement$readable.id) %in% demographics$readable.id)

# okay so all 865 are found in both demo and unique engagement: so we are going to use these to test
# by using %in% we are testing to see if the bigger table is contained in modules or bw_details
# we get back the full length of the modules and bw_details. so yes we can join all IDs and no one is missing. 
sum(unique(engagement$readable.id) %in% unique(modules$readable.id))
sum(demographics$readable.id %in% bw_detail$user.id)

########################################################################################################################
# joining demographics and bw_details.
# lets see what we can find or see with the DV and the demos. 
# vikunja:
# task 3: `http://192.168.1.30:3456/tasks/105`  Is Readable ID the same as User Id. 
# task 7: `http://192.168.1.30:3456/tasks/109`  Demographics + subscription/churn profile
#
########################################################################################################################
# task 3
dv.demo <- merge(x=demographics, y=bw_detail, by.x="readable.id", by.y="user.id", all=TRUE)

# Task 7:
table(dv.demo$sex)

# Claude: Look here
table(dv.demo$ethnicity, dv.demo$sex)

# Claude: Add Here
########################################################################################################################
# ETHNICITY: indicator encoding + Latino-access interaction + first weight-change model.
# All base R. No packages. Self-contained (rebuilds indicators so this block runs alone).
#
# WHY indicators, not one collapsed "multiethnicity" factor:
#  - ethnicity is self-reported multi-select (comma list). Collapsing to one bucket forces a
#    single race per member -> erases mixed/Latino identity. Sharghi 2024: collapsing racial
#    categories for ANALYSIS is "very seldom appropriate".
#  - keeping designations separate keeps the WHITE co-tag visible: latino+white (better access)
#    stays numerically distinct from latino-only. That distinction is the point in a weight study.
########################################################################################################################

# --- 1. atomic designations -> one 0/1 column each. member counts in EVERY group marked. ---
eth_levels <- c(
    eth_amind    = "AMERICAN_NATIVE_OR_ALASKAN_NATIVE",
    eth_asian    = "ASIAN",
    eth_black    = "BLACK_OR_AFRICAN_AMERICAN",
    eth_hispanic = "HISPANIC_LATINO",
    eth_pacisl   = "NATIVE_HAWAIIAN_OR_PACIFIC_ISLANDER",
    eth_white    = "WHITE"
)

# split each member's comma multi-select into a clean set of tags
tag_sets <- lapply(strsplit(demographics$ethnicity, ","),
                   function(x) trimws(x[trimws(x) != ""]))

for (col in names(eth_levels)) {
  demographics[[col]] <- as.integer(
    vapply(tag_sets, function(t) eth_levels[[col]] %in% t, logical(1)))
}

demographics$eth_ntags    <- lengths(tag_sets)                       # 0..5 marked
demographics$eth_reported <- as.integer(demographics$eth_ntags >= 1) # 0 = Unknown/Not reported (9)

# --- 2. low-cell fold: amind(13)+pacisl(7) too thin for own coef. STABILITY only, model only. ---
demographics$eth_amind_pacisl <- as.integer(
  demographics$eth_amind == 1 | demographics$eth_pacisl == 1)

# --- 3. Andrew-vs-family axis: Latino WITH white access vs WITHOUT. proxy for SES/food access. ---
demographics$latino_access <- factor(with(demographics, ifelse(
  eth_hispanic == 0, "non_latino",
  ifelse(eth_white == 1, "latino_white", "latino_nonwhite"))),
  levels = c("non_latino", "latino_white", "latino_nonwhite"))  # ref set on purpose, not by size

# --- checks: column totals must match the ethnicity x Sex table; row sums must match ntags ---
stopifnot(
  sum(demographics$eth_hispanic) == 166,
  sum(demographics$eth_white)    == 518,
  all(rowSums(demographics[names(eth_levels)]) == demographics$eth_ntags)
)
cat("indicators OK. latino_access spread:\n"); print(table(demographics$latino_access))

# --- 4. re-join to body weight so the new eth_* cols ride along ---
dv.demo <- merge(x = demographics, y = bw_detail,
                 by.x = "readable.id", by.y = "user.id", all = TRUE)

# >>> SET THIS to your real weight-difference column in bw_detail <<<
#     run  print(names(bw_detail))  to grab the exact string, then check its sign convention.
dv.demo$bw_change <- dv.demo$diff

# --- 5. first cut: which designations move weight. eth_hispanic:eth_white = access axis. ---
m <- lm(bw_change ~ eth_hispanic * eth_white + eth_black + eth_asian + eth_amind_pacisl,
        data = dv.demo)
print(summary(m))

# descriptive companion: mean weight change per Latino-access bucket
cat("\nmean bw_change by latino_access:\n")
print(tapply(dv.demo$bw_change, dv.demo$latino_access, mean, na.rm = TRUE))

# cleaning global environment
rm(eth_levels, tag_sets, col, m)

########################################################################################################################
####: The Ethnicity code block
# code for reporting by Claude
# HERE
# --- Table-1 composition (DESCRIPTIVE only; not a model term). Alphabetical per JAMA. ---
# multi-select => pct_of_reported sums >100 by design; footnote so no one "corrects" it.
# eth_amind_pacisl n=20 is power-starved; footnote, don't infer from it.
# eth_tab <- data.frame(
#   designation = c("Am. Indian/Alaska Native","Asian","Black/African American",
#                   "Hispanic/Latino","Native HI/Pacific Islander","White",
#                   "Multiethnic (>=2)","Not reported"),
#   n = c(sum(demographics$eth_amind), sum(demographics$eth_asian),
#         sum(demographics$eth_black), sum(demographics$eth_hispanic),
#         sum(demographics$eth_pacisl), sum(demographics$eth_white),
#         sum(demographics$eth_ntags >= 2), sum(demographics$eth_reported == 0)),
#   stringsAsFactors = FALSE)
# eth_tab$pct_of_reported <- round(100 * eth_tab$n / sum(demographics$eth_reported), 1)
# eth_tab
########################################################################################################################

########################################################################################################################
# bw_details
# bw_details
# bw_details
# bw_details
# not sure what to do with this section. 
# one active member has a finished date.  I am starting to think this means they have all of the engagements and education. 
# 
# for the cohort table we need to have a status and difference measure. I am still not sure how to model this but I am 
# thinking logintunianly as a paird t-test. 
# bw_details
# bw_details
# bw_details
# bw_details
########################################################################################################################
#################################################
# basic analysis of character strings and dates
#################################################
# there are two groups and 2 people who have paused their participation: in the cohort data set this needs to be a selection criteria value. 
table(dv.demo$status)

# 60 null who and what is going on here? 7 for GLP-1 for diabetes. 
table(dv.demo$mem.type)

# these are just Feburary and all in 2025. 
table(dv.demo$start.date)

# there is a time value but I am not sure if this is necessary. All 2025 and from Jan to Sept.  a total of 798 still active or paused. 
table(dv.demo$cancel.date)

# this shows an active member with a cancellation date. 
table(dv.demo$status, dv.demo$cancel.date)

#################################################
# what is the patter with weight loss:
# what is happening with days and diff
# I am going to need stuff from hub::: there should be a diagnostic file from my earlier work.
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
#################################################
# plot(x=bw_detail$fl.cnt, y=bw_detail$diff)

#################################################
# going from wide to long format
#################################################
long <- data.frame(
    user.id = rep(bw_detail$user.id, 2),
    bw_measure = c(bw_detail$first, bw_detail$last),

    # 0=first and 1=last: basic t-test set up
    time = rep(c(0L, 1L), each = nrow(bw_detail)),
    mem.type = rep(bw_detail$mem.type, 2),
    fl.cnt = rep(bw_detail$fl.cnt, 2)
)

# occasion index for R-side matrix: this is matrix stuff...refer to the SAS proc mixed guide for the notation. 
long$occ <- factor(long$time)

#################################################
# baseline: paired t (== SAS proc ttest; paired last*first). sanity anchor.
# this says we do not have equal variances.
#################################################
t.test(bw_detail$last, bw_detail$first, paired = TRUE)

#################################################
# CS: equal pre/post variance (== random intercept == plain paired-t)
#################################################
m.cs <- gls(bw_measure ~ time + factor(mem.type) + fl.cnt,
            data=long,
            correlation=corCompSymm(form=~1 | user.id))

#################################################
# UN/CSH: unequal first-vs-last variance (heteroscedastic paired)
#################################################
m.un <- gls(bw_measure ~ time + factor(mem.type) + fl.cnt,
            data = long,
            correlation=corSymm(form=~as.integer(occ) | user.id),
            weights=varIdent(form=~1 | occ))

# LRT, 1 df: does unequal pre/post variance pay off?
# this is the test and we see that we do not have equal variances.
# so the unstructured covariance matrix is the way to go. 
anova(m.cs, m.un)   

## so just like written below we do have covariates in both between and within subjects.
## 
# mem.type / fl.cnt are between-subject (constant within user.id).
# informative forms are the interactions: time:factor(mem.type), time:fl.cnt (does group/gap change the loss).

########################################################################################################################
# long formatted data sets
# engagement
# engagement
# engagement
# engagement
########################################################################################################################
# Number of events and members who have seen that event.
# A member can have a type more than once. 
sqldf('
select type,
    count(*) as events,
    count(distinct "readable.id") as members,
    1.0*count(*)/count(distinct "readable.id") as per_member
from engagement
group by type 
order by members desc')

# what is the distinct number of types (N=19)
sqldf('Select count(Distinct type) as cnt from engagement')

# so there are members with a min of 3 types and a max of 17. 
# no one has all 19.  Average says 10.62
sqldf('
select
    min(n_types) as min,
    avg(n_types) as avg,
    max(n_types) as max
from (select distinct "readable.id" as members,
        count(distinct type) as n_types
     from engagement
     group by "readable.id")')

###########################################
###########################################
# 1. classify each type: one-shot vs repeatable (this is the events/members diagnostic, formalized)
#    repeatable requires BOTH:
#      per_member >= 2.0  -> genuinely re-hit (cut sits in the empirical gap 1.64 -> 2.99)
#      members    >= 30   -> coverage floor; rare types (blood glucose: 6 members) are ~all-zero
#                            across the 865-member cohort and add noise, not signal.
type_class <- sqldf('
select type,
    count(*) as events,
    count(distinct "readable.id") as mbrs,
    1.0*count(*)/count(distinct "readable.id") as per_mbr,
    case
        when 1.0*count(*)/count(distinct "readable.id") >= 2.0 and count(distinct "readable.id") >= 30 then 1
        else 0
    end as repeatable
from engagement
group by type')

# 2.0 = midpoint of the only real gap in the per_member distribution (1.64 -> 2.99), not a thumb pick.
# 30  = coverage floor; loosen/tighten if you want rarer clinical events (BP, video calls) to count.

# 2. member-level features: breadth + repeatable-volume, joined to tenure, then rate-normalized
engage_feat <- sqldf('
select e."readable.id" as readable_id,
    count(distinct e.type) as breadth,
    sum(tc.repeatable) as volume_rep,
    b."day.total" as tenure_days
from engagement e
join type_class tc on e.type = tc.type
join bw_detail b on e."readable.id" = b."user.id"
group by e."readable.id", b."day.total"')

# rate = per week. pmax(tenure,7) guards divide-by-zero and absurd rates for <1-week tenure.
# breadth kept RAW (it saturates at 19, not tenure-accumulative); only volume gets rate-normalized.
engage_feat$volume_rep_rate <- engage_feat$volume_rep / pmax(engage_feat$tenure_days, 7)

# sanity: one row per member, no NA tenure (inner join to bw_detail should guarantee it)
stopifnot(!any(duplicated(engage_feat$readable_id)),
          !any(is.na(engage_feat$tenure_days)))
cat("\nengage_feat built:", nrow(engage_feat), "members. head:\n")
print(head(engage_feat))

# cleaning global environment
rm(type_class)

########################################################################################################################
# long formatted data sets
# modules
# modules
# modules
# modules
# modules
# modules
# So this is obviously a questionnaire or something similar to it. 
# So I am splitting it up into Core, mindset, nutrition, and physical activity. 
# then I am adding the average and sums of the splits. lowest possible value is 0 highest possible is 24. 
# modules
# modules
# modules
# modules
# modules
# modules
########################################################################################################################
# this is not going to work past this part. we can also see there is a 4 questionnaire break down. 
# looking at the data of modules not everyone is doing all modules. for Core: ID1 only did 9 skipping 2 and others.
sqldf('
select "mod.title",
    count(*) as events,
    count(distinct "readable.id") as members,
    1.0*count(*)/count(distinct "readable.id") as per_member
from modules
group by "mod.title" 
order by members desc')

# what is the distinct number of "mod.title"s (N=21)
sqldf('Select count(Distinct "mod.title") as cnt from modules')

# splitting by modules
mod_prop <- 
sqldf('
select top."readable.id",
  1.0*sum(case when top.track="CORE" then 1 else 0 end) as "mod.core",
  1.0*sum(case when top.track="MINDSET" then 1 else 0 end) as "mod.mindset",
  1.0*sum(case when top.track="NUTRITION" then 1 else 0 end) as "mod.nutrition",
  1.0*sum(case when top.track="PHYSICAL ACTIVITY" then 1 else 0 end) as "mod.phys"
from (
    select distinct main."readable.id", main."mod.title",
        case
            when substr(main."mod.title", 1,1) between "0" and "9" then "CORE"
            when main."mod.title" like "MINDSET%" THEN "MINDSET"
            when main."mod.title" like "NUTRITION%" THEN "NUTRITION"
            when main."mod.title" like "PHYSICAL ACTIVITY%" THEN "PHYSICAL ACTIVITY"
        end as track
    from modules as main) as top
group by top."readable.id"')

mod_prop$mod.mean <- rowMeans(mod_prop[, c("mod.core", "mod.mindset", "mod.nutrition", "mod.phys")])
mod_prop$mod.sum <- rowSums(mod_prop[, c("mod.core", "mod.mindset", "mod.nutrition", "mod.phys")])





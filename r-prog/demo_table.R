########################################################################################################################
# demo_table.R  -- Table-1 (demographics/measures x member type) -> figures/demo-table.ods
#
# MUST run AFTER cohort.R and BEFORE covariates.R: covariates.R reduces `cohort` to a modeling subset
# (drops status, the eth_* indicators, last, ...), which this table needs. Depends on `cohort`, `prj.loc`,
# and readODS (loaded once in main.R).
# categorical rows = n (%) of the column's members ; ethnicity is multi-select so its % sum >100 by design.
# continuous rows  = mean (SD). columns are the mem.type strata, header order matches the template.
########################################################################################################################
grp_levels <- c(
  "Active Generic Medication" = "Active Generic Medication for Weight-loss (NOT on GLP-1 for weight-loss)",
  "GLP-1 Diabetes"            = "Active GLP-1 for Diabetes",
  "GLP-1 Weight"              = "Active GLP-1 for Weight-loss",
  "Coaching"                  = "Coaching Only",
  "Null"                      = "Null")

# cell formatters: flag = logical over the column subset ; x = numeric vector
n_pct <- function(flag) sprintf("%d (%.1f%%)", sum(flag), 100 * mean(flag))
m_sd  <- function(x)    sprintf("%.1f (%.1f)", mean(x, na.rm = TRUE), sd(x, na.rm = TRUE))  # engagement cols carry NA (no-event members, left-join)

# row spec: label, kind ("h" header / "b" blank spacer / "v" value), fn(subset). h/b carry no fn.
spec <- list(
  list("Female (ref = Male)","v",      function(s) n_pct(s$sex == "FEMALE")),
  list("Active (ref = Finished)","v",  function(s) n_pct(s$status == "ACTIVE")),
  list("","b"),
  list("Ethnicity","h"),
  list("Am. Indian/Alaska Native","v",  function(s) n_pct(s$eth_amind == 1)),
  list("Asian","v",                     function(s) n_pct(s$eth_asian == 1)),
  list("Black/African American","v",    function(s) n_pct(s$eth_black == 1)),
  list("Hispanic/Latino","v",           function(s) n_pct(s$eth_hispanic == 1)),
  list("Native HI/Pacific Islander","v",function(s) n_pct(s$eth_pacisl == 1)),
  list("White","v",                     function(s) n_pct(s$eth_white == 1)),
  list("Multiethnic","v",               function(s) n_pct(s$eth_ntags >= 2)),
  list("Not Reported","v",              function(s) n_pct(s$eth_reported == 0)),
  list("","b"),
  list("Modules","h"),
  list("Core","v",              function(s) m_sd(s$mod.core)),
  list("Mindset","v",           function(s) m_sd(s$mod.mindset)),
  list("Nutrition","v",         function(s) m_sd(s$mod.nutrition)),
  list("Physical Activity","v", function(s) m_sd(s$mod.phys)),
  list("","b"),
  list("Engagement","h"),
  list("Average number of distinct events","v",   function(s) m_sd(s$breadth)),
  list("Average number of repeatable events","v", function(s) m_sd(s$volume_rep)),
  list("Average repeatable rate","v",             function(s) m_sd(s$volume_rep_rate)),
  list("","b"),
  list("Outcomes","h"),
  list("First BW measure","v",  function(s) m_sd(s$first)),
  list("Second BW measure","v", function(s) m_sd(s$last)),
  list("Difference","v",        function(s) m_sd(s$diff)),
  list("","b"),
  list("Study Measures","h"),
  list("Days between measurements","v", function(s) m_sd(s$fl.cnt)),   # fl.cnt = days first->last BW
  list("Length in Study","v",           function(s) m_sd(s$day.total)))

# build grid: label column + one column per member-type stratum (with its n in the header)
subs <- lapply(grp_levels, function(lv) cohort[cohort$mem.type == lv, ])
demo <- data.frame(Measure = vapply(spec, `[[`, "", 1), check.names = FALSE, stringsAsFactors = FALSE)
for (g in names(grp_levels)) {
  hdr <- sprintf("%s (n=%d)", g, nrow(subs[[g]]))
  demo[[hdr]] <- vapply(spec, function(r) if (r[[2]] != "v") "" else r[[3]](subs[[g]]), "")
}
print(demo, right = FALSE)
write_ods(demo, paste0(prj.loc, "figures/demo-table.ods"))

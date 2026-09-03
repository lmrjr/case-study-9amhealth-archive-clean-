########################################################################################################################
# merging.R  -- build the analytical table   (Task 3)
#
# spine = demographics (865 = full universe; == unique engagement IDs, verified in explore.R lines 200-217).
# LEFT-join features onto the spine so the drop-off stays VISIBLE (missing outcome = NA, not silently gone).
# Depends on objects left in the env by explore.R: bw_detail, demographics, engage_feat, mod_prop.
########################################################################################################################
# --- 1. one keyed frame per source (rename every id column to readable.id) ---
bw_feat <- bw_detail[, c("user.id","first","last","diff","fl.cnt","day.total","mem.type")]
names(bw_feat)[names(bw_feat) == "user.id"] <- "readable.id"

# [please understand this code] "ethnicity" is the raw multi-select STRING column. I added it here so it
# rides into the cohort for reporting (Table-1). The eth_* 0/1 indicators + latino_access come in via the
# grep() -- note "ethnicity" itself does NOT match "^eth_" (no underscore), so it must be named explicitly.
demo_feat <- demographics[, c("readable.id","sex","status","start.date","cancel.date","ethnicity",
                              grep("^eth_|^latino_access$", names(demographics), value = TRUE))]

names(engage_feat)[names(engage_feat) == "readable_id"] <- "readable.id"  # sqldf aliased it

# --- 2. left-join everything onto the 865 spine ---
analytic <- Reduce(function(a, b) merge(a, b, by = "readable.id", all.x = TRUE),
                   list(demo_feat, bw_feat, engage_feat, mod_prop))

# --- 3. module non-participation is a real 0, not missing (they were in-cohort, completed none) ---
mod_cols <- c("mod.core","mod.mindset","mod.nutrition","mod.phys","mod.mean","mod.sum")
analytic[mod_cols][is.na(analytic[mod_cols])] <- 0

# --- 4. presence flags: this is where the population drops off ---
analytic$has_bw     <- as.integer(!is.na(analytic$diff))       # 827 expected
analytic$has_engage <- as.integer(!is.na(analytic$breadth))    # engagement feature present
analytic$has_type   <- as.integer(!is.na(analytic$mem.type) & analytic$mem.type != "")

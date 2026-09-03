########################################################################################################################
# functions.R  -- helper functions only. sourced first by main.R.
########################################################################################################################
############################################################################################
# function for installing packages and loading them.
ipak <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dependencies = TRUE)
  sapply(pkg, require, character.only = TRUE)
}

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

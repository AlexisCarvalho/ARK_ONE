# checks if an email is in the standard form
# The same regex used in the database, do not modify
validate_email_pattern <- function(email) {
  is.character(email) && grepl("^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$", email)
}

# Extract the constraint name from the standard error message PostgreSQL
parse_constraint_names_pgsql <- function(error_message) {
  matches <- regmatches(error_message, gregexpr('"(.*?)"', error_message))[[1]]

  if (length(matches) > 0) {
    return(gsub('"', "", matches))
  }

  NULL
}
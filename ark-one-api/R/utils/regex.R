# checks if an email is in the standard form 
validate_email <- function(email) {
  return(is.character(email) && grepl("^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$", email))
}

# Extrack the constraint name from the standard error message PostgreSQL 
extract_constraint_name_pgsql <- function(error_message) {
  matches <- regmatches(error_message, gregexpr('"(.*?)"', error_message))[[1]]
  
  if (length(matches) > 0) {
    return(gsub('"', '', matches))
  }
  
  return(NULL)
}
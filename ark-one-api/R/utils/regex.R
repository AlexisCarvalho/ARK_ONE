validate_email <- function(email) {
  return(is.character(email) && grepl("^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$", email))
}
# Function to access the status_map
get_status_map <- function() {
  return(status_env$http_status_map)
}

# Function to verify if a value is missing or empty
is_missing_or_empty <- function(value) {
  return(is.null(value) || value == "")
}
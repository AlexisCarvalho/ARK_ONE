source("regex.R", chdir = TRUE)

# Function to access the http_status_map
get_status_map <- function() {
  return(status_env$http_status_map)
}

# Function to access the constraint_violation_messages
get_constraint_violation_info <- function() {
  return(status_env$constraint_violation_map)
}

# Standard result sender to endpoints
send_http_response <- function(res, result) {
  if (result$status %in% names(get_status_map())) {
    res$status <- get_status_map()[[result$status]]
    return(result)
  }

  res$status <- 500
  return(result)
}

constraint_violation_response <- function(constraint) {
  if(constraint %in% names(get_constraint_violation_info())) {
    return(get_constraint_violation_info()[[constraint]])
  }
}

# Extract a pgsql constraint from a error based on the documented ones
# If a new constraint was add to the database and not inserted on the map
# it will return NULL
find_matching_constraint_pgsql <- function(error_message) {
  constraint_names <- extract_constraint_name_pgsql(error_message)
  
  if (is.null(constraint_names) || length(constraint_names) == 0) {
    # There isn't any match returned from the error that is similar to a constraint
    return(NULL)
  }
  
  known_constraints <- names(get_constraint_violation_info())

  matching_constraint <- intersect(constraint_names, known_constraints)
  
  if (length(matching_constraint) > 0) {
    return(matching_constraint[1])  
  }
  
  # There is something similar to a constraint but is not mapped
  return(NULL)
}

# Function to verify if a value is missing or empty
is_missing_or_empty <- function(value) {
  return(is.null(value) || value == "")
}
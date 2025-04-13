# +------------------------+
# |   FUNCTION RESPONSES   |
# +------------------------+

source("regex.R", chdir = TRUE)

status_env <- get("status_env", envir = .GlobalEnv)

# Function to access the http_status_map
get_status_map <- function() {
  status_env$http_status_map
}

# Standard result sender to endpoints
send_http_response <- function(res, result) {
  if (result$status %in% names(get_status_map())) {
    res$status <- get_status_map()[[result$status]]
    return(result)
  }

  res$status <- 500
  list(status = "internal_server_error", message = paste0("Error, status: ", result$status, " not mapped"))
}

# Maintenance message
maintenance_message <- function() {
  list(
    status = "service_unavailable",
    message = "Service Temporary Unavailable due to Maintenance"
  )
}

# +------------------------+
# |   DATABASE RESPONSES   |
# +------------------------+

# Function to access the constraint_violation_messages
get_constraint_violation_info <- function() {
  status_env$constraint_violation_map
}

# Return a list of status and message to the constraint that was violated
constraint_violation_response <- function(constraint) {
  if (constraint %in% names(get_constraint_violation_info())) {
    get_constraint_violation_info()[[constraint]]
  }
}

# Extract a pgsql constraint from a error based on the documented ones
# If a new constraint was add to the database and not inserted on the map
# it will return NULL
find_matching_constraint_pgsql <- function(error_message) {
  constraint_names <- parse_constraint_names_pgsql(error_message)

  if (is.null(constraint_names) || length(constraint_names) == 0) {
    # There isn't any match returned from the error that is similar to a constraint
    return(NULL)
  }

  known_constraints <- names(get_constraint_violation_info())

  matching_constraints <- intersect(constraint_names, known_constraints)

  if (length(matching_constraints) > 0) {
    # Return the first valid constraint
    return(matching_constraints[1])
  }

  # There is something similar to a constraint but is not mapped
  NULL
}
source("regex.R", chdir = TRUE)

# Get the token from the authorization header, without decoding
get_token_from_req <- function(req) {
  if (!"HTTP_AUTHORIZATION" %in% names(req)) {
    stop("Authorization header is missing")
  }

  token <- req$HTTP_AUTHORIZATION

  if (is.null(token) || !nzchar(token)) {
    stop("Missing or invalid JWT Token Authorization")
  }

  token <- trimws(token)

  if (grepl("^Bearer\\s+", token)) {
    token <- sub("^Bearer\\s+", "", token)
  }

  if (!nzchar(token)) {
    stop("Token extraction failed")
  }

  return(token)
}

# Decode Token
decode_jwt_token <- function(token) {
  secret_key <- Sys.getenv("TOKEN_SECRET_KEY")

  if (is.null(secret_key) || !nzchar(secret_key)) {
    stop("Server misconfiguration: missing TOKEN_SECRET_KEY")
  }

  decoded <- tryCatch(
    jwt_decode_hmac(token, charToRaw(secret_key)),
    error = function(e) stop("Invalid Token")
  )

  if (is.null(decoded)) {
    stop("Invalid Token")
  }

  return(decoded)
}

# Verifies if the token is expired
is_expired_token <- function(decoded_token) {
  current_time <- as.numeric(Sys.time())

  if (!is.null(decoded_token$exp) && decoded_token$exp < current_time) {
    TRUE
  }

  FALSE
}

# Verifies if a entry is utf-8 or not
is_invalid_utf8 <- function(input) {
  if (!is.character(input) || is.null(input) || is.na(input)) {
    return(TRUE)
  }

  any(!utf8::utf8_valid(input))
}

# Verifies if a entry is ascii or not
is_ascii <- function(input) {
  identical(input, iconv(input, to = "ASCII//TRANSLIT"))
}

# Function to verify if a input is missing or empty
is_blank_string <- function(input) {
  trimws(input) == ""
}

# Function to access the http_status_map
get_status_map <- function() {
  status_env$http_status_map
}

# Function to access the constraint_violation_messages
get_constraint_violation_info <- function() {
  status_env$constraint_violation_map
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
source("../models/user_model.R", chdir = TRUE)
source("token_handler.R", chdir = TRUE)

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

# Get the user id from his token using the request
get_id_user_from_req <- function(req) {
  tryCatch(
    {
      token <- get_token_from_req(req)
      decoded_token <- decode_jwt_token(token)

      decoded_token$sub
    },
    error = function(e) stop(e)
  )
}

get_id_user_from_token <- function(token) {
  tryCatch(
    {
      decoded_token <- decode_jwt_token(token)

      decoded_token$sub
    },
    error = function(e) stop(e)
  )
}

get_username_from_token <- function(token) {
  tryCatch(
    {
      decoded_token <- decode_jwt_token(token)

      decoded_token$username
    },
    error = function(e) stop(e)
  )
}

# Get the user role from his token using the request
get_user_role_from_req <- function(req) {
  tryCatch(
    {
      id_user <- get_id_user_from_req(req)
      fetch_user_role_by_id(id_user)
    },
    error = function(e) stop(e)
  )
}
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
source("utils.R", chdir = TRUE)

authenticate <- function(req, res) {
  
  if (grepl("/__swagger__/", req$PATH_INFO)) {
    forward()
  }
  
  token <- req$HTTP_AUTHORIZATION
  
  if (is.null(token)) {
    res$status <- 401 
    return(list(error = "Token required", code = "TOKEN_REQUIRED"))
  }
  
  if (startsWith(token, "Bearer ")) {
    token <- sub("Bearer ", "", token)
  }
  
  token <- trimws(token)
  
  decoded <- try(jwt_decode_hmac(token, token_secret_key), silent = TRUE)
  
  if (inherits(decoded, "try-error")) {
    res$status <- 401 
    return(list(error = "Invalid token", code = "INVALID_TOKEN"))
  }
  
  current_time <- as.numeric(Sys.time())
  
  if (!is.null(decoded$exp) && decoded$exp < current_time) {
    res$status <- 401 
    return(list(error = "Expired token", code = "EXPIRED_TOKEN"))
  }
  
  forward()
}
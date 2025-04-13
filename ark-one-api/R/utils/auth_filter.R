source("request_handler.R", chdir = TRUE)
source("response_handler.R", chdir = TRUE)
source("token_handler.R", chdir = TRUE)

authenticate <- function(req, res) {
  if (grepl("/__swagger__/", req$PATH_INFO)) {
    forward()
  }

  tryCatch(
    {
      token <- get_token_from_req(req)

      if (is.null(token) || !nzchar(token)) {
        stop("Invalid or missing token")
      }

      decoded_token <- decode_jwt_token(token)

      if (is.null(decoded_token)) {
        stop("Failed to decode token")
      }

      if (is_expired_token(decoded_token)) {
        stop("Expired Token")
      }

      forward()
    },
    error = function(e) {
      send_http_response(res, list(status = "unauthorized", message = e$message))
    }
  )
}

# Initialize pool_env, that is used to store the connection pools
if (!exists("pool_env", envir = .GlobalEnv)) {
  pool_env <- new.env()
}

# Used to store a status map for the http codes to
# interpret the functions returns
if (!exists("status_env", envir = .GlobalEnv)) {
  status_env <- new.env()
  status_env$http_status_map <- list(
    success = 200,
    created = 201,
    updated = 204,
    bad_request = 400,
    unauthorized = 401,
    forbidden = 402,
    not_found = 404,
    internal_server_error = 500,
    service_unavailable = 503
  )
}

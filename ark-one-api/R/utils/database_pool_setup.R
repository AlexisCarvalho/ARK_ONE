pools_env <- get("pools_env", envir = .GlobalEnv)

# Function to check if a pool is still valid
is_pool_active <- function(pool) {
  if (is.null(pool)) {
    return(FALSE)
  }
  tryCatch(
    {
      conn <- poolCheckout(pool)
      poolReturn(conn)
      TRUE
    },
    error = function(e) {
      FALSE
    }
  )
}

# Add a pool to the environment
add_pool <- function(pool_name, drv, db_params) {
  if (!exists("pools_env", envir = globalenv())) {
    stop("pools_env does not exist. Make sure to initialize it before adding pools.")
  }

  if (exists(pool_name, envir = pools_env)) {
    existing_pool <- pools_env[[pool_name]]
    if (is_pool_active(existing_pool)) {
      return(existing_pool)
    } else {
      if (!is.null(existing_pool)) try(poolClose(existing_pool), silent = TRUE)
    }
  }

  # Create a new pool
  pools_env[[pool_name]] <- dbPool(
    drv = drv,
    dbname = db_params$dbname,
    host = db_params$host,
    port = db_params$port,
    user = db_params$user,
    password = db_params$password
  )

  return(pools_env[[pool_name]])
}

# Return the pool if it exists if not send a message for debug
get_pool <- function(pool_name) {
  if (exists(pool_name, envir = pools_env)) {
    pools_env[[pool_name]]
  } else {
    NULL
  }
}

# Return the connection to the pool after use
pool_return <- function(conn) {
  tryCatch(
    {
      poolReturn(conn)
    },
    error = function(e) {
      message(paste("Error returning connection to the pool:", e$message))
    }
  )
}

# Take one connection off the pool, ensuring the pool exists
get_conn <- function(pool_name = "postgres_pool") {
  conn <- NULL
  tryCatch(
    {
      conn <- poolCheckout(get_pool(pool_name))
    },
    error = function(e) {
      message(paste("Error getting connection from pool:", e$message))
    }
  )
  return(conn)
}
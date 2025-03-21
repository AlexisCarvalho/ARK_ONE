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
      message(paste("Pool", pool_name, "already exists and is active"))
      return(existing_pool)
    } else {
      message(paste("Pool", pool_name, "exists but is not active. Recreating..."))
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

# Function to close all pools before shutting down
close_all_pools <- function() {
  if (exists("pools_env", envir = globalenv())) {
    for (pool_name in ls(pools_env)) {
      poolClose(pools_env[[pool_name]])
      rm(list = pool_name, envir = pools_env)
    }
    message("All database pools have been closed.")
  }
}

# Return the pool if it exists if not send a message for debug
get_pool <- function(pool_name) {
  if (exists(pool_name, envir = pools_env)) {
    return(pools_env[[pool_name]])
  } else {
    message(paste("Pool", pool_name, "not found"))
    return(NULL)
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




# TODO: Remove after the end of refactor
# Maintained as reference, will be removed soon
getConn <- function(dbname = Sys.getenv("DB_NAME"),
                    host = Sys.getenv("DB_HOST"),
                    port = as.integer(Sys.getenv("DB_PORT")),
                    user = Sys.getenv("DB_USER"),
                    password = Sys.getenv("DB_PASSWORD")) {
  con <- NULL

  tryCatch(
    {
      con <- dbConnect(RPostgres::Postgres(),
        dbname = dbname,
        host = host,
        port = port,
        user = user,
        password = password
      )
      return(con)
    },
    error = function(e) {
      message(paste("Error connecting to database:", e$message))
      return(NULL)
    }
  )
}

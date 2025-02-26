# Return the pool if it exists, if not, create a new one
get_pool <- function() {
  if (is.null(pool_env$pool)) {
    pool_env$pool <<- construct_pool()  
  }
  return(pool_env$pool)
}

# Return the connection to the pool after use
pool_return <- function(conn) {
  tryCatch({
    poolReturn(conn)  
  }, error = function(e) {
    message(paste("Error returning connection to the pool:", e$message))
  })
}

# Take one connection off the pool, ensuring the pool exists
get_conn <- function() {
  conn <- NULL
  tryCatch({
    conn <- poolCheckout(get_pool())
  }, error = function(e) {
    message(paste("Error getting connection from pool:", e$message))
  })
  return(conn)
}

# Construct a new pool
construct_pool <- function(dbname = Sys.getenv("DB_NAME"),
                           host = Sys.getenv("DB_HOST"),
                           port = Sys.getenv("DB_PORT"),
                           user = Sys.getenv("DB_USER"),
                           password = Sys.getenv("DB_PASSWORD")) {
  tryCatch({
    return(dbPool(
      drv = RPostgres::Postgres(),
      dbname = dbname,
      host = host,
      port = port,
      user = user,
      password = password
    ))
  }, error = function(e) {
    message(paste("Error creating connection pool:", e$message))
    return(NULL)
  })
}

# Maintained as reference, will be removed soon
getConn <- function(dbname = Sys.getenv("DB_NAME"),
                    host = Sys.getenv("DB_HOST"),
                    port = as.integer(Sys.getenv("DB_PORT")),
                    user = Sys.getenv("DB_USER"),
                    password = Sys.getenv("DB_PASSWORD")) {

  con <- NULL

  tryCatch({
    con <- dbConnect(RPostgres::Postgres(),
                     dbname = dbname,
                     host = host,
                     port = port,
                     user = user,
                     password = password)
    return(con)

  }, error = function(e) {
    message(paste("Error connecting to database:", e$message))
    return(NULL)
  })
}
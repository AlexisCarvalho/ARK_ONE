source("../utils/database_pool_setup.R", chdir = TRUE)

# Contains the logic to check if a password is correct using bcrypt
check_password <- function(input_password, stored_hashed_password) {
  return(checkpw(input_password, stored_hashed_password))
}

# As a function that not require so much information about the user
# it returns just basic information from the database for authentication
get_user_by_email <- function(email) {
  con <- get_conn()

  if (is.null(con) || !DBI::dbIsValid(con)) {
    stop("Database Connection Failed")
  }

  on.exit(pool_return(con), add = TRUE)

  tryCatch(
    {
      query <- "SELECT id_user, name, password FROM user_data WHERE email = $1"
      return(dbGetQuery(con, query, params = list(email)))
    },
    error = function(e) stop(e)
  )
}

# Insert a user on the database with all their required information
insert_user <- function(name, email, hashed_password, user_type) {
  con <- get_conn()

  if (is.null(con) || !DBI::dbIsValid(con)) {
    stop("Database Connection Failed")
  }

  on.exit(pool_return(con), add = TRUE)

  tryCatch(
    {
      query_insert <- "INSERT INTO user_data (name, email, password, user_type) VALUES ($1, $2, $3, $4)"
      return(dbExecute(con, query_insert, params = list(name, email, hashed_password, user_type)))
    },
    error = function(e) stop(e)
  )
}
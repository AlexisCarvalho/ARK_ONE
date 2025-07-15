source("../utils/database_pool_setup.R", chdir = TRUE)

fetch_user_by_id <- function(id_user) {
  con <- get_conn()

  if (is.null(con) || !DBI::dbIsValid(con)) {
    stop("Database Connection Failed")
  }

  on.exit(pool_return(con), add = TRUE)

  tryCatch(
    {
      query_select <- "SELECT name, email, password, user_role, registration_date FROM user_data WHERE id_user = $1"
      return(dbGetQuery(con, query_select, params = list(id_user)))
    },
    error = function(e) stop(e)
  )
}

fetch_all_users <- function() {
  con <- get_conn()

  if (is.null(con) || !DBI::dbIsValid(con)) {
    stop("Database Connection Failed")
  }

  on.exit(pool_return(con), add = TRUE)

  tryCatch(
    {
      return(dbReadTable(con, "user_data"))
    },
    error = function(e) stop(e)
  )
}

fetch_user_role_by_id <- function(id_user) {
  con <- get_conn()

  if (is.null(con) || !DBI::dbIsValid(con)) {
    stop("Database Connection Failed")
  }

  on.exit(pool_return(con), add = TRUE)

  tryCatch(
    {
      query_select <- "SELECT user_role FROM user_data WHERE id_user = $1"
      return(dbGetQuery(con, query_select, params = list(id_user)))
    },
    error = function(e) stop(e)
  )
}

# As a function that not require so much information about the user
# it returns just basic information from the database for authentication
fetch_user_by_email <- function(email) {
  con <- get_conn()

  if (is.null(con) || !DBI::dbIsValid(con)) {
    stop("Database Connection Failed")
  }

  on.exit(pool_return(con), add = TRUE)

  tryCatch(
    {
      query <- "SELECT id_user, name, password, user_role FROM user_data WHERE email = $1"
      return(dbGetQuery(con, query, params = list(email)))
    },
    error = function(e) stop(e)
  )
}

# Insert a user on the database with all their required information
insert_user <- function(name, email, hashed_password, user_role) {
  con <- get_conn()

  if (is.null(con) || !DBI::dbIsValid(con)) {
    stop("Database Connection Failed")
  }

  on.exit(pool_return(con), add = TRUE)

  tryCatch(
    {
      query_insert <- "INSERT INTO user_data (name, email, password, user_role) VALUES ($1, $2, $3, $4)"
      return(dbExecute(con, query_insert, params = list(name, email, hashed_password, user_role)))
    },
    error = function(e) stop(e)
  )
}
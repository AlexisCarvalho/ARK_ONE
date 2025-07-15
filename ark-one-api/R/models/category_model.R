source("../utils/database_pool_setup.R", chdir = TRUE)

fetch_all_categories <- function() {
  con <- get_conn()

  if (is.null(con) || !DBI::dbIsValid(con)) {
    stop("Database Connection Failed")
  }

  on.exit(pool_return(con), add = TRUE)

  tryCatch(
    {
      return(dbReadTable(con, "category"))
    },
    error = function(e) stop(e)
  )
}

fetch_category_by_id <- function(id_category) {
  con <- get_conn()

  if (is.null(con) || !DBI::dbIsValid(con)) {
    stop("Database Connection Failed")
  }

  on.exit(pool_return(con), add = TRUE)

  tryCatch(
    {
      query <- "SELECT * FROM category WHERE id_category = $1"
      return(dbGetQuery(con, query, params = list(id_category)))
    },
    error = function(e) stop(e)
  )
}

insert_category <- function(category_name, category_description, id_father_category) {
  con <- get_conn()

  if (is.null(con) || !DBI::dbIsValid(con)) {
    stop("Database Connection Failed")
  }

  on.exit(pool_return(con), add = TRUE)

  tryCatch(
    {
      query <- "INSERT INTO category (category_name, category_description, id_father_category) VALUES ($1, $2, $3)"
      return(dbExecute(con, query, params = list(category_name, category_description, id_father_category)))
    },
    error = function(e) stop(e)
  )
}

update_category <- function(id_category, category_name, category_description, id_father_category) {
  con <- get_conn()

  if (is.null(con) || !DBI::dbIsValid(con)) {
    stop("Database Connection Failed")
  }

  on.exit(pool_return(con), add = TRUE)

  tryCatch(
    {
      query <- "UPDATE category SET category_name = $2, category_description = $3, id_father_category = $4 WHERE id_category = $1"

      affected_rows <- dbExecute(con, query, params = list(id_category, category_name, category_description, id_father_category))

      if (affected_rows == 0) {
        stop("\"no_rows_updated\"")
      }
    },
    error = function(e) stop(e)
  )
}

erase_category <- function(id_category) {
  con <- get_conn()

  if (is.null(con) || !DBI::dbIsValid(con)) {
    stop("Database Connection Failed")
  }

  on.exit(pool_return(con), add = TRUE)

  tryCatch(
    {
      DBI::dbBegin(con)

      query <- "DELETE FROM category WHERE id_category = $1"

      affected_rows <- DBI::dbExecute(con, query, params = list(id_category))

      if (affected_rows == 0) {
        stop("\"no_rows_deleted\"")
      }

      DBI::dbCommit(con)
    },
    error = function(e) {
      DBI::dbRollback(con)
      stop(e)
    }
  )
}
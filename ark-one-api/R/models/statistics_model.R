source("../utils/database_pool_setup.R", chdir = TRUE)

fetch_esp32_data_today_by_instance <- function(id_product_instance) {
  con <- get_conn()

  if (is.null(con) || !DBI::dbIsValid(con)) {
    stop("Database Connection Failed")
  }

  on.exit(pool_return(con), add = TRUE)

  tryCatch({
    query <- "SELECT * FROM get_esp32_data_today($1)"
    dbGetQuery(con, query, params = list(id_product_instance))
  }, error = function(e) stop(e))
}

fetch_esp32_data_week_by_instance <- function(id_product_instance) {
  con <- get_conn()

  if (is.null(con) || !DBI::dbIsValid(con)) {
    stop("Database Connection Failed")
  }

  on.exit(pool_return(con), add = TRUE)

  tryCatch({
    query <- "SELECT * FROM get_esp32_data_week($1)"
    dbGetQuery(con, query, params = list(id_product_instance))
  }, error = function(e) stop(e))
}
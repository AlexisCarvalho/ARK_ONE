source("../utils/database_pool_setup.R", chdir = TRUE)

fetch_all_locations <- function() {
  con <- get_conn()

  if (is.null(con) || !DBI::dbIsValid(con)) {
    stop("Database Connection Failed")
  }

  on.exit(pool_return(con), add = TRUE)

  tryCatch(
    {
      dbReadTable(con, "location_data")
    },
    error = function(e) {
      stop(e)
    }
  )
}

fetch_location_by_id <- function(id_product_instance) {
  con <- get_conn()

  if (is.null(con) || !DBI::dbIsValid(con)) {
    stop("Database Connection Failed")
  }

  on.exit(pool_return(con), add = TRUE)

  tryCatch(
    {
      query <- "SELECT latitude, longitude FROM location_data WHERE id_product_instance = $1"
      dbGetQuery(con, query, params = list(id_product_instance))
    },
    error = function(e) {
      stop(e)
    }
  )
}

fetch_location_data_with_esp_id <- function(esp32_unique_id) {
  con <- get_conn()

  if (is.null(con) || !DBI::dbIsValid(con)) {
    stop("Database Connection Failed")
  }

  on.exit(pool_return(con), add = TRUE)

  tryCatch(
    {
      query <- "
    SELECT
        pi.id_product_instance,
        ld.latitude,
        ld.longitude
    FROM product_instance pi
    JOIN location_data ld ON pi.id_product_instance = ld.id_product_instance
    WHERE pi.esp32_unique_id = $1;
"
      dbGetQuery(con, query, params = list(esp32_unique_id))
    },
    error = function(e) {
      stop(e)
    }
  )
}

insert_location <- function(id_product_instance, latitude, longitude) {
  con <- get_conn()

  if (is.null(con) || !DBI::dbIsValid(con)) {
    stop("Database Connection Failed")
  }

  on.exit(pool_return(con), add = TRUE)

  tryCatch(
    {
      query <- "INSERT INTO location_data (id_product_instance, latitude, longitude) VALUES ($1, $2, $3)"
      dbExecute(con, query, params = list(id_product_instance, latitude, longitude))
    },
    error = function(e) {
      stop(e)
    }
  )
}

update_location <- function(id_product_instance, latitude, longitude) {
  con <- get_conn()

  if (is.null(con) || !DBI::dbIsValid(con)) {
    stop("Database Connection Failed")
  }

  on.exit(pool_return(con), add = TRUE)

  tryCatch(
    {
      query <- "UPDATE location_data SET latitude = $2, longitude = $3 WHERE id_product_instance = $1"

      affected_rows <- dbExecute(con, query, params = list(id_product_instance, latitude, longitude))

      if (affected_rows == 0) {
        stop("\"no_rows_updated\"")
      }
    },
    error = function(e) {
      stop(e)
    }
  )
}

erase_location <- function(id_product_instance) {
  con <- get_conn()

  if (is.null(con) || !DBI::dbIsValid(con)) {
    stop("Database Connection Failed")
  }

  on.exit(pool_return(con), add = TRUE)

  tryCatch(
    {
      DBI::dbBegin(con)

      query <- "DELETE FROM location_data WHERE id_product_instance = $1"

      affected_rows <- DBI::dbExecute(con, query, params = list(id_product_instance))

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

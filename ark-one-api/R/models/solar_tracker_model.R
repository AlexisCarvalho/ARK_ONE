source("../utils/database_pool_setup.R", chdir = TRUE)

fetch_product_instance <- function(esp32_unique_id) {
  con <- get_conn()

  if (is.null(con) || !DBI::dbIsValid(con)) {
    stop("Database Connection Failed")
  }

  on.exit(pool_return(con), add = TRUE)

  tryCatch(
    {
      query <- "SELECT id_product_instance FROM product_instance WHERE esp32_unique_id = $1"
      return(dbGetQuery(con, query, params = list(esp32_unique_id)))
    },
    error = function(e) stop(e)
  )
}

bulk_insert_solar_tracker_values <- function(solar_tracker_data_to_query) {
  con <- get_conn()

  if (is.null(con) || !DBI::dbIsValid(con)) {
    stop("Database Connection Failed")
  }

  on.exit(pool_return(con), add = TRUE)

  tryCatch(
    {
      values_list <- apply(solar_tracker_data_to_query, 1, function(row) {
        common_data <- toJSON(list(voltage = row['voltage'], current = row['current']), auto_unbox = TRUE)
        product_specific_data <- toJSON(list(servo_tower_angle = row['servo_tower_angle'], 
                                            solar_panel_temperature = row['solar_panel_temperature'], 
                                            esp32_core_temperature = row['esp32_core_temperature']), auto_unbox = TRUE)

        sprintf("('%s', '%s', '%s')", row['id_product_instance'], common_data, product_specific_data)
      })

      values_string <- paste(values_list, collapse = ", ")

      query <- sprintf("INSERT INTO esp32_data (id_product_instance, common_data, product_specific_data) VALUES %s", values_string)

      return(dbExecute(con, query))
    },
    error = function(e) stop(e)
  )
}
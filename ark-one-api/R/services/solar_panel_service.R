source("../models/solar_panel_model.R", chdir = TRUE)

# Idea: Use a system to save the id of the products that are already verifyed as registered to not need to execute a query all the time when a new entry by the esp comes
# to the save_incoming_solar_panel_data, this way the first time it will be executed it will search and find out if is already registered or not by the time the api is running

# +-------------------------------------+
# |                                     |
# |          SOLAR PANEL SERVICE        |
# |                                     |
# +-------------------------------------+

recently_received_solar_panel_data <- data.table(id_product_instance = numeric(),
                                                 voltage = numeric(),
                                                 current = numeric(),
                                                 servo_tower_angle = numeric(),
                                                 solar_panel_temperature = numeric(),
                                                 esp32_core_temperature = numeric())
solar_panel_data_to_query <- data.table(id_product_instance = numeric(),
                                        voltage = numeric(),
                                        current = numeric(),
                                        servo_tower_angle = numeric(),
                                        solar_panel_temperature = numeric(),
                                        esp32_core_temperature = numeric())

# +----------------------------+
# |   SOLAR PANEL DATA ENTRY   |
# +----------------------------+

query_threshold <- 10
count_solar_panel_insertions <- 0
solar_panel_new_data_to_query <- FALSE

bulk_insert_solar_panel_values <- function(solar_panel_data_to_query) 
{
  con <- getConn()
  on.exit(dbDisconnect(con))

  tryCatch({
    if (is.null(con))
    {
      stop("Failed to connect to the database.")
    }

    if (nrow(solar_panel_data_to_query) == 0) 
    {
      stop("solar_panel_data_to_query is empty, nothing to write.")
    }

    values_list <- apply(solar_panel_data_to_query, 1, function(row) {
      common_data <- toJSON(list(voltage = row['voltage'], current = row['current']), auto_unbox = TRUE)
      product_specific_data <- toJSON(list(servo_tower_angle = row['servo_tower_angle'], 
                                           solar_panel_temperature = row['solar_panel_temperature'], 
                                           esp32_core_temperature = row['esp32_core_temperature']), auto_unbox = TRUE)

      sprintf("('%s', '%s', '%s')", row['id_product_instance'], common_data, product_specific_data)
    })

    values_string <- paste(values_list, collapse = ", ")

    query <- sprintf("INSERT INTO esp32_data (id_product_instance, common_data, product_specific_data) VALUES %s", values_string)

    dbExecute(con, query)

    return(TRUE)
  }, error = function(e)
  {
    message(paste("Error writing to database:", e$message))
    return(FALSE)
  })
}

# +-----------------------------------+
# |   SOLAR PANEL DATA MANIPULATION   |
# +-----------------------------------+

save_incoming_solar_panel_data <- function(esp32_unique_id, servo_tower_angle, solar_panel_temperature, esp32_core_temperature, voltage, current) {
  con <- getConn()
  on.exit(dbDisconnect(con))

  query <- "SELECT id_product_instance FROM product_instance WHERE esp32_unique_id = $1"

  id_product_instance <- dbGetQuery(con, query, params = list(esp32_unique_id))

  if (nrow(id_product_instance) == 0) {
    return(list(status = "error", message = "No product found for the given esp32_unique_id."))
  }

  id_product_instance <- id_product_instance$id_product_instance[1]

  recently_received_solar_panel_data <<- rbind(recently_received_solar_panel_data, 
                                               data.table(id_product_instance = id_product_instance,
                                                          voltage = voltage,
                                                          current = current,
                                                          servo_tower_angle = servo_tower_angle,
                                                          solar_panel_temperature = solar_panel_temperature,
                                                          esp32_core_temperature = esp32_core_temperature))

  if (nrow(recently_received_solar_panel_data) > query_threshold) {
    recently_received_solar_panel_data <<- recently_received_solar_panel_data[-1, ]
  }

  count_solar_panel_insertions <<- count_solar_panel_insertions + 1

  if (count_solar_panel_insertions == query_threshold) {
    if (solar_panel_new_data_to_query == FALSE) {
      move_to_solar_panel_data_to_query()
      solar_panel_new_data_to_query <<- TRUE
    } else {
      stop("*NOT IMPLEMENTED YET* Database fails to receive the data at some point, to prevent data loss it was maintained but numerous new data come and overflow the threshold.")
    }
  }

  if (solar_panel_new_data_to_query == TRUE) {
    success <- bulk_insert_solar_panel_values(solar_panel_data_to_query)
    if (success) {
      solar_panel_new_data_to_query <<- FALSE
      solar_panel_data_to_query <<- data.table(id_product_instance = numeric(), 
                                               voltage = numeric(),
                                               current = numeric(),
                                               servo_tower_angle = numeric(),
                                               solar_panel_temperature = numeric(),
                                               esp32_core_temperature = numeric())
    } else {
      stop("*NOT IMPLEMENTED YET* Database fails to receive the data. Retry feature in development")
    }
  }
  return(list(status = "success", message = "Success Receiving Data"))
}

# +-------------------------------------+
# |                                     |
# |          SOLAR PANEL SERVICE        |
# |                                     |
# +-------------------------------------+

source("../models/solar_tracker_model.R", chdir = TRUE)
source("../utils/utils.R", chdir = TRUE)

solar_tracker_data_storage <- get("solar_tracker_data_storage", envir = .GlobalEnv)
esp32_metadata <- get("esp32_metadata", envir = .GlobalEnv)
total_steps <- 100

get_data_by_instance_from_memory <- function(id_product_instance) {
  esp32_unique_id <- find_esp32_unique_id(id_product_instance, esp32_metadata)

  if (is.null(esp32_unique_id)) {
    return(NULL)
  }

  filtered_data <- get(as.character(esp32_unique_id), envir = solar_tracker_data_storage)

  if (nrow(filtered_data) == 0) {
    return(NULL)
  }

  filtered_data
}

# Only the data associated to the UniqueID is wiped
delete_esp32_data_from_memory <- function(esp32_unique_id) {
  if (exists(esp32_unique_id, envir = solar_tracker_data_storage)) {
    dt <- get(esp32_unique_id, envir = solar_tracker_data_storage)
    assign(esp32_unique_id, dt[0], envir = solar_tracker_data_storage)
  }

  # Only reset the counter, id_product_instance are not erased
  # because the esp32 was not deleted from database, still uses the same instance
  if (exists(esp32_unique_id, envir = esp32_metadata)) {
    metadata <- get(esp32_unique_id, envir = esp32_metadata)
    metadata$insert_count <- 0
    assign(esp32_unique_id, metadata, envir = esp32_metadata)
  }
}

# The UniqueID the data and the metadata is erased
delete_esp32_from_memory <- function(esp32_unique_id) {
  if (exists(esp32_unique_id, envir = solar_tracker_data_storage)) {
    rm(list = esp32_unique_id, envir = solar_tracker_data_storage)
    rm(list = esp32_unique_id, envir = esp32_metadata)
  }
}

# Get all esp32 data of the environment
get_all_data <- function() {
  unique_ids <- ls(envir = solar_tracker_data_storage)
  all_data <- lapply(unique_ids, function(unique_id) {
    metadata <- get(unique_id, envir = esp32_metadata)
    data <- get(unique_id, envir = solar_tracker_data_storage)
    list(unique_id = unique_id, metadata = metadata, data = data)
  })
  all_data
}

# Save the information of the recognizable esp32 on the database
save_to_database <- function(esp32_unique_id, dt, metadata) {
  if (is.null(metadata$id_product_instance)) {
    id_product_instance <- tryCatch(
      fetch_product_instance(esp32_unique_id),
      error = function(e) NULL
    )
    if (!is.null(id_product_instance) && nrow(id_product_instance) > 0) {
      metadata$id_product_instance <- id_product_instance$id_product_instance[1]
      assign(esp32_unique_id, metadata, envir = esp32_metadata)
    } else {
      # Unrecognizable ESP32 Device Ignored (Only the UniqueID remains saved)
      delete_esp32_data_from_memory(esp32_unique_id)
      return(FALSE)
    }
  }

  dt_copy <- copy(dt)
  dt_copy[, id_product_instance := metadata$id_product_instance]

  result <- tryCatch(
    bulk_insert_solar_tracker_values(dt_copy),
    error = function(e) NULL
  )

  # Return before the reset of the counter to try again
  # immediately on the next sended data from the same ESP32
  # (The same that happen to the non registered)
  # Return bellow to refill entirely with new data before trying again
  # If moved refactor the returned message
  if (is.null(result)) {
    stop("Failed while inserting ESP32 Data on Database, the data is maintained in memory")
  }

  metadata$insert_count <- 0
  assign(esp32_unique_id, metadata, envir = esp32_metadata)

  TRUE
}

insert_data <- function(esp32_unique_id, max_elevation, min_elevation, servo_tower_angle, solar_panel_temperature, esp32_core_temperature, voltage, current) {
  dt <- get(esp32_unique_id, envir = solar_tracker_data_storage)
  metadata <- get(esp32_unique_id, envir = esp32_metadata)

  new_row <- data.table(
    max_elevation = max_elevation,
    min_elevation = min_elevation,
    servo_tower_angle = servo_tower_angle,
    solar_panel_temperature = solar_panel_temperature,
    esp32_core_temperature = esp32_core_temperature,
    voltage = voltage,
    current = current
  )

  dt <- rbindlist(list(dt, new_row), use.names = TRUE, fill = FALSE)

  if (nrow(dt) > total_steps) {
    dt <- dt[(.N - total_steps + 1):.N]
  }

  metadata$insert_count <- min(metadata$insert_count + 1, total_steps)

  assign(esp32_unique_id, dt, envir = solar_tracker_data_storage)
  assign(esp32_unique_id, metadata, envir = esp32_metadata)

  tryCatch({
    if (metadata$insert_count == total_steps) {
      device_founded <- save_to_database(esp32_unique_id, dt, metadata)

      return(list(
        status = if (device_founded) "created" else "bad_request",
        message = if (device_founded) "Sending ESP32 Data to Database" else "ESP32 Device Not Registered",
        data = list(
          step = metadata$insert_count,
          total_steps = total_steps
        )
      ))
    }

    list(
      status = "accepted",
      message = "Saving ESP32 Data on Memory",
      data = list(
        step = metadata$insert_count,
        total_steps = total_steps
      )
    )
  }, error = function(e) {
    list(
      status = "internal_server_error",
      message = paste("Unexpected Error:", e$message),
      data = list(
        step = metadata$insert_count,
        total_steps = total_steps
      )
    )
  })
}

process_data <- function(esp32_unique_id, max_elevation, min_elevation, servo_tower_angle, solar_panel_temperature, esp32_core_temperature, voltage, current) {
  if (!exists(esp32_unique_id, envir = solar_tracker_data_storage)) {
    empty_dt <- data.table(
      max_elevation = numeric(),
      min_elevation = numeric(),
      servo_tower_angle = numeric(),
      solar_panel_temperature = numeric(),
      esp32_core_temperature = numeric(),
      voltage = numeric(),
      current = numeric()
    )
    assign(esp32_unique_id, empty_dt, envir = solar_tracker_data_storage)
  }

  if (!exists(esp32_unique_id, envir = esp32_metadata)) {
    assign(esp32_unique_id, list(id_product_instance = NULL, insert_count = 0), envir = esp32_metadata)
  }

  insert_data(esp32_unique_id, max_elevation, min_elevation, servo_tower_angle, solar_panel_temperature, esp32_core_temperature, voltage, current)
}

send_data_solar_tracker <- function(esp32_unique_id, max_elevation, min_elevation, servo_tower_angle, solar_panel_temperature, esp32_core_temperature, voltage, current) {
  if (is_invalid_utf8(esp32_unique_id) || is_blank_string(esp32_unique_id)) {
    return(list(
      status = "bad_request",
      message = "ESP32 ID must be valid, non-empty and UTF-8 string",
      data = NULL
    ))
  }

  # Validate and convert numeric fields
  validation_result <- validate_and_convert_numeric_fields(
    max_elevation = max_elevation,
    min_elevation = min_elevation,
    servo_tower_angle = servo_tower_angle,
    solar_panel_temperature = solar_panel_temperature,
    esp32_core_temperature = esp32_core_temperature,
    voltage = voltage,
    current = current
  )

  if (validation_result$status != "success") {
    return(validation_result)
  }

  do.call(process_data, c(list(esp32_unique_id), validation_result$data))
}

receive_data_solar_tracker <- function(esp32_unique_id) {
  if (is_invalid_utf8(esp32_unique_id) || is_blank_string(esp32_unique_id)) {
    return(list(
      status = "bad_request",
      message = "ESP32 ID must be valid, non-empty and UTF-8 string",
      data = NULL
    ))
  }

  current_time <- Sys.time()
  current_date <- as.POSIXlt(current_time)

  location_informs <- get_locations_solar_tracker(esp32_unique_id)

  if (location_informs$status != "success") {
    return(list(
      status = location_informs$status,
      message = location_informs$message,
      data = NULL
    ))
  }

  response <- list(
    year = current_date$year + 1900,
    month = current_date$mon + 1,
    day = current_date$mday,
    hour = current_date$hour,
    minute = current_date$min,
    second = current_date$sec,
    latitude = 0,
    longitude = 0
  )

  if (is.null(location_informs$data$location) || nrow(location_informs$data$location) == 0) {
    return(list(
      status = "success",
      message = "No location data found for the ESP32",
      data = response
    ))
  }

  response$latitude <- location_informs$data$location$latitude
  response$longitude <- location_informs$data$location$longitude

  list(
    status = "success",
    message = "Location and time data successfully retrieved",
    data = response
  )
}
# +-------------------------------------+
# |                                     |
# |          SOLAR PANEL SERVICE        |
# |                                     |
# +-------------------------------------+

source("../models/solar_panel_model.R", chdir = TRUE)
source("../utils/utils.R", chdir = TRUE)

esp32_data_storage <- get("esp32_data_storage", envir = .GlobalEnv)
esp32_metadata <- get("esp32_metadata", envir = .GlobalEnv)

# Only the data associated to the key is wiped
delete_esp32_data_from_memory <- function(esp32_unique_id) {
  if (exists(as.character(esp32_unique_id), envir = esp32_data_storage)) {
    dt <- get(as.character(esp32_unique_id), envir = esp32_data_storage)
    assign(as.character(esp32_unique_id), dt[0], envir = esp32_data_storage)

    message(sprintf("Os dados do dispositivo %s foram apagados, mas a chave foi mantida.", esp32_unique_id))
  } else {
    message("Chave não encontrada.")
  }

  # Only reset the counter, id_product_instance are not erased
  # because the esp32 was not deleted from database, still uses the same instance
  if (exists(as.character(esp32_unique_id), envir = esp32_metadata)) {
    metadata <- get(as.character(esp32_unique_id), envir = esp32_metadata)
    metadata$insert_count <- 0
    assign(as.character(esp32_unique_id), metadata, envir = esp32_metadata)
  }
}

# The key the data and the metadata is erased
delete_esp32_from_memory <- function(esp32_unique_id) {
  if (exists(as.character(esp32_unique_id), envir = esp32_data_storage)) {
    rm(list = as.character(esp32_unique_id), envir = esp32_data_storage)
    rm(list = as.character(esp32_unique_id), envir = esp32_metadata)
    message(sprintf("Os dados do dispositivo %s foram removidos.", esp32_unique_id))
  } else {
    message("Chave não encontrada.")
  }
}

# Get all esp32 data of the environment
get_all_data <- function() {
  keys <- ls(envir = esp32_data_storage)
  all_data <- lapply(keys, function(key) {
    data <- get(key, envir = esp32_data_storage)
    list(id = key, data = data)
  })
  return(all_data)
}

# Save the information of the recognizable esp32 on the database
save_to_database <- function(esp32_unique_id, dt, metadata) {
  if (is.null(metadata$id_product_instance)) {
    id_product_instance <- tryCatch(
      fetch_product_instance(esp32_unique_id),
      error = function(e) return(NULL)
    )
    if (!is.null(id_product_instance) && nrow(id_product_instance) > 0) {
      metadata$id_product_instance <- id_product_instance$id_product_instance[1]
      assign(as.character(esp32_unique_id), metadata, envir = esp32_metadata)
    } else {
      message("Unrecognizable ESP32 Device Blocked")
      metadata$insert_count <- 0
      assign(as.character(esp32_unique_id), metadata, envir = esp32_metadata)
      return()
    }
  }

  dt_copy <- copy(dt)
  dt_copy[, id_product_instance := metadata$id_product_instance]

  message(sprintf("Salvando dados do dispositivo %s no banco de dados...", esp32_unique_id))

  result <- tryCatch(
    bulk_insert_solar_panel_values(dt_copy),
    error = function(e) return(NULL)
  )

  if (is.null(result)) {
    message("Error Inserting")
  }

  metadata$insert_count <- 0
  assign(as.character(esp32_unique_id), metadata, envir = esp32_metadata)
}

insert_data <- function(esp32_unique_id, max_elevation, min_elevation, servo_tower_angle, solar_panel_temperature, esp32_core_temperature, voltage, current) {
  dt <- get(as.character(esp32_unique_id), envir = esp32_data_storage)
  metadata <- get(as.character(esp32_unique_id), envir = esp32_metadata)

  dt <- rbind(dt, data.table(
    max_elevation = max_elevation,
    min_elevation = min_elevation,
    servo_tower_angle = servo_tower_angle,
    solar_panel_temperature = solar_panel_temperature,
    esp32_core_temperature = esp32_core_temperature,
    voltage = voltage,
    current = current
  ))

  if (nrow(dt) > 10) {
    dt <- dt[-1]
  }

  metadata$insert_count <- metadata$insert_count + 1

  assign(as.character(esp32_unique_id), dt, envir = esp32_data_storage)
  assign(as.character(esp32_unique_id), metadata, envir = esp32_metadata)

  if (metadata$insert_count >= 10) {
    save_to_database(esp32_unique_id, dt, metadata)
  }

  return(list(
    status = "success",
    message = "Successfully Saved ESP32 Data"
  ))
}

process_data <- function(esp32_unique_id, max_elevation, min_elevation, servo_tower_angle, solar_panel_temperature, esp32_core_temperature, voltage, current) {
  if (!exists(as.character(esp32_unique_id), envir = esp32_data_storage)) {
    assign(as.character(esp32_unique_id),
      data.table(
        max_elevation = numeric(),
        min_elevation = numeric(),
        servo_tower_angle = numeric(),
        solar_panel_temperature = numeric(),
        esp32_core_temperature = numeric(),
        voltage = numeric(),
        current = numeric()
      ),
      envir = esp32_data_storage
    )
  }

  if (!exists(as.character(esp32_unique_id), envir = esp32_metadata)) {
    assign(as.character(esp32_unique_id), list(id_product_instance = NULL, insert_count = 0), envir = esp32_metadata)
  }

  insert_data(esp32_unique_id, max_elevation, min_elevation, servo_tower_angle, solar_panel_temperature, esp32_core_temperature, voltage, current)
}

send_data_solar_panel <- function(esp32_unique_id, max_elevation, min_elevation, servo_tower_angle, solar_panel_temperature, esp32_core_temperature, voltage, current) {
  if (is_invalid_utf8(esp32_unique_id) || is_blank_string(esp32_unique_id)) {
    return(list(
      status = "bad_request",
      message = "ESP32 ID must be valid, non-empty and UTF-8 string"
    ))
  }

  validation_result <- validate_and_convert_numeric_fields(
    max_elevation = max_elevation,
    min_elevation = min_elevation,
    servo_tower_angle = servo_tower_angle,
    solar_panel_temperature = solar_panel_temperature,
    esp32_core_temperature = esp32_core_temperature,
    voltage = voltage,
    current = current
  )

  if (validation_result$status == "bad_request") {
    return(validation_result)
  } else {
    max_elevation <- validation_result$data$max_elevation
    min_elevation <- validation_result$data$min_elevation
    servo_tower_angle <- validation_result$data$servo_tower_angle
    solar_panel_temperature <- validation_result$data$solar_panel_temperature
    esp32_core_temperature <- validation_result$data$esp32_core_temperature
    voltage <- validation_result$data$voltage
    current <- validation_result$data$current
  }

  process_data(esp32_unique_id, max_elevation, min_elevation, servo_tower_angle, solar_panel_temperature, esp32_core_temperature, voltage, current)
}
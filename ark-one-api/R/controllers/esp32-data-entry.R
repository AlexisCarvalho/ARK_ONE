# +-----------------------+
# |                       |
# |   ESP32 DATA ENTRY    |
# |                       |
# +-----------------------+

source("../services/solar_panel_service.R", chdir = TRUE)
source("../services/location_data_service.R", chdir = TRUE)

#* Stores the values entered with the treatment of the data and the proper analysis of their fluctuation
#* @response 200 Data Received
#* @response 404 ESP32 id not found
#* @response 500 Internal Server Error
#* @description This endpoint is dedicated to receive data from ESP32 specifically Voltage, Current and Watts
#* @tag ESP32_DataEntry
#* @param esp32_unique_id esp32_unique_id
#* @param max_elevation max_elevation
#* @param min_elevation min_elevation
#* @param servo_tower_angle servo_tower_angle
#* @param solar_panel_temperature solar_panel_temperature
#* @param esp32_core_temperature esp32_core_temperature
#* @param voltage voltage
#* @param current current
#* @post /send_data/solar_panel
function(res, esp32_unique_id, max_elevation, min_elevation, servo_tower_angle, solar_panel_temperature, esp32_core_temperature, voltage, current){
  tryCatch({
    servo_tower_angle <- as.numeric(servo_tower_angle)
    solar_panel_temperature <- as.numeric(solar_panel_temperature)
    esp32_core_temperature <- as.numeric(esp32_core_temperature)
    voltage <- as.numeric(voltage)
    current <- as.numeric(current)
    
    if (is.na(esp32_unique_id) || is.na(voltage) || is.na(current) || is.na(servo_tower_angle) || is.na(solar_panel_temperature) || is.na(esp32_core_temperature)) {
      return(list(status = "error", message = "Null values are not permitted"))
    }
    
    response <- save_incoming_solar_panel_data(esp32_unique_id, servo_tower_angle, solar_panel_temperature, esp32_core_temperature, voltage, current)
    
    if(response$status == "success")
    {
      res$status <- 200
      return(response)
    } else
    {
      res$status <- 404
      return(response)
    }
  }, error = function(e) {
    res$status <- 500
    return(list(error = e$message))
  })
}

#* @tag ESP32_DataEntry
#* @param esp32_unique_id
#* @get /receive_data/solar_panel
function(res, esp32_unique_id) {
  current_time <- Sys.time()
  current_date <- as.POSIXlt(current_time)

  location_informs <- return_location_of_ESP32_using_id(esp32_unique_id)

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

  if(location_informs$status == "error")
  {
    res$status <- 400
    return(list(status = location_informs$status, message = location_informs$message))
  }

  if(nrow(location_informs$data) == 0)
  {
    res$status <- 200
    return(response)
  }
  else
  {
    response$latitude = location_informs$data$latitude
    response$longitude = location_informs$data$longitude
    res$status <- 200
    return(response)
  }
}
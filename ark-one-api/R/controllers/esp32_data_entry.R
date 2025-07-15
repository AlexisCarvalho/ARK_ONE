# +-----------------------+
# |                       |
# |   ESP32 DATA ENTRY    |
# |                       |
# +-----------------------+

source("../services/solar_tracker_service.R", chdir = TRUE)
source("../services/location_service.R", chdir = TRUE)
source("../utils/response_handler.R", chdir = TRUE)

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
#* @post /solar_tracker/send_data
function(res, esp32_unique_id, max_elevation, min_elevation, servo_tower_angle, solar_panel_temperature, esp32_core_temperature, voltage, current) {
  send_http_response(res, send_data_solar_tracker(esp32_unique_id, max_elevation, min_elevation, servo_tower_angle, solar_panel_temperature, esp32_core_temperature, voltage, current))
}

#* Receive location and time data for a specific ESP32
#* @tag ESP32_DataEntry
#* @param esp32_unique_id The unique ID of the ESP32
#* @get /solar_tracker/receive_data
#* @response 200 Returns location and time data
#* @response 400 Bad Request if the ESP32 ID is invalid
#* @response 500 Internal Server Error
function(res, esp32_unique_id) {
  send_http_response(res, receive_data_solar_tracker(esp32_unique_id))
}
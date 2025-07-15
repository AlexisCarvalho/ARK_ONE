if (!require("httr")) install.packages("httr", dependencies = TRUE)
library(httr)
if (!require("jsonlite")) install.packages("jsonlite", dependencies = TRUE)
library(jsonlite)

messages_per_minute <- 30
interval <- 60 / messages_per_minute

esp32_unique_id <- "sampleInformation"
servo_tower_angle <- 0

time <- 0
amplitude <- 5
offset <- 15
frequency <- 0.05
previous_code <- 1

angle_increment <- 1
angle_direction <- 1

temp_amplitude <- 2
temp_offset_solar <- 30
temp_offset_esp32 <- 35
temp_frequency <- 0.02

send_data <- function(esp32_unique_id, max_elevation, min_elevation, servo_tower_angle, solar_panel_temperature, esp32_core_temperature, voltage, current) {
  url <- "http://localhost:8000/ESP32_DataEntry/solar_tracker/send_data"

  body <- list(
    esp32_unique_id = esp32_unique_id,
    max_elevation = max_elevation,
    min_elevation = min_elevation,
    servo_tower_angle = servo_tower_angle,
    solar_panel_temperature = solar_panel_temperature,
    esp32_core_temperature = esp32_core_temperature,
    voltage = voltage,
    current = current
  )

  start <- Sys.time()

  response <- suppressWarnings(
    POST(url, body = toJSON(body, auto_unbox = TRUE), encode = "json")
  )

  end <- Sys.time()

  code <- status_code(response)
  response_text <- content(response, "text", encoding = "UTF-8")

  #if (previous_code != code) {
  #  elapsed_time_ms <- as.numeric(difftime(end, start, units = "secs")) * 1000
  #  cat("Code:", code, "| Elapsed:", sprintf("%.3f", elapsed_time_ms), "milliseconds | Response:", response_text, "\n")
  #}

  elapsed_time_ms <- as.numeric(difftime(end, start, units = "secs")) * 1000
  cat("| Elapsed:", sprintf("%.3f", elapsed_time_ms), "milliseconds |", "\n")

  previous_code <<- code
}

while (TRUE) {
  voltage <- offset + amplitude * sin(frequency * time)
  current <- offset + amplitude * sin(frequency * time + pi / 2)

  voltage <- max(0, voltage)
  current <- max(0, current)

  solar_panel_temperature <- temp_offset_solar + temp_amplitude * sin(temp_frequency * time)
  esp32_core_temperature <- temp_offset_esp32 + temp_amplitude * cos(temp_frequency * time)

  send_data(
    esp32_unique_id = esp32_unique_id,
    max_elevation = 0,
    min_elevation = 0,
    servo_tower_angle = servo_tower_angle,
    solar_panel_temperature = solar_panel_temperature,
    esp32_core_temperature = esp32_core_temperature,
    voltage = voltage,
    current = current
  )

  servo_tower_angle <- servo_tower_angle + angle_increment * angle_direction

  if (servo_tower_angle >= 180) {
    servo_tower_angle <- 180
    angle_direction <- -1
  } else if (servo_tower_angle <= 0) {
    servo_tower_angle <- 0
    angle_direction <- 1
  }

  time <- time + interval
  Sys.sleep(interval)
}
if (!require("httr")) install.packages("httr", dependencies = TRUE); library(httr)
if (!require("jsonlite")) install.packages("jsonlite", dependencies = TRUE); library(jsonlite)

envios_por_minuto <- 60
intervalo <- 60 / envios_por_minuto

esp32_unique_id <- "sampleInformation"
servo_tower_angle <- 0

tempo <- 0
amplitude <- 5
offset <- 15
frequencia <- 0.05
codigo_anterior <- 1

angle_increment <- 1
angle_direction <- 1

temp_amplitude <- 2
temp_offset_solar <- 30
temp_offset_esp32 <- 35
temp_frequencia <- 0.02

send_data <- function(esp32_unique_id, voltage, current, servo_tower_angle, max_elevation, min_elevation, elevation_angle, solar_panel_temperature, esp32_core_temperature) {
  url <- "http://192.168.0.139:8000/ESP32_DataEntry/send_data/solar_panel"
  
  body <- list(
    esp32_unique_id = esp32_unique_id,
    voltage = voltage,
    current = current,
    servo_tower_angle = servo_tower_angle,
    max_elevation = max_elevation,
    min_elevation = min_elevation,
    elevation_angle = elevation_angle,
    solar_panel_temperature = solar_panel_temperature,
    esp32_core_temperature = esp32_core_temperature
  )
  
  response <- suppressWarnings(
    POST(url, body = toJSON(body, auto_unbox = TRUE), encode = "json")
  )
  
  codigo <- status_code(response)
  resposta <- content(response, "text", encoding = "UTF-8")
  
  if (codigo_anterior != codigo) {
    cat("Código:", codigo, "| Resposta:", resposta, "\n")
  }
  codigo_anterior <<- codigo
}

while (TRUE) {
  voltage <- offset + amplitude * sin(frequencia * tempo)
  current <- offset + amplitude * sin(frequencia * tempo + pi / 2)
  
  voltage <- max(0, voltage)
  current <- max(0, current)
  
  solar_panel_temperature <- temp_offset_solar + temp_amplitude * sin(temp_frequencia * tempo)
  esp32_core_temperature <- temp_offset_esp32 + temp_amplitude * cos(temp_frequencia * tempo)
  
  send_data(
    esp32_unique_id = esp32_unique_id,
    voltage = voltage,
    current = current,
    servo_tower_angle = servo_tower_angle,
    max_elevation = 0,
    min_elevation = 0,
    elevation_angle = 0,
    solar_panel_temperature = solar_panel_temperature,
    esp32_core_temperature = esp32_core_temperature
  )
  
  servo_tower_angle <- servo_tower_angle + angle_increment * angle_direction
  
  if (servo_tower_angle >= 180) {
    servo_tower_angle <- 180
    angle_direction <- -1
  } else if (servo_tower_angle <= 0) {
    servo_tower_angle <- 0
    angle_direction <- 1
  }
  
  tempo <- tempo + intervalo
  Sys.sleep(intervalo)
}

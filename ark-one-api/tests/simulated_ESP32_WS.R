library(jsonlite)
library(websocket)
library(later)

# WebSocket client
ws <- WebSocket$new("ws://localhost:8081")
connected <- FALSE # Flag to track connection state

# Generate random esp32_data
generate_esp32_data <- function(id) {
  list(
    esp32_data = list(
      esp32_unique_id = id,
      max_elevation = runif(1, min = 0, max = 90),
      min_elevation = runif(1, min = 0, max = 90),
      servo_tower_angle = runif(1, min = 0, max = 360),
      solar_panel_temperature = runif(1, min = -10, max = 80),
      esp32_core_temperature = runif(1, min = -10, max = 80),
      voltage = runif(1, min = 0, max = 24),
      current = runif(1, min = 0, max = 10)
    )
  )
}

# Periodically send esp32_data
send_data_periodically <- function(id, interval = 2) {
  later::later(function() {
    if (connected) { # Use the connected flag
      data <- generate_esp32_data(id)

      start <- Sys.time()
      ws$send(toJSON(data, auto_unbox = TRUE))
      end <- Sys.time()

      elapsed_time_ms <- as.numeric(difftime(end, start, units = "secs")) * 1000
      #cat("Sended data for |", id, "| in", sprintf("%.3f", elapsed_time_ms), "milliseconds", "\n")
      cat("| Elapsed:", sprintf("%.3f", elapsed_time_ms), "milliseconds |", "\n")
      send_data_periodically(id, interval)
    }
  }, interval)
}

# WebSocket event handlers
ws$onOpen(function(event) {
  cat("Connected to WebSocket server\n")
  connected <<- TRUE # Set the connected flag to TRUE
  send_data_periodically("esp32_001") # Replace with desired ID
})

ws$onMessage(function(event) {
  #cat("Received message from server:\n", event$data, "\n")
})

ws$onClose(function(event) {
  cat("Disconnected from WebSocket server\n")
  connected <<- FALSE # Set the connected flag to FALSE
})

ws$onError(function(event) {
  cat("WebSocket error:", event$message, "\n")
  connected <<- FALSE # Set the connected flag to FALSE
})
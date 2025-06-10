if (requireNamespace("renv", quietly = TRUE)) {
  if (is.null(renv::project())) {
    source("renv/activate.R", chdir = TRUE)
  }
} else {
  stop("The Package 'renv' is not installed. You can install it using install.packages('renv').")
}

readRenviron(".Renviron")

source("R/utils/libraries.R", chdir = TRUE)
source("R/utils/env_setup.R", chdir = TRUE)
source("R/services/solar_tracker_service.R", chdir = TRUE)

# Simulated in-memory data (instead of globalenv)
solar_tracker_data_storage <- get("solar_tracker_data_storage", envir = .GlobalEnv)
esp32_metadata <- get("esp32_metadata", envir = .GlobalEnv)

# WebSocket state
clients <- list() # connectionId -> WebSocket connection
subscriptions <- list() # connectionId -> vector of esp32_ids
max_points <- 30

# Start WebSocket server
solar_ws_server <- startServer("0.0.0.0", 8081, list(
  onWSOpen = function(ws) {
    conn_id <- UUIDgenerate()
    clients[[conn_id]] <<- ws
    subscriptions[[conn_id]] <<- character(0)

    message(sprintf("Client %s connected", conn_id))

    ws$onMessage(function(binary, message) {
      tryCatch(
        {
          #cat("Raw message received from client:\n", message, "\n")
          req <- fromJSON(message)

          if (is.null(req)) {
            return()
          }

          # Handle esp32_data
          if (!is.null(req$esp32_data)) {
            result <- do.call(send_data_solar_tracker, req$esp32_data)
            ws$send(toJSON(result, auto_unbox = TRUE))
          }

          # Handle esp32_ids subscription
          if (!is.null(req$request_esp32_ids) && is.character(req$request_esp32_ids)) {
            subscriptions[[conn_id]] <<- unique(req$request_esp32_ids)
            message(sprintf(
              "Client %s subscribed to: %s", conn_id,
              paste(req$request_esp32_ids, collapse = ", ")
            ))
          }
        },
        error = function(e) {
          cat("Error processing message:", e$message, "\n")
          ws$send(toJSON(list(error = e$message), auto_unbox = TRUE))
        }
      )
    })

    ws$onClose(function() {
      message(sprintf("Client %s disconnected", conn_id))
      clients[[conn_id]] <<- NULL
      subscriptions[[conn_id]] <<- NULL
    })
  }
))

# Periodic broadcaster
send_targeted_updates <- function() {
  for (conn_id in names(clients)) {
    conn <- clients[[conn_id]]
    requested_ids <- subscriptions[[conn_id]]

    if (length(requested_ids) > 0 && !is.null(conn)) {
      cat("Processing updates for Connection ID:", conn_id, "\n")
      cat("Requested IDs:", paste(requested_ids, collapse = ", "), "\n")
      device_data_list <- lapply(requested_ids, function(esp32_id) {
        if (exists(esp32_id, envir = solar_tracker_data_storage)) {
          data <- tail(get(esp32_id, envir = solar_tracker_data_storage), max_points)
          meta <- get(esp32_id, envir = esp32_metadata)
          list(esp32_id = esp32_id, metadata = meta, data = data)
        } else {
          NULL
        }
      })

      device_data_list <- Filter(Negate(is.null), device_data_list)

      if (length(device_data_list) > 0) {
        payload <- list(type = "device_data", data = device_data_list)
        cat("Sending payload to client:", conn_id, "\n")
        conn$send(toJSON(payload, auto_unbox = TRUE))
      }
    }
  }

  later(send_targeted_updates, 2)
}

send_targeted_updates()
message("✅ WebSocket server started on ws://localhost:8081")

# +------------------+
# |                  |
# |  STATUS SERVICE  |
# |                  |
# +------------------+

status_ping <- function() {
  list(status = "success", message = "The API is Running")
}

status_solar_panel_values <- function() {
  list(status = "service_unavailable", message = "Service Temporary Unavailable due to Maintenance")
}
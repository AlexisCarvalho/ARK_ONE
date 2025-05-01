# +------------------+
# |                  |
# |  STATUS SERVICE  |
# |                  |
# +------------------+

status_ping <- function() {
  list(status = "success", message = "The API is Running")
}

status_solar_tracker_values <- function() {
  list(status = "service_unavailable", message = "Service Temporary Unavailable due to Maintenance")
}
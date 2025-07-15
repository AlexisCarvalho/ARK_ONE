# +------------------------+
# |                        |
# |  TEST ENDPOINT STATUS  |
# |                        |
# +------------------------+

library(testthat)
library(httr)
library(jsonlite)

# API Base URL
base_url <- "http://localhost:8000"

# Request function for status
ping_request <- function() {
  GET(paste0(base_url, "/Status/ping"))
}

solar_tracker_values_request <- function() {
  GET(paste0(base_url, "/Status/recent_values/solar_tracker"))
}

# Function designed to test the status endpoint
status_ping_tests <- function() {
  message("Testing GET (/Status/ping) ...")

  test_that("The API Status ping should return 200", {
    response <- ping_request()
    content <- content(response, as = "parsed", simplifyVector = TRUE)

    expect_equal(status_code(response), 200)
    expect_equal(content$status, "success")
  })
}

# Function designed to test the solar panel values endpoint
status_solar_tracker_values_tests <- function() {
  message("Testing GET (/Status/recent_values/solar_tracker) ...")

  test_that("Solar Panel values should return 503", {
    response <- solar_tracker_values_request()
    content <- content(response, as = "parsed", simplifyVector = TRUE)

    expect_equal(status_code(response), 503)
    expect_equal(content$status, "service_unavailable")
    expect_equal(content$message, "Service Temporary Unavailable due to Maintenance")
  })
}

status_ping_tests()
status_solar_tracker_values_tests()
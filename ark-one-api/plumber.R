# plumber.R
if (!require("plumber")) install.packages("plumber", dependencies = TRUE); library(plumber)
if (!require("jose")) install.packages("jose", dependencies = TRUE); library(jose)
if (!require("digest")) install.packages("digest", dependencies = TRUE); library(digest)
if (!require("data.table")) install.packages("data.table", dependencies = TRUE); library(data.table)
if (!require("DBI")) install.packages("DBI", dependencies = TRUE); library(DBI)
if (!require("RPostgres")) install.packages("RPostgres", dependencies = TRUE); library(RPostgres)
if (!require("qcc")) install.packages("qcc", dependencies = TRUE); library(qcc)
if (!require("e1071")) install.packages("e1071", dependencies = TRUE); library(e1071)
if (!require("forecast")) install.packages("forecast", dependencies = TRUE); library(forecast)
if (!require("isotree")) install.packages("isotree", dependencies = TRUE); library(isotree)
if (!require("dbscan")) install.packages("dbscan", dependencies = TRUE); library
if (!require("future")) install.packages("future", dependencies = TRUE); library(future)
if (!require("parallel")) install.packages("parallel", dependencies = TRUE); library(parallel)

# Configuring parallelism using multisession to maintain Windows Compatibility
future::plan(future::multisession, workers = parallel::detectCores() - 1)

source("R/auth-filter.R", chdir = TRUE)

pr <- plumber::pr()

# +-------------------------------------+
# |         API ACCESS POLICY           |
# +-------------------------------------+

# ADD CORS Filter globally
pr <- pr %>%
  pr_filter("cors", function(req, res) {
    res$setHeader("Access-Control-Allow-Origin", "*") 
    res$setHeader("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS") 
    res$setHeader("Access-Control-Allow-Headers", "Content-Type, Authorization") 
    if (req$REQUEST_METHOD == "OPTIONS") {
      res$status <- 200
      return(list())
    } else {
      plumber::forward() 
    }
  })

# +-------------------------------------+
# |     ENDPOINTS ROUTER CRIATION       |
# +-------------------------------------+

account_router <- plumber::plumb("R/endpoints/account.R")
analytics_router <- plumber::plumb("R/endpoints/analytics.R")
anomaly_detection_router <- plumber::plumb("R/endpoints/anomaly-detection.R")
category_router <- plumber::plumb("R/endpoints/category.R")
esp32_data_entry_router <- plumber::plumb("R/endpoints/esp32-data-entry.R")
location_router <- plumber::plumb("R/endpoints/location.R")
products_router <- plumber::plumb("R/endpoints/products.R")
solar_cell_router <- plumber::plumb("R/endpoints/solar-cell.R")
statistics_router <- plumber::plumb("R/endpoints/statistics.R")
status_router <- plumber::plumb("R/endpoints/status.R")
time_series_router <- plumber::plumb("R/endpoints/time-series.R")
person_router <- plumber::plumb("R/endpoints/person.R")

# +-------------------------------------+
# |    FILTER ADDITION TO ENDPOINTS     |
# +-------------------------------------+

anomaly_detection_router <- anomaly_detection_router %>%
  pr_filter("authenticate", authenticate)

solar_cell_router <- solar_cell_router %>%
  pr_filter("authenticate", authenticate)

statistics_router <- statistics_router %>%
  pr_filter("authenticate", authenticate)

time_series_router <- time_series_router %>%
  pr_filter("authenticate", authenticate)

person_router <- person_router %>%
  pr_filter("authenticate", authenticate)

# +-------------------------------------+
# |        MOUNTING ENDPOINTS           |
# +-------------------------------------+

pr$mount("/Account", account_router)                      # No authentication required
pr$mount("/Analytics", analytics_router)                  # No authentication required
pr$mount("/Anomaly_Detection", anomaly_detection_router)  # Requires authentication
pr$mount("/Category", category_router)                    # Requires authentication
pr$mount("/ESP32_DataEntry", esp32_data_entry_router)     # No authentication required
pr$mount("/Location", location_router)                    # Requires authentication
pr$mount("/Products", products_router)                    # Requires authentication
pr$mount("/Solar_Cell", solar_cell_router)                # Requires authentication
pr$mount("/Statistics", statistics_router)                # Requires authentication
pr$mount("/Status", status_router)                        # No authentication required
pr$mount("/Time_Series", time_series_router)              # Requires authentication
pr$mount("/Person", person_router)                        # No authentication required

# +-------------------------------------+
# |      DOCUMENTATION SETTINGS         |
# +-------------------------------------+

pr <- pr %>% pr_set_api_spec(function(spec) 
{
  spec$components$securitySchemes$bearerAuth <- list(
    type = "http",
    scheme = "bearer",
    bearerFormat = "JWT"
  )
  
  spec$security <- list(list(bearerAuth = list()))
  
  spec$paths$`/Account/register`$get$security <- NULL
  spec$paths$`/Account/login`$get$security <- NULL
  spec$paths$`/Status/ping`$get$security <- NULL
  spec$path$`/ESP32_DataEntry/send_data/solar_panel`$get$security <- NULL
  
  spec$info$title <- "Solar Panel One API"
  spec$info$description <- "This API is constructed using the R Language and the packages Plumber, and it is designated to work beside the system of solar panels \"One\" that uses ESP32. The objective is to make queries on the database, analyze and process the data generated by the system and plot them with it interactive warnings depending on the variations of the data."
  
  return(spec)
})

pr$setDocs(TRUE)

# +-------------------------------------+
# |  RUNNING THE API AND SETTING PORT   |
# +-------------------------------------+

pr$run(host = "0.0.0.0", port = 8000)

source("../models/location_model.R", chdir = TRUE)

# +------------------------------+
# |                              |
# |    LOCATION DATA SERVICE     |
# |                              |
# +------------------------------+

verify_location <- function(id_product_instance)
{
  tryCatch({
    con <- getConn()
    on.exit(dbDisconnect(con))

    select_query <- "
    SELECT latitude, longitude
    FROM location_data
    WHERE id_product_instance = $1;
    "
    result <- dbGetQuery(con, select_query, params = list(id_product_instance))
    return(list(status = "success", message = "Success Receiving Data", data = result))
  }, error = function(e) {
    return(list(status = "error", message = e$message))
  })
}

return_location_of_ESP32_using_id <- function(esp32_unique_id)
{
  con <- getConn()
  on.exit(dbDisconnect(con))

  query <- "SELECT id_product_instance FROM product_instance WHERE esp32_unique_id = $1"

  id_product_instance <- dbGetQuery(con, query, params = list(esp32_unique_id))

  if (nrow(id_product_instance) == 0) {
    return(list(status = "error", message = "No product found for the given esp32_unique_id."))
  }

  id_product_instance <- id_product_instance$id_product_instance[1]

  response <- verify_location(id_product_instance)
  return(response)
}

update_location_data <- function(id_product_instance, latitude, longitude)
{
  tryCatch({
    con <- getConn()  
    on.exit(dbDisconnect(con))  

    if (is.null(latitude) || is.null(longitude)) {
      return(list(status = "error", message = "Latitude and Longitude must be provided together."))
    }

    update_query <- "
    UPDATE location_data
    SET latitude = $1, longitude = $2
    WHERE id_product_instance = $3;
    "

    dbExecute(con, update_query, params = list(latitude, longitude, id_product_instance))

    return(list(status = "success", message = "Location data updated successfully"))
  }, error = function(e) {
    return(list(status = "error", message = e$message))
  })
}

# Function to create new location data for a product instance
create_location_data <- function(id_product_instance, latitude, longitude) {
  con <- getConn()
  on.exit(dbDisconnect(con))

  existing_instance <- dbGetQuery(con, "SELECT * FROM product_instance WHERE id_product_instance = $1", params = list(id_product_instance))

  if (nrow(existing_instance) == 0) {
    return(list(status = "error", message = "Product instance not found"))
  }

  query <- "INSERT INTO location_data (id_product_instance, latitude, longitude) VALUES ($1, $2, $3)"
  dbExecute(con, query, params = list(id_product_instance, latitude, longitude))

  return(list(status = "success", message = "Location data created"))
}



# Function to get all location data
get_all_location_data <- function() {
  con <- getConn()
  on.exit(dbDisconnect(con))

  locations <- dbReadTable(con, "location_data")
  return(locations)
}

# Function to get location data by ID
get_location_by_id <- function(id) {
  con <- getConn()
  on.exit(dbDisconnect(con))

  query <- "SELECT * FROM location_data WHERE id_location = ?"
  location <- dbGetQuery(con, query, params = list(id))

  if (nrow(location) == 0) {
    return(list(status = "error", message = "Location data not found"))
  }

  return(location)
}

# Function to update location data by ID
update_location_by_id <- function(id, id_product_instance = NULL, latitude = NULL, longitude = NULL) {
  con <- getConn()
  on.exit(dbDisconnect(con))

  updates <- c()

  if (!is.null(id_product_instance)) updates <- c(updates, sprintf("id_product_instance = %s", id_product_instance))
  if (!is.null(latitude)) updates <- c(updates, sprintf("latitude = %f", latitude))
  if (!is.null(longitude)) updates <- c(updates, sprintf("longitude = %f", longitude))

  if (length(updates) > 0) {
    update_query <- paste(updates, collapse = ", ")
    dbExecute(con, sprintf("UPDATE location_data SET %s WHERE id_location = ?", update_query), params = list(id))
    return(list(status = "success", message = "Location data updated"))
  }

  return(list(status = "error", message = "No fields to update"))
}

# Function to delete location data by ID
delete_location_by_id <- function(id) {
  con <- getConn()
  on.exit(dbDisconnect(con))

  dbExecute(con, "DELETE FROM location_data WHERE id_location = ?", params = list(id))

  return(list(status = "success", message = "Location data deleted"))
}

# Function to get all location data for a specific product instance
get_location_by_product_instance_id <- function(product_instance_id) {
  con <- getConn()
  on.exit(dbDisconnect(con))

  query <- "
    SELECT * 
    FROM location_data 
    WHERE id_product_instance = ?"

  results <- dbGetQuery(con, query, params=list(product_instance_id))

  if (nrow(results) == 0) {
    return(list(status="error", message="No location data found for this product instance"))
  }

  return(results)
}
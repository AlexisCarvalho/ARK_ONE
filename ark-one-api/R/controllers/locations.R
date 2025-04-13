# +-----------------------+
# |                       |
# |       LOCATION        |
# |                       |
# +-----------------------+

source("../services/location_data_service.R", chdir = TRUE)

#* @tag Locations
#* @param esp32_unique_id 
#* @get /get_location
function(res, esp32_unique_id) {
  tryCatch(
    {
      location_informs <- future::value(future::future({
        return_location_of_ESP32_using_id(esp32_unique_id)
      }))
      
      response <- list(
        latitude = -23.5505,      
        longitude = -46.6333    
      )
      
      if(location_informs$status == "error")
      {
        res$status <- 400
        return(list(status = location_informs$status, message = location_informs$message))
      }
      
      if(nrow(location_informs$data) == 0)
      {
        res$status <- 200
        return(list(status = "noLocationData", data = response))
      }
      else
      {
        response$latitude = location_informs$data$latitude
        response$longitude = location_informs$data$longitude
        res$status <- 200
        return(list(status = "success", data = response))
      }
    },
    error = function(e) {
      res$status <- 500
      return(list(status = "error", message = "Internal Server Error", details = e$message))
    }
  )
}

#* Create new location data for a product instance
#* @param id_product_instance The ID of the product instance
#* @param latitude Latitude of the location
#* @param longitude Longitude of the location
#* @tag Locations
#* @post /set
#* @response 201 Created if location data is successfully created
#* @response 400 Bad Request if product instance does not exist
#* @response 500 Internal Server Error if there is an issue creating location data
function(res, id_product_instance, latitude, longitude) {
  if (missing(id_product_instance) || missing(latitude) || missing(longitude)) {
    res$status <- 400
    return(list(status = "error", message = "Missing required parameters"))
  }
  
  tryCatch(
    {
      existingLocation <- future::value(future::future({
        verify_location(id_product_instance)
      }))
      
      if(existingLocation$status == "error")
      {
        res$status <- 400
        return(list(status = existingLocation$status, message = existingLocation$message))
      }
      
      if(nrow(existingLocation$data) == 0)
      {
        result <- future::value(future::future({
          create_location_data(id_product_instance, latitude, longitude)
        }))
      }
      else
      {
        result <- future::value(future::future({
          update_location_data(id_product_instance, latitude, longitude)
        }))
      }
      
      if(result$status == "error")
      {
        res$status <- 400
        return(list(status = result$status, message = result$message))
      }
      
      res$status <- 200
      return(list(status = "success", message = result$message))
    },
    error = function(e) {
      res$status <- 500
      return(list(status = "error", message = "Internal Server Error", details = e$message))
    }
  )
}

#* Get all location data
#* @tag Locations
#* @get /get_all
#* @response 200 Returns a list of all location data
#* @response 500 Internal Server Error if there is an issue retrieving location data
function() {
  tryCatch({
    locations <- get_all_location_data()
    return(list(status = "success", data = locations))
  }, error = function(e) {
    return(list(status = "error", message = "Failed to retrieve location data", details = e$message))
  })
}

#* Get location data by ID
#* @param id The ID of the location data to retrieve
#* @tag Locations
#* @get /<id>
#* @response 200 Returns the details of the specified location data
#* @response 404 Not Found if the location data does not exist
#* @response 500 Internal Server Error if there is an issue retrieving the location data
function(id) {
  if (missing(id) || !is.numeric(as.numeric(id))) {
    return(list(status = "error", message = "Invalid or missing location ID"))
  }
  
  id <- as.numeric(id)
  
  tryCatch({
    location <- get_location_by_id(id)
    
    if (is.null(location) || nrow(location) == 0) {
      return(list(status = "error", message = "Location data not found"))
    }
    
    return(list(status = "success", data = location))
    
  }, error = function(e) {
    return(list(status = "error", message = "Failed to retrieve location data", details = e$message))
  })
}

#* Delete a location by ID
#* @param id The ID of the location data to delete
#* @tag Locations
#* @delete /<id>
#* @response 200 OK if the location data was successfully deleted
#* @response 404 Not Found if the location data does not exist
#* @response 500 Internal Server Error if there is an issue deleting the location data
function(id) {
  if (missing(id) || !is.numeric(as.numeric(id))) {
    return(list(status = "error", message = "Invalid or missing location ID"))
  }
  
  id <- as.numeric(id)
  
  tryCatch({
    result <- delete_location_by_id(id)
    
    if (result$status == "error") {
      return(list(status = "error", message = result$message))
    }
    
    return(list(status = "success", message = "Location data deleted successfully"))
    
  }, error = function(e) {
    return(list(status = "error", message = "Failed to delete location data", details = e$message))
  })
}

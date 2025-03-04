# +-----------------------+
# |                       |
# |        PERSON         |
# |                       |
# +-----------------------+

source("../services/user_service.R", chdir = TRUE)
source("../services/product_service.R", chdir = TRUE)

#* Get the tipe of the user
#* @tag Person
#* @get /getType
#* @response 200 Returns the type of the specified user
#* @response 404 Not Found if the user does not exist
#* @response 500 Internal Server Error
function(req, res) {
  result <- tryCatch({
    
    response <- get_user_type_from_request(req)
    
    if (response$status == "success") {
      res$status <- 200
      return(list(status = "success", data = response$data))
    } else {
      res$status <- 404
      return(list(status = "error", message = response$message))
    }
    
  }, error = function(e) {
    res$status <- 500
    return(list(status = "error", message = "Internal Server Error", details = e$message))
  })
}

#* Get all products purchased by user
#* @tag Person
#* @get /products_purchased
#* @response 200 Returns the details of the specified user products
#* @response 400 Bad Request if the Authorization header is missing or invalid
#* @response 404 Not Found if the user does not exist or doesn't have any products
#* @response 500 Internal Server Error
function(req, res) {
    tryCatch({
      result <- future::value(future::future({
        get_user_products_from_request(req)
      }))
    
    if (result$status == "success") {
      res$status <- 200
      return(list(status = "success", data = result$data))
    } else {
      res$status <- 404
      return(list(status = "error", message = result$message))
    }
    
  }, error = function(e) {
    res$status <- 500
    return(list(status = "error", message = "Internal Server Error", details = e$message))
  })
}

#* Get all products of a specific type purchased by user
#* @param id_product
#* @tag Person
#* @post /products_purchased/specific_one
#* @response 200 Returns the details of the specified user products
#* @response 400 Bad Request if the Authorization header is missing or invalid
#* @response 404 Not Found if the user does not exist or doesn't have any products
#* @response 500 Internal Server Error
function(req, res, id_product) {
  tryCatch({
    result <- future::value(future::future({
      get_user_one_type_of_products_from_request(req, id_product)
    }))
    
    if (result$status == "success") {
      res$status <- 200
      return(list(status = "success", data = result$data))
    } else {
      res$status <- 404
      return(list(status = "error", message = result$message))
    }
    
  }, error = function(e) {
    res$status <- 500
    return(list(status = "error", message = "Internal Server Error", details = e$message))
  })
}

#* Get all users
#* @tag Person
#* @get /get_all
#* @response 200 Returns a list of all users
#* @response 500 Internal Server Error
function() {
  tryCatch({
    users <- get_all_users()
    return(list(status = "success", data = users))
  }, error = function(e) {
    return(list(status = "error", message = "Failed to retrieve users", details = e$message))
  })
}

#* Get a user by ID
#* @param id The ID of the user to retrieve
#* @tag Person
#* @get /<id>
#* @response 200 Returns the details of the specified user
#* @response 404 Not Found if the user does not exist
#* @response 500 Internal Server Error
function(id) {
  if (missing(id) || !is.numeric(as.numeric(id))) {
    return(list(status = "error", message = "Invalid or missing user ID", status_code = 400))
  }
  
  id <- as.numeric(id)
  
  if (is.na(id)) {
    return(list(status = "error", message = "Invalid user ID", status_code = 400))
  }
  
  tryCatch({
    user <- get_user_by_id(id)
    
    if (is.null(user)) {
      return(list(status = "error", message = "User not found", status_code = 404))
    }
    
    return(list(status = "success", data = user, status_code = 200))
    
  }, error = function(e) {
    return(list(status = "error", message = "Failed to retrieve user", details = e$message, status_code = 500))
  })
}

#* Update a user by ID
#* @param id The ID of the user to update
#* @param name New name for the user (optional)
#* @param email New email for the user (optional)
#* @tag Person
#* @put /<id>
#* @response 200 OK if the user was successfully updated
#* @response 400 Bad Request if no fields are provided to update or if the ID is invalid
#* @response 404 Not Found if the user does not exist
#* @response 500 Internal Server Error
function(id, name, email) {
  if (missing(id) || !is.numeric(as.numeric(id))) {
    return(list(status = "error", message = "Invalid or missing user ID", status_code = 400))
  }
  
  id <- as.numeric(id)
  
  if (is.na(id)) {
    return(list(status = "error", message = "Invalid user ID", status_code = 400))
  }
  
  tryCatch({
    result <- update_user_by_id(id, name, email)
    
    if (result$status == "error") {
      return(list(status = "error", message = result$message, status_code = result$status_code))
    }
    
    return(list(status = "success", message = result$message, status_code = 200))
    
  }, error = function(e) {
    return(list(status = "error", message = "Failed to update user", details = e$message, status_code = 500))
  })
}

#* Delete a user by ID
#* @param id The ID of the user to delete
#* @tag Person
#* @delete /<id>
#* @response 200 OK if the user was successfully deleted
#* @response 404 Not Found if the user does not exist
#* @response 500 Internal Server Error
function(id) {
  if (missing(id) || !is.numeric(as.numeric(id))) {
    return(list(status = "error", message = "Invalid or missing user ID", status_code = 400))
  }
  
  id <- as.numeric(id)
  
  if (is.na(id)) {
    return(list(status = "error", message = "Invalid user ID", status_code = 400))
  }
  
  tryCatch({
    result <- delete_user_by_id(id)
    
    if (result$status == "error") {
      return(list(status = "error", message = result$message, status_code = result$status_code))
    }
    
    return(list(status = "success", message = "User deleted successfully", status_code = 200))
    
  }, error = function(e) {
    return(list(status = "error", message = "Failed to delete user", details = e$message, status_code = 500))
  })
}

#* Register a product in the name of the user
#* @param id_product The ID of the associated product
#* @param esp32_unique_id The unique ESP32 identifier for this instance
#* @tag Person
#* @post /products/register
#* @response 201 Created if the instance is successfully created 
#* @response 400 Bad Request if required parameters are missing 
#* @response 500 Internal Server Error 
function(req, res, id_product, esp32_unique_id) {
  tryCatch({
    result <- future::value(future::future({
      register_ESP32_from_request(req, id_product, esp32_unique_id)
    }))
    
    if (result$status == "success") {
      res$status <- 201
      return(list(status = "success", data = result$data))
    } else {
      res$status <- 400
      return(list(status = "error", message = result$message))
    }
    
  }, error = function(e) {
    res$status <- 500
    return(list(status = "error", message = "Internal Server Error", details = e$message))
  })
}
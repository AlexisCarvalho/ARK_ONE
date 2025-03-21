# +-----------------------+
# |                       |
# |       PRODUCTS        |
# |                       |
# +-----------------------+

source("../services/product_service.R", chdir = TRUE)

#* Create a new product
#* @param product_name The name of the product
#* @param product_description The description of the product
#* @param id_category The ID of the category (optional)
#* @param location_dependent Whether the product is location dependent (boolean)
#* @param product_price The price of the product
#* @tag Products
#* @post /create
#* @response 201 Created if the product is successfully created
#* @response 400 Bad Request if required parameters are missing
#* @response 500 Internal Server Error if there is an issue creating the product
function(res, product_name, product_description, id_category, location_dependent, product_price) {
  if (missing(product_name) || missing(product_description) || missing(location_dependent) || missing(product_price)) {
    res$status <- 400
    return(list(status = "error", message = "Missing required parameters"))
  }
  tryCatch(
    {
      result <- future::value(future::future({
        create_product(product_name, product_description, id_category, location_dependent, product_price)
      }))
      
      res$status <- 201
      return(result)
    },
    error = function(e) {
      res$status <- 500
      return(list(status = "error", message = "Internal Server Error", details = e$message))
    }
  )
}

#* Get all products
#* @tag Products
#* @get /get_all
#* @response 200 Returns a list of all products
#* @response 500 Internal Server Error if there is an issue retrieving products
function(res) {
  tryCatch(
  {
    products <- future::value(future::future({
      get_all_products()
    }))
      
    if(nrow(products) == 0)
    {
      res$status <- 204
      return(list(status = "success", data = products))
    }
      
    res$status <- 200
    return(list(status = "success", data = products))
  }, error = function(e) 
  {
    return(list(status = "error", message = "Failed to retrieve products", details = e$message))
  })
}

#* Get all products purchased
#* @tag Products
#* @get /get_all_purchased
#* @response 200 Returns a list of all products
#* @response 500 Internal Server Error if there is an issue retrieving products
function() {
  tryCatch({
    products_purchased <- get_all_products_purchased()
    return(list(status = "success", data = products_purchased))
  }, error = function(e) {
    return(list(status = "error", message = "Failed to retrieve products", details = e$message))
  })
}

#* Get a product by ID
#* @param id The ID of the product to retrieve
#* @tag Products
#* @get /<id>
#* @response 200 Returns the details of the specified product
#* @response 404 Not Found if the product does not exist
#* @response 500 Internal Server Error if there is an issue retrieving the product
function(id) {
  if (missing(id) || !is.numeric(as.numeric(id))) {
    return(list(status = "error", message = "Invalid or missing product ID"))
  }
  
  id <- as.numeric(id)
  
  tryCatch({
    product <- get_product_by_id(id)
    
    if (is.null(product) || nrow(product) == 0) {
      return(list(status = "error", message = "Product not found"))
    }
    
    return(list(status = "success", data = product))
    
  }, error = function(e) {
    return(list(status = "error", message = "Failed to retrieve product", details = e$message))
  })
}

#* Update a product by ID
#* @param id The ID of the product to update
#* @param product_name New name for the product (optional)
#* @param product_description New description for the product (optional)
#* @param id_category New category ID (optional)
#* @param location_dependent New location dependency status (optional)
#* @param product_price New price for the product (optional)
#* @tag Products
#* @put /<id>
#* @response 200 OK if the product was successfully updated
#* @response 400 Bad Request if no fields are provided to update or if the ID is invalid
#* @response 404 Not Found if the product does not exist
#* @response 500 Internal Server Error if there is an issue updating the product
function(id, product_name, product_description, id_category, location_dependent, product_price) {
  if (missing(id) || !is.numeric(as.numeric(id))) {
    return(list(status = "error", message = "Invalid or missing product ID"))
  }
  
  id <- as.numeric(id)
  
  tryCatch({
    result <- update_product_by_id(id, product_name, product_description, id_category, location_dependent, product_price)
    
    if (result$status == "error") {
      return(list(status = "error", message = result$message))
    }
    
    return(list(status = "success", message = "Product updated successfully"));
    
  }, error = function(e) {
    return(list(status = "error", message = "Failed to update product", details = e$message));
  })
}

#* Delete a esp32 by ID
#* @param esp32_unique_id The unique id of the esp32 to be deleted
#* @tag Products
#* @delete /delete_ESP32
#* @response 200 OK if the esp32 was successfully deleted
#* @response 404 Not Found if the esp32 does not exist
#* @response 500 Internal Server Error if there is an issue deleting the esp32
function(res, esp32_unique_id) {
  if (missing(esp32_unique_id)) {
    res$status <- 400
    return(list(status = "error", message = "Invalid or missing esp32 ID"));
  }
  
  tryCatch({
    result <- future::value(future::future({
      delete_esp32(esp32_unique_id)
    }))
    
    if (result$status == "error") {
      res$status <- 404
      return(list(status = "error", message = result$message));
    }
    
    res$status <- 200
    return(list(status = "success", message = "ESP32 deleted successfully"));
    
  }, error= function(e){
    res$status <- 500
    return(list(status="error",message="Failed to delete ESP32" ,details=e$message));
  });
}

#* Delete a product by ID
#* @param id_product The id of the product to be deleted
#* @tag Products
#* @delete /delete_product
#* @response 200 OK if the product was successfully deleted
#* @response 404 Not Found if the product does not exist
#* @response 500 Internal Server Error if there is an issue deleting the product
function(res, id_product) {
  if (missing(id_product)) {
    res$status <- 400
    return(list(status = "error", message = "Invalid or missing esp32 ID"));
  }
  
  id_product <- as.numeric(id_product)
  
  tryCatch({
    result <- future::value(future::future({
      delete_product_by_id(id_product)
    }))
    
    if (result$status == "error") {
      res$status <- 404
      return(list(status = "error", message = result$message));
    }
    
    res$status <- 200
    return(list(status = "success", message = "Product deleted successfully"));
    
  }, error= function(e){
    res$status <- 500
    return(list(status="error",message="Failed to delete Product" ,details=e$message));
  });
}

#* Register a product in the name of the user
#* @param id_product The ID of the associated product
#* @param esp32_unique_id The unique ESP32 identifier for this instance
#* @tag Products
#* @post /owned
#* @response 201 Created if the instance is successfully created
#* @response 400 Bad Request if required parameters are missing
#* @response 500 Internal Server Error
function(req, res, id_product, esp32_unique_id) {
  tryCatch(
    {
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
    },
    error = function(e) {
      res$status <- 500
      return(list(status = "error", message = "Internal Server Error", details = e$message))
    }
  )
}

#* Get all products purchased by user
#* @tag Products
#* @get /owned
#* @response 200 Returns the details of the specified user products
#* @response 400 Bad Request if the Authorization header is missing or invalid
#* @response 404 Not Found if the user does not exist or doesn't have any products
#* @response 500 Internal Server Error
function(req, res) {
  tryCatch(
    {
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
    },
    error = function(e) {
      res$status <- 500
      return(list(status = "error", message = "Internal Server Error", details = e$message))
    }
  )
}

#* Get all products of a specific type purchased by user
#* @param id_product
#* @tag Products
#* @get /owned/<id>
#* @response 200 Returns the details of the specified user products
#* @response 400 Bad Request if the Authorization header is missing or invalid
#* @response 404 Not Found if the user does not exist or doesn't have any products
#* @response 500 Internal Server Error
function(req, res, id_product) {
  tryCatch(
    {
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
    },
    error = function(e) {
      res$status <- 500
      return(list(status = "error", message = "Internal Server Error", details = e$message))
    }
  )
}
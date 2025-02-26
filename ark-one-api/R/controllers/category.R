# +-----------------------+
# |                       |
# |       CATEGORY        |
# |                       |
# +-----------------------+

source("../services/category_service.R", chdir = TRUE)

#* Create a new category
#* @param category_name The name of the category
#* @param category_description The description of the category
#* @param id_father_category The ID of the parent category (optional)
#* @tag Category
#* @post /create
function(res, category_name, category_description, id_father_category = 0) {
  tryCatch({
    if (missing(category_name) || missing(category_description)) {
     res$status <- 400
     return(list(status = "error", message = "Missing required parameters: category_name or category_description"))
    }
  
    if (id_father_category == 0 || is.null(id_father_category)) {
      id_father_category <- NULL
    } else {
      id_father_category <- as.numeric(id_father_category)
    }
  
    result <- future::value(future::future({
    create_category(category_name, category_description, id_father_category)
    }))
  
    res$status <- result$status_code
    return(list(status = result$status, message = result$message))
  }, error = function(e) {
   return(list(status = "error", message = "Failed to create categorie", details = e$message))
  })
}

#* Get all categories
#* @tag Category
#* @get /get_all
#* @response 200 Returns a list of all categories
#* @response 500 Internal Server Error if there is an issue retrieving categories
function() {
  tryCatch({
    categories <- future::value(future::future({
      get_all_categories()
    }))
    return(list(status = "success", data = categories))
  }, error = function(e) {
    return(list(status = "error", message = "Failed to retrieve categories", details = e$message))
  })
}

#* Get a category by ID
#* @param id The ID of the category to retrieve
#* @tag Category
#* @get /<id>
#* @response 200 Returns the details of the specified category
#* @response 404 Not Found if the category does not exist
#* @response 500 Internal Server Error if there is an issue retrieving the category
function(id) {
  if (missing(id) || !is.numeric(as.numeric(id))) {
    return(list(status = "error", message = "Invalid or missing category ID"))
  }
  
  id <- as.numeric(id)
  
  tryCatch({
    category <- get_category_by_id(id)
    
    if (is.null(category) || nrow(category) == 0) {
      return(list(status = "error", message = "Category not found"))
    }
    
    return(list(status = "success", data = category))
    
  }, error = function(e) {
    return(list(status = "error", message = "Failed to retrieve category", details = e$message))
  })
}

#* Update a category by ID
#* @param id The ID of the category to update
#* @param category_name New name for the category (optional)
#* @param category_description New description for the category (optional)
#* @param id_father_category New parent category ID (optional)
#* @tag Category
#* @put /<id>
#* @response 200 OK if the category was successfully updated
#* @response 400 Bad Request if no fields are provided to update or if the ID is invalid
#* @response 404 Not Found if the category does not exist
#* @response 500 Internal Server Error if there is an issue updating the category
function(id, category_name, category_description, id_father_category) {
  if (missing(id) || !is.numeric(as.numeric(id))) {
    return(list(status = "error", message = "Invalid or missing category ID"))
  }
  
  id <- as.numeric(id)
  
  tryCatch({
    result <- update_category_by_id(id, category_name, category_description, id_father_category)
    
    if (result$status == "error") {
      return(list(status = "error", message = result$message))
    }
    
    return(list(status = "success", message = "Category updated successfully"))
    
  }, error = function(e) {
    return(list(status = "error", message = "Failed to update category", details = e$message))
  })
}

#* Delete a category by ID
#* @param id The ID of the category to delete
#* @tag Category
#* @delete /<id>
#* @response 200 OK if the category was successfully deleted
#* @response 404 Not Found if the category does not exist
#* @response 500 Internal Server Error if there is an issue deleting the category
function(id) {
  if (missing(id) || !is.numeric(as.numeric(id))) {
    return(list(status = "error", message = "Invalid or missing category ID"))
  }
  
  id <- as.numeric(id)
  
  tryCatch({
    result <- delete_category_by_id(id)
    
    if (result$status == "error") {
      return(list(status = "error", message = result$message))
    }
    
    return(list(status = "success", message = "Category deleted successfully"))
    
  }, error = function(e) {
    return(list(status = "error", message = "Failed to delete category", details = e$message))
  })
}
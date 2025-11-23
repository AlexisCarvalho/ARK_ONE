# +---------------------+
# |                     |
# |     CATEGORIES      |
# |                     |
# +---------------------+

source("../services/category_service.R", chdir = TRUE)
source("../utils/response_handler.R", chdir = TRUE)

# Helper: normalize optional parameters (treat NULL, length 0, empty string or NA as NULL)
normalize_optional_param <- function(x) {
  if (is.null(x)) return(NULL)
  if (length(x) == 0) return(NULL)
  if (is.character(x) && identical(x, "")) return(NULL)
  if (length(x) == 1 && is.na(x)) return(NULL)
  return(x)
}

#* Create a new category
#* @param category_name The name of the category
#* @param category_description The description of the category
#* @param id_father_category The ID of the parent category (optional)
#* @tag Categories
#* @post /create
#* @response 201 Created if the category is successfully created
#* @response 400 Bad Request if parameters are invalid
#* @response 401 Unauthorized if user is not an admin
#* @response 500 Internal Server Error
function(res, req, category_name, category_description, id_father_category = NA) {
  id_father_category <- normalize_optional_param(id_father_category)
  send_http_response(res, post_category_register(req, category_name, category_description, id_father_category))
}

#* Get all categories
#* @tag Categories
#* @get /get_all
#* @response 200 Returns a list of all categories
#* @response 404 Not Found if there are no categories
#* @response 500 Internal Server Error
function(res) {
  send_http_response(res, get_categories_get_all())
}

#* Get a category by ID
#* @param id_category The ID of the category to retrieve
#* @tag Categories
#* @get /<id_category>
#* @response 200 Returns the details of the specified category
#* @response 400 Bad Request if the ID is invalid
#* @response 404 Not Found if the category does not exist
#* @response 500 Internal Server Error
function(res, id_category) {
  send_http_response(res, get_category_with_id(id_category))
}

#* Update a category by ID
#* @param id_category The ID of the category to update
#* @param category_name New name for the category (optional)
#* @param category_description New description for the category (optional)
#* @param id_father_category New parent category ID (optional)
#* @tag Categories
#* @put /<id_category>
#* @response 200 OK if the category was successfully updated
#* @response 400 Bad Request if the ID or fields are invalid
#* @response 401 Unauthorized if the user is not an admin
#* @response 500 Internal Server Error
function(res, req, id_category, category_name, category_description, id_father_category = NA) {
  id_father_category <- normalize_optional_param(id_father_category)
  send_http_response(res, put_categories_with_id(req, id_category, category_name, category_description, id_father_category))
}

#* Delete a category by ID
#* @param id_category The ID of the category to delete
#* @tag Categories
#* @delete /<id_category>
#* @response 200 OK if the category was successfully deleted
#* @response 400 Bad Request if the ID is invalid
#* @response 401 Unauthorized if the user is not an admin
#* @response 500 Internal Server Error
function(res, req, id_category) {
  send_http_response(res, delete_category_with_id(req, id_category))
}
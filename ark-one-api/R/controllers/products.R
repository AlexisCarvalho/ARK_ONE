# +-----------------------+
# |                       |
# |       PRODUCTS        |
# |                       |
# +-----------------------+

source("../services/product_service.R", chdir = TRUE)
source("../utils/response_handler.R", chdir = TRUE)

#* Get all products
#* @tag Products
#* @get /get_all
#* @response 200 Returns a list of all products
#* @response 500 Internal Server Error if there is an issue retrieving products
function(res) {
  send_http_response(res, get_products_get_all())
}

#* Get all products purchased by user
#* @tag Products
#* @get /owned
#* @response 200 Returns the details of the specified user products
#* @response 400 Bad Request if the Authorization header is missing or invalid
#* @response 404 Not Found if the user does not exist or doesn't have any products
#* @response 500 Internal Server Error
function(res, req) {
  send_http_response(res, get_products_owned(req))
}

#* Get all products that are owned by someone and the information of who have each
#* @tag Products
#* @get owned/all_users
#* @response 200 Returns a list of all products
#* @response 500 Internal Server Error if there is an issue retrieving products
function(res, req) {
  send_http_response(res, get_products_owned_all_users(req))
}

#* Create a new product
#* @param product_name The name of the product
#* @param product_description The description of the product
#* @param id_category The ID of the category (optional)
#* @param location_dependent:boolean Whether the product is location dependent (boolean)
#* @param product_price:number The price of the product
#* @tag Products
#* @post /register
#* @response 201 Created if the product is successfully created
#* @response 400 Bad Request if required parameters are missing
#* @response 500 Internal Server Error if there is an issue creating the product
function(res, req, product_name, product_description, location_dependent, product_price, id_category = NA) {
  id_category <- if (is.na(id_category)) NULL else id_category
  send_http_response(res, post_products_register(req, product_name, product_description, location_dependent, product_price, id_category))
}

#* Register a product in the name of the user
#* @param id_product The ID of the associated product
#* @param esp32_unique_id The unique ESP32 identifier for this instance
#* @tag Products
#* @post /owned
#* @response 201 Created if the instance is successfully created
#* @response 400 Bad Request if required parameters are missing
#* @response 500 Internal Server Error
function(res, req, id_product, esp32_unique_id) {
  send_http_response(res, post_products_owned(req, id_product, esp32_unique_id))
}

#* Search a Product using his name
#* @param name The name of the product you are searching
#* @tag Products
#* @get /search
#* @response 200 Products with similar names found
#* @response 404 Any Product found with a similar name
#* @response 500 Internal Server Error
function(res, name) {
  send_http_response(res, get_products_search(name))
}

#* Get a product by ID
#* @param id_product The ID of the product to retrieve
#* @tag Products
#* @get /<id_product>
#* @response 200 Returns the details of the specified product
#* @response 404 Not Found if the product does not exist
#* @response 500 Internal Server Error if there is an issue retrieving the product
function(res, id_product) {
  send_http_response(res, get_products_with_id(id_product))
}

#* Get all products of a specific type purchased by user
#* @param id_product
#* @tag Products
#* @get /owned/<id_product>
#* @response 200 Returns the details of the specified user products
#* @response 400 Bad Request if the Authorization header is missing or invalid
#* @response 404 Not Found if the user does not exist or doesn't have any products
#* @response 500 Internal Server Error
function(res, req, id_product) {
  send_http_response(res, get_products_owned_with_id(req, id_product))
}

#* Update a product by ID
#* @param id_product The ID of the product to update
#* @param product_name New name for the product (optional)
#* @param product_description New description for the product (optional)
#* @param id_category New category ID (optional)
#* @param location_dependent New location dependency status (optional)
#* @param product_price New price for the product (optional)
#* @tag Products
#* @put /<id_product>
#* @response 200 OK if the product was successfully updated
#* @response 400 Bad Request if no fields are provided to update or if the ID is invalid
#* @response 404 Not Found if the product does not exist
#* @response 500 Internal Server Error if there is an issue updating the product
function(res, req, id_product, product_name, product_description, location_dependent, product_price, id_category = NA) {
  id_category <- if (is.na(id_category)) NULL else id_category
  send_http_response(res, put_products_with_id(req, id_product, product_name, product_description, location_dependent, product_price, id_category))
}

#* Delete a product by ID
#* @param id_product The id of the product to be deleted
#* @tag Products
#* @delete /<id_product>
#* @response 200 OK if the product was successfully deleted
#* @response 404 Not Found if the product does not exist
#* @response 500 Internal Server Error if there is an issue deleting the product
function(res, req, id_product) {
  send_http_response(res, delete_products_with_id(req, id_product))
}

#* Delete a esp32 by ID
#* @param esp32_unique_id The unique id of the esp32 to be deleted
#* @tag Products
#* @delete /owned/<esp32_unique_id>
#* @response 200 OK if the esp32 was successfully deleted
#* @response 404 Not Found if the esp32 does not exist
#* @response 500 Internal Server Error if there is an issue deleting the esp32
function(res, req, esp32_unique_id) {
  send_http_response(res, delete_products_owned(req, esp32_unique_id))
}
# +-----------------------+
# |                       |
# |       LOCATION        |
# |                       |
# +-----------------------+

source("../services/location_service.R", chdir = TRUE)

#* Get location data by ESP32 unique ID (used in solar tracker)
#* @tag Locations
#* @param esp32_unique_id The ESP32 unique identifier
#* @get /solar_tracker
#* @response 200 Returns location for ESP32 ID
#* @response 404 If no location found
#* @response 500 On internal error
function(res, esp32_unique_id) {
  send_http_response(res, get_locations_solar_tracker(esp32_unique_id))
}

#* Create or update location data for a product instance (smart set logic)
#* @param id_product_instance The ID of the product instance
#* @param latitude Latitude of the location
#* @param longitude Longitude of the location
#* @tag Locations
#* @post /set
#* @response 200 Updated if location data is processed successfully
#* @response 201 Created if location data is processed successfully
#* @response 400 Bad Request for invalid inputs
#* @response 401 Unauthorized if user doesn't have permission
#* @response 500 Internal Server Error if there's an issue
function(res, req, id_product_instance, latitude, longitude) {
  send_http_response(res, post_locations_set(req, id_product_instance, latitude, longitude))
}

#* Create location data for a product instance
#* @param id_product_instance The ID of the product instance
#* @param latitude Latitude of the location
#* @param longitude Longitude of the location
#* @tag Locations
#* @post /register
#* @response 201 Created if location data is processed successfully
#* @response 400 Bad Request for invalid inputs
#* @response 401 Unauthorized if user doesn't have permission
#* @response 500 Internal Server Error if there's an issue
function(res, req, id_product_instance, latitude, longitude) {
  send_http_response(res, post_locations_register(req, id_product_instance, latitude, longitude))
}

#* Get all location data (admin only)
#* @tag Locations
#* @get /get_all
#* @response 200 Returns all location data
#* @response 401 Unauthorized if user is not admin
#* @response 500 Internal Server Error
function(res, req) {
  send_http_response(res, get_locations_get_all(req))
}

#* Get location data by product instance ID
#* @param id_product_instance The ID of the product instance
#* @tag Locations
#* @get /<id_product_instance>
#* @response 200 Returns the location
#* @response 400 Invalid ID
#* @response 404 Not Found if no data exists
#* @response 500 Internal Server Error
function(res, id_product_instance) {
  send_http_response(res, get_locations_with_id(id_product_instance))
}

#* Update location by product instance ID
#* @param id_product_instance The ID of the product instance
#* @param latitude Latitude to update
#* @param longitude Longitude to update
#* @tag Locations
#* @put /<id_product_instance>
#* @response 200 Location updated successfully
#* @response 400 Bad Request
#* @response 401 Unauthorized if not permitted
#* @response 500 Internal Server Error
function(res, req, id_product_instance, latitude, longitude) {
  send_http_response(res, put_locations_with_id(req, id_product_instance, latitude, longitude))
}

#* Delete a location by product instance ID
#* @param id_product_instance The ID of the product instance
#* @tag Locations
#* @delete /<id_product_instance>
#* @response 200 OK if deleted
#* @response 400 Invalid ID
#* @response 404 Not Found
#* @response 500 Internal Server Error
function(res, req, id_product_instance) {
  send_http_response(res, delete_locations_with_id(req, id_product_instance))
}

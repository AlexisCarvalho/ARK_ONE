# +-----------------------+
# |                       |
# |         USER          |
# |                       |
# +-----------------------+

source("../services/user_service.R", chdir = TRUE)
source("../services/product_service.R", chdir = TRUE)
source("../utils/utils.R", chdir = TRUE)

#* Get all users
#* @tag User
#* @get /get_all
#* @response 200 Returns a list of all users
#* @response 500 Internal Server Error
function(req, res) {
  send_http_response(res, user_get_all(req))
}

#* Get the type of the user
#* @tag User
#* @get /get_type
#* @response 200 Returns the type of the specified user
#* @response 404 Not Found if the user does not exist
#* @response 500 Internal Server Error
function(req, res) {
  send_http_response(res, user_get_type(req))
}

#* Get a user by ID
#* @param id The ID of the user to retrieve
#* @tag User
#* @get /<id_user>
#* @response 200 Returns the details of the specified user
#* @response 404 Not Found if the user does not exist
#* @response 500 Internal Server Error
function(req, res, id_user) {
  send_http_response(res, user_get_with_id(req, id_user))
}
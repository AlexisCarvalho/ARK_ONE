# +-----------------------+
# |                       |
# |         USERS         |
# |                       |
# +-----------------------+

source("../services/user_service.R", chdir = TRUE)
source("../utils/response_handler.R", chdir = TRUE)

#* Get all users
#* @tag Users
#* @get /all
#* @response 200 Returns a list of all users
#* @response 500 Internal Server Error
function(res, req) {
  send_http_response(res, get_users_all(req))
}

#* Affiliate an analyst to an owner
#* @param id_analyst The ID of the analyst to affiliate
#* @tag Users
#* @post /affiliate
#* @response 201 Created if affiliation created
#* @response 400 Bad Request if parameters are invalid
#* @response 401 Unauthorized if caller lacks permissions
#* @response 500 Internal Server Error
function(res, req, id_analyst) {
  send_http_response(res, post_affiliate_analyst(req, id_analyst))
}

#* Get the role of the user
#* @tag Users
#* @get /role
#* @response 200 Returns the role of the specified user
#* @response 404 Not Found if the user does not exist
#* @response 500 Internal Server Error
function(res, req) {
  send_http_response(res, get_users_role(req))
}

#* Get a user by ID
#* @param id The ID of the user to retrieve
#* @tag Users
#* @get /<id_user>
#* @response 200 Returns the details of the specified user
#* @response 404 Not Found if the user does not exist
#* @response 500 Internal Server Error
function(res, req, id_user) {
  send_http_response(res, get_users_with_id(req, id_user))
}
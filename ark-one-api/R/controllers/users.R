# +-----------------------+
# |                       |
# |         USERS         |
# |                       |
# +-----------------------+

source("../services/user_service.R", chdir = TRUE)
source("../services/affiliation_service.R", chdir = TRUE)
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
#* @param token_analyst The ID of the analyst to affiliate
#* @tag Users
#* @post /affiliate
#* @response 201 Created if affiliation created
#* @response 400 Bad Request if parameters are invalid
#* @response 401 Unauthorized if caller lacks permissions
#* @response 500 Internal Server Error
function(res, req, token_analyst) {
  # extract analyst id from provided token
  analyst_id <- tryCatch(
    get_id_user_from_token(token_analyst),
    error = function(e) NULL
  )

  if (is.null(analyst_id) || !nzchar(analyst_id)) {
    send_http_response(res, list(status = 'bad_request', message = 'Invalid analyst token', data = list(affiliated = FALSE)))
    return()
  }

  send_http_response(res, post_affiliate_analyst(req, analyst_id))
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

#* Get the role of the user
#* @tag Users
#* @get /owner_id
#* @response 200 Returns the role of the specified user
#* @response 404 Not Found if the user does not exist
#* @response 500 Internal Server Error
function(res, req) {
  send_http_response(res, get_owner_for_analyst(req))
}

#* Get the role of the user
#* @tag Users
#* @get /username
#* @response 200 Returns the role of the specified user
#* @response 404 Not Found if the user does not exist
#* @response 500 Internal Server Error
function(res, req) {
  send_http_response(res, get_username(req))
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
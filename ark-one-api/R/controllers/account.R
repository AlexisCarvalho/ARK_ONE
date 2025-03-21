# +-----------------------+
# |                       |
# |        ACCOUNT        |
# |                       |
# +-----------------------+

source("../services/user_service.R", chdir = TRUE)
source("../utils/utils.R", chdir = TRUE)

#* Login and get the JWT Token
#* @tag Account
#* @post /login
#* @description This endpoint is designated for user login where the user receives a token that authorizes access to the system for a limited time.
#* @response 200 Valid Credentials
#* @response 400 Invalid Input Type
#* @response 404 Invalid Credentials
#* @response 500 Unexpected Error: depends_on_the_error
#* @param email The email of the registered user
#* @param password The password associated with the registered email
function(res, email, password) {
  send_http_response(res, account_login(email, password))
}

#* Register a new user
#* @tag Account
#* @post /register
#* @description This endpoint is used to create a new user account. The user must provide a name, email, password, and optionally a user type
#* @response 201 User Registered Successfully
#* @response 400 Invalid Input Type
#* @response 409 Email must be unique. This email is already in use
#* @response 500 Unexpected Error: depends_on_the_error
#* @param name The name of the user
#* @param email The email of the user
#* @param password The password of the user
#* @param user_type The type of user access (default: regular)
function(res, name, email, password, user_type = "regular") {
  send_http_response(res, account_register(name, email, password, user_type))
}
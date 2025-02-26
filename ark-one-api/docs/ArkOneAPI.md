# Possible Returns
## Success Indicators:

- **`success:`** Indicates that the operation was completed successfully. REF 200, 204 ✅
- **`created:`** Used when a new resource (e.g., user) has been successfully created. REF 201 🆕
- **`updated:`** Indicates that an existing resource has been successfully updated. REF 200, 204 🔄

## Client Error Indicators:

- **`bad_request:`** The request was invalid or malformed. REF 400 🚫
- **`unauthorized:`** Authentication is required and has failed or has not been provided. REF 401 🔒
- **`forbidden:`** The server understands the request but refuses to authorize it. REF 403 🚷
- **`not_found:`** The requested resource could not be found. REF 404 🔍

## Server Error Indicators:

- **`internal_server_error:`** An unexpected condition was encountered on the server. REF 500 💥
- **`service_unavailable:`** The server is currently unable to handle the request due to temporary overloading or maintenance. REF 503 🛠️


# Endpoints

## /Account

### POST /Account/login
**`Values:`**

`STRING` *email, password*

**`Return:`**

    200 ✅
    status = "success", message = "Valid Credentials", token = JWT_Token

    400 🚫
    status = "bad_request", message = "Email and Password are Required", token = empty_string
    status = "bad_request", message = "Invalid Input Type", token = empty_string
    status = "bad_request", message = "Invalid Email Pattern", token = empty_string

    404 🔍
    status = "not_found", message = "Invalid Credentials", token = empty_string
    
    500 💥
    status = "error", message = "Unexpected Error: depends_on_the_error", token = empty_string
# +-----------------------+
# |                       |
# |     USER SERVICE      |
# |                       |
# +-----------------------+

source("../models/user_model.R", chdir = TRUE)
source("../utils/regex.R", chdir = TRUE)
source("../utils/utils.R", chdir = TRUE)
source("../utils/request_handler.R", chdir = TRUE)
source("../utils/response_handler.R", chdir = TRUE)

# +-----------------------+
# |    HELP FUNCTIONS     |
# +-----------------------+

# Generate a JWT with basic user params
generate_token <- function(user) {
  current_time <- Sys.time()

  # Define token expiration based on user role
  expiry_duration <- switch(user$user_role,
    "analyst" = as.difftime(24, units = "hours"),
    "moderator" = as.difftime(1, units = "hours"),
    "admin" = as.difftime(30, units = "mins"),
    NULL
  )

  # If a expire time for a certain user role is not set, 1 hour of expiration is set as default
  if (is.null(expiry_duration)) expiry_duration <- as.difftime(1, units = "hours")

  expiry_time <- current_time + expiry_duration

  payload <- jwt_claim(
    sub = user$id_user,
    username = user$name,
    role = user$user_role,
    exp = as.numeric(expiry_time), # Converts to timestamp UNIX (For JWT)
    jti = substr(uuid::UUIDgenerate(use.time = TRUE), 1, 8)
  )

  secret_key <- Sys.getenv("TOKEN_SECRET_KEY")
  if (nchar(secret_key) == 0) stop("TOKEN_SECRET_KEY Is not defined.")

  jwt_encode_hmac(payload, charToRaw(secret_key))
}

# Contains the logic to check if a password is correct using bcrypt
check_password <- function(input_password, stored_hashed_password) {
  checkpw(input_password, stored_hashed_password)
}

# +-----------------------+
# |        ACCOUNT        |
# +-----------------------+
# +-----------------------+
# |        LOGIN          |
# +-----------------------+

# The function verifies if the inserted password is correct and if it is call the token generation
validate_credentials <- function(email, password) {
  tryCatch(
    {
      user <- fetch_user_by_email(email)

      if (!is.data.frame(user) || nrow(user) == 0 || !check_password(password, user$password)) {
        return(list(
          status = "not_found",
          message = "Invalid Credentials",
          data = list(token = NULL)
        ))
      }

      token <- generate_token(user)
      return(list(
        status = "success",
        message = "Valid Credentials",
        data = list(token = token)
      ))
    },
    error = function(e) {
      list(
        status = "internal_server_error",
        message = paste("Unexpected Error:", e$message),
        data = list(token = NULL)
      )
    }
  )
}

# The function verifies if the email pattern and ensure user input is valid
# before calling validate_credentials
post_account_login <- function(email, password) {
  req_fields <- list(email, password)

  if (any(sapply(req_fields, is_invalid_utf8))) {
    return(list(
      status = "bad_request",
      message = "Invalid Input Type",
      data = list(token = NULL)
    ))
  }

  if (any(sapply(req_fields, is_blank_string))) {
    return(list(
      status = "bad_request",
      message =
        "Email and Password are Required",
      data = list(token = NULL)
    ))
  }

  if (nchar(email) > 100 || !validate_email_pattern(email)) {
    return(list(
      status = "bad_request",
      message = "Invalid Email Pattern or exceeds 100 characters",
      data = list(token = NULL)
    ))
  }

  if (nchar(password) > 72 || !is_ascii(password)) {
    return(list(
      status = "bad_request",
      message = "Invalid Password: Must be ASCII and below 72 characters",
      data = list(token = NULL)
    ))
  }

  validate_credentials(email, password)
}

# +-----------------------+
# |       REGISTER        |
# +-----------------------+

create_user <- function(name, email, password, user_role) {
  tryCatch(
    {
      hashed_password <- hashpw(password)

      insert_user(name, email, hashed_password, user_role)

      return(list(
        status = "created",
        message = "User Registered Successfully"
      ))
    },
    error = function(e) {
      constraint_name <- find_matching_constraint_pgsql(e$message)

      if (!is.null(constraint_name)) {
        return(constraint_violation_response(constraint_name))
      }

      list(
        status = "internal_server_error",
        message = paste("Unexpected Error:", error_message)
      )
    }
  )
}

# Function to register a user
post_account_register <- function(name, email, password, user_role) {
  req_fields <- list(name, email, user_role, password)

  if (any(sapply(req_fields, is_invalid_utf8))) {
    return(list(
      status = "bad_request",
      message = "Invalid Input Type"
    ))
  }

  if (any(sapply(req_fields, is_blank_string))) {
    return(list(
      status = "bad_request",
      message = "All Required Fields must be completed"
    ))
  }

  if (nchar(email) > 100) {
    return(list(
      status = "bad_request",
      message = "Email can't exceed 100 characters"
    ))
  }

  if (nchar(password) > 72 || !is_ascii(password)) {
    return(list(
      status = "bad_request",
      message = "Invalid Password: Must be ASCII and below 72 characters"
    ))
  }

  create_user(name, email, password, user_role)
}

# +-----------------------+
# |         USERS         |
# +-----------------------+
# +-----------------------+
# |          ALL          |
# +-----------------------+

# Function to get all users
get_users_all <- function(req) {
  user_role <- tryCatch(
    get_user_role_from_req(req),
    error = function(e) return(NULL)
  )

  if (is.null(user_role) || user_role != "admin") {
    return(list(
      status = "unauthorized",
      message = "To retrieve all user info, you must be an administrator",
      data = list(users = NULL)
    ))
  }

  users <- tryCatch(
    fetch_all_users(),
    error = function(e) e
  )

  if (inherits(users, "error")) {
    return(list(
      status = "internal_server_error",
      message = paste("Unexpected Error:", users$message),
      data = list(users = NULL)
    ))
  }

  if (!is.data.frame(users) || nrow(users) == 0) {
    return(list(
      status = "not_found",
      message = "There are no users in the database",
      data = list(users = NULL)
    ))
  }

  list(
    status = "success",
    message = "All users successfully retrieved",
    data = list(users = users)
  )
}

# +-----------------------+
# |         ROLE          |
# +-----------------------+

get_users_role <- function(req) {
  tryCatch(
    {
      user_role <- get_user_role_from_req(req)

      if (!is.data.frame(user_role) || nrow(user_role) == 0) {
        return(list(
          status = "not_found",
          message = "There are no users in the database that own this token",
          data = list(user_role = NULL)
        ))
      }

      list(
        status = "success",
        message = "User role successfully retrieved",
        data = user_role
      )
    },
    error = function(e) {
      list(
        status = "internal_server_error",
        message = paste("Unexpected Error:", e$message),
        data = list(user_role = NULL)
      )
    }
  )
}

# +-----------------------+
# |      GET WITH ID      |
# +-----------------------+

# Function to get a user by ID
get_users_with_id <- function(req, id_user) {
  if (is_invalid_utf8(id_user) || !UUIDvalidate(id_user)) {
    return(list(
      status = "bad_request",
      message = "Missing or Invalid user ID",
      data = list(user = NULL)
    ))
  }

  user_role <- tryCatch(
    get_user_role_from_req(req),
    error = function(e) {
      NULL
    }
  )

  if (is.null(user_role) || user_role != "admin") {
    return(list(
      status = "unauthorized",
      message = "Retrieving user information that does not belong to you requires administrative privileges. To access your own data, use a different endpoint",
      data = list(user = NULL)
    ))
  }

  user <- tryCatch(
    fetch_user_by_id(id_user),
    error = function(e) e
  )

  if (inherits(user, "error")) {
    return(list(
      status = "internal_server_error",
      message = paste("Unexpected Error:", user$message),
      data = list(user = NULL)
    ))
  }

  if (!is.data.frame(user) || nrow(user) == 0) {
    return(list(
      status = "not_found",
      message = "There are no user with this id in the database",
      data = list(user = NULL)
    ))
  }

  list(
    status = "success",
    message = "User successfully retrieved",
    data = list(user = user)
  )
}
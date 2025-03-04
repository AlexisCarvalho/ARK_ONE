source("../models/user_model.R", chdir = TRUE)
source("../utils/regex.R", chdir = TRUE)
source("../utils/utils.R", chdir = TRUE)

# +-----------------------+
# |                       |
# |     USER SERVICE      |
# |                       |
# +-----------------------+

# Generate a JWT with basic user params
generate_token <- function(user) {
  one_hour_in_seconds <- 3600
  time <- Sys.time()

  payload <- jwt_claim(
    id_user = user$id_user,
    username = user$name,
    exp = time + one_hour_in_seconds,
    jti = as.character(uuid::UUIDgenerate())
  )

  return(jwt_encode_hmac(payload, charToRaw(Sys.getenv("TOKEN_SECRET_KEY"))))
}

# Verify if the inserted password is correct and if it is call the token generation
validate_credentials <- function(email, password) {
  tryCatch(
    {
      user <- get_user_by_email(email)

      if (!is.data.frame(user) || nrow(user) == 0 || !check_password(password, user$password)) {
        return(list(status = "not_found", message = "Invalid Credentials", token = ""))
      }

      token <- generate_token(user)
      return(list(status = "success", message = "Valid Credentials", token = token))
    },
    error = function(e) {
      return(list(status = "internal_server_error", message = paste("Unexpected Error:", e$message), token = ""))
    }
  )
}

# Verify the email pattern and ensure user input is valid
# before calling validate_credentials
account_login <- function(email, password) {
  required_fields <- list(email, password)

  if (any(sapply(required_fields, is_missing_or_empty))) {
    return(list(status = "bad_request", message = "Email and Password are Required", token = ""))
  }

  if (any(sapply(required_fields, function(x) !is.character(x)))) {
    return(list(status = "bad_request", message = "Invalid Input Type", token = ""))
  }

  if (!validate_email(email)) {
    return(list(status = "bad_request", message = "Invalid Email Pattern", token = ""))
  }

  return(validate_credentials(email, password))
}

create_user <- function(name, email, password, user_type) {
  tryCatch({
      hashed_password <- hashpw(password)

      insert_user(name, email, hashed_password, user_type)

      return(list(status = "success", message = "User Registered Successfully"))
    }, 
    error = function(e) {
      constraint_name <- find_matching_constraint_pgsql(e$message)

      if (!is.null(constraint_name)) {
        return(constraint_violation_response(constraint_name))
      }

      return(list(status = "internal_server_error", message = paste("Unexpected Error:", error_message)))
    }
  )
}

# Function to create a user
account_register <- function(name, email, password, user_type) {
  required_fields <- list(name, email, password, user_type)

  if (any(sapply(required_fields, is_missing_or_empty))) {
    return(list(status = "bad_request", message = "Email and Password are Required"))
  }

  if (any(sapply(required_fields, function(x) !is.character(x)))) {
    return(list(status = "bad_request", message = "Invalid Input Type"))
  }

  if (!validate_email(email)) {
    return(list(status = "bad_request", message = "Invalid Email Pattern"))
  }

  return(create_user(name, email, password, user_type))
}




get_user_type <- function(id_user) {
  con <- getConn()
  on.exit(dbDisconnect(con))

  query <- paste("SELECT user_type FROM user_data WHERE id_user = $1", sep = "")

  result <- dbGetQuery(con, query, params = list(id_user))

  if (nrow(result) > 0) {
    return(result$user_type)
  } else {
    return(NULL)
  }
}

get_user_type_from_request <- function(req) {
  auth_header <- req$HTTP_AUTHORIZATION

  if (missing(auth_header) || !grepl("Bearer ", auth_header)) {
    return(list(status = "error", message = "Missing or invalid Authorization header"))
  }

  # Extract token
  token <- sub("Bearer ", "", auth_header)

  tryCatch(
    {
      jwt <- jwt_decode_hmac(token, charToRaw(Sys.getenv("TOKEN_SECRET_KEY")))

      id <- jwt$id_user
      user_type <- jwt$user_type

      if (is.null(id) || !is.numeric(as.numeric(id))) {
        return(list(status = "error", message = "Invalid user ID in token"))
      }

      if (is.null(user_type)) {
        return(list(status = "error", message = "User Not Found"))
      }

      return(list(status = "success", data = user_type))
    },
    error = function(e) {
      return(list(status = "error", message = "Failed to retrieve user type", details = e$message))
    }
  )
}

# Function to get all users
get_all_users <- function() {
  con <- getConn()
  on.exit(dbDisconnect(con))

  users <- dbReadTable(con, "user_data")
  return(users)
}

# Function to get a user by ID
get_user_by_id <- function(id) {
  con <- getConn()
  on.exit(dbDisconnect(con))

  query <- "SELECT * FROM user_data WHERE id_user = $1"
  user <- dbGetQuery(con, query, params = list(id))

  if (nrow(user) == 0) {
    return(list(status = "error", message = "User not found"))
  }

  return(user)
}

# Function to update a user by ID
update_user_by_id <- function(id, name = NULL, email = NULL) {
  con <- getConn()
  on.exit(dbDisconnect(con))

  # Check if user exists
  user_check <- dbGetQuery(con, "SELECT * FROM user_data WHERE id_user = $1", params = list(id))

  if (nrow(user_check) == 0) {
    return(list(status = "error", message = "User not found"))
  }

  updates <- c()

  if (!is.null(name)) updates <- c(updates, sprintf("name = '%s'", name))

  if (!is.null(email)) {
    # Check for unique email
    existing_user <- dbGetQuery(con, "SELECT * FROM user_data WHERE email = $1 AND id_user != $2", params = list(email, id))
    if (nrow(existing_user) > 0) {
      return(list(status = "error", message = "Email already exists"))
    }
    updates <- c(updates, sprintf("email = '%s'", email))
  }

  if (length(updates) > 0) {
    update_query <- paste(updates, collapse = ", ")
    dbExecute(con, sprintf("UPDATE user_data SET %s WHERE id_user = $1", update_query), params = list(id))
    return(list(status = "success", message = "User updated successfully"))
  }

  return(list(status = "error", message = "No fields to update"))
}

# Function to delete a user by ID
delete_user_by_id <- function(id) {
  con <- getConn()
  on.exit(dbDisconnect(con))

  existing_user <- dbGetQuery(con, "SELECT * FROM user_data WHERE id_user = $1", params = list(id))

  if (nrow(existing_user) == 0) {
    return(list(status = "error", message = "User not found"))
  }

  dbExecute(con, "DELETE FROM user_data WHERE id_user = $1", params = list(id))

  return(list(status = "success", message = "User deleted"))
}

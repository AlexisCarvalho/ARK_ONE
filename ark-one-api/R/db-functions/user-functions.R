source("../connection.R", chdir = TRUE)
source("../utils.R", chdir = TRUE)

# +-----------------------+
# |                       |
# |    USER FUNCTIONS     |
# |                       |
# +-----------------------+

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

#* Get the type of the user
#* @tag Person
#* @get /getType
#* @response 200 Returns the type of the specified user
#* @response 404 Not Found if the user does not exist
#* @response 500 Internal Server Error
function(req, res) {
  result <- tryCatch({
    response <- future::value(future::future({
      get_user_type_from_request(req)
    }))
    
    if (response$status == "success") {
      res$status <- 200
      return(list(status = "success", data = response$data))
    } else {
      res$status <- 404
      return(list(status = "error", message = response$message))
    }
    
  }, error = function(e) {
    res$status <- 500
    return(list(status = "error", message = "Internal Server Error", details = e$message))
  })
}

# Function to get logged in the system
login_user <- function(email, password) {
  future_login <- future::future({
    con <- getConn()
    on.exit(dbDisconnect(con))
    
    hashed_password <- digest(password)
    query <- "SELECT * FROM user_data WHERE email = $1 AND password = $2"
    user <- dbGetQuery(con, query, params = list(email, hashed_password))
    return(user)
  })
  
  user <- future::value(future_login) 
  
  if (nrow(user) == 1) {
    unique_id <- as.numeric(Sys.time())
    
    payload <- jwt_claim(
      id_user = user$id_user,
      username = user$name,
      user_type = user$user_type,
      exp = Sys.time() + 3600,
      jti = unique_id            
    )
    
    token <- jwt_encode_hmac(payload, token_secret_key)
    return(list(token = token))
  } else {
    return(list(error = "Invalid email or password"))
  }
}

# Function to create a user 
create_user <- function(name, email, password, user_type) {
  check_user_future <- future::future({
    con <- getConn()
    on.exit(dbDisconnect(con))
    existing_user <- dbGetQuery(con, "SELECT * FROM user_data WHERE email = $1", params = list(email))
    return(existing_user)
  })
  
  existing_user <- future::value(check_user_future) 
  
  if (nrow(existing_user) > 0) {
    return(list(status = "error", message = "Email Already Exists"))
  }
  
  password <- digest(password)
  
  insert_user_future <- future::future({
    con <- getConn()
    on.exit(dbDisconnect(con))
    
    if (user_type == "regular") {
      query <- "INSERT INTO user_data (name, email, password) VALUES ($1, $2, $3)"
      dbExecute(con, query, params = list(name, email, password))
    } else {
      query <- "INSERT INTO user_data (name, email, password, user_type) VALUES ($1, $2, $3, $4)"
      dbExecute(con, query, params = list(name, email, password, user_type))
    }
    
    return(list(status = "success", message = "User created"))
  })
  
  result <- future::value(insert_user_future) 
  return(result)
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
# +-----------------------+
# |                       |
# |        ACCOUNT        |
# |                       |
# +-----------------------+

source("../db-functions/user-functions.R", chdir = TRUE)

#* Login and get the comprovation token
#* @response 200 Logged successfully, token returned
#* @response 401 Username and/or password missing or invalid
#* @description This endpoint is designated for user login where the user receives a token that authorizes access to the system for a limited time.
#* @tag Account
#* @param email The email of the registered user
#* @param password The key determined by the user associated with the email
#* @post /login
function(res, email, password) {
  if (missing(email) || missing(password)) {
    res$status <- 401
    return(list(error = "Email and password are required"))
  }
  
  result <- future::value(future::future({
    login_user(email, password) 
  }))
  
  if (!is.null(result$error)) {
    res$status <- 401
    return(result)
  }
  
  res$status <- 200
  return(result)
}

#* Create a new user
#* @param name The name of the user
#* @param email The email of the user
#* @param password The password of the user
#* @param user_type The type of access of the user
#* @tag Account
#* @post /register
#* @response 201 Returned if the user is successfully created
#* @response 400 Bad Request if the email already exists
#* @response 500 Internal Server Error
function(res, name, email, password, user_type = "regular") {
  if (missing(name) || missing(email) || missing(password)) {
    res$status <- 400
    return(list(error = "Missing required parameters"))
  }
  
  tryCatch({
    result <- future::value(future::future({
      create_user(name, email, password, user_type)
    }))
    
    if (result$status == "error") {
      res$status <- 400
      return(list(status = "error", message = result$message))
    }
    
    res$status <- 201
    return(list(status = "success", message = "User created successfully"))
    
  }, error = function(e) {
    res$status <- 500
    return(list(error = "Internal Server Error"))
  })
}
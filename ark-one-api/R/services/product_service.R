source("../models/product_model.R", chdir = TRUE)

# +-----------------------+
# |                       |
# |    PRODUCT SERVICE    |
# |                       |
# +-----------------------+

# Function to create a new product
create_product <- function(product_name, product_description, id_category, location_dependent, product_price) {
  con <- getConn()
  on.exit(dbDisconnect(con))

  if(is.null(id_category)){
    id_category <- list(id_category)
  }

  query <- "INSERT INTO products (product_name, product_description, id_category, location_dependent, product_price) VALUES ($1, $2, $3, $4, $5)"
  dbExecute(con, query, params = list(product_name, product_description, id_category, location_dependent, product_price))

  return(list(status = "success", message = "Product created"))
}

# Function to get all products
get_all_products <- function() {
  con <- getConn()
  on.exit(dbDisconnect(con))

  products <- dbGetQuery(con, "SELECT * FROM products")
  return(products)
}

# Function to get a product by ID
get_product_by_id <- function(id) {
  con <- getConn()
  on.exit(dbDisconnect(con))

  query <- "SELECT * FROM products WHERE id_product = $1"
  product <- dbGetQuery(con, query, params = list(id))

  if (nrow(product) == 0) {
    return(list(status = "error", message = "Product not found"))
  }

  return(product)
}

# Function to update product by ID in PostgreSQL
update_product_by_id <- function(id_product, product_name, product_description, 
                                 id_category, location_dependent, 
                                 product_price) {

  con <- getConn()
  on.exit(dbDisconnect(con))  # Ensure the connection is closed after execution

  if (is.null(id_product) || !is.numeric(as.numeric(id_product))) {
    return(list(status = "error", message = "Invalid or missing product ID"))
  }

  product_exists <- dbGetQuery(con, "SELECT 1 FROM products WHERE id_product = $1", params = list(id_product))
  if (nrow(product_exists) == 0) {
    return(list(status = "error", message = "Product not found"))
  }

  fields_to_update <- list()
  params <- list()

  if (!is.null(product_name)) {
    fields_to_update <- c(fields_to_update, "product_name = $2")
    params <- c(params, product_name)
  }
  if (!is.null(product_description)) {
    fields_to_update <- c(fields_to_update, "product_description = $3")
    params <- c(params, product_description)
  }
  if (!is.null(id_category)) {
    fields_to_update <- c(fields_to_update, "id_category = $4")
    params <- c(params, id_category)
  }
  if (!is.null(location_dependent)) {
    fields_to_update <- c(fields_to_update, "location_dependent = $5")
    params <- c(params, location_dependent)
  }
  if (!is.null(product_price)) {
    fields_to_update <- c(fields_to_update, "product_price = $6")
    params <- c(params, product_price)
  }

  if (length(fields_to_update) == 0) {
    return(list(status = "error", message = "No fields provided to update"))
  }

  set_clause <- paste(fields_to_update, collapse = ", ")
  sql_query <- sprintf("UPDATE products SET %s WHERE id_product = $1", set_clause)

  tryCatch({
    result <- dbExecute(con, sql_query, params = c(id_product, params))

    if (result == 0) {
      return(list(status = "error", message = "No changes made"))
    }

    return(list(status = "success", message = "Product updated successfully"))

  }, error = function(e) {
    return(list(status = "error", message = "Failed to update product", details = e$message))
  })
}

# Function to get all products owned by a specific user
get_products_by_user_id <- function(user_id) {
  con <- getConn()
  on.exit(dbDisconnect(con))

  query <- "
      SELECT p.* 
      FROM products p
      JOIN product_instance pi ON p.id_product = pi.id_product
      WHERE pi.id_user = ?"

  results <- dbGetQuery(con, query, params = list(user_id))

  if (nrow(results) == 0) {
    return(list(status = "error", message = "No products found for this user"))
  }

  return(results)
}

# Function to search products by name
search_products_by_name <- function(name) {
  con <- getConn()  # Establish a connection to the database
  on.exit(dbDisconnect(con))  # Ensure the connection is closed after execution

  query <- "SELECT * FROM products WHERE product_name ILIKE ?"

  results <- dbGetQuery(con, query, params = list(paste0("%", name, "%")))

  if (nrow(results) == 0) {
    return(list(status = "error", message = "No products found with this name"))
  }

  return(results)  # Return the found products
}

# +-----------------------+
# |   PRODUCT INSTANCE    |
# +-----------------------+

delete_product_by_id <- function(id_product) {
  con <- getConn()

  on.exit(DBI::dbDisconnect(con))

  DBI::dbBegin(con)

  tryCatch({
    query_select <- "
      SELECT id_product
      FROM products
      WHERE id_product = $1"

    product_instance <- DBI::dbGetQuery(con, query_select, params = list(id_product))

    if (nrow(product_instance) == 0) {
      return(list(status = "error", message = "The given product doesn't exists."))
    }

    id_product <- product_instance$id_product
    id_user <- product_instance$id_user

    query_delete_product <- "
      DELETE FROM products
      WHERE id_product = $1"

    DBI::dbExecute(con, query_delete_product, params = list(id_product))

    DBI::dbCommit(con)

    return(list(status = "success", message = "The given product was deleted sucessfully."))
  }, error = function(e) {
    DBI::dbRollback(con)
    stop("The attempt of deleting the product fails: ", e$message)
  })
}

delete_esp32 <- function(esp32_unique_id) {
  con <- getConn()

  on.exit(DBI::dbDisconnect(con))

  DBI::dbBegin(con)

  tryCatch({
    query_select <- "
      SELECT id_product, id_user
      FROM product_instance
      WHERE esp32_unique_id = $1"

    product_instance <- DBI::dbGetQuery(con, query_select, params = list(esp32_unique_id))

    if (nrow(product_instance) == 0) {
      return(list(status = "error", message = "The given esp32 doesn't exists."))
    }

    id_product <- product_instance$id_product
    id_user <- product_instance$id_user

    query_delete_instance <- "
      DELETE FROM product_instance
      WHERE esp32_unique_id = $1"

    DBI::dbExecute(con, query_delete_instance, params = list(esp32_unique_id))

    query_check_instances <- "
      SELECT COUNT(*)
      FROM product_instance
      WHERE id_product = $1 AND id_user = $2"

    count_instances <- DBI::dbGetQuery(con, query_check_instances, params = list(id_product, id_user))

    if (count_instances$count == 0) {
      query_delete_user_product <- "
        DELETE FROM user_products
        WHERE id_user = $1 AND id_product = $2"

      DBI::dbExecute(con, query_delete_user_product, params = list(id_user, id_product))
    }

    DBI::dbCommit(con)

    return(list(status = "success", message = "The given esp32 was deleted sucessfully."))
  }, error = function(e) {
    DBI::dbRollback(con)
    stop("The attempt of deleting the product fails: ", e$message)
  })
}

# Function to create a new product instance
create_product_instance <- function(id_product, id_user, esp32_unique_id) {
  con <- getConn()  
  on.exit(dbDisconnect(con))  

  query <- "INSERT INTO product_instance (id_product, id_user, esp32_unique_id) VALUES ($1, $2, $3)"

  dbExecute(con, query, params = list(id_product, id_user, esp32_unique_id))

  return(list(status = "success", message = "Product instance created"))
}

# Function to get all product instances
get_all_products_purchased <- function() {
  con <- getConn()  
  on.exit(dbDisconnect(con))  

  instances <- dbGetQuery(con, "SELECT 
    user_data.name AS user_name, 
    products.product_name AS product_name,
    product_instance.esp32_unique_id
FROM 
    product_instance
INNER JOIN 
    user_data ON product_instance.id_user = user_data.id_user
INNER JOIN 
    products ON product_instance.id_product = products.id_product")

  return(instances)
}

# Function to get a product instance by ID
get_product_instance_by_id <- function(id) {
  con <- getConn()  
  on.exit(dbDisconnect(con))  

  query <- "SELECT * FROM product_instance WHERE id_product_instance = ?"

  instance <- dbGetQuery(con, query, params = list(id))

  if (nrow(instance) == 0) {
    return(list(status = "error", message = "Product instance not found"))
  }

  return(instance)
}

# Function to update a product instance by ID
update_product_instance_by_id <- function(id, id_product, id_user, esp32_unique_id) {
  con <- getConn()  
  on.exit(dbDisconnect(con))
  
  updates <- c()

  if (!is.null(id_product)) updates <- c(updates, sprintf("id_product = %s", id_product))
  if (!is.null(id_user)) updates <- c(updates, sprintf("id_user = %s", id_user))
  if (!is.null(esp32_unique_id)) updates <- c(updates, sprintf("esp32_unique_id = '%s'", esp32_unique_id))

  if (length(updates) > 0) {
    update_query <- paste(updates, collapse = ", ")  # Combine updates into a single string
    dbExecute(con, sprintf("UPDATE product_instance SET %s WHERE id_product_instance = ?", update_query), params = list(id))
    return(list(status = "success", message = "Product instance updated"))
  }

  return(list(status = "error", message = "No fields to update"))
}

# Function to delete a product instance by ID
delete_product_instance_by_id <- function(id) {
  con <- getConn()  
  on.exit(dbDisconnect(con))

  dbExecute(con, "DELETE FROM product_instance WHERE id_product_instance = ?", params = list(id))

  return(list(status = "success", message = "Product instance deleted"))
}

# Function to get all product instances for a specific user
get_product_instances_by_user_id <- function(user_id) {
  con <- getConn()  
  on.exit(dbDisconnect(con))  

  query <- "
      SELECT pi.* 
      FROM product_instance pi
      WHERE pi.id_user = ?"

  results <- dbGetQuery(con, query, params = list(user_id))

  if (nrow(results) == 0) {
    return(list(status = "error", message = "No product instances found for this user"))
  }

  return(results)
}

# Function to get all product instances for a specific product
get_product_instances_by_product_id <- function(product_id) {
  con <- getConn()
  on.exit(dbDisconnect(con))

  query <- "
      SELECT pi.* 
      FROM product_instance pi
      WHERE pi.id_product = ?"

  results <- dbGetQuery(con, query, params = list(product_id))

  if (nrow(results) == 0) {
    return(list(status = "error", message = "No product instances found for this product"))
  }

  return(results)
}

# Function to get all products purchased by the user using the token from request
get_user_products_from_request <- function(req) {

  auth_header <- req$HTTP_AUTHORIZATION

  if (missing(auth_header) || !grepl("Bearer ", auth_header)) {
    return(list(status = "error", message = "Missing or invalid Authorization header"))
  }

  # Extract token
  token <- sub("Bearer ", "", auth_header)

  tryCatch({

    jwt <- jwt_decode_hmac(token, charToRaw(Sys.getenv("TOKEN_SECRET_KEY")))

    id <- jwt$id_user

    if (is.null(id) || !is.numeric(as.numeric(id))) {
      return(list(status = "error", message = "Invalid user ID in token"))
    }

    id <- as.numeric(id)

    user_purchased_products <- get_products_purchased_by_user(id)

    if (nrow(user_purchased_products) == 0) 
    {
      return(list(status = "error", message = "Products aren't find for this user"))
    } 

    return(list(status = "success", data = user_purchased_products))

  }, error = function(e) {
    return(list(status = "error", message = "Failed to retrieve user products", details = e$message))
  })
}

# Function to get all products purchased by the user using the token from request
get_user_one_type_of_products_from_request <- function(req, id_product) {

  auth_header <- req$HTTP_AUTHORIZATION

  if (missing(auth_header) || !grepl("Bearer ", auth_header)) {
    return(list(status = "error", message = "Missing or invalid Authorization header"))
  }

  # Extract token
  token <- sub("Bearer ", "", auth_header)

  tryCatch({

    jwt <- jwt_decode_hmac(token, charToRaw(Sys.getenv("TOKEN_SECRET_KEY")))

    id <- jwt$id_user

    if (is.null(id) || !is.numeric(as.numeric(id))) {
      return(list(status = "error", message = "Invalid user ID in token"))
    }

    if (is.null(id_product) || !is.numeric(as.numeric(id_product))) {
      return(list(status = "error", message = "Invalid product ID"))
    }

    id <- as.numeric(id)
    id_product <- as.numeric(id_product)

    user_purchased_products <- get_one_type_of_products_purchased_by_user(id, id_product)

    if (nrow(user_purchased_products) == 0) 
    {
      return(list(status = "error", message = "Products of this type aren't find for this user"))
    }

    return(list(status = "success", data = user_purchased_products))

  }, error = function(e) {
    return(list(status = "error", message = "Failed to retrieve user products", details = e$message))
  })
}

# Function that allows the user to register a esp32 using the token from request
register_ESP32_from_request <- function(req, id_product, esp32_unique_id) {

  auth_header <- req$HTTP_AUTHORIZATION

  if (missing(auth_header) || !grepl("Bearer ", auth_header)) {
    return(list(status = "error", message = "Missing or invalid Authorization header"))
  }

  # Extract token
  token <- sub("Bearer ", "", auth_header)

  tryCatch({

    jwt <- jwt_decode_hmac(token, charToRaw(Sys.getenv("TOKEN_SECRET_KEY")))

    id <- jwt$id_user

    if (is.null(id) || !is.numeric(as.numeric(id))) {
      return(list(status = "error", message = "Invalid user ID in token"))
    }

    if (is.null(id_product) || !is.numeric(as.numeric(id_product))) {
      return(list(status = "error", message = "Invalid product ID"))
    }

    id <- as.numeric(id)
    id_product <- as.numeric(id_product)

    create_user_product(id, id_product)
    create_product_instance(id_product, id, esp32_unique_id)

    return(list(status = "success", message = "Sucessfully registered ESP32 ID"))

  }, error = function(e) {
    return(list(status = "error", message = "Failed to register ESP32 ID", details = e$message))
  })
}

# +----------------------------------------+
# |   PRODUCT INSTANCE - HELP FUNCTIONS    |
# +----------------------------------------+
# They are here just to retrieve data from
# the database, don't treat errors
# they may be treated on the funcionality
# functions

# Function to get all product instances for a specific user, including product name and esp32 unique ID
get_products_purchased_by_user <- function(user_id) {
  con <- getConn()
  on.exit(dbDisconnect(con))

  query <- "
      SELECT pi.id_product_instance, p.product_name, pi.esp32_unique_id, p.location_dependent
      FROM product_instance pi
      JOIN products p ON pi.id_product = p.id_product
      WHERE pi.id_user = $1"

  results <- dbGetQuery(con, query, params = list(user_id))

  return(results)
}

# Function to get all product instances for a specific user, including product name and esp32 unique ID
get_one_type_of_products_purchased_by_user <- function(user_id, product_id) {
  con <- getConn()
  on.exit(dbDisconnect(con))

  query <- "
      SELECT pi.id_product_instance, p.product_name, pi.esp32_unique_id, p.location_dependent
      FROM product_instance pi
      JOIN products p ON pi.id_product = p.id_product
      WHERE pi.id_user = $1 AND p.id_product = $2"

  results <- dbGetQuery(con, query, params = list(user_id, product_id))

  return(results)
}

# +-------------------------------+
# |   USER PRODUCT ASSOCIATION    |
# +-------------------------------+

# Function to associate a user with a product
create_user_product <- function(id_user, id_product) {
  con <- getConn()
  on.exit(dbDisconnect(con))

  query <- "INSERT INTO user_products (id_user, id_product) VALUES ($1, $2)"

  tryCatch({
    dbExecute(con, query, params = list(id_user, id_product))
    return(list(status = "success", message = "User-Product association created"))
  }, error = function(e) {
    if (grepl("duplicate key value violates unique constraint", e$message)) {
      return(list(status = "warning", message = "User-Product association already exists"))
    } else {
      return(list(status = "error", message = "Failed to create User-Product association", details = e$message))
    }
  })
}

get_all_user_products <- function() {
  con <- getConn()
  on.exit(dbDisconnect(con))

  associations <- dbReadTable(con, "user_products")

  return(associations)
}

get_user_products_by_user_id <- function(user_id) {
  con <- getConn()
  on.exit(dbDisconnect(con))

  query <- "
      SELECT up.*, p.product_name 
      FROM user_products up 
      JOIN products p ON up.id_product = p.id_product 
      WHERE up.id_user = $1"

  stmt <- dbSendQuery(con, query)
  dbBind(stmt, list(user_id))
  results <- dbFetch(stmt)
  dbClearResult(stmt)

  if (nrow(results) == 0) {
    return(list(status = "error", message = "No products found for this user"))
  }

  return(results)
}

# Function to get user-product associations by product ID
get_user_products_by_product_id <- function(product_id) {
  con <- getConn()
  on.exit(dbDisconnect(con))

  query <- "
      SELECT up.*, u.name 
      FROM user_products up 
      JOIN user_data u ON up.id_user = u.id_user 
      WHERE up.id_product = ?"

  results <- dbGetQuery(con, query, params = list(product_id))

  if (nrow(results) == 0) {
    return(list(status = "error", message = "No users found for this product"))
  }

  return(results)
}

# Function to delete a user-product association
delete_user_product <- function(id_user, id_product) {
  con <- getConn()  
  on.exit(dbDisconnect(con))

  dbExecute(con, "DELETE FROM user_products WHERE id_user = ? AND id_product = ?", params = list(id_user, id_product))

  return(list(status = "success", message = "User-Product association deleted"))
}
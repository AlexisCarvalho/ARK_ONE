# +-----------------------+
# |                       |
# |    PRODUCT SERVICE    |
# |                       |
# +-----------------------+

source("../models/product_model.R", chdir = TRUE)
source("solar_tracker_service.R", chdir = TRUE)
source("../utils/response_handler.R", chdir = TRUE)
source("../utils/request_handler.R", chdir = TRUE)
source("../utils/utils.R", chdir = TRUE)

# +-----------------------+
# |    HELP FUNCTIONS     |
# +-----------------------+

# +-----------------------+
# |       PRODUCTS        |
# +-----------------------+
# +-----------------------+
# |        GET ALL        |
# +-----------------------+

# Function to get all products
get_products_get_all <- function() {
  products <- tryCatch(
    fetch_all_products(),
    error = function(e) e
  )

  if (inherits(products, "error")) {
    return(list(
      status = "internal_server_error",
      message = paste("Unexpected Error:", products$message),
      data = list(products = NULL)
    ))
  }

  if (!is.data.frame(products) || nrow(products) == 0) {
    return(list(
      status = "not_found",
      message = "There aren't any products in the database",
      data = list(products = NULL)
    ))
  }

  list(
    status = "success",
    message = "All products successfully retrieved",
    data = list(products = products)
  )
}

# +-----------------------+
# |       GET OWNED       |
# +-----------------------+

# Function to get all products owned by a specific user
get_products_owned <- function(req) {
  id_user <- tryCatch(
    get_id_user_from_req(req),
    error = function(e) {
      NULL
    }
  )

  if (is.null(id_user)) {
    return(list(
      status = "unauthorized",
      message = "Failed to identify user, malformed or invalid token",
      data = list(products_owned = NULL)
    ))
  }

  products_owned <- tryCatch(
    fetch_products_owned(id_user),
    error = function(e) e
  )

  if (inherits(products_owned, "error")) {
    return(list(
      status = "internal_server_error",
      message = paste("Unexpected Error:", products_owned$message),
      data = list(products_owned = NULL)
    ))
  }

  if (!is.data.frame(products_owned) || nrow(products_owned) == 0) {
    return(list(
      status = "not_found",
      message = "There are no products owned by this user",
      data = list(products_owned = NULL)
    ))
  }

  list(
    status = "success",
    message = "Products owned successfully retrieved",
    data = list(products_owned = products_owned)
  )
}

# +-----------------------+
# |       OWNED ALL       |
# +-----------------------+

# Function to get all product instances
get_products_owned_all_users <- function(req) {
  user_role <- tryCatch(
    get_user_role_from_req(req),
    error = function(e) {
      return(NULL)
    }
  )

  if (is.null(user_role) || user_role != "admin") {
    return(list(
      status = "unauthorized",
      message = "To retrieve all products owned info, you must be an administrator",
      data = list(products_owned = NULL)
    ))
  }

  products_owned <- tryCatch(
    fetch_products_owned_all_users(),
    error = function(e) e
  )

  if (inherits(products_owned, "error")) {
    return(list(
      status = "internal_server_error",
      message = paste("Unexpected Error:", products_owned$message),
      data = list(products_owned = NULL)
    ))
  }

  if (!is.data.frame(products_owned) || nrow(products_owned) == 0) {
    return(list(
      status = "not_found",
      message = "There are no products owned in the database",
      data = list(products_owned = NULL)
    ))
  }

  list(
    status = "success",
    message = "All products owned successfully retrieved",
    data = list(products_owned = products_owned)
  )
}

# +-----------------------+
# |       REGISTER        |
# +-----------------------+

create_product <- function(product_name, product_description, location_dependent, product_price, id_category) {
  tryCatch(
    {
      insert_product(product_name, product_description, location_dependent, product_price, id_category)

      return(list(
        status = "created",
        message = "Product Registered Successfully"
      ))
    },
    error = function(e) {
      constraint_name <- find_matching_constraint_pgsql(e$message)

      if (!is.null(constraint_name)) {
        return(constraint_violation_response(constraint_name))
      }

      list(
        status = "internal_server_error",
        message = paste("Unexpected Error:", e$message)
      )
    }
  )
}

# Function to handle the creation of a new product
post_products_register <- function(req, product_name, product_description, location_dependent, product_price, id_category) {
  user_role <- tryCatch(
    get_user_role_from_req(req),
    error = function(e) {
      NULL
    }
  )
  if (is.null(user_role) || user_role != "admin") {
    return(list(
      status = "unauthorized",
      message = "To register a product, you must be an administrator"
    ))
  }

  if (any(sapply(list(product_name, product_description), is_invalid_utf8)) ||
    any(sapply(list(product_name, product_description), is_blank_string))) {
    return(list(
      status = "bad_request",
      message = "Product Name and Description must be valid, non-empty and UTF-8 strings"
    ))
  }

  if (nchar(product_name) > 50) {
    return(list(
      status = "bad_request",
      message = "Product Name can't exceed 50 characters"
    ))
  }

  if (nchar(product_description) > 200) {
    return(list(
      status = "bad_request",
      message = "Product Description can't exceed 200 characters"
    ))
  }

  if (!is.logical(location_dependent) || is.na(location_dependent)) {
    return(list(
      status = "bad_request",
      message = "Location Dependent must be TRUE or FALSE"
    ))
  }

  if (!suppressWarnings(!is.na(as.numeric(product_price)))) {
    return(list(
      status = "bad_request",
      message = "Product Price must be a valid number"
    ))
  }

  if (!is.null(id_category) && (is_invalid_utf8(id_category) || !UUIDvalidate(id_category))) {
    return(list(
      status = "bad_request",
      message = "Invalid Category ID"
    ))
  }

  id_category <- if (is.null(id_category)) list(id_category) else id_category

  create_product(product_name, product_description, location_dependent, product_price, id_category)
}

# +-----------------------+
# |      POST OWNED       |
# +-----------------------+

# Function to create a new product instance
create_product_owned <- function(id_product, id_user, esp32_unique_id) {
  tryCatch(
    {
      insert_product_instance(id_product, id_user, esp32_unique_id)

      return(list(
        status = "created",
        message = "Product Owned Registered Successfully"
      ))
    },
    error = function(e) {
      constraint_name <- find_matching_constraint_pgsql(e$message)

      if (!is.null(constraint_name)) {
        return(constraint_violation_response(constraint_name))
      }

      list(
        status = "internal_server_error",
        message = paste("Unexpected Error:", e$message)
      )
    }
  )
}

# Function to register a product on the name of a user
post_products_owned <- function(req, id_product, esp32_unique_id) {
  user_role <- tryCatch(
    get_user_role_from_req(req),
    error = function(e) {
      NULL
    }
  )
  if (is.null(user_role) || user_role == "analyst") {
    return(list(
      status = "unauthorized",
      message = "To register a product on your name, you must be a moderator or higher"
    ))
  }

  if (any(sapply(list(id_product, esp32_unique_id), is_invalid_utf8)) ||
    is_blank_string(esp32_unique_id)) {
    return(list(
      status = "bad_request",
      message = "Product ID and ESP32 ID must be valid, non-empty and UTF-8 strings"
    ))
  }

  if (!UUIDvalidate(id_product)) {
    return(list(
      status = "bad_request",
      message = "Invalid Product ID"
    ))
  }

  id_user <- tryCatch(
    get_id_user_from_req(req),
    error = function(e) {
      NULL
    }
  )

  if (is.null(id_user)) {
    return(list(
      status = "unauthorized",
      message = "Failed to identify user, malformed or invalid token"
    ))
  }

  create_product_owned(id_product, id_user, esp32_unique_id)
}

# +-----------------------+
# |      GET WITH ID      |
# +-----------------------+

# Function to get a product by ID
get_products_with_id <- function(id_product) {
  if (is_invalid_utf8(id_product) || !UUIDvalidate(id_product)) {
    return(list(
      status = "bad_request",
      message = "Missing or Invalid product ID",
      data = list(product = NULL)
    ))
  }

  product <- tryCatch(
    fetch_product_by_id(id_product),
    error = function(e) e
  )

  if (inherits(product, "error")) {
    return(list(
      status = "internal_server_error",
      message = paste("Unexpected Error:", product$message),
      data = list(product = NULL)
    ))
  }

  if (!is.data.frame(product) || nrow(product) == 0) {
    return(list(
      status = "not_found",
      message = "There isn't any product with this id in the database",
      data = list(product = NULL)
    ))
  }

  list(
    status = "success",
    message = "Product successfully retrieved",
    data = list(product = product)
  )
}

# +-----------------------+
# |   GET OWNED WITH ID   |
# +-----------------------+

# Function to get all products owned by a specific user
get_products_owned_with_id <- function(req, id_product) {
  id_user <- tryCatch(
    get_id_user_from_req(req),
    error = function(e) {
      NULL
    }
  )

  if (is.null(id_user)) {
    return(list(
      status = "unauthorized",
      message = "Failed to identify user, malformed or invalid token",
      data = list(products_owned = NULL)
    ))
  }

  if (is_invalid_utf8(id_product) || !UUIDvalidate(id_product)) {
    return(list(
      status = "bad_request",
      message = "Invalid Product ID",
      data = list(products_owned = NULL)
    ))
  }

  products_owned <- tryCatch(
    fetch_products_owned_with_id(id_user, id_product),
    error = function(e) e
  )

  if (inherits(products_owned, "error")) {
    return(list(
      status = "internal_server_error",
      message = paste("Unexpected Error:", products_owned$message),
      data = list(products_owned = NULL)
    ))
  }

  if (!is.data.frame(products_owned) || nrow(products_owned) == 0) {
    return(list(
      status = "not_found",
      message = "There are no products owned by this user",
      data = list(products_owned = NULL)
    ))
  }

  list(
    status = "success",
    message = "Products owned successfully retrieved",
    data = list(products_owned = products_owned)
  )
}

# +-----------------------+
# |      PUT WITH ID      |
# +-----------------------+

edit_product <- function(id_product, product_name, product_description, location_dependent, product_price, id_category) {
  tryCatch(
    {
      update_product(id_product, product_name, product_description, location_dependent, product_price, id_category)

      return(list(
        status = "success",
        message = "Product Updated Successfully"
      ))
    },
    error = function(e) {
      constraint_name <- find_matching_constraint_pgsql(e$message)

      if (!is.null(constraint_name)) {
        return(constraint_violation_response(constraint_name))
      }

      list(
        status = "internal_server_error",
        message = paste("Unexpected Error:", e$message)
      )
    }
  )
}

# Function to update product by ID in PostgreSQL
put_products_with_id <- function(req, id_product, product_name, product_description, location_dependent, product_price, id_category) {
  user_role <- tryCatch(
    get_user_role_from_req(req),
    error = function(e) {
      NULL
    }
  )
  if (is.null(user_role) || user_role != "admin") {
    return(list(
      status = "unauthorized",
      message = "To update a product, you must be an administrator"
    ))
  }

  if (any(sapply(list(product_name, product_description), is_invalid_utf8)) ||
    any(sapply(list(product_name, product_description), is_blank_string))) {
    return(list(
      status = "bad_request",
      message = "Product Name and Description must be valid, non-empty and UTF-8 strings"
    ))
  }

  if (nchar(product_name) > 50) {
    return(list(
      status = "bad_request",
      message = "Product Name can't exceed 50 characters"
    ))
  }

  if (nchar(product_description) > 200) {
    return(list(
      status = "bad_request",
      message = "Product Description can't exceed 200 characters"
    ))
  }

  if (!is.logical(location_dependent) || is.na(location_dependent)) {
    return(list(
      status = "bad_request",
      message = "Location Dependent must be TRUE or FALSE"
    ))
  }

  if (!suppressWarnings(!is.na(as.numeric(product_price)))) {
    return(list(
      status = "bad_request",
      message = "Product Price must be a valid number"
    ))
  }

  if (!is.null(id_category) && (is_invalid_utf8(id_category) || !UUIDvalidate(id_category))) {
    return(list(
      status = "bad_request",
      message = "Invalid Category ID"
    ))
  }

  if (is_invalid_utf8(id_product) || !UUIDvalidate(id_product)) {
    return(list(
      status = "bad_request",
      message = "Invalid Product ID, can't be null"
    ))
  }

  id_category <- if (is.null(id_category)) list(id_category) else id_category

  edit_product(id_product, product_name, product_description, location_dependent, product_price, id_category)
}

# +-----------------------+
# |    DELETE WITH ID     |
# +-----------------------+

remove_product <- function(id_product) {
  tryCatch(
    {
      erase_product(id_product)

      return(list(
        status = "success",
        message = "Product Deleted Successfully"
      ))
    },
    error = function(e) {
      constraint_name <- find_matching_constraint_pgsql(e$message)

      if (!is.null(constraint_name)) {
        return(constraint_violation_response(constraint_name))
      }

      list(
        status = "internal_server_error",
        message = paste("Unexpected Error:", e$message)
      )
    }
  )
}

delete_products_with_id <- function(req, id_product) {
  user_role <- tryCatch(
    get_user_role_from_req(req),
    error = function(e) {
      NULL
    }
  )
  if (is.null(user_role) || user_role != "admin") {
    return(list(
      status = "unauthorized",
      message = "To delete a product, you must be an administrator"
    ))
  }

  if (is_invalid_utf8(id_product) || !UUIDvalidate(id_product)) {
    return(list(
      status = "bad_request",
      message = "Invalid Product ID, can't be null"
    ))
  }

  remove_product(id_product)
}

# +-----------------------+
# |      DELETE OWNED     |
# +-----------------------+

remove_product_owned <- function(esp32_unique_id) {
  tryCatch(
    {
      erase_product_owned(esp32_unique_id)

      delete_esp32_from_memory(esp32_unique_id)

      return(list(
        status = "success",
        message = "Product Deleted Successfully"
      ))
    },
    error = function(e) {
      constraint_name <- find_matching_constraint_pgsql(e$message)

      if (!is.null(constraint_name)) {
        return(constraint_violation_response(constraint_name))
      }

      list(
        status = "internal_server_error",
        message = paste("Unexpected Error:", e$message)
      )
    }
  )
}

delete_products_owned <- function(req, esp32_unique_id) {
  user_role <- tryCatch(
    get_user_role_from_req(req),
    error = function(e) {
      NULL
    }
  )
  if (is.null(user_role) || user_role == "analyst") {
    return(list(
      status = "unauthorized",
      message = "To delete a product on your name, you must be an moderator or higher"
    ))
  }

  if (is_invalid_utf8(esp32_unique_id) || is_blank_string(esp32_unique_id)) {
    return(list(
      status = "bad_request",
      message = "Invalid ESP32 ID"
    ))
  }

  remove_product_owned(esp32_unique_id)
}

# Function to search products by name
get_products_search <- function(name) {
  if (is_invalid_utf8(name) || is_blank_string(name)) {
    return(list(
      status = "bad_request",
      message = "Invalid Product Name",
      data = list(products = NULL)
    ))
  }

  products <- tryCatch(
    fetch_products_by_name(name),
    error = function(e) e
  )

  if (inherits(products, "error")) {
    return(list(
      status = "internal_server_error",
      message = paste("Unexpected Error:", products$message),
      data = list(products = NULL)
    ))
  }

  if (!is.data.frame(products) || nrow(products) == 0) {
    return(list(
      status = "not_found",
      message = "There are no products with similar names",
      data = list(products = NULL)
    ))
  }

  list(
    status = "success",
    message = "Products with Similar Names Successfully Retrieved",
    data = list(products = products)
  )
}

# Initialize esp32_data_storage, that is used to store esp32 data
if (!exists("esp32_data_storage", envir = .GlobalEnv)) {
  esp32_data_storage <- new.env(parent = .GlobalEnv)
  assign("esp32_data_storage", esp32_data_storage, envir = .GlobalEnv)
}

# Initialize esp32_metadata, that is used to store esp32 data
if (!exists("esp32_metadata", envir = .GlobalEnv)) {
  esp32_metadata <- new.env(parent = .GlobalEnv)
  assign("esp32_metadata", esp32_metadata, envir = .GlobalEnv)
}

# Initialize pools_env, that is used to store connection pools
if (!exists("pools_env", envir = .GlobalEnv)) {
  pools_env <- new.env(parent = .GlobalEnv)
  assign("pools_env", pools_env, envir = .GlobalEnv)
}

# Used to store a status map for the http codes
if (!exists("status_env", envir = .GlobalEnv)) {
  status_env <- new.env(parent = .GlobalEnv)
  status_env$http_status_map <- list(
    success = 200,
    created = 201,
    updated = 204,
    bad_request = 400,
    unauthorized = 401,
    forbidden = 402,
    not_found = 404,
    conflict = 409,
    internal_server_error = 500,
    service_unavailable = 503
  )

  status_env$constraint_violation_map <- list(
    # Check
    chk_user_role_pd_values = list(
      status = "bad_request",
      message = "User role must be 'analyst', 'moderator', or 'admin'"
    ),
    chk_valid_email = list(
      status = "bad_request",
      message = "Email must be in a valid format (e.g., user@example.com)"
    ),
    chk_location_coordinates = list(
      status = "bad_request",
      message = "Latitude and longitude must be provided together or left NULL, this could be triggered too if latitude aren't in between -90 AND 90 as well if longitude aren't in between -180 and 180"
    ),
    chk_analyst_not_owner = list(
      status = "bad_request",
      message = "id_analyst and id_owner must be provided with different users"
    ),
    # Unique
    user_data_email_key = list(
      status = "conflict",
      message = "Email must be unique. This email is already in use"
    ),
    category_category_name_key = list(
      status = "conflict",
      message = "Category name must be unique"
    ),
    location_data_id_product_instance_key = list(
      status = "conflict",
      message = "A Product must be associated with only one location"
    ),
    product_instance_esp32_unique_id_key = list(
      status = "conflict",
      message = "ESP32 ID must be unique"
    ),
    products_product_name_key = list(
      status = "conflict",
      message = "Product name must be unique"
    ),
    # Primary Key
    user_data_pkey = list(
      status = "internal_server_error",
      message = "User ID must be unique. Duplicate entries are not allowed"
    ),
    category_pkey = list(
      status = "internal_server_error",
      message = "Category ID must be unique"
    ),
    products_pkey = list(
      status = "internal_server_error",
      message = "Product ID must be unique"
    ),
    product_instance_pkey = list(
      status = "internal_server_error",
      message = "Product Instance ID must be unique"
    ),
    location_data_pkey = list(
      status = "internal_server_error",
      message = "Location ID must be unique"
    ),
    esp32_data_pkey = list(
      status = "internal_server_error",
      message = "ESP32 Data ID must be unique"
    ),
    user_products_pkey = list(
      status = "bad_request",
      message = "Each user-product association must be unique"
    ),
    user_affiliations_pkey = list(
      status = "bad_request",
      message = "Each analyst-owner association must be unique"
    ),
    # Foreign Key
    fk_category_parent = list(
      status = "bad_request",
      message = "Parent category must reference an existing category"
    ),
    fk_products_to_category = list(
      status = "bad_request",
      message = "Product category must reference an existing category"
    ),
    fk_product_instance_to_products = list(
      status = "bad_request",
      message = "Product instance must reference an existing product"
    ),
    fk_product_instance_to_user_data = list(
      status = "bad_request",
      message = "Product instance must belong to a valid user"
    ),
    fk_location_data_to_product_instance = list(
      status = "bad_request",
      message = "Location must belong to a valid product instance"
    ),
    fk_esp32_data_to_product_instance = list(
      status = "bad_request",
      message = "ESP32 data must be linked to a valid product instance"
    ),
    fk_user_products_to_user = list(
      status = "bad_request",
      message = "User-product association must reference a valid user"
    ),
    fk_user_products_to_products = list(
      status = "bad_request",
      message = "User-product association must reference a valid product"
    ),
    fk_user_affiliations_analyst_to_user = list(
      status = "bad_request",
      message = "User_affiliations analyst must reference a valid user"
    ),
    fk_user_affiliations_owner_to_user = list(
      status = "bad_request",
      message = "User_affiliations owner must reference a valid user"
    )
  )

  assign("status_env", status_env, envir = .GlobalEnv)
}

# +--------------------------------------+
# |  INITIAL SCRIPT AND CLOSE FUNCTIONS  |
# +--------------------------------------+

source("database_pool_setup.R", chdir = TRUE)

# Starting the connection with the database using a connection pool
add_pool(
  "postgres_pool",
  RPostgres::Postgres(),
  list(
    dbname = Sys.getenv("DB_NAME"),
    host = Sys.getenv("DB_HOST"),
    port = Sys.getenv("DB_PORT"),
    user = Sys.getenv("DB_USER"),
    password = Sys.getenv("DB_PASSWORD")
  )
)

clear_all_environments <- function() {
  if (exists("esp32_data_storage", envir = .GlobalEnv)) {
    esp32_data_storage <- get("esp32_data_storage", envir = .GlobalEnv)
    rm(list = ls(envir = esp32_data_storage), envir = esp32_data_storage)
    rm(esp32_data_storage, envir = .GlobalEnv)
  }

  if (exists("esp32_metadata", envir = .GlobalEnv)) {
    esp32_metadata <- get("esp32_metadata", envir = .GlobalEnv)
    rm(list = ls(envir = esp32_metadata), envir = esp32_metadata)
    rm(esp32_metadata, envir = .GlobalEnv)
  }

  if (exists("pools_env", envir = .GlobalEnv)) {
    pools_env <- get("pools_env", envir = .GlobalEnv)
    pool_names <- ls(pools_env)

    for (pool_name in pool_names) {
      tryCatch({
        poolClose(pools_env[[pool_name]])
      }, error = function(e) {
        message(sprintf("Erro ao fechar pool '%s': %s", pool_name, e$message))
      })
    }

    message("All database pools have been closed.")

    rm(list = pool_names, envir = pools_env)
    rm(pools_env, envir = .GlobalEnv)
  }

  if (exists("status_env", envir = .GlobalEnv)) {
    status_env <- get("status_env", envir = .GlobalEnv)
    rm(list = ls(envir = status_env), envir = status_env)
    rm(status_env, envir = .GlobalEnv)
  }

  gc()  # Garbage Collector Call for cleaning the memory
  message("All environments and variables are cleaned")
}
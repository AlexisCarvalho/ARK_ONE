# +---------------------+
# |                     |
# |  LOCATION SERVICE   |
# |                     |
# +---------------------+

source("../models/location_model.R", chdir = TRUE)
source("../utils/utils.R", chdir = TRUE)

# +-----------------------+
# |    HELP FUNCTIONS     |
# +-----------------------+

# +-------------------------+
# |        LOCATION         |
# +-------------------------+

# +-----------------------+
# |        GET ALL        |
# +-----------------------+

get_locations_get_all <- function(req) {
  user_role <- tryCatch(
    get_user_role_from_req(req),
    error = function(e) {
      NULL
    }
  )
  if (is.null(user_role) || user_role != "admin") {
    return(list(
      status = "unauthorized",
      message = "To delete a location, you must be an administrator"
    ))
  }

  locations <- tryCatch(
    fetch_all_locations(),
    error = function(e) e
  )

  if (inherits(locations, "error")) {
    return(list(
      status = "internal_server_error",
      message = paste("Unexpected Error:", locations$message),
      data = list(locations = NULL)
    ))
  }

  if (!is.data.frame(locations) || nrow(locations) == 0) {
    return(list(
      status = "not_found",
      message = "No locations found in the database",
      data = list(locations = NULL)
    ))
  }

  list(
    status = "success",
    message = "All locations successfully retrieved",
    data = list(locations = locations)
  )
}

# +-----------------------+
# |      GET WITH ID      |
# +-----------------------+

get_locations_with_id <- function(id_product_instance) {
  if (is_invalid_utf8(id_product_instance) || !UUIDvalidate(id_product_instance)) {
    return(list(
      status = "bad_request",
      message = "Missing or Invalid location ID",
      data = list(location = NULL)
    ))
  }

  location <- tryCatch(
    fetch_location_by_id(id_product_instance),
    error = function(e) e
  )

  if (inherits(location, "error")) {
    return(list(
      status = "internal_server_error",
      message = paste("Unexpected Error:", location$message),
      data = list(location = NULL)
    ))
  }

  if (!is.data.frame(location) || nrow(location) == 0) {
    return(list(
      status = "not_found",
      message = "Location not found with this ID",
      data = list(location = NULL)
    ))
  }

  list(
    status = "success",
    message = "Location successfully retrieved",
    data = list(location = location)
  )
}

# +-------------------+
# |   SOLAR TRACKER   |
# +-------------------+

get_locations_solar_tracker <- function(esp32_unique_id) {
  if (is_invalid_utf8(esp32_unique_id)) {
    return(list(
      status = "bad_request",
      message = "Missing or Invalid ESP32 ID",
      data = list(location = NULL)
    ))
  }

  location <- tryCatch(
    fetch_location_data_with_esp_id(esp32_unique_id),
    error = function(e) e
  )

  if (inherits(location, "error")) {
    return(list(
      status = "internal_server_error",
      message = paste("Unexpected Error:", location$message),
      data = list(location = NULL)
    ))
  }

  if (!is.data.frame(location) || nrow(location) == 0) {
    return(list(
      status = "not_found",
      message = "Location not found with this ESP32 ID",
      data = list(location = NULL)
    ))
  }

  list(
    status = "success",
    message = "Location successfully retrieved",
    data = list(location = location)
  )
}

# +-----------------------+
# |       REGISTER        |
# +-----------------------+

create_location <- function(id_product_instance, latitude, longitude) {
  tryCatch(
    {
      insert_location(id_product_instance, latitude, longitude)

      return(list(
        status = "created",
        message = "Location Registered Successfully"
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

# Function to handle the register of a new Location
post_locations_register <- function(req, id_product_instance, latitude, longitude) {
  user_role <- tryCatch(
    get_user_role_from_req(req),
    error = function(e) {
      NULL
    }
  )
  if (is.null(user_role) || user_role == "analyst") {
    return(list(
      status = "unauthorized",
      message = "To register a location, you must be an moderator or higher"
    ))
  }

  if (!is.null(id_product_instance) && (is_invalid_utf8(id_product_instance) || !UUIDvalidate(id_product_instance))) {
    return(list(
      status = "bad_request",
      message = "Invalid Product Instance ID"
    ))
  }

  validation_result <- validate_and_convert_numeric_fields(
    latitude = latitude,
    longitude = longitude
  )

  if (validation_result$status != "success") {
    return(validation_result)
  }

  id_product_instance <- if (is.null(id_product_instance)) list(id_product_instance) else id_product_instance

  create_location(id_product_instance, latitude, longitude)
}

# +-----------------------+
# |      PUT WITH ID      |
# +-----------------------+

edit_location <- function(id_product_instance, latitude, longitude) {
  tryCatch(
    {
      update_location(id_product_instance, latitude, longitude)

      return(list(
        status = "success",
        message = "Location Updated Successfully"
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

# Function to handle the update of a Location
put_locations_with_id <- function(req, id_product_instance, latitude, longitude) {
  user_role <- tryCatch(
    get_user_role_from_req(req),
    error = function(e) {
      NULL
    }
  )
  if (is.null(user_role) || user_role == "analyst") {
    return(list(
      status = "unauthorized",
      message = "To update a location, you must be an moderator or higher"
    ))
  }

  if (!is.null(id_product_instance) && (is_invalid_utf8(id_product_instance) || !UUIDvalidate(id_product_instance))) {
    return(list(
      status = "bad_request",
      message = "Invalid Product Instance ID"
    ))
  }

  validation_result <- validate_and_convert_numeric_fields(
    latitude = latitude,
    longitude = longitude
  )

  if (validation_result$status != "success") {
    return(validation_result)
  }

  id_product_instance <- if (is.null(id_product_instance)) list(id_product_instance) else id_product_instance

  edit_location(id_product_instance, latitude, longitude)
}

# +-----------+
# |    SET    |
# +-----------+

post_locations_set <- function(req, id_product_instance, latitude, longitude) {
  user_role <- tryCatch(
    get_user_role_from_req(req),
    error = function(e) {
      NULL
    }
  )
  if (is.null(user_role) || user_role == "analyst") {
    return(list(
      status = "unauthorized",
      message = "To set a location, you must be an moderator or higher"
    ))
  }

  validation_result <- validate_and_convert_numeric_fields(
    latitude = latitude,
    longitude = longitude
  )

  if (validation_result$status != "success") {
    return(validation_result)
  }

  # id_product_instance tests are executed in get_locations_with_id
  # That's why there aren't any of them here before using bellow
  response <- get_locations_with_id(id_product_instance)

  if (response$status == "success") {
    return(edit_location(id_product_instance, latitude, longitude))
  }

  if (response$status == "not_found") {
    return(create_location(id_product_instance, latitude, longitude))
  }

  response$data <- NULL
  response
}

# +-----------------------+
# |    DELETE WITH ID     |
# +-----------------------+

remove_location <- function(id_product_instance) {
  tryCatch(
    {
      erase_location(id_product_instance)

      return(list(
        status = "success",
        message = "Location Deleted Successfully"
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

delete_locations_with_id <- function(req, id_product_instance) {
  user_role <- tryCatch(
    get_user_role_from_req(req),
    error = function(e) {
      NULL
    }
  )
  if (is.null(user_role) || user_role != "admin") {
    return(list(
      status = "unauthorized",
      message = "To delete a location, you must be an administrator"
    ))
  }

  if (is_invalid_utf8(id_product_instance) || !UUIDvalidate(id_product_instance)) {
    return(list(
      status = "bad_request",
      message = "Invalid Location ID, can't be null"
    ))
  }

  remove_location(id_product_instance)
}
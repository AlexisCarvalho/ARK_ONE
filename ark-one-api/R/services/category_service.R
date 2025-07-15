# +---------------------+
# |                     |
# |  CATEGORY SERVICE   |
# |                     |
# +---------------------+

source("../models/category_model.R", chdir = TRUE)

# +-----------------------+
# |    HELP FUNCTIONS     |
# +-----------------------+

# +-------------------------+
# |       CATEGORIES        |
# +-------------------------+
# +-----------------------+
# |        GET ALL        |
# +-----------------------+

# Function to get all categories
get_categories_get_all <- function() {
  categories <- tryCatch(
    fetch_all_categories(),
    error = function(e) e
  )

  if (inherits(categories, "error")) {
    return(list(
      status = "internal_server_error",
      message = paste("Unexpected Error:", categories$message),
      data = list(categories = NULL)
    ))
  }

  if (!is.data.frame(categories) || nrow(categories) == 0) {
    return(list(
      status = "not_found",
      message = "There aren't any categories in the database",
      data = list(categories = NULL)
    ))
  }

  list(
    status = "success",
    message = "All categories successfully retrieved",
    data = list(categories = categories)
  )
}

# +-----------------------+
# |      GET WITH ID      |
# +-----------------------+

# Function to get a category by ID
get_category_with_id <- function(id_category) {
  if (is_invalid_utf8(id_category) || !UUIDvalidate(id_category)) {
    return(list(
      status = "bad_request",
      message = "Missing or Invalid category ID",
      data = list(category = NULL)
    ))
  }

  category <- tryCatch(
    fetch_category_by_id(id_category),
    error = function(e) e
  )

  if (inherits(category, "error")) {
    return(list(
      status = "internal_server_error",
      message = paste("Unexpected Error:", category$message),
      data = list(category = NULL)
    ))
  }

  if (!is.data.frame(category) || nrow(category) == 0) {
    return(list(
      status = "not_found",
      message = "There isn't any category with this id in the database",
      data = list(category = NULL)
    ))
  }

  list(
    status = "success",
    message = "Category successfully retrieved",
    data = list(category = category)
  )
}

# +-----------------------+
# |       REGISTER        |
# +-----------------------+

create_category <- function(category_name, category_description, id_father_category) {
  tryCatch(
    {
      insert_category(category_name, category_description, id_father_category)

      return(list(
        status = "created",
        message = "Category Registered Successfully"
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

# Function to handle the creation of a new category
post_category_register <- function(req, category_name, category_description, id_father_category) {
  user_role <- tryCatch(
    get_user_role_from_req(req),
    error = function(e) {
      NULL
    }
  )
  if (is.null(user_role) || user_role != "admin") {
    return(list(
      status = "unauthorized",
      message = "To register a category, you must be an administrator"
    ))
  }

  if (any(sapply(list(category_name, category_description), is_invalid_utf8)) ||
      any(sapply(list(category_name, category_description), is_blank_string))) {
    return(list(
      status = "bad_request",
      message = "Category Name and Description must be valid, non-empty and UTF-8 strings"
    ))
  }

  if (nchar(category_name) > 50) {
    return(list(
      status = "bad_request",
      message = "Category Name can't exceed 50 characters"
    ))
  }

  if (nchar(category_description) > 200) {
    return(list(
      status = "bad_request",
      message = "Category Description can't exceed 200 characters"
    ))
  }

  if (!is.null(id_father_category) && (is_invalid_utf8(id_father_category) || !UUIDvalidate(id_father_category))) {
    return(list(
      status = "bad_request",
      message = "Invalid Father Category ID"
    ))
  }

  id_father_category <- if (is.null(id_father_category)) list(id_father_category) else id_father_category

  create_category(category_name, category_description, id_father_category)
}

# +-----------------------+
# |      PUT WITH ID      |
# +-----------------------+

edit_category <- function(id_category, category_name, category_description, id_father_category) {
  tryCatch(
    {
      update_category(id_category, category_name, category_description, id_father_category)

      return(list(
        status = "success",
        message = "Category Updated Successfully"
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

# Function to update category by ID in PostgreSQL
put_categories_with_id <- function(req, id_category, category_name, category_description, id_father_category) {
  user_role <- tryCatch(
    get_user_role_from_req(req),
    error = function(e) {
      NULL
    }
  )
  if (is.null(user_role) || user_role != "admin") {
    return(list(
      status = "unauthorized",
      message = "To update a category, you must be an administrator"
    ))
  }

  if (any(sapply(list(category_name, category_description), is_invalid_utf8)) ||
      any(sapply(list(category_name, category_description), is_blank_string))) {
    return(list(
      status = "bad_request",
      message = "Category Name and Description must be valid, non-empty and UTF-8 strings"
    ))
  }

  if (nchar(category_name) > 50) {
    return(list(
      status = "bad_request",
      message = "Category Name can't exceed 50 characters"
    ))
  }

  if (nchar(category_description) > 200) {
    return(list(
      status = "bad_request",
      message = "Category Description can't exceed 200 characters"
    ))
  }

  if (is_invalid_utf8(id_category) || !UUIDvalidate(id_category)) {
    return(list(
      status = "bad_request",
      message = "Invalid Category ID, can't be null"
    ))
  }

  if (!is.null(id_father_category) && (is_invalid_utf8(id_father_category) || !UUIDvalidate(id_father_category))) {
    return(list(
      status = "bad_request",
      message = "Invalid Father Category ID"
    ))
  }

  id_father_category <- if (is.null(id_father_category)) list(id_father_category) else id_father_category

  edit_category(id_category, category_name, category_description, id_father_category)
}

# +-----------------------+
# |    DELETE WITH ID     |
# +-----------------------+

remove_category <- function(id_category) {
  tryCatch(
    {
      erase_category(id_category)

      return(list(
        status = "success",
        message = "Category Deleted Successfully"
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

delete_category_with_id <- function(req, id_category) {
  user_role <- tryCatch(
    get_user_role_from_req(req),
    error = function(e) {
      NULL
    }
  )
  if (is.null(user_role) || user_role != "admin") {
    return(list(
      status = "unauthorized",
      message = "To delete a category, you must be an administrator"
    ))
  }

  if (is_invalid_utf8(id_category) || !UUIDvalidate(id_category)) {
    return(list(
      status = "bad_request",
      message = "Invalid Category ID, can't be null"
    ))
  }

  remove_category(id_category)
}
source("../models/category_model.R", chdir = TRUE)

# +-----------------------+
# |                       |
# |   CATEGORY SERVICE    |
# |                       |
# +-----------------------+

# Function to create a new category
create_category <- function(category_name, category_description, id_father_category) {
  con <- getConn()
  on.exit(dbDisconnect(con))

  if (is.null(id_father_category) || id_father_category == 0) {
    id_father_category <- NULL
    id_father_category <- list(id_father_category)
  }

  tryCatch(
    {
      query <- "INSERT INTO category (category_name, category_description, id_father_category) VALUES ($1, $2, $3)"
      dbExecute(con, query, params = list(category_name, category_description, id_father_category))

      return(list(status = "success", status_code = 201, message = "Category created successfully"))
    },
    error = function(e) {
      if (grepl("duplicate key", e$message, ignore.case = TRUE)) {
        return(list(status = "error", status_code = 409, message = "A category with this name already exists."))
      } else if (grepl("violates foreign key constraint", e$message, ignore.case = TRUE)) {
        return(list(status = "error", status_code = 400, message = "Invalid parent category."))
      } else if (grepl("connection", e$message, ignore.case = TRUE)) {
        return(list(status = "error", status_code = 503, message = "Database connection error. Please try again later."))
      } else {
        return(list(status = "error", status_code = 500, message = paste("An unexpected error occurred:", e$message)))
      }
    }
  )
}

# Function to get all categories
get_all_categories <- function() {
  con <- getConn()
  on.exit(dbDisconnect(con))

  categories <- dbReadTable(con, "category")
  return(categories)
}

# Function to get a category by ID
get_category_by_id <- function(id) {
  con <- getConn()
  on.exit(dbDisconnect(con))

  query <- "SELECT * FROM category WHERE id_category = $1"
  category <- dbGetQuery(con, query, params = list(id))

  if (nrow(category) == 0) {
    return(list(status = "error", message = "Category not found"))
  }

  return(category)
}

# Function to update a category by ID
update_category_by_id <- function(id, category_name = NULL, category_description = NULL, id_father_category = NULL) {
  con <- getConn()
  on.exit(dbDisconnect(con))

  updates <- c()

  if (!is.null(category_name)) updates <- c(updates, sprintf("category_name = '%s'", category_name))
  if (!is.null(category_description)) updates <- c(updates, sprintf("category_description = '%s'", category_description))
  if (!is.null(id_father_category)) updates <- c(updates, sprintf("id_father_category = %s", id_father_category))

  if (length(updates) > 0) {
    update_query <- paste(updates, collapse = ", ")
    dbExecute(con, sprintf("UPDATE category SET %s WHERE id_category = $1", update_query), params = list(id))
    return(list(status = "success", message = "Category updated"))
  }

  return(list(status = "error", message = "No fields to update"))
}

# Function to delete a category by ID
delete_category_by_id <- function(id) {
  con <- getConn()
  on.exit(dbDisconnect(con))

  # Check if the category exists before deletion
  existing_category <- dbGetQuery(con, "SELECT * FROM category WHERE id_category = $1", params = list(id))

  if (nrow(existing_category) == 0) {
    return(list(status = "error", message = "Category not found"))
  }

  dbExecute(con, "DELETE FROM category WHERE id_category = $1", params = list(id))

  return(list(status = "success", message = "Category deleted"))
}
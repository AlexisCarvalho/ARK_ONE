source("../utils/database_pool_setup.R", chdir = TRUE)

fetch_all_products <- function() {
  con <- get_conn()

  if (is.null(con) || !DBI::dbIsValid(con)) {
    stop("Database Connection Failed")
  }

  on.exit(pool_return(con), add = TRUE)

  tryCatch(
    {
      return(dbReadTable(con, "products"))
    },
    error = function(e) stop(e)
  )
}

fetch_products_owned_all_users <- function() {
  con <- get_conn()

  if (is.null(con) || !DBI::dbIsValid(con)) {
    stop("Database Connection Failed")
  }

  on.exit(pool_return(con), add = TRUE)

  tryCatch(
    {
      query <- "
        SELECT
          user_data.name AS user_name,
          products.product_name AS product_name,
          product_instance.esp32_unique_id
        FROM
          product_instance
        INNER JOIN
          user_data ON product_instance.id_user = user_data.id_user
        INNER JOIN
          products ON product_instance.id_product = products.id_product
      "

      return(DBI::dbGetQuery(con, query))
    },
    error = function(e) {
      stop(e)
    }
  )
}

fetch_products_owned <- function(user_id) {
  con <- get_conn()
  on.exit(pool_return(con), add = TRUE)

  query <- "
      SELECT pi.id_product_instance, pi.esp32_unique_id, p.product_name, p.location_dependent
      FROM product_instance pi
      JOIN products p ON pi.id_product = p.id_product
      WHERE pi.id_user = $1"

  tryCatch(
    {
      results <- DBI::dbGetQuery(con, query, params = list(user_id))
      return(results)
    },
    error = function(e) {
      stop(e)
    }
  )
}

fetch_products_owned_with_id <- function(user_id, product_id) {
  con <- get_conn()

  if (is.null(con) || !DBI::dbIsValid(con)) {
    stop("Database Connection Failed")
  }

  on.exit(pool_return(con), add = TRUE)

  query <- "
      SELECT pi.id_product_instance, pi.esp32_unique_id, p.product_name, p.location_dependent
      FROM products p
      JOIN product_instance pi ON p.id_product = pi.id_product
      WHERE pi.id_user = $1 AND pi.id_product = $2"

  tryCatch(
    {
      results <- DBI::dbGetQuery(con, query, params = list(user_id, product_id))
      return(results)
    },
    error = function(e) {
      stop(e)
    }
  )
}

insert_product <- function(product_name, product_description, location_dependent, product_price, id_category) {
  con <- get_conn()

  if (is.null(con) || !DBI::dbIsValid(con)) {
    stop("Database Connection Failed")
  }

  on.exit(pool_return(con), add = TRUE)

  tryCatch(
    {
      query <- "INSERT INTO products (product_name, product_description, id_category, location_dependent, product_price) VALUES ($1, $2, $3, $4, $5)"
      return(dbExecute(con, query, params = list(product_name, product_description, id_category, location_dependent, product_price)))
    },
    error = function(e) stop(e)
  )
}

insert_product_instance <- function(id_product, id_user, esp32_unique_id) {
  con <- get_conn()

  if (is.null(con) || !DBI::dbIsValid(con)) {
    stop("Database Connection Failed")
  }

  on.exit(pool_return(con), add = TRUE)

  tryCatch(
    {
      query <- "
        INSERT INTO product_instance (id_product, id_user, esp32_unique_id)
        VALUES ($1, $2, $3)
      "

      DBI::dbExecute(con, query, params = list(id_product, id_user, esp32_unique_id))

      return(TRUE)
    },
    error = function(e) {
      stop(e)
    }
  )
}

fetch_product_by_id <- function(id) {
  con <- get_conn()

  if (is.null(con) || !DBI::dbIsValid(con)) {
    stop("Database Connection Failed")
  }

  on.exit(pool_return(con), add = TRUE)

  tryCatch(
    {
      query <- "SELECT * FROM products WHERE id_product = $1"
      return(dbGetQuery(con, query, params = list(id)))
    },
    error = function(e) stop(e)
  )
}

update_product <- function(id_product, product_name, product_description, location_dependent, product_price, id_category) {
  con <- get_conn()

  if (is.null(con) || !DBI::dbIsValid(con)) {
    stop("Database Connection Failed")
  }

  on.exit(pool_return(con), add = TRUE)

  tryCatch(
    {
      query <- "UPDATE products SET product_name = $2, product_description = $3, location_dependent = $4, product_price = $5, id_category = $6 WHERE id_product = $1"

      affected_rows <- dbExecute(con, query, params = list(id_product, product_name, product_description, location_dependent, product_price, id_category))

      if (affected_rows == 0) {
        stop("\"no_rows_updated\"")
      }
    },
    error = function(e) stop(e)
  )
}

erase_product <- function(id_product) {
  con <- get_conn()

  if (is.null(con) || !DBI::dbIsValid(con)) {
    stop("Database Connection Failed")
  }

  on.exit(pool_return(con), add = TRUE)

  tryCatch(
    {
      DBI::dbBegin(con)

      query <- "DELETE FROM products WHERE id_product = $1"

      affected_rows <- DBI::dbExecute(con, query, params = list(id_product))

      if (affected_rows == 0) {
        stop("\"no_rows_deleted\"")
      }

      DBI::dbCommit(con)
    },
    error = function(e) {
      DBI::dbRollback(con)
      stop(e)
    }
  )
}

erase_product_owned <- function(esp32_unique_id) {
  con <- get_conn()

  if (is.null(con) || !DBI::dbIsValid(con)) {
    stop("Database Connection Failed")
  }

  on.exit(pool_return(con), add = TRUE)

  tryCatch(
    {
      DBI::dbBegin(con)

      query_select <- "
        SELECT id_product, id_user
        FROM product_instance
        WHERE esp32_unique_id = $1"

      product_instance <- DBI::dbGetQuery(con, query_select, params = list(esp32_unique_id))

      if (nrow(product_instance) == 0) {
        stop("\"no_rows_deleted\"")
      }

      id_product <- product_instance$id_product
      id_user <- product_instance$id_user

      query_delete_instance <- "
        DELETE FROM product_instance
        WHERE esp32_unique_id = $1"
      DBI::dbExecute(con, query_delete_instance, params = list(esp32_unique_id))

      query_check_instances <- "
        SELECT COUNT(*) as count
        FROM product_instance
        WHERE id_product = $1 AND id_user = $2"
      count_instances <- DBI::dbGetQuery(con, query_check_instances, params = list(id_product, id_user))

      if (count_instances$count == 0) {
        query_delete_user_product <- "
          DELETE FROM user_products
          WHERE id_user = $1 AND id_product = $2"
        DBI::dbExecute(con, query_delete_user_product, params = list(id_user, id_product))
        # Here is not necessary to search if changes where made or there is no_rows_deleted
        # because the logic make impossible to get here if there is no product_instance
      }

      DBI::dbCommit(con)
    },
    error = function(e) {
      DBI::dbRollback(con)
      stop(e)
    }
  )
}

fetch_products_by_name <- function(name) {
  con <- get_conn()

  if (is.null(con) || !DBI::dbIsValid(con)) {
    stop("Database Connection Failed")
  }

  on.exit(pool_return(con), add = TRUE)

  tryCatch(
    {
      query <- "SELECT * FROM products WHERE product_name ILIKE $1"
      return(dbGetQuery(con, query, params = list(paste0("%", name, "%"))))
    },
    error = function(e) stop(e)
  )
}

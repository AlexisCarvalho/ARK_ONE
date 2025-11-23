# Request function for product registration with JWT authentication
product_register_request <- function(base_url, admin_token, product_name, product_description, product_price, location_dependent, id_category = NA) {
  body_data <- list(
    product_name = product_name,
    product_description = product_description,
    product_price = product_price,
    location_dependent = location_dependent
  )

  if (!is.na(id_category)) {
    body_data$id_category <- id_category
  }

  response <- POST(
    url = paste0(base_url, "/Products/register"),
    body = toJSON(body_data, auto_unbox = TRUE),
    encode = "json",
    content_type_json(),
    add_headers(Authorization = paste("Bearer", admin_token))
  )

  return(response)
}

# Request function for owned product registration with JWT authentication
product_owned_register_request <- function(base_url, moderator_token, id_product, esp32_unique_id) {
  body_data <- list(
    id_product = id_product,
    esp32_unique_id = esp32_unique_id
  )

  response <- POST(
    url = paste0(base_url, "/Products/owned"),
    body = toJSON(body_data, auto_unbox = TRUE),
    encode = "json",
    content_type_json(),
    add_headers(Authorization = paste("Bearer", moderator_token))
  )

  return(response)
}

# Request function to search a product with JWT authentication
product_search_request <- function(base_url, analyst_token, name) {
  response <- GET(
    url = paste0(base_url, "/Products/search?name=", URLencode(name, reserved = TRUE)),
    content_type_json(),
    add_headers(Authorization = paste("Bearer", analyst_token))
  )

  return(response)
}

# Request function for product update with JWT authentication
product_update_request <- function(base_url, admin_token, product_id, product_name, product_description, product_price, location_dependent, id_category = NA) {
  body_data <- list(
    product_id = product_id,
    product_name = product_name,
    product_description = product_description,
    product_price = product_price,
    location_dependent = location_dependent
  )

  if (!is.na(id_category)) {
    body_data$id_category <- id_category
  }

  url <- paste0(base_url, "/Products/", product_id)

  response <- PUT(
    url = url,
    body = toJSON(body_data, auto_unbox = TRUE),
    encode = "json",
    content_type_json(),
    add_headers(Authorization = paste("Bearer", admin_token))
  )

  return(response)
}

# Test function for product registration
test_product_register <- function(base_url, admin_token) {
  message("Testing POST (/Products/register) ...")

  message("Testing with Invalid Input Types ...")

  test_that("Invalid price format returns 400", {
    response <- product_register_request(base_url, admin_token, "Solar Panel", "A high-efficiency solar panel", 12345, "invalid_boolean")
    content <- content(response, as = "parsed", simplifyVector = TRUE)

    expect_equal(status_code(response), 400)
    expect_equal(content$status, "bad_request")
    expect_equal(content$message, "Location Dependent must be TRUE or FALSE")
  })

  test_that("Missing required fields return 400", {
    response <- product_register_request(base_url, admin_token, "", "", "", TRUE)
    content <- content(response, as = "parsed", simplifyVector = TRUE)

    expect_equal(status_code(response), 400)
    expect_equal(content$status, "bad_request")
  })

  test_that("Invalid UUID format in id_category returns 400", {
    response <- product_register_request(base_url, admin_token, "Solar Panel", "A high-efficiency solar panel", "199.99", TRUE, "invalid-uuid")
    content <- content(response, as = "parsed", simplifyVector = TRUE)

    expect_equal(status_code(response), 400)
    expect_equal(content$status, "bad_request")
    expect_equal(content$message, "Invalid Category ID")
  })

  message("Testing with Valid Data ...")
  test_that("Successful product registration returns 201", {
    response <- product_register_request(base_url, admin_token, "Solar Panel", "A high-efficiency solar panel", "199.99", TRUE)
    content <- content(response, as = "parsed", simplifyVector = TRUE)

    expect_equal(status_code(response), 201)
    expect_equal(content$status, "created")
    expect_equal(content$message, "Product Registered Successfully")
  })
}

test_product_search <- function(base_url, analyst_token) {
  message("Testing POST (/Products/search) ...")

  message("Testing with Invalid Input Types ...")

  message("Testing with Valid Data ...")
  test_that("Successful product search returns 200", {
    response <- product_search_request(base_url, analyst_token, "Solar Panel")
    content <- content(response, as = "parsed", simplifyVector = TRUE)

    expect_equal(status_code(response), 200)
    expect_equal(content$status, "success")
    expect_equal(content$message, "Products with Similar Names Successfully Retrieved")
    expect_true(!is.null(content$data$products) && nchar(content$data$products[1]$id_product) > 0)
  })
}

test_product_owned_register <- function(base_url, moderator_token) {
  message("Testing POST (/Products/owned) ...")

  response <- product_search_request(base_url, admin_token, "Solar Panel")
  content <- content(response, as = "parsed", simplifyVector = TRUE)
  id_product <- content$data$products[1]$id_product

  message("Testing with Invalid Input Types ...")

  message("Testing with Valid Data ...")
  test_that("Successful product registration returns 201", {
    response <- product_owned_register_request(base_url, moderator_token, id_product, "sampleInformation")
    content <- content(response, as = "parsed", simplifyVector = TRUE)

    expect_equal(status_code(response), 201)
    expect_equal(content$status, "created")
    expect_equal(content$message, "Product Owned Registered Successfully")
  })

  test_that("Successful product registration returns 201", {
    response <- product_owned_register_request(base_url, moderator_token, id_product, "esp32_001")
    content <- content(response, as = "parsed", simplifyVector = TRUE)

    expect_equal(status_code(response), 201)
    expect_equal(content$status, "created")
    expect_equal(content$message, "Product Owned Registered Successfully")
  })

  test_that("Successful product registration returns 201", {
    response <- product_owned_register_request(base_url, moderator_token, id_product, "esp32_003")
    content <- content(response, as = "parsed", simplifyVector = TRUE)

    expect_equal(status_code(response), 201)
    expect_equal(content$status, "created")
    expect_equal(content$message, "Product Owned Registered Successfully")
  })

  test_that("Successful product registration returns 201", {
    response <- product_owned_register_request(base_url, moderator_token, id_product, "esp32_999")
    content <- content(response, as = "parsed", simplifyVector = TRUE)

    expect_equal(status_code(response), 201)
    expect_equal(content$status, "created")
    expect_equal(content$message, "Product Owned Registered Successfully")
  })
}
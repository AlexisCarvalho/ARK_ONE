# Request function for login
account_login_request <- function(base_url, email, password) {
  POST(
    url = paste0(base_url, "/Account/login"),
    body = toJSON(list(email = email, password = password), auto_unbox = TRUE),
    encode = "json",
    content_type_json()
  )
}

# Request function for register
account_register_request <- function(base_url, name, email, password, user_role = "moderator") {
  POST(
    url = paste0(base_url, "/Account/register"),
    body = toJSON(list(name = name, email = email, password = password, user_role = user_role), auto_unbox = TRUE),
    encode = "json",
    content_type_json()
  )
}

test_account_register <- function(base_url) {
  message("Testing POST (/Account/register) ...")

  message("Testing with Invalid Input Types ...")

  test_that("Invalid email format returns 400", {
    response <- account_register_request(base_url, "Test User", "invalid-email", "ValidPassword123")
    content <- content(response, as = "parsed", simplifyVector = TRUE)

    expect_equal(status_code(response), 400)
    expect_equal(content$status, "bad_request")
    expect_equal(content$message, "Email must be in a valid format (e.g., user@example.com)")
  })

  test_that("If values that aren't strings are passed the API returns 400", {
    not_a_string <- 1

    fields <- list(
      list(name = "Name", args = list(base_url, not_a_string, "user@example.com", "a")),
      list(name = "Email", args = list(base_url, "a", not_a_string, "a")),
      list(name = "Password", args = list(base_url, "a", "user@example.com", not_a_string)),
      list(name = "User_role", args = list(base_url, "a", "user@example.com", "a", not_a_string))
    )

    for (field in fields) {
      response <- do.call(account_register_request, field$args)
      content <- content(response, as = "parsed", simplifyVector = TRUE)

      expect_equal(status_code(response), 400, info = paste("Failed for field:", field$name))
      expect_equal(content$status, "bad_request", info = paste("Failed for field:", field$name))
      expect_equal(content$message, "Invalid Input Type", info = paste("Failed for field:", field$name))
    }
  })

  test_that("Invalid UTF-8 characters in any field return 400", {
    invalid_utf8 <- rawToChar(as.raw(c(0xC0, 0x80)))

    fields <- list(
      list(name = "Name", args = list(base_url, invalid_utf8, "user@example.com", "a")),
      list(name = "Email", args = list(base_url, "a", invalid_utf8, "a")),
      list(name = "Password", args = list(base_url, "a", "user@example.com", invalid_utf8)),
      list(name = "User_role", args = list(base_url, "a", "user@example.com", "a", invalid_utf8))
    )

    for (field in fields) {
      response <- do.call(account_register_request, field$args)
      content <- content(response, as = "parsed", simplifyVector = TRUE)

      expect_equal(status_code(response), 400, info = paste("Failed for field:", field$name))
      expect_equal(content$status, "bad_request", info = paste("Failed for field:", field$name))
      expect_equal(content$message, "Invalid Input Type", info = paste("Failed for field:", field$name))
    }
  })

  test_that("Email exceeding 100 characters returns 400", {
    long_email <- paste0(paste(rep("A", 101), collapse = ""), "@gmail.com")
    response <- account_register_request(base_url, "Test User", long_email, "ValidPassword123")
    content <- content(response, as = "parsed", simplifyVector = TRUE)

    expect_equal(status_code(response), 400)
    expect_equal(content$status, "bad_request")
    expect_equal(content$message, "Email can't exceed 100 characters")
  })

  test_that("Password exceeding 72 characters returns 400", {
    long_password <- paste(rep("A", 73), collapse = "")
    response <- account_register_request(base_url, "Test User", "user@example.com", long_password)
    content <- content(response, as = "parsed", simplifyVector = TRUE)

    expect_equal(status_code(response), 400)
    expect_equal(content$status, "bad_request")
    expect_equal(content$message, "Invalid Password: Must be ASCII and below 72 characters")
  })

  test_that("Invalid user role returns 400", {
    response <- account_register_request(base_url, "Test User", "user@example.com", "ValidPassword123", "invalid_role")
    content <- content(response, as = "parsed", simplifyVector = TRUE)

    expect_equal(status_code(response), 400)
    expect_equal(content$status, "bad_request")
    expect_equal(content$message, "User role must be 'analyst', 'moderator', or 'admin'")
  })

  test_that("Invalid User Role returns 400", {
    response <- account_register_request(base_url, "Test User", "user@example.com", "ValidPassword123", "InvalidRole")
    content <- content(response, as = "parsed", simplifyVector = TRUE)

    expect_equal(status_code(response), 400)
    expect_equal(content$status, "bad_request")
    expect_equal(content$message, "User role must be 'analyst', 'moderator', or 'admin'")
  })

  message("Testing with Missing Values ...")
  test_that("Missing fields return 400", {
    response <- account_register_request(base_url, "", "", "")
    content <- content(response, as = "parsed", simplifyVector = TRUE)

    expect_equal(status_code(response), 400)
    expect_equal(content$status, "bad_request")
  })

  message("Testing with Valid Credentials ...")
  test_that("Successful admin registration returns 201", {
    response <- account_register_request(base_url, "Test User", "admin@gmail.com", "admin", "admin")
    content <- content(response, as = "parsed", simplifyVector = TRUE)

    expect_equal(status_code(response), 201)
    expect_equal(content$status, "created")
    expect_equal(content$message, "User Registered Successfully")
  })

  test_that("Successful moderator registration returns 201", {
    response <- account_register_request(base_url, "Test User", "moderator@gmail.com", "moderator")
    content <- content(response, as = "parsed", simplifyVector = TRUE)

    expect_equal(status_code(response), 201)
    expect_equal(content$status, "created")
    expect_equal(content$message, "User Registered Successfully")
  })

  test_that("Duplicate email returns 409", {
    response <- account_register_request(base_url, "Test User", "admin@gmail.com", "admin")
    content <- content(response, as = "parsed", simplifyVector = TRUE)

    expect_equal(status_code(response), 409)
    expect_equal(content$status, "conflict")
    expect_equal(content$message, "Email must be unique. This email is already in use")
  })
}

test_account_login <- function(base_url) {
  message("Testing POST (/Account/login) ...")

  message("Testing with Invalid Input Types ...")

  test_that("If Password have invalid ASCII characters the API returns 400", {
    response <- account_login_request(base_url, "user@example.com", "Wrong💥Password")
    content <- content(response, as = "parsed", simplifyVector = TRUE)

    expect_equal(status_code(response), 400)
    expect_equal(content$status, "bad_request")
    expect_equal(content$message, "Invalid Password: Must be ASCII and below 72 characters")
    expect_equal(length(content$data$token), 0)
  })

  test_that("If values that aren't strings are passed the API returns 400", {
    not_a_string <- 1

    fields <- list(
      list(name = "Email", args = list(base_url, not_a_string, "a")),
      list(name = "Password", args = list(base_url, "user@example.com", not_a_string))
    )

    for (field in fields) {
      response <- do.call(account_login_request, field$args)
      content <- content(response, as = "parsed", simplifyVector = TRUE)

      expect_equal(status_code(response), 400, info = paste("Failed for field:", field$name))
      expect_equal(content$status, "bad_request", info = paste("Failed for field:", field$name))
      expect_equal(content$message, "Invalid Input Type", info = paste("Failed for field:", field$name))
      expect_equal(length(content$data$token), 0, info = paste("Failed for field:", field$name))
    }
  })

  test_that("Invalid UTF-8 characters in any field return 400", {
    invalid_utf8 <- rawToChar(as.raw(c(0xC0, 0x80)))

    fields <- list(
      list(name = "Email", args = list(base_url, invalid_utf8, "a")),
      list(name = "Password", args = list(base_url, "user@example.com", invalid_utf8))
    )

    for (field in fields) {
      response <- do.call(account_login_request, field$args)
      content <- content(response, as = "parsed", simplifyVector = TRUE)

      expect_equal(status_code(response), 400, info = paste("Failed for field:", field$name))
      expect_equal(content$status, "bad_request", info = paste("Failed for field:", field$name))
      expect_equal(content$message, "Invalid Input Type", info = paste("Failed for field:", field$name))
      expect_equal(length(content$data$token), 0, info = paste("Failed for field:", field$name))
    }
  })

  test_that("Email exceeding 100 characters returns 400", {
    long_email <- paste0(paste(rep("A", 101), collapse = ""), "@gmail.com")
    response <- account_login_request(base_url, long_email, "ValidPassword123")
    content <- content(response, as = "parsed", simplifyVector = TRUE)

    expect_equal(status_code(response), 400)
    expect_equal(content$status, "bad_request")
    expect_equal(content$message, "Invalid Email Pattern or exceeds 100 characters")
  })

  test_that("Password exceeding 72 characters returns 400", {
    long_password <- paste(rep("A", 73), collapse = "")
    response <- account_login_request(base_url, "user@example.com", long_password)
    content <- content(response, as = "parsed", simplifyVector = TRUE)

    expect_equal(status_code(response), 400)
    expect_equal(content$status, "bad_request")
    expect_equal(content$message, "Invalid Password: Must be ASCII and below 72 characters")
  })

  message("Testing with Missing Values ...")
  test_that("Sending Empty Email and Password the API returns 400", {
    response <- account_login_request(base_url, "", "")
    content <- content(response, as = "parsed", simplifyVector = TRUE)

    expect_equal(status_code(response), 400)
    expect_equal(content$status, "bad_request")
    expect_equal(content$message, "Email and Password are Required")
    expect_equal(length(content$data$token), 0)
  })

  test_that("Sending Whitespace Email and Password the API returns 400", {
    response <- account_login_request(base_url, "  ", "  ")
    content <- content(response, as = "parsed", simplifyVector = TRUE)

    expect_equal(status_code(response), 400)
    expect_equal(content$status, "bad_request")
    expect_equal(content$message, "Email and Password are Required")
    expect_equal(length(content$data$token), 0)
  })

  message("Testing with Invalid Patterns ...")
  test_that("If an Invalid Email Pattern is sent the API returns 400", {
    response <- account_login_request(base_url, "invalid-email", "ValidPassword123")
    content <- content(response, as = "parsed", simplifyVector = TRUE)

    expect_equal(status_code(response), 400)
    expect_equal(content$status, "bad_request")
    expect_equal(content$message, "Invalid Email Pattern or exceeds 100 characters")
    expect_equal(length(content$data$token), 0)
  })

  message("Testing with Valid Credentials ...")
  test_that("When admin Login is done a token is returned with 200", {
    response <- account_login_request(base_url, "admin@gmail.com", "admin")
    content <- content(response, as = "parsed", simplifyVector = TRUE)

    expect_equal(status_code(response), 200)
    expect_equal(content$status, "success")
    expect_equal(content$message, "Valid Credentials")
    expect_true(!is.null(content$data$token) && nchar(content$data$token) > 0)
  })

  test_that("When moderator Login is done a token is returned with 200", {
    response <- account_login_request(base_url, "moderator@gmail.com", "moderator")
    content <- content(response, as = "parsed", simplifyVector = TRUE)

    expect_equal(status_code(response), 200)
    expect_equal(content$status, "success")
    expect_equal(content$message, "Valid Credentials")
    expect_true(!is.null(content$data$token) && nchar(content$data$token) > 0)
  })

  test_that("When Valid Credentials coming from non registered User the API returns 404", {
    response <- account_login_request(base_url, "admin@gmail.com", "WrongPassword")
    content <- content(response, as = "parsed", simplifyVector = TRUE)

    expect_equal(status_code(response), 404)
    expect_equal(content$status, "not_found")
    expect_equal(content$message, "Invalid Credentials")
    expect_equal(length(content$data$token), 0)
  })
}
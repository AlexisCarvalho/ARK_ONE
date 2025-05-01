setwd("C:\\Users\\White\\Documents\\Fatec\\Github\\ARK_ONE\\ark-one-api")

source("tests/test_endpoint_account.R", chdir = TRUE)
source("tests/test_endpoint_products.R", chdir = TRUE)

library(testthat)
library(httr)
library(jsonlite)

# API Base URL
base_url <- "http://localhost:8000"

# +----------------------------+
# |   WITHOUT AUTHENTICATION   |
# +----------------------------+
# +-----------------+
# |     ACCOUNT     |
# +-----------------+

test_account_register(base_url)
test_account_login(base_url)

# +----------------------------+
# |   GET TOKEN BEFORE TESTS   |
# +----------------------------+

# Login with the already registered and tested admin user on the tests bellow
response <- account_login_request(base_url, "admin@gmail.com", "admin")
content <- content(response, as = "parsed", simplifyVector = TRUE)

admin_token <- content$data$token

# Login with the already registered and tested admin user on the tests bellow
response <- account_login_request(base_url, "moderator@gmail.com", "moderator")
content <- content(response, as = "parsed", simplifyVector = TRUE)

moderator_token <- content$data$token

# +----------------------------+
# |    WITH AUTHENTICATION     |
# +----------------------------+
# +-----------------+
# |     PRODUCT     |
# +-----------------+

test_product_register(base_url, admin_token)

test_product_search(base_url, moderator_token)

test_product_owned_register(base_url, moderator_token)
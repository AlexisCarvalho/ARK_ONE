# Necessary packages
required_packages <- c(
  "plumber", "jose", "digest", "data.table", "DBI", "RPostgres",
  "qcc", "e1071", "forecast", "isotree", "dbscan", "future",
  "parallel", "jsonlite", "ggplot2", "dplyr", "grid", "magrittr",
  "pool", "bcrypt", "uuid"
)

# Function to load quietly the packages and install the inexistent ones
ensure_package <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, dependencies = TRUE)
  }
  library(pkg, character.only = TRUE)
}

lapply(required_packages, ensure_package)

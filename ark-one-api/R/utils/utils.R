# Validate all fields inserted on the function (numeric)
validate_numeric_fields <- function(...) {
  fields <- list(...)
  field_names <- names(fields)

  for (i in seq_along(fields)) {
    if (!suppressWarnings(!is.na(as.numeric(fields[[i]])))) {
      return(list(
        status = "bad_request",
        message = paste(field_names[i], "must be a valid number")
      ))
    }
  }

  return(NULL) # If all fields are valid return NULL
}

# Validade all fields inserted on the function and convert to (numeric)
validate_and_convert_numeric_fields <- function(...) {
  fields <- list(...)
  field_names <- names(fields)
  converted_values <- list()

  for (i in seq_along(fields)) {
    num_value <- suppressWarnings(as.numeric(fields[[i]]))

    if (is.na(num_value)) {
      return(list(
        status = "bad_request",
        message = paste(field_names[i], "must be a valid number")
      ))
    }

    converted_values[[field_names[i]]] <- num_value
  }

  return(list(
    status = "success",
    data = converted_values
  ))
}

# Verifies if a input is a valid numeric
is_invalid_numeric <- function(input, min_val = -Inf, max_val = Inf) {
  if (!is.numeric(input) || is.null(input) || is.na(input)) {
    return(TRUE)
  }

  any(input < min_val || input > max_val)
}

# Verifies if a entry is utf-8 or not
is_invalid_utf8 <- function(input) {
  if (!is.character(input) || is.null(input) || is.na(input)) {
    return(TRUE)
  }

  any(!utf8::utf8_valid(input))
}

# Verifies if a entry is ascii or not
is_ascii <- function(input) {
  identical(input, iconv(input, to = "ASCII//TRANSLIT"))
}

# Function to verify if a input is missing or empty
is_blank_string <- function(input) {
  trimws(input) == ""
}
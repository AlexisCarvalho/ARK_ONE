# +-----------------------+
# |                       |
# |   STATISTICS SERVICE  |
# |                       |
# +-----------------------+

source("../services/solar_tracker_service.R", chdir = TRUE)
source("../models/statistics_model.R", chdir = TRUE)
source("../utils/response_handler.R", chdir = TRUE)
source("../utils/request_handler.R", chdir = TRUE)
source("../utils/utils.R", chdir = TRUE)

# +-----------------------+
# |    HELP FUNCTIONS     |
# +-----------------------+

calculate_correlation <- function(vector1, vector2) {
  if (is.null(vector1) || is.null(vector2) ||
      length(vector1) != length(vector2) || length(vector1) < 2) {
    return(list(
      status = "bad_request",
      message = "Invalid vectors. Ensure they have the same length and sufficient data points.",
      data = list(correlation = NULL)
    ))
  }

  corr_value <- cor(vector1, vector2, use = "complete.obs")

  list(
    status = "success",
    message = "Correlation successfully calculated.",
    data = list(correlation = corr_value)
  )
}

decompose_time_series <- function(series_data, frequency) {
  if (is.null(series_data) || length(series_data) < 2) {
    return(list(
      status = "bad_request",
      message = "Insufficient data points to decompose time series.",
      data = list(decomposition = NULL)
    ))
  }

  if (frequency <= 0) {
    return(list(
      status = "bad_request",
      message = "Invalid frequency. Must be a positive number.",
      data = list(decomposition = NULL)
    ))
  }

  if (any(is.na(series_data))) {
    return(list(
      status = "bad_request",
      message = "Series contains NA values. Please clean your data.",
      data = list(decomposition = NULL)
    ))
  }

  if (length(series_data) < frequency) {
    return(list(
      status = "bad_request",
      message = "Not enough data points for the specified frequency.",
      data = list(decomposition = NULL)
    ))
  }

  ts_data <- ts(series_data, frequency = frequency)
  decomposed_data <- decompose(ts_data)

  list(
    status = "success",
    message = "Time series decomposition successfully generated.",
    data = list(
      trend = decomposed_data$trend,
      seasonal = decomposed_data$seasonal,
      random = decomposed_data$random
    )
  )
}

# +-------------------------+
# |       STATISTICS        |
# +-------------------------+

get_esp32_summary_today <- function(esp32_unique_id) {
  if (is_invalid_utf8(esp32_unique_id) || !is.character(esp32_unique_id) || nchar(esp32_unique_id) == 0) {
    return(list(
      status = "bad_request",
      message = "Missing or Invalid esp32_unique_id",
      data = list(summary = NULL)
    ))
  }

  esp32_data <- tryCatch(
    fetch_esp32_data_today_by_esp32(esp32_unique_id),
    error = function(e) e
  )

  if (inherits(esp32_data, "error")) {
    return(list(
      status = "internal_server_error",
      message = paste("Unexpected Error:", esp32_data$message),
      data = list(summary = NULL)
    ))
  }

  if (!is.data.frame(esp32_data) || nrow(esp32_data) == 0) {
    return(list(
      status = "not_found",
      message = "No ESP32 data found for this ESP32 today",
      data = list(summary = NULL)
    ))
  }

  parsed_common <- lapply(esp32_data$common_data, fromJSON)
  voltages <- as.numeric(sapply(parsed_common, function(x) x$voltage))
  currents <- as.numeric(sapply(parsed_common, function(x) x$current))

  wattages <- voltages * currents
  mean_wattage <- mean(wattages)

  data_summary <- data.frame(
    MeanVoltages = mean(voltages),
    MedianVoltages = median(voltages),
    SDVoltages = sd(voltages),
    IQRVoltages = IQR(voltages),
    SkewnessVoltages = skewness(voltages),
    KurtosisVoltages = kurtosis(voltages),
    MeanCurrents = mean(currents),
    MedianCurrents = median(currents),
    SDCurrent = sd(currents),
    IQRCurrents = IQR(currents),
    SkewnessCurrents = skewness(currents),
    KurtosisCurrents = kurtosis(currents),
    MeanWattage = mean_wattage
  )

  list(
    status = "success",
    message = "ESP32 data summary successfully generated",
    data = list(summary = data_summary)
  )
}

get_solar_tracker_mem_volt_curr_correlation <- function(id_product_instance) {
  if (is_invalid_utf8(id_product_instance) || !UUIDvalidate(id_product_instance)) {
    return(list(
      status = "bad_request",
      message = "Missing or Invalid Product ID",
      data = list(category = NULL)
    ))
  }

  solar_tracker_data <- get_data_by_instance_from_memory(id_product_instance)

  if (!is.data.table(solar_tracker_data) || nrow(solar_tracker_data) == 0) {
    return(list(
      status = "not_found",
      message = "There isn't any data with this id in the memory",
      data = list(category = NULL)
    ))
  }

  calculate_correlation(solar_tracker_data$voltage, solar_tracker_data$current)
}

get_solar_tracker_mem_volt_trend_detection <- function(id_product_instance, frequency) {
  if (is_invalid_utf8(id_product_instance) || !UUIDvalidate(id_product_instance)) {
    return(list(
      status = "bad_request",
      message = "Missing or Invalid Product ID",
      data = list(category = NULL)
    ))
  }

  validation_result <- validate_and_convert_numeric_fields(
    converted_frequency = frequency
  )

  if (validation_result$status != "success") {
    return(validation_result)
  }

  solar_tracker_data <- get_data_by_instance_from_memory(id_product_instance)

  if (!is.data.table(solar_tracker_data) || nrow(solar_tracker_data) == 0) {
    return(list(
      status = "not_found",
      message = "There isn't any data with this id in the memory",
      data = list(category = NULL)
    ))
  }

  with(validation_result$data,
    decompose_time_series(solar_tracker_data$voltage, converted_frequency)
  )
}

get_esp32_weekly_minmax <- function(esp32_unique_id) {
  if (is_invalid_utf8(esp32_unique_id) || !is.character(esp32_unique_id) || nchar(esp32_unique_id) == 0) {
    return(list(
      status = "bad_request",
      message = "Missing or Invalid esp32_unique_id",
      data = list(weekly = NULL)
    ))
  }

  result <- tryCatch(
    fetch_esp32_weekly_minmax_by_esp32(esp32_unique_id),
    error = function(e) e
  )

  if (inherits(result, "error")) {
    return(list(
      status = "internal_server_error",
      message = paste("Unexpected Error:", result$message),
      data = list(weekly = NULL)
    ))
  }

  if (!is.data.frame(result) || nrow(result) == 0) {
    return(list(
      status = "not_found",
      message = "No weekly min/max data found for this ESP32",
      data = list(weekly = NULL)
    ))
  }

  # ensure proper types
  result$day_date <- as.character(result$day_date)
  result$min_voltage <- as.numeric(result$min_voltage)
  result$max_voltage <- as.numeric(result$max_voltage)
  result$min_current <- as.numeric(result$min_current)
  result$max_current <- as.numeric(result$max_current)

  list(
    status = "success",
    message = "Weekly min/max data successfully retrieved",
    data = list(weekly = result)
  )
}
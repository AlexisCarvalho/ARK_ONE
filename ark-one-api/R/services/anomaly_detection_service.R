# +----------------------------+
# |  ANOMALY DETECTION SERVICE |
# +----------------------------+

source("../services/solar_tracker_service.R", chdir = TRUE)
source("../models/statistics_model.R", chdir = TRUE)
source("../utils/response_handler.R", chdir = TRUE)
source("../utils/request_handler.R", chdir = TRUE)
source("../utils/utils.R", chdir = TRUE)

# +-----------------------+
# |    HELP FUNCTIONS     |
# +-----------------------+

calculate_zscore_outliers <- function(values) {
  if (is.null(values) || length(values) < 2) {
    return(list(
      status = "bad_request",
      message = "Not enough data points to calculate Z-scores.",
      data = list(outliers = NULL)
    ))
  }

  z_scores <- scale(values)
  outliers <- which(abs(z_scores) > 3)

  list(
    status = "success",
    message = "Z-score outliers detected successfully.",
    data = list(outliers = outliers, values = values[outliers])
  )
}

calculate_iqr_outliers <- function(values) {
  if (is.null(values) || length(values) < 2) {
    return(list(
      status = "bad_request",
      message = "Not enough data points to calculate IQR.",
      data = list(outliers = NULL)
    ))
  }

  Q1 <- quantile(values, 0.25)
  Q3 <- quantile(values, 0.75)
  IQR_value <- IQR(values)

  lower_bound <- Q1 - 1.5 * IQR_value
  upper_bound <- Q3 + 1.5 * IQR_value
  outliers <- which(values < lower_bound | values > upper_bound)

  list(
    status = "success",
    message = "IQR outliers detected successfully.",
    data = list(outliers = outliers, values = values[outliers])
  )
}

calculate_mad_outliers <- function(values, threshold = 3) {
  if (is.null(values) || length(values) < 2 || is.na(threshold)) {
    return(list(
      status = "bad_request",
      message = "Invalid data or threshold.",
      data = list(outliers = NULL)
    ))
  }

  med <- median(values, na.rm = TRUE)
  mad_value <- mad(values, na.rm = TRUE)
  lower_bound <- med - threshold * mad_value
  upper_bound <- med + threshold * mad_value
  outliers <- values[values < lower_bound | values > upper_bound]

  list(
    status = "success",
    message = "MAD outliers detected successfully.",
    data = list(outliers = outliers, lower_bound = lower_bound, upper_bound = upper_bound)
  )
}

calculate_lof_anomalies <- function(values, k = 5) {
  if (is.null(values) || length(values) < k + 1 || is.na(k) || k < 1) {
    return(list(
      status = "bad_request",
      message = "Invalid data or parameter 'k'.",
      data = list(anomalies = NULL)
    ))
  }

  lof_scores <- lof(matrix(values, ncol = 1), k)
  anomalies <- values[lof_scores > quantile(lof_scores, 0.95)]

  list(
    status = "success",
    message = "LOF anomalies detected successfully.",
    data = list(lof_scores = lof_scores, anomalies = anomalies)
  )
}

calculate_isolation_forest_anomalies <- function(values, contamination = 0.1) {
  if (is.null(values) || length(values) < 2 || is.na(contamination) || contamination < 0 || contamination > 1) {
    return(list(
      status = "bad_request",
      message = "Invalid data or contamination parameter.",
      data = list(anomalies = NULL)
    ))
  }

  iso_forest <- isolation.forest(data.frame(values), ntrees = 100, sample_size = min(256, length(values)), nthreads = 2)
  scores <- predict(iso_forest, data.frame(values), type = "score")
  anomalies <- values[scores > quantile(scores, (1 - contamination))]

  list(
    status = "success",
    message = "Isolation Forest anomalies detected successfully.",
    data = list(anomalies = anomalies, scores = scores)
  )
}

calculate_cusum_anomalies <- function(values) {
  if (is.null(values) || length(values) < 2) {
    return(list(
      status = "bad_request",
      message = "Not enough data points for CUSUM analysis.",
      data = list(anomalies = NULL)
    ))
  }

  cusum_chart <- cusum(values)
  anomalies <- cusum_chart$decision[cusum_chart$decision != 0]

  list(
    status = "success",
    message = "CUSUM anomalies detected successfully.",
    data = list(anomalies = anomalies, decision = cusum_chart$decision,
                upper_limit = cusum_chart$upper, lower_limit = cusum_chart$lower)
  )
}

# +------------------------+
# |   ANOMALY DETECTION    |
# +------------------------+

get_solar_tracker_mem_voltage_zscore_outliers <- function(id_product_instance) {
  if (is_invalid_utf8(id_product_instance) || !UUIDvalidate(id_product_instance)) {
    return(list(
      status = "bad_request",
      message = "Missing or Invalid Product ID",
      data = list(outliers = NULL)
    ))
  }

  data <- get_data_by_instance_from_memory(id_product_instance)
  if (!is.data.table(data) || nrow(data) == 0) {
    return(list(
      status = "not_found",
      message = "No data found in memory for this Product ID",
      data = list(outliers = NULL)
    ))
  }

  calculate_zscore_outliers(data$voltage)
}

get_solar_tracker_mem_voltage_iqr_outliers <- function(id_product_instance) {
  if (is_invalid_utf8(id_product_instance) || !UUIDvalidate(id_product_instance)) {
    return(list(
      status = "bad_request",
      message = "Missing or Invalid Product ID",
      data = list(outliers = NULL)
    ))
  }

  data <- get_data_by_instance_from_memory(id_product_instance)
  if (!is.data.table(data) || nrow(data) == 0) {
    return(list(
      status = "not_found",
      message = "No data found in memory for this Product ID",
      data = list(outliers = NULL)
    ))
  }

  calculate_iqr_outliers(data$voltage)
}

get_solar_tracker_mem_voltage_mad_outliers <- function(id_product_instance, threshold = 3) {
  if (is_invalid_utf8(id_product_instance) || !UUIDvalidate(id_product_instance)) {
    return(list(
      status = "bad_request",
      message = "Missing or Invalid Product ID",
      data = list(outliers = NULL)
    ))
  }

  data <- get_data_by_instance_from_memory(id_product_instance)
  if (!is.data.table(data) || nrow(data) == 0) {
    return(list(
      status = "not_found",
      message = "No data found in memory for this Product ID",
      data = list(outliers = NULL)
    ))
  }

  values <- data$voltage
  threshold <- as.numeric(threshold)

  if (is.null(values) || length(values) < 2 || is.na(threshold)) {
    return(list(
      status = "bad_request",
      message = "Invalid data or threshold.",
      data = list(outliers = NULL)
    ))
  }

  calculate_mad_outliers(values, threshold)
}

get_solar_tracker_mem_voltage_lof_anomalies <- function(id_product_instance, k = 5) {
  if (is_invalid_utf8(id_product_instance) || !UUIDvalidate(id_product_instance)) {
    return(list(
      status = "bad_request",
      message = "Missing or Invalid Product ID",
      data = list(anomalies = NULL)
    ))
  }

  data <- get_data_by_instance_from_memory(id_product_instance)
  if (!is.data.table(data) || nrow(data) == 0) {
    return(list(
      status = "not_found",
      message = "No data found in memory for this product instance",
      data = list(anomalies = NULL)
    ))
  }

  values <- data$voltage
  k <- as.numeric(k)

  if (is.null(values) || length(values) < k + 1 || is.na(k) || k < 1) {
    return(list(
      status = "bad_request",
      message = "Invalid data or parameter 'k'.",
      data = list(anomalies = NULL)
    ))
  }

  calculate_lof_anomalies(values, k)
}

get_solar_tracker_mem_voltage_isolation_forest_anomalies <- function(id_product_instance, contamination = 0.1) {
  if (is_invalid_utf8(id_product_instance) || !UUIDvalidate(id_product_instance)) {
    return(list(
      status = "bad_request",
      message = "Missing or Invalid Product ID",
      data = list(anomalies = NULL)
    ))
  }

  data <- get_data_by_instance_from_memory(id_product_instance)
  if (!is.data.table(data) || nrow(data) == 0) {
    return(list(
      status = "not_found",
      message = "No data found in memory for this Product ID",
      data = list(anomalies = NULL)
    ))
  }

  values <- data$voltage
  contamination <- as.numeric(contamination)

  if (is.null(values) || length(values) < 2 || is.na(contamination) || contamination < 0 || contamination > 1) {
    return(list(
      status = "bad_request",
      message = "Invalid data or contamination parameter.",
      data = list(anomalies = NULL)
    ))
  }

  calculate_isolation_forest_anomalies(values, contamination)
}

get_solar_tracker_mem_voltage_cusum_anomalies <- function(id_product_instance) {
  if (is_invalid_utf8(id_product_instance) || !UUIDvalidate(id_product_instance)) {
    return(list(
      status = "bad_request",
      message = "Missing or Invalid Product ID",
      data = list(anomalies = NULL)
    ))
  }

  data <- get_data_by_instance_from_memory(id_product_instance)
  if (!is.data.table(data) || nrow(data) == 0) {
    return(list(
      status = "not_found",
      message = "No data found in memory for this Product ID",
      data = list(anomalies = NULL)
    ))
  }

  values <- data$voltage
  if (is.null(values) || length(values) < 2) {
    return(list(
      status = "bad_request",
      message = "Not enough data points for CUSUM analysis.",
      data = list(anomalies = NULL)
    ))
  }

  calculate_cusum_anomalies(values)
}
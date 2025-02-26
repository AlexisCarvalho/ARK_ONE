# +-----------------+
# |                 |
# |   STATISTICS    |
# |                 |
# +-----------------+

source("../services/solar_panel_service.R", chdir = TRUE)

# Needs revision

#* Returns an extended summary of descriptive statistics for the Vcc column in T1
#* @response 200 A detailed statistical summary including mean, median, SD, IQR, skewness, and kurtosis
#* @response 400 Missing parameters
#* @response 404 If there is no data is invalid or empty
#* @description This endpoint provides an extended statistical summary.
#* @tag Statistics
#* @param id_product_instance
#* @get /summary
function(res, id_product_instance) {
  if (is.null(id_product_instance)) {
    res$status <- 400
    return(list(status = "error", message = "The product instance id cannot be null"))
  }
  id_product_instance <- as.numeric(id_product_instance)

  response <- get_esp32_data_today(id_product_instance)

  if (nrow(response) == 0) {
    res$status <- 404
    return(list(status = "error", message = "Database is empty, no data to analyze."))
  }

  voltages <- response$voltage
  currents <- response$current
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

  res$status <- 200
  return(list(status = "success", data = data_summary))
}

#* Returns the Pearson correlation coefficient between Vcc and Curr columns in T1
#* @response 200 The correlation between the two variables
#* @response 400 If T1 is invalid or empty
#* @description This endpoint calculates the Pearson correlation coefficient between Vcc and Curr columns in T1.
#* @tag Statistics
#* @get /correlation
function() {
  if (nrow(T1) == 0) {
    res$status <- 400
    return(list(error = "T1 is empty, no data to analyze."))
  }

  parameter1 <- T1$Vcc
  parameter2 <- T1$Curr

  if (length(parameter1) != length(parameter2)) {
    res$status <- 400
    return(list(error = "Invalid data. Ensure both columns have the same length."))
  }

  corr_value <- cor(parameter1, parameter2, use = "complete.obs")

  return(list(Correlation = corr_value))
}

#* Returns the decomposition of the time series into trend, seasonal, and random components based on Vcc values in T1
#* @response 200 The time series decomposition of the values (Trend, Seasonal, Random)
#* @response 400 If the time series data or frequency is invalid
#* @description This endpoint decomposes time series data into its trend, seasonal, and random components based on Vcc values in T1.
#* @tag Statistics
#* @param frequency The frequency of the time series (e.g., 12 for monthly data)
#* @get /trend_detection
function(frequency) {
  if (nrow(T1) == 0) {
    res$status <- 400
    return(list(error = "T1 is empty, no data to analyze."))
  }

  parameter <- T1$Vcc

  frequency <- as.numeric(frequency)

  if (is.na(frequency) || frequency <= 0) {
    res$status <- 400
    return(list(error = "Invalid frequency. Please provide a valid numeric frequency greater than zero."))
  }

  if (any(is.na(parameter))) {
    res$status <- 400
    return(list(error = "The Vcc column contains NA values. Please clean your data."))
  }

  if (length(parameter) < frequency) {
    res$status <- 400
    return(list(error = "Not enough data points for the specified frequency."))
  }

  ts_data <- ts(parameter, frequency = frequency)

  decomposed_data <- decompose(ts_data)

  return(list(Trend = decomposed_data$trend, Seasonal = decomposed_data$seasonal, Random = decomposed_data$random))
}

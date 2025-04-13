# +-----------------------+
# |                       |
# |   STATISTICS SERVICE  |
# |                       |
# +-----------------------+

source("../models/statistics_model.R", chdir = TRUE)
source("../utils/response_handler.R", chdir = TRUE)
source("../utils/request_handler.R", chdir = TRUE)
source("../utils/utils.R", chdir = TRUE)

get_esp32_summary_today_by_instance <- function(id_product_instance) {
  if (is.null(id_product_instance)) {
    return(list(
      status = "bad_request",
      message = "The product instance id cannot be null",
      data = list(summary = NULL)
    ))
  }

  result <- tryCatch(
    fetch_esp32_data_today_by_instance(id_product_instance),
    error = function(e) {
      return(list(
        status = "internal_server_error",
        message = paste("Unexpected Error:", e$message),
        data = list(summary = NULL)
      ))
    }
  )

  if (!is.data.frame(result) || nrow(result) == 0) {
    return(list(
      status = "not_found",
      message = "No ESP32 data found for this product instance today",
      data = list(summary = NULL)
    ))
  }

  # Parse campos common_data JSON e extrai como numérico
  parsed_common <- lapply(result$common_data, fromJSON)
  voltages <- as.numeric(sapply(parsed_common, function(x) x$voltage))
  currents <- as.numeric(sapply(parsed_common, function(x) x$current))

  # Cálculo dos watts
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

  return(list(
    status = "success",
    message = "ESP32 data summary successfully generated",
    data = list(summary = data_summary)
  ))
}
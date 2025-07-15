# +-----------------+
# |                 |
# |   STATISTICS    |
# |                 |
# +-----------------+

source("../services/statistics_service.R", chdir = TRUE)
source("../utils/response_handler.R", chdir = TRUE)

#* Returns an extended summary of descriptive statistics for the voltage and current column in solar tracker
#* @description This endpoint provides an extended statistical summary.
#* @tag Statistics
#* @param id_product_instance
#* @get solar_tracker/today/summary
#* @response 200 A detailed statistical summary including mean, median, SD, IQR, skewness, and kurtosis
#* @response 400 Missing parameters
#* @response 404 If there is no data is invalid or empty
#* @response 500 Internal Server Error
function(res, id_product_instance) {
  send_http_response(res, get_esp32_summary_today(id_product_instance))
}

#* Get correlation between Voltage and Current
#* @tag Statistics
#* @param id_product_instance
#* @get solar_tracker/memory/voltage_current/correlation
#* @response 200 OK
#* @response 400 Bad Request
#* @response 500 Internal Server Error
function(res, id_product_instance) {
  send_http_response(res, get_solar_tracker_mem_volt_curr_correlation(id_product_instance))
}

#* Get trend decomposition
#* @tag Statistics
#* @param id_product_instance
#* @param frequency
#* @get solar_tracker/memory/voltage/trend_detection
#* @response 200 OK
#* @response 400 Bad Request
#* @response 500 Internal Server Error
function(res, id_product_instance, frequency) {
  send_http_response(res, get_solar_tracker_mem_volt_trend_detection(id_product_instance, frequency))
}
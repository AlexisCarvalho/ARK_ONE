# +-----------------------+
# |                       |
# |   ANOMALY DETECTION   |
# |                       |
# +-----------------------+

source("../services/anomaly_detection_service.R", chdir = TRUE)
source("../utils/response_handler.R", chdir = TRUE)

#* Returns a list of outliers based on Z-scores
#* @response 200 A list of outliers based on the Z-score method
#* @response 400 If the data in memory is invalid or empty
#* @description This endpoint detects outliers using the Z-score method.
#* @tag AnomalyDetection
#* @post solar_tracker/memory/voltage/zscore_outliers
function(res, req, id_product_instance) {
  send_http_response(res, get_solar_tracker_mem_voltage_zscore_outliers(id_product_instance))
}

#* Returns a list of outliers based on the IQR method
#* @response 200 A list of outliers based on the IQR method
#* @response 400 If the data in memory is invalid or empty
#* @description This endpoint detects outliers using the IQR method.
#* @tag AnomalyDetection
#* @post solar_tracker/memory/voltage/iqr_outliers
function(res, req, id_product_instance) {
  send_http_response(res, get_solar_tracker_mem_voltage_iqr_outliers(id_product_instance))
}

#* Returns outliers detected using the MAD method
#* @response 200 MAD-based outliers, with thresholds
#* @response 400 If the data in memory is invalid or empty
#* @description This endpoint detects anomalies using the MAD method.
#* @tag AnomalyDetection
#* @get solar_tracker/memory/voltage/mad_outliers
function(res, req, id_product_instance, threshold = 3) {
  send_http_response(res, get_solar_tracker_mem_voltage_mad_outliers(id_product_instance, threshold))
}

#* Returns local outlier factor (LOF) scores and identifies anomalies
#* @response 200 LOF scores and anomalies
#* @response 400 If the data in memory is invalid or empty
#* @description This endpoint calculates LOF scores for the voltage values.
#* @tag AnomalyDetection
#* @get solar_tracker/memory/voltage/lof_anomalies
function(res, req, id_product_instance, k = 5) {
  send_http_response(res, get_solar_tracker_mem_voltage_lof_anomalies(id_product_instance, k))
}

#* Returns anomalies detected using Isolation Forest
#* @response 200 Anomalies detected using Isolation Forest
#* @response 400 If the data in memory is invalid or empty
#* @description This endpoint uses the Isolation Forest algorithm to detect anomalies.
#* @tag AnomalyDetection
#* @get solar_tracker/memory/voltage/isolation_forest
function(res, req, id_product_instance, contamination = 0.1) {
  send_http_response(res, get_solar_tracker_mem_voltage_isolation_forest_anomalies(id_product_instance, contamination))
}

#* Returns anomalies detected using the CUSUM method
#* @response 200 CUSUM-based anomalies and shifts in the data
#* @response 400 If the data in memory is invalid or empty
#* @description This endpoint detects anomalies using the CUSUM method.
#* @tag AnomalyDetection
#* @get solar_tracker/memory/voltage/cusum_anomalies
function(res, req, id_product_instance) {
  send_http_response(res, get_solar_tracker_mem_voltage_cusum_anomalies(id_product_instance))
}

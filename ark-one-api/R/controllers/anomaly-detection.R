# +-----------------------+
# |                       |
# |   ANOMALY DETECTION   |
# |                       |
# +-----------------------+

source("../services/solar_panel_service.R", chdir = TRUE)

#* Returns a list of outliers based on Z-scores
#* @response 200 A list of outliers based on the Z-score method
#* @response 400 If the data in T1 is invalid or empty
#* @description This endpoint detects outliers using the Z-score method from T1. Any data point with an absolute Z-score greater than 3 is flagged as an outlier.
#* @tag AnomalyDetection
#* @post /voltage/zscore_outliers
function(req, res) {
  if (nrow(recently_received_solar_panel_data) == 0) {
    res$status <- 400
    return(list(error = "recently_received_solar_panel_data is empty, no data to analyze."))
  }
  
  data <- recently_received_solar_panel_data$voltage  
  
  if (length(data) < 2) {
    res$status <- 400
    return(list(error = "Not enough data points to calculate Z-scores."))
  }
  
  z_scores <- scale(data)
  outliers <- which(abs(z_scores) > 1)
  
  res$status <- 200
  return(list(Outliers = outliers, Values = data[outliers]))
}

#* Returns a list of outliers based on the IQR method
#* @response 200 A list of outliers based on the IQR method
#* @response 400 If the data in T1 is invalid or empty
#* @description This endpoint detects outliers using the IQR method from T1.
#* @tag AnomalyDetection
#* @post /vcc/iqr_outliers
function(req, res) {
  if (nrow(T1) == 0) {
    res$status <- 400
    return(list(error = "T1 is empty, no data to analyze."))
  }
  
  data <- T1$Vcc  
  
  if (length(data) < 2) {
    res$status <- 400
    return(list(error = "Not enough data points to calculate IQR."))
  }
  
  Q1 <- quantile(data, 0.25)
  Q3 <- quantile(data, 0.75)
  IQR_value <- IQR(data)
  
  lower_bound <- Q1 - 1.5 * IQR_value
  upper_bound <- Q3 + 1.5 * IQR_value
  
  outliers <- which(data < lower_bound | data > upper_bound)
  
  return(list(Outliers = outliers, Values = data[outliers]))
}

#* Returns outliers detected using the MAD method
#* @response 200 MAD-based outliers, with thresholds
#* @response 400 If T1 is empty or invalid
#* @description This endpoint detects anomalies using the MAD method from T1.
#* @tag AnomalyDetection
#* @get /vcc/mad_outliers
function(threshold = 3) {
  if (nrow(T1) == 0) {
    res$status <- 400
    return(list(error = "T1 is empty, no data to analyze."))
  }
  
  parameter <- T1$Vcc 
  
  threshold <- as.numeric(threshold)
  
  if (is.na(threshold)) {
    res$status <- 400
    return(list(error = "Threshold must be a numeric value."))
  }
  
  if (length(parameter) < 2 || any(is.na(parameter))) {
    res$status <- 400
    return(list(error = "Not enough valid data points to calculate MAD."))
  }
  
  med <- median(parameter, na.rm = TRUE)
  mad_value <- mad(parameter, na.rm = TRUE)
  
  lower_bound <- med - threshold * mad_value
  upper_bound <- med + threshold * mad_value
  
  outliers_mad <- parameter[parameter < lower_bound | parameter > upper_bound]
  
  return(list(MADOutliers = outliers_mad, LowerBound = lower_bound, UpperBound = upper_bound))
}
#* Returns local outlier factor (LOF) scores and identifies anomalies based on Vcc values in T1.
#* @response 200 LOF scores and anomalies based on T1 data
#* @response 400 If T1 is empty or invalid
#* @description This endpoint calculates LOF scores for the Vcc values in T1.
#* @tag AnomalyDetection
#* @get /vcc/lof_anomalies
function(k = 5) {
  if (nrow(T1) == 0) {
    res$status <- 400 
    return(list(error = "T1 is empty, no data to analyze.")) 
  }
  
  parameter <- T1$Vcc
  
  k <- as.numeric(k)
  
  if (is.na(k) || k < 1) {
    res$status <- 400 
    return(list(error = "Parameter 'k' must be a positive integer.")) 
  }
  
  if (length(parameter) < k + 1) {
    res$status <- 400 
    return(list(error = "Not enough data points to calculate LOF.")) 
  }
  
  lof_scores <- lof(matrix(parameter, ncol = 1), k)
  
  anomalies <- parameter[lof_scores > quantile(lof_scores, .95)] 
  
  return(list(LOFScores = lof_scores, Anomalies = anomalies))
}

#* Returns anomalies detected using Isolation Forest from T1 data.
#* @response 200 Anomalies detected using Isolation Forest from T1 data.
#* @response 400 If T1 is empty or invalid.
#* @description This endpoint uses the Isolation Forest algorithm to detect anomalies in the Vcc values from T1.
#* @tag AnomalyDetection
#* @get /vcc/isolation_forest
function(contamination = 0.1) {
  if (nrow(T1) == 0) {
    res$status <- 400 
    return(list(error = "T1 is empty, no data to analyze.")) 
  }
  
  parameter <- T1$Vcc 
  
  contamination <- as.numeric(contamination)
  
  if (is.na(contamination) || contamination < 0 || contamination > 1) {
    res$status <- 400 
    return(list(error = "Parameter 'contamination' must be a numeric value between 0 and 1.")) 
  }
  
  if (length(parameter) < min(256, nrow(T1))) {
    res$status <- 400 
    return(list(error = "Not enough data points for Isolation Forest.")) 
  }
  
  iso_forest <- isolation.forest(data.frame(parameter), ntrees =100, sample_size=min(256,nrow(T1)), nthreads=2)
  
  predictions <- predict(iso_forest, data.frame(parameter), type="score")
  
  anomalies <- parameter[predictions > quantile(predictions, (1 - contamination))]
  
  return(list(Anomalies = anomalies, Scores = predictions))
}

#* Returns anomalies detected using the CUSUM method on Vcc values in T1.
#* @response 200 CUSUM-based anomalies and shifts in the data from T1.
#* @response 400 If T1 is empty or invalid.
#* @description This endpoint detects anomalies by using the CUSUM method on Vcc values in T1.
#* @tag AnomalyDetection
#* @get /vcc/cusum_anomalies
function() {
  if (nrow(T1) == 0) {
    res$status <- 400 
    return(list(error = "T1 is empty, no data to analyze.")) 
  }
  
  parameter <- T1$Vcc
  
  if (length(parameter) < 2) {
    res$status <- 400 
    return(list(error = "Not enough data points for CUSUM analysis.")) 
  }
  
  cusum_chart <- cusum(parameter)
  
  anomalies <- cusum_chart$decision[cusum_chart$decision != 0]
  
  result <- list(
    Anomalies = anomalies,
    Decision = cusum_chart$decision, 
    UpperLimit = cusum_chart$upper,   
    LowerLimit = cusum_chart$lower     
  )
  
  return(result)
}
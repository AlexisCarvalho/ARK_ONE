# +-----------------+
# |                 |
# |   TIME SERIES   |
# |                 |
# +-----------------+

#* Returns the decomposition of the time series into trend, seasonal, and random components based on Vcc in T1
#* @response 200 The time series decomposition of the values (Trend, Seasonal, Random)
#* @response 400 If the frequency is invalid or T1 is empty
#* @description This endpoint decomposes the Vcc column in T1 into trend, seasonal, and random components.
#* @tag TimeSeries
#* @param frequency The frequency of the time series (e.g., 12 for monthly data)
#* @post /time_series
function(req, res) {
  frequency <- as.numeric(req$parameters$frequency)
  
  if (nrow(T1) == 0) {
    res$status <- 400
    return(list(error = "T1 is empty, no data to analyze."))
  }
  
  data <- T1$Vcc 
  
  if (is.na(frequency) || frequency <= 0) {
    res$status <- 400
    return(list(error = "Invalid frequency. Please provide a valid numeric frequency greater than zero."))
  }
  
  if (any(is.na(data))) {
    res$status <- 400
    return(list(error = "The Vcc column contains NA values. Please clean your data."))
  }
  
  if (length(data) < frequency) {
    res$status <- 400
    return(list(error = "Not enough data points for the specified frequency."))
  }
  
  ts_data <- ts(data, frequency = frequency)
  decomposed_data <- decompose(ts_data)
  
  return(list(Trend = decomposed_data$trend,
              Seasonal = decomposed_data$seasonal,
              Random = decomposed_data$random))
}

#* Returns ARIMA-based forecast for the Vcc column in T1
#* @response 200 ARIMA forecast for the next specified periods
#* @response 400 If the parameters are invalid or T1 is empty
#* @description This endpoint performs ARIMA forecasting on the Vcc column in T1.
#* @tag TimeSeries
#* @param frequency The frequency of the time series (e.g., 12 for monthly data)
#* @param periods The number of future periods to forecast
#* @get /arima_forecast
function(frequency, periods = 12) {
  if (nrow(T1) == 0) {
    res$status <- 400
    return(list(error = "T1 is empty, no data to analyze."))
  }
  
  data <- T1$Vcc 
  
  frequency <- as.numeric(frequency)
  periods <- as.numeric(periods)
  
  if (is.na(frequency) || frequency <= 0 || is.na(periods) || periods <= 0) {
    res$status <- 400
    return(list(error = "Invalid data. Please provide valid numeric frequency and periods greater than zero."))
  }
  
  if (any(is.na(data))) {
    res$status <- 400
    return(list(error = "The Vcc column contains NA values. Please clean your data."))
  }
  
  ts_data <- ts(data, frequency = frequency)
  
  fit <- auto.arima(ts_data)
  
  forecast_data <- forecast(fit, h = periods)
  
  return(list(Forecast = forecast_data$mean, Lower = forecast_data$lower, Upper = forecast_data$upper))
}

#* Returns ETS (Exponential Smoothing) forecast for the Vcc column in T1
#* @response 200 ETS forecast for the next specified periods
#* @response 400 If the parameters are invalid or T1 is empty
#* @description This endpoint applies Exponential Smoothing (ETS) forecasting to the Vcc column in T1.
#* @tag TimeSeries
#* @param frequency The frequency of the time series (e.g., 12 for monthly data)
#* @param periods The number of future periods to forecast
#* @get /ets_forecast
function(frequency, periods = 12) {
  if (nrow(T1) == 0) {
    res$status <- 400
    return(list(error = "T1 is empty, no data to analyze."))
  }
  
  data <- T1$Vcc 
  
  frequency <- as.numeric(frequency)
  periods <- as.numeric(periods)
  
  if (is.na(frequency) || frequency <= 0 || is.na(periods) || periods <= 0) {
    res$status <- 400
    return(list(error = "Invalid data. Please provide valid numeric frequency and periods greater than zero."))
  }
  
  if (any(is.na(data))) {
    res$status <- 400
    return(list(error = "The Vcc column contains NA values. Please clean your data."))
  }
  
  ts_data <- ts(data, frequency = frequency)
  
  fit <- ets(ts_data)
  
  forecast_data <- forecast(fit, h = periods)
  
  return(list(Forecast = forecast_data$mean, Lower = forecast_data$lower, Upper = forecast_data$upper))
}

#* Returns STL decomposition of the Vcc column in T1 into seasonal, trend, and residual components
#* @response 200 STL decomposition with seasonal, trend, and residual components
#* @response 400 If the parameters are invalid or T1 is empty
#* @description This endpoint applies Seasonal-Trend decomposition using LOESS (STL) to the Vcc column in T1.
#* @tag TimeSeries
#* @param frequency The frequency of the time series (e.g., 12 for monthly data)
#* @get /stl_decomposition
function(frequency) {
  if (nrow(T1) ==0){
    res$status<-400 
    return(list(error="T1 is empty, no data to analyze.")) 
  }
  
  data<-T1$Vcc 
  
  frequency <- as.numeric(frequency)
  
  if (is.na(frequency) || frequency <=0){
    res$status<-400 
    return(list(error="Invalid data. Please provide a valid numeric frequency greater than zero.")) 
  }
  
  if(any(is.na(data))) {
    res$status<-400 
    return(list(error="The Vcc column contains NA values. Please clean your data.")) 
  }
  
  ts_data<-ts(data,frequency=frequency)
  
  stl_data<-stl(ts_data,s.window="periodic")
  
  return(list(Seasonal=stl_data$time.series[,"seasonal"], Trend=stl_data$time.series[,"trend"], Residual=stl_data$time.series[,"remainder"]))
}

#* Returns the autocorrelation (ACF) and partial autocorrelation (PACF) functions of the Vcc column in T1
#* @response 200 ACF and PACF values for the time series based on Vcc in T1
#* @response 400 If the time series data is invalid or T1 is empty
#* @description This endpoint calculates the ACF and PACF of the Vcc column in T1.
#* @tag TimeSeries
#* @param lag.max The maximum lag to consider for ACF/PACF (default is 20)
#* @get /acf_pacf
function(lag.max = 20) {
  if (nrow(T1)==0){
    res$status<-400 
    return(list(error="T1 is empty, no data to analyze.")) 
  }
  
  parameter<-T1$Vcc
  
  if(any(is.na(parameter))) {
    res$status<-400 
    return(list(error="Invalid data. Please provide a numeric vector.")) 
  }
  
  lag.max <- as.numeric(lag.max)
  
  if(is.na(lag.max) || lag.max < 1){
    res$status<-400 
    return(list(error="Invalid lag.max value. It must be a positive integer.")) 
  }
  
  acf_values<- Acf(parameter, plot=FALSE, lag.max=lag.max)
  pacf_values<- Pacf(parameter, plot=FALSE, lag.max=lag.max)
  
  return(list(ACF=acf_values$acf,PACF=pacf_values$acf))
}

#* Returns Holt-Winters forecast for the Vcc column in T1
#* @response 200 Holt-Winters forecast for the next specified periods
#* @response 400 If the parameters are invalid or T1 is empty
#* @description This endpoint applies Holt-Winters exponential smoothing to forecast future values in the Vcc column of T1.
#* @tag TimeSeries
#* @param frequency The frequency of the time series (e.g., 12 for monthly data)
#* @param periods The number of future periods to forecast
#* @get /holt_winters_forecast
function(frequency, periods =12){
  if(nrow(T1)==0){
    res$status<-400 
    return(list(error="T1 is empty, no data to analyze.")) 
  }
  
  parameter<-T1$Vcc
  
  frequency <- as.numeric(frequency)
  periods <- as.numeric(periods)
  
  if(is.na(frequency)||frequency<=0||is.na(periods)||periods<=0){
    res$status<-400 
    return(list(error="Invalid data. Please provide valid numeric time series, frequency greater than zero and positive periods.")) 
  }
  
  if(any(is.na(parameter))) {
    res$status<-400 
    return(list(error="The Vcc column contains NA values. Please clean your data.")) 
  }
  
  ts_data<-ts(parameter,frequency=frequency)
  
  fit<-HoltWinters(ts_data)
  
  forecast_data<-forecast(fit,h=periods)
  
  return(list(Forecast=forecast_data$mean,
              Lower=forecast_data$lower,
              Upper=forecast_data$upper))
}
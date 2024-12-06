# +-----------------+
# |                 |
# |   SOLAR CELL    |
# |                 |
# +-----------------+

#* Returns the calculated fill factor
#*
#* @response 200 The fill factor calculated for the given parameters
#* @response 400 If one or more parameters (Pmax, Voc, Isc) are missing or invalid
#* @description This endpoint calculates the Fill Factor (FF) for a solar cell based on the maximum power output (Pmax), open-circuit voltage (Voc), and short-circuit current (Isc).
#* @tag SolarCell
#* @param Pmax The maximum power output (in watts)
#* @param Voc The open-circuit voltage (in volts)
#* @param Isc The short-circuit current (in amperes)
#* @get /fill_factor
function(Pmax, Voc, Isc) {
  Pmax <- as.numeric(Pmax)
  Voc <- as.numeric(Voc)
  Isc <- as.numeric(Isc)
  
  if (is.na(Pmax) || is.na(Voc) || is.na(Isc) || Pmax <= 0 || Voc <= 0 || Isc <= 0) {
    res$status <- 400
    return(list(error = "Please provide positive numeric values for Pmax, Voc, and Isc."))
  }
  
  FF <- Pmax / (Voc * Isc)
  
  return(list(FillFactor = FF))
}

#* Calculates the solar cell's efficiency
#* 
#* @response 200 The efficiency of the solar cell
#* @response 400 If one or more parameters are missing or invalid
#* @description This endpoint calculates the efficiency of the solar cell as the ratio of output power to the incident solar power.
#* @tag SolarCell
#* @param Pout The output power of the solar cell (in watts)
#* @param Pin The incident solar power (in watts)
#* @get /efficiency
function(Pout, Pin) {
  Pout <- as.numeric(Pout)
  Pin <- as.numeric(Pin)
  
  if (is.na(Pout) || is.na(Pin) || Pout <= 0 || Pin <= 0) {
    res$status <- 400
    return(list(error = "Please provide positive numeric values for Pout and Pin."))
  }
  
  efficiency <- (Pout / Pin) * 100
  
  return(list(Efficiency = efficiency))
}

#* Estimates power output based on area, irradiance, and efficiency
#* 
#* @response 200 The estimated power output of the solar cell
#* @response 400 If one or more parameters are missing or invalid
#* @description This endpoint estimates the power output of a solar cell based on the area, irradiance, and efficiency.
#* @tag SolarCell
#* @param area The area of the solar cell (in square meters)
#* @param irradiance The solar irradiance (in watts per square meter)
#* @param efficiency The efficiency of the solar cell (as a percentage)
#* @get /power_output
function(area, irradiance, efficiency) {
  area <- as.numeric(area)
  irradiance <- as.numeric(irradiance)
  efficiency <- as.numeric(efficiency)
  
  if (is.na(area) || is.na(irradiance) || is.na(efficiency) || area <= 0 || irradiance <= 0 || efficiency <= 0 || efficiency > 100) {
    res$status <- 400
    return(list(error = "Please provide positive numeric values for area, irradiance, and efficiency (0-100)."))
  }
  
  power_output <- area * irradiance * (efficiency / 100)
  
  return(list(PowerOutput = power_output))
}

#* Simulates a current-voltage (IV) curve
#* 
#* @response 200 The simulated IV curve values (current and voltage)
#* @response 400 If one or more parameters are missing or invalid
#* @description This endpoint simulates an IV curve based on input parameters like the short-circuit current (Isc), open-circuit voltage (Voc), and the diode ideality factor.
#* @tag SolarCell
#* @param Isc The short-circuit current (in amperes)
#* @param Voc The open-circuit voltage (in volts)
#* @param n The diode ideality factor (dimensionless)
#* @get /iv_curve
function(Isc, Voc, n = 1) {
  Isc <- as.numeric(Isc)
  Voc <- as.numeric(Voc)
  n <- as.numeric(n)
  
  if (is.na(Isc) || is.na(Voc) || is.na(n) || Isc <= 0 || Voc <= 0 || n <= 0) {
    res$status <- 400
    return(list(error = "Please provide positive numeric values for Isc, Voc, and n."))
  }
  
  V <- seq(0, Voc, length.out = 100)  
  I <- Isc * (1 - V / Voc)  
  
  return(list(Voltage = V, Current = I))
}

#* Estimates the maximum power point (MPP).
#* 
#* @response 200 The estimated maximum power point (MPP)
#* @response 400 If one or more parameters are missing or invalid
#* @description This endpoint estimates the maximum power point (MPP) of the solar cell based on its open-circuit voltage (Voc), short-circuit current (Isc), and fill factor (FF).
#* @tag SolarCell
#* @param Voc The open-circuit voltage (in volts)
#* @param Isc The short-circuit current (in amperes)
#* @param FF The fill factor of the solar cell
#* @get /mpp
function(Voc, Isc, FF) {
  Voc <- as.numeric(Voc)
  Isc <- as.numeric(Isc)
  FF <- as.numeric(FF)
  
  if (is.na(Voc) || is.na(Isc) || is.na(FF) || Voc <= 0 || Isc <= 0 || FF <= 0 || FF > 1) {
    res$status <- 400
    return(list(error = "Please provide positive numeric values for Voc, Isc, and FF (0-1)."))
  }
  
  MPP <- Voc * Isc * FF
  
  return(list(MaxPowerPoint = MPP))
}

#* Calculates the effect of temperature on performance.
#* 
#* @response 200 The performance adjustment due to temperature change
#* @response 400 If one or more parameters are missing or invalid
#* @description This endpoint calculates the impact of temperature on the solar cell's performance, considering the temperature coefficient and the difference from the standard test conditions (25°C).
#* @tag SolarCell
#* @param Pmax The maximum power output at standard test conditions (in watts)
#* @param temperature The current operating temperature (in °C)
#* @param temp_coeff The temperature coefficient of the solar cell (typically negative, in %/°C)
#* @get /temp_effect
function(Pmax, temperature, temp_coeff) {
  Pmax <- as.numeric(Pmax)
  temperature <- as.numeric(temperature)
  temp_coeff <- as.numeric(temp_coeff)
  
  if (is.na(Pmax) || is.na(temperature) || is.na(temp_coeff) || Pmax <= 0) {
    res$status <- 400
    return(list(error = "Please provide valid numeric values for Pmax, temperature, and temp_coeff."))
  }
  
  delta_temp <- temperature - 25  
  adjustment <- Pmax * (1 + temp_coeff / 100 * delta_temp)
  
  return(list(AdjustedPower = adjustment))
}
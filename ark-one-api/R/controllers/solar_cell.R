# +-----------------+
# |   SOLAR CELL    |
# +-----------------+

source("../services/solar_cell_service.R", chdir = TRUE)
source("../utils/response_handler.R", chdir = TRUE)

#* Returns the calculated fill factor
#* @response 200 The fill factor calculated for the given parameters
#* @response 400 If one or more parameters (Pmax, Voc, Isc) are missing or invalid
#* @tag SolarCell
#* @param Pmax The maximum power output (in watts)
#* @param Voc The open-circuit voltage (in volts)
#* @param Isc The short-circuit current (in amperes)
#* @get /fill_factor
function(res, req, Pmax, Voc, Isc) {
  send_http_response(res, calculate_fill_factor(Pmax, Voc, Isc))
}

#* Calculates the solar cell's efficiency
#* @response 200 The efficiency of the solar cell
#* @response 400 If one or more parameters are missing or invalid
#* @tag SolarCell
#* @param Pout The output power of the solar cell (in watts)
#* @param Pin The incident solar power (in watts)
#* @get /efficiency
function(res, req, Pout, Pin) {
  send_http_response(res, calculate_efficiency(Pout, Pin))
}

#* Estimates power output based on area, irradiance, and efficiency
#* @response 200 The estimated power output of the solar cell
#* @response 400 If one or more parameters are missing or invalid
#* @tag SolarCell
#* @param area The area of the solar cell (in square meters)
#* @param irradiance The solar irradiance (in watts per square meter)
#* @param efficiency The efficiency of the solar cell (as a percentage)
#* @get /power_output
function(res, req, area, irradiance, efficiency) {
  send_http_response(res, estimate_power_output(area, irradiance, efficiency))
}

#* Simulates a current-voltage (IV) curve
#* @response 200 The simulated IV curve values (current and voltage)
#* @response 400 If one or more parameters are missing or invalid
#* @tag SolarCell
#* @param Isc The short-circuit current (in amperes)
#* @param Voc The open-circuit voltage (in volts)
#* @param n The diode ideality factor (dimensionless)
#* @get /iv_curve
function(res, req, Isc, Voc, n = 1) {
  send_http_response(res, simulate_iv_curve(Isc, Voc, n))
}

#* Estimates the maximum power point (MPP)
#* @response 200 The estimated maximum power point (MPP)
#* @response 400 If one or more parameters are missing or invalid
#* @tag SolarCell
#* @param Voc The open-circuit voltage (in volts)
#* @param Isc The short-circuit current (in amperes)
#* @param FF The fill factor of the solar cell
#* @get /mpp
function(res, req, Voc, Isc, FF) {
  send_http_response(res, estimate_mpp(Voc, Isc, FF))
}

#* Calculates the effect of temperature on performance
#* @response 200 The performance adjustment due to temperature change
#* @response 400 If one or more parameters are missing or invalid
#* @tag SolarCell
#* @param Pmax The maximum power output at standard test conditions (in watts)
#* @param temperature The current operating temperature (in °C)
#* @param temp_coeff The temperature coefficient of the solar cell (typically negative, in %/°C)
#* @get /temp_effect
function(res, req, Pmax, temperature, temp_coeff) {
  send_http_response(res, calculate_temp_effect(Pmax, temperature, temp_coeff))
}
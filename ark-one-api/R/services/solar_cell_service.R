# +-----------------------+
# |                       |
# |   SOLAR CELL SERVICE  |
# |                       |
# +-----------------------+

source("../utils/response_handler.R", chdir = TRUE)
source("../utils/request_handler.R", chdir = TRUE)
source("../utils/utils.R", chdir = TRUE)

calculate_fill_factor <- function(Pmax, Voc, Isc) {
  validated <- validate_and_convert_numeric_fields(Pmax = Pmax, Voc = Voc, Isc = Isc)
  if (validated$status != "success") return(validated)

  with(validated$data, {
    if (Pmax <= 0 || Voc <= 0 || Isc <= 0) {
      return(list(status = "bad_request", message = "Pmax, Voc, and Isc must be positive.", data = NULL))
    }

    FF <- Pmax / (Voc * Isc)
    list(status = "success", message = "Fill factor calculated.", data = list(FillFactor = FF))
  })
}

calculate_efficiency <- function(Pout, Pin) {
  validated <- validate_and_convert_numeric_fields(Pout = Pout, Pin = Pin)
  if (validated$status != "success") return(validated)

  with(validated$data, {
    if (Pout <= 0 || Pin <= 0) {
      return(list(status = "bad_request", message = "Pout and Pin must be positive.", data = NULL))
    }

    efficiency <- (Pout / Pin) * 100
    list(status = "success", message = "Efficiency calculated.", data = list(Efficiency = efficiency))
  })
}

estimate_power_output <- function(area, irradiance, efficiency) {
  validated <- validate_and_convert_numeric_fields(area = area, irradiance = irradiance, efficiency = efficiency)
  if (validated$status != "success") return(validated)

  with(validated$data, {
    if (area <= 0 || irradiance <= 0 || efficiency <= 0 || efficiency > 100) {
      return(list(status = "bad_request", message = "Area, irradiance must be > 0 and efficiency in (0–100].", data = NULL))
    }

    power_output <- area * irradiance * (efficiency / 100)
    list(status = "success", message = "Power output estimated.", data = list(PowerOutput = power_output))
  })
}

simulate_iv_curve <- function(Isc, Voc, n = 1) {
  validated <- validate_and_convert_numeric_fields(Isc = Isc, Voc = Voc, n = n)
  if (validated$status != "success") return(validated)

  with(validated$data, {
    if (Isc <= 0 || Voc <= 0 || n <= 0) {
      return(list(status = "bad_request", message = "Isc, Voc, and n must be positive.", data = NULL))
    }

    V <- seq(0, Voc, length.out = 100)
    I <- Isc * (1 - V / Voc)

    list(status = "success", message = "IV curve simulated.", data = list(Voltage = V, Current = I))
  })
}

estimate_mpp <- function(Voc, Isc, FF) {
  validated <- validate_and_convert_numeric_fields(Voc = Voc, Isc = Isc, FF = FF)
  if (validated$status != "success") return(validated)

  with(validated$data, {
    if (Voc <= 0 || Isc <= 0 || FF <= 0 || FF > 1) {
      return(list(status = "bad_request", message = "Voc, Isc must be > 0 and FF in (0–1].", data = NULL))
    }

    MPP <- Voc * Isc * FF
    list(status = "success", message = "Maximum power point estimated.", data = list(MaxPowerPoint = MPP))
  })
}

calculate_temp_effect <- function(Pmax, temperature, temp_coeff) {
  validated <- validate_and_convert_numeric_fields(Pmax = Pmax, temperature = temperature, temp_coeff = temp_coeff)
  if (validated$status != "success") return(validated)

  with(validated$data, {
    if (Pmax <= 0) {
      return(list(status = "bad_request", message = "Pmax must be positive.", data = NULL))
    }

    delta_temp <- temperature - 25
    adjustment <- Pmax * (1 + temp_coeff / 100 * delta_temp)

    list(status = "success", message = "Temperature effect calculated.", data = list(AdjustedPower = adjustment))
  })
}
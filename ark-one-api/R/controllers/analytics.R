# +-----------------------+
# |                       |
# |       ANALYTICS       |
# |                       |
# +-----------------------+

source("../services/solar_tracker_service.R", chdir = TRUE)

# Function to generate a line graph showing average voltage over the current week using test data
#* @description This endpoint provides a graph displaying the daily average voltage over the current week for a specified product instance, considering the week starts on Sunday, with test data.
#* @tag Analytics
#* @get /generateWeeklyVoltageGraph
#* @param id_product_instance
#* @serializer png
function(res, id_product_instance) {
  tryCatch(
    {
      current_date <- Sys.Date()
      start_of_week <- current_date - as.numeric(format(current_date, "%u")) %% 7
      end_of_week <- start_of_week + 6

      set.seed(1234)

      dates <- seq.Date(start_of_week, end_of_week, by = "day")

      avg_voltages <- round(runif(length(dates), min = 210, max = 230), 2)

      weekly_data <- data.frame(
        date = dates,
        avg_voltage = avg_voltages
      )

      if (nrow(weekly_data) == 0) {
        res$status <- 404
        return(list(status = "error", message = "No data available for the specified week."))
      }

      voltage_plot <- ggplot(weekly_data, aes(x = date, y = avg_voltage)) +
        geom_line(color = "blue", size = 1.2) +
        geom_point(color = "red", size = 3) +
        labs(
          title = "Média Diária de Voltagem - Semana Atual (Dados de Teste)",
          x = "Data",
          y = "Média de Voltagem (V)"
        ) +
        theme_minimal(base_size = 15) +
        theme(
          plot.title = element_text(hjust = 0.5, size = 18, face = "bold"),
          axis.text.x = element_text(angle = 45, hjust = 1)
        )

      res$status <- 200
      print(voltage_plot)
    },
    error = function(e) {
      res$status <- 500
      return(list(status = "error", message = e$message))
    }
  )
}

# Function to generate a line graph showing average current over the current week using test data
#* @description This endpoint provides a graph displaying the daily average current over the current week for a specified product instance, considering the week starts on Sunday, with test data.
#* @tag Analytics
#* @get /generateWeeklyCurrentGraph
#* @param id_product_instance:int
#* @serializer png
function(res, id_product_instance) {
  tryCatch(
    {
      current_date <- Sys.Date()
      start_of_week <- current_date - as.numeric(format(current_date, "%u")) %% 7
      end_of_week <- start_of_week + 6

      set.seed(123)

      dates <- seq.Date(start_of_week, end_of_week, by = "day")

      avg_currents <- round(runif(length(dates), min = 8, max = 12), 2)

      weekly_data <- data.frame(
        date = dates,
        avg_current = avg_currents
      )

      if (nrow(weekly_data) == 0) {
        res$status <- 404
        return(list(status = "error", message = "No data available for the specified week."))
      }

      current_plot <- ggplot(weekly_data, aes(x = date, y = avg_current)) +
        geom_line(color = "green", size = 1.2) +
        geom_point(color = "red", size = 3) +
        labs(
          title = "Média Diária de Corrente - Semana Atual (Dados de Teste)",
          x = "Data",
          y = "Média de Corrente (A)"
        ) +
        theme_minimal(base_size = 15) +
        theme(
          plot.title = element_text(hjust = 0.5, size = 18, face = "bold"),
          axis.text.x = element_text(angle = 45, hjust = 1)
        )

      res$status <- 200
      print(current_plot)
    },
    error = function(e) {
      res$status <- 500
      return(list(status = "error", message = e$message))
    }
  )
}

# Function to generate a line graph showing two temperatures over time
#* @description This endpoint provides a graph displaying the solar panel and ESP32 core temperatures over time.
#* @tag Analytics
#* @get /generateTemperatureGraph
#* @param esp32_unique_id
#* @serializer png
function(res, esp32_unique_id) {
  tryCatch(
    {
      if (!exists(as.character(esp32_unique_id), envir = solar_tracker_data_storage)) {
        res$status <- 404
        return(list(status = "error", message = "ESP32 ID não encontrado na memória."))
      }

      filtered_data <- get(as.character(esp32_unique_id), envir = solar_tracker_data_storage)

      if (nrow(filtered_data) == 0) {
        res$status <- 404
        return(list(status = "error", message = "Não há dados disponíveis para o ESP32 fornecido."))
      }

      if (!all(c("solar_panel_temperature", "esp32_core_temperature") %in% names(filtered_data))) {
        res$status <- 400
        return(list(status = "error", message = "Dados de temperatura estão ausentes no conjunto de dados."))
      }

      temperature_plot <- ggplot(filtered_data, aes(x = seq_along(solar_panel_temperature))) +
        geom_line(aes(y = solar_panel_temperature, color = "Temperatura do Painel Solar"), size = 1.2) +
        geom_line(aes(y = esp32_core_temperature, color = "Temperatura do ESP32"), size = 1.2) +
        scale_color_manual(values = c(
          "Temperatura do Painel Solar" = "red",
          "Temperatura do ESP32" = "blue"
        )) +
        labs(
          x = "Últimas Inserções do ESP32",
          y = "Temperatura (°C)",
          color = "Fonte"
        ) +
        theme_minimal(base_size = 15) +
        theme(
          plot.title = element_text(hjust = 0.5, size = 18, face = "bold"),
          legend.position = "top",
          legend.title = element_text(size = 12),
          legend.text = element_text(size = 10)
        )

      res$status <- 200
      print(temperature_plot)
    },
    error = function(e) {
      res$status <- 500
      return(list(status = "error", message = e$message))
    }
  )
}

# Function to generate an arrow graph indicating a specific angle
#* @description This endpoint provides a graph with an arrow pointing at a specified angle (0 to 180 degrees).
#* @tag Analytics
#* @get /generateServoAngleGraph
#* @param esp32_unique_id
#* @serializer png
function(res, esp32_unique_id) {
  tryCatch(
    {
      if (!exists(as.character(esp32_unique_id), envir = solar_tracker_data_storage)) {
        res$status <- 404
        return(list(status = "error", message = "ESP32 ID não encontrado na memória."))
      }

      filtered_data <- get(as.character(esp32_unique_id), envir = solar_tracker_data_storage)

      if (nrow(filtered_data) == 0) {
        res$status <- 404
        return(list(status = "error", message = "Não há dados disponíveis para o ESP32 fornecido."))
      }

      last_angle <- tail(filtered_data$servo_tower_angle, 1)
      if (length(last_angle) == 0 || is.na(last_angle)) {
        res$status <- 400
        return(list(status = "error", message = "Nenhum dado disponível para servo_tower_angle."))
      }

      angle <- as.numeric(last_angle)

      if (angle < 0 || angle > 180) {
        res$status <- 400
        return(list(status = "error", message = "Ângulo deve estar entre 0 e 180 graus."))
      }

      angle_rad <- angle * pi / 180
      length_factor <- 5 / 3
      x_end <- -cos(angle_rad) * 0.55 * length_factor
      y_end <- sin(angle_rad) * 0.55 * length_factor

      arrow_plot <- ggplot() +
        geom_segment(aes(x = 0, y = 0, xend = x_end, yend = y_end),
          arrow = arrow(length = unit(0.3, "inches")),
          linewidth = 1.5, color = "black", alpha = 0
        ) +
        geom_point(aes(x = x_end, y = y_end), shape = 21, size = 18, fill = "yellow", color = "orange") +
        coord_fixed(ratio = 1, xlim = c(-1, 1), ylim = c(-1, 1)) +
        labs(
          title = paste("Ângulo do Sol:", angle, "graus"),
          subtitle = "Direção do Sol em relação ao painel solar"
        ) +
        theme_minimal(base_size = 15) +
        theme(
          plot.title = element_text(hjust = 0.5, size = 18, face = "bold", color = "darkblue"),
          plot.subtitle = element_text(hjust = 0.5, size = 12, face = "italic", color = "darkblue"),
          panel.background = element_rect(fill = "skyblue"),
          plot.margin = margin(20, 20, 20, 20),
          axis.title.x = element_blank(),
          axis.title.y = element_blank(),
          axis.text.x = element_blank(),
          axis.text.y = element_blank(),
          axis.ticks = element_blank()
        )

      res$status <- 200
      print(arrow_plot)
    },
    error = function(e) {
      res$status <- 500
      return(list(status = "error", message = e$message))
    }
  )
}

# Endpoint para gerar o gráfico de z-score de voltagem usando dados do dia, distribuído ao longo das horas
#* @description This endpoint provides a graph showing voltage z-scores, highlighting anomalies, distributed across hours.
#* @tag Analytics
#* @get /generateVoltageZScoreGraph
#* @param id_product_instance
#* @serializer png
function(res, id_product_instance) {
  tryCatch(
    {
      if (is.null(id_product_instance) || is.na(id_product_instance)) {
        res$status <- 400
        return(list(status = "error", message = "Invalid or null product instance ID."))
      }

      raw_data <- fetch_esp32_data_today_by_instance(id_product_instance)

      if (!is.data.frame(raw_data) || nrow(raw_data) == 0) {
        res$status <- 404
        return(list(status = "error", message = "There is no data for the specified product."))
      }

      # Extrai os campos common_data
      parsed_common <- lapply(raw_data$common_data, jsonlite::fromJSON)
      raw_data$voltage <- as.numeric(sapply(parsed_common, function(x) x$voltage))
      raw_data$current <- as.numeric(sapply(parsed_common, function(x) x$current))

      # Converte data e calcula intervalos
      raw_data$created_at <- as.POSIXct(raw_data$created_at)
      raw_data$time_interval <- cut(raw_data$created_at, breaks = "15 min", labels = FALSE)
      raw_data$hour <- as.numeric(format(raw_data$created_at, "%H"))
      raw_data$minute <- as.numeric(format(raw_data$created_at, "%M"))
      raw_data$time_position <- raw_data$hour + (raw_data$minute / 60)

      # Cálculo do z-score da voltagem por intervalo
      raw_data$z_score_voltage <- ave(raw_data$voltage, raw_data$time_interval, FUN = function(x) scale(x))

      voltage_zscore_plot <- ggplot(raw_data, aes(x = time_position, y = voltage)) +
        geom_line() +
        geom_point(aes(color = abs(z_score_voltage) > 1.5)) +
        labs(
          title = "Análise de Anomalias de Voltagem",
          x = "Hora (distribuída ao longo do tempo)",
          y = "Z-score de Voltagem"
        ) +
        scale_color_manual(values = c("black", "red"), labels = c("Normal", "Anomalia")) +
        scale_x_continuous(breaks = seq(0, 23, by = 1), labels = paste0(seq(0, 23, by = 1), ":00")) +
        theme_classic()

      res$status <- 200
      print(voltage_zscore_plot)
    },
    error = function(e) {
      res$status <- 500
      return(list(status = "error", message = e$message))
    }
  )
}

# Endpoint para gerar o gráfico de z-score de corrente usando dados do dia, distribuído ao longo das horas
#* @description This endpoint provides a graph showing current z-scores, highlighting anomalies, distributed across hours.
#* @tag Analytics
#* @get /generateCurrentZScoreGraph
#* @param id_product_instance
#* @serializer png
function(res, id_product_instance) {
  tryCatch(
    {
      if (is.null(id_product_instance) || is.na(id_product_instance)) {
        res$status <- 400
        return(list(status = "error", message = "Invalid or null product instance ID."))
      }

      raw_data <- fetch_esp32_data_today_by_instance(id_product_instance)

      if (!is.data.frame(raw_data) || nrow(raw_data) == 0) {
        res$status <- 404
        return(list(status = "error", message = "There is no data for the specified product."))
      }

      # Extrai os campos common_data
      parsed_common <- lapply(raw_data$common_data, jsonlite::fromJSON)
      raw_data$voltage <- as.numeric(sapply(parsed_common, function(x) x$voltage))
      raw_data$current <- as.numeric(sapply(parsed_common, function(x) x$current))

      # Converte data e calcula intervalos
      raw_data$created_at <- as.POSIXct(raw_data$created_at)
      raw_data$time_interval <- cut(raw_data$created_at, breaks = "15 min", labels = FALSE)
      raw_data$hour <- as.numeric(format(raw_data$created_at, "%H"))
      raw_data$minute <- as.numeric(format(raw_data$created_at, "%M"))
      raw_data$time_position <- raw_data$hour + (raw_data$minute / 60)

      # Cálculo do z-score da corrente por intervalo
      raw_data$z_score_current <- ave(raw_data$current, raw_data$time_interval, FUN = function(x) scale(x))

      current_zscore_plot <- ggplot(raw_data, aes(x = time_position, y = current)) +
        geom_line() +
        geom_point(aes(color = abs(z_score_current) > 1.5)) +
        labs(
          title = "Análise de Anomalias de Corrente",
          x = "Hora (distribuída ao longo do tempo)",
          y = "Corrente (A)"
        ) +
        scale_color_manual(values = c("black", "red"), labels = c("Normal", "Anomalia")) +
        scale_x_continuous(breaks = seq(0, 23, by = 1), labels = paste0(seq(0, 23, by = 1), ":00")) +
        theme_classic()

      res$status <- 200
      print(current_zscore_plot)
    },
    error = function(e) {
      res$status <- 500
      return(list(status = "error", message = e$message))
    }
  )
}

#* @description This endpoint provides a graph displaying the voltage trend over time for a given ESP32.
#* @tag Analytics
#* @get /generateVoltageTrendGraph
#* @param esp32_unique_id
#* @serializer png
function(res, esp32_unique_id) {
  tryCatch(
    {
      if (!exists(as.character(esp32_unique_id), envir = solar_tracker_data_storage)) {
        res$status <- 404
        return(list(status = "error", message = "ESP32 ID não encontrado na memória."))
      }

      filtered_data <- get(as.character(esp32_unique_id), envir = solar_tracker_data_storage)

      if (nrow(filtered_data) == 0) {
        res$status <- 404
        return(list(status = "error", message = "Não há dados disponíveis para o ESP32 fornecido."))
      }

      if (!"voltage" %in% names(filtered_data)) {
        res$status <- 400
        return(list(status = "error", message = "Dados de voltagem ausentes no conjunto de dados."))
      }

      voltage_plot <- ggplot(filtered_data, aes(x = seq_len(nrow(filtered_data)), y = voltage)) +
        geom_line(color = "blue", size = 1.2) +
        labs(
          x = "Últimas Inserções do ESP32",
          y = "Voltagem (V)"
        ) +
        theme_minimal(base_size = 15) +
        theme(
          plot.title = element_text(hjust = 0.5, size = 18, face = "bold")
        )

      res$status <- 200
      print(voltage_plot)
    },
    error = function(e) {
      res$status <- 500
      return(list(status = "error", message = e$message))
    }
  )
}

#* @description This endpoint provides a graph displaying the current trend over time for a given ESP32.
#* @tag Analytics
#* @get /generateCurrentTrendGraph
#* @param esp32_unique_id
#* @serializer png
function(res, esp32_unique_id) {
  tryCatch(
    {
      if (!exists(as.character(esp32_unique_id), envir = solar_tracker_data_storage)) {
        res$status <- 404
        return(list(status = "error", message = "ESP32 ID não encontrado na memória."))
      }

      filtered_data <- get(as.character(esp32_unique_id), envir = solar_tracker_data_storage)

      if (nrow(filtered_data) == 0) {
        res$status <- 404
        return(list(status = "error", message = "Não há dados disponíveis para o ESP32 fornecido."))
      }

      if (!"current" %in% names(filtered_data)) {
        res$status <- 400
        return(list(status = "error", message = "Dados de corrente ausentes no conjunto de dados."))
      }

      current_plot <- ggplot(filtered_data, aes(x = seq_len(nrow(filtered_data)), y = current)) +
        geom_line(color = "blue", size = 1.2) +
        labs(
          x = "Últimas Inserções do ESP32",
          y = "Corrente (A)"
        ) +
        theme_minimal(base_size = 15) +
        theme(
          plot.title = element_text(hjust = 0.5, size = 18, face = "bold")
        )

      res$status <- 200
      print(current_plot)
    },
    error = function(e) {
      res$status <- 500
      return(list(status = "error", message = e$message))
    }
  )
}

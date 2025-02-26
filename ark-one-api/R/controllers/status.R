# +-----------------+
# |                 |
# |     STATUS      |
# |                 |
# +-----------------+

source("../services/solar_panel_service.R", chdir = TRUE)

#* Verifies the current state of the API
#*
#* @get /ping
#* @response 200 "API está funcionando"
#* @description Endpoint for seeing if th api is running correctly.
#* @tag Status
function() {
  list(message = "The API is running")
}

#* Return the current values on the list to be sended to the database
#*
#* @get /recent_values/solar_panel
#* @response 200 "The values recently received by the API"
#* @description Endpoint destinated to peek on the values that will be sended to the database once the query threshold is filled.
#* @tag Status
function() {
  list(value = recently_received_solar_panel_data)
}
# +-----------------+
# |                 |
# |     STATUS      |
# |                 |
# +-----------------+

source("../services/status_service.R", chdir = TRUE)
source("../utils/response_handler.R", chdir = TRUE)

#* Verifies the current state of the API
#* @get /ping
#* @response 200 The API is Running
#* @description This endpoint is simply to verify in a fast way if the api is running on the called address and port, if not any response will come.
#* @tag Status
function(res) {
  send_http_response(res, status_ping())
}

#* Return the current values on the list to be sended to the database
#* @get /recent_values/solar_panel
#* @response 200 "The values recently received by the API"
#* @description Endpoint is designated to peek on the values that will be sended to the database once the query threshold is filled.
#* @tag Status
function(res) {
  send_http_response(res, maintenance_message())
}
package api

import "encoding/json"

// TrackerData represents the payload from the solar tracker.
type TrackerData struct {
	ESP32ID         string  `json:"esp32_unique_id"`
	MaxElevation    float64 `json:"max_elevation"`
	MinElevation    float64 `json:"min_elevation"`
	ServoTowerAngle float64 `json:"servo_tower_angle"`
	SolarPanelTemp  float64 `json:"solar_panel_temperature"`
	ESP32CoreTemp   float64 `json:"esp32_core_temperature"`
	Voltage         float64 `json:"voltage"`
	Current         float64 `json:"current"`
}

// Message is the generic message structure for WebSocket communication.
type Message struct {
	Type    string          `json:"type"`
	Payload json.RawMessage `json:"payload"`
}

type DeviceData struct {
	ESP32ID  string      `json:"esp32_id"`
	Metadata interface{} `json:"metadata"`
	Data     interface{} `json:"data"`
}

type OutgoingPayload struct {
	Type string       `json:"type"`
	Data []DeviceData `json:"data"`
}

type GenericResponse struct {
	Status  string      `json:"status"`
	Message string      `json:"message"`
	Data    interface{} `json:"data,omitempty"`
}

type ErrorResponse struct {
	Error string `json:"error"`
}

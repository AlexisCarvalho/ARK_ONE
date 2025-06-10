package model

import "time"

type MemoryTrackerData struct {
	MaxElevation    float64   `json:"max_elevation"`
	MinElevation    float64   `json:"min_elevation"`
	ServoTowerAngle float64   `json:"servo_tower_angle"`
	SolarPanelTemp  float64   `json:"solar_panel_temp"`
	ESP32CoreTemp   float64   `json:"esp32_core_temp"`
	Voltage         float64   `json:"voltage"`
	Current         float64   `json:"current"`
	CreatedAt       time.Time `json:"created_at"`
}

type MemoryMetadata struct {
	IDProductInstance string
	InsertCount       int
}

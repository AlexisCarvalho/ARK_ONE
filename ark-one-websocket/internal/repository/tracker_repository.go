package repository

import (
	"ark-one-websocket/internal/model"
	"database/sql"
	"encoding/json"
	"fmt"
	"strings"
)

type TrackerRepository struct {
	DB *sql.DB
}

func NewTrackerRepository(db *sql.DB) *TrackerRepository {
	return &TrackerRepository{DB: db}
}

func (r *TrackerRepository) SaveTrackerData(idProductInstance string, data []model.MemoryTrackerData) error {
	if len(data) == 0 {
		return nil
	}

	valueStrings := make([]string, 0, len(data))
	valueArgs := make([]interface{}, 0, len(data)*3)

	for i, d := range data {
		commonData, err := json.Marshal(map[string]interface{}{
			"voltage": d.Voltage,
			"current": d.Current,
		})
		if err != nil {
			return err
		}
		productSpecificData, err := json.Marshal(map[string]interface{}{
			"servo_tower_angle":       d.ServoTowerAngle,
			"solar_panel_temperature": d.SolarPanelTemp,
			"esp32_core_temperature":  d.ESP32CoreTemp,
		})
		if err != nil {
			return err
		}
		// Use unique placeholders for each row
		startIdx := i*3 + 1
		valueStrings = append(valueStrings, fmt.Sprintf("($%d, $%d, $%d)", startIdx, startIdx+1, startIdx+2))
		valueArgs = append(valueArgs, idProductInstance, string(commonData), string(productSpecificData))
	}

	query := fmt.Sprintf(
		"INSERT INTO esp32_data (id_product_instance, common_data, product_specific_data) VALUES %s",
		strings.Join(valueStrings, ", "),
	)

	stmt, err := r.DB.Prepare(query)
	if err != nil {
		return err
	}
	defer stmt.Close()

	_, err = stmt.Exec(valueArgs...)
	return err
}

func (r *TrackerRepository) SaveTrackerDataInChunks(idProductInstance string, data []model.MemoryTrackerData, chunkSize int) error {
	for i := 0; i < len(data); i += chunkSize {
		end := i + chunkSize
		if end > len(data) {
			end = len(data)
		}
		chunk := data[i:end]
		if err := r.SaveTrackerData(idProductInstance, chunk); err != nil {
			return err
		}
	}
	return nil
}

func (r *TrackerRepository) FetchProductInstanceID(esp32UniqueID string) (string, error) {
	var idProductInstance string
	query := "SELECT id_product_instance FROM product_instance WHERE esp32_unique_id = $1"
	err := r.DB.QueryRow(query, esp32UniqueID).Scan(&idProductInstance)
	if err != nil {
		return "", err
	}
	return idProductInstance, nil
}

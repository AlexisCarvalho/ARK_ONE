package tracker

import (
	"ark-one-websocket/api"
	"ark-one-websocket/internal/model"
	"ark-one-websocket/internal/repository"
	"sync"
	"time"
)

type MemoryStorage struct {
	data       map[string][]model.MemoryTrackerData
	metadata   map[string]model.MemoryMetadata
	repository *repository.TrackerRepository
	mu         sync.RWMutex
}

func NewMemoryStorage(repo *repository.TrackerRepository) *MemoryStorage {
	return &MemoryStorage{
		data:       make(map[string][]model.MemoryTrackerData),
		metadata:   make(map[string]model.MemoryMetadata),
		repository: repo,
	}
}

func (m *MemoryStorage) SendData(d *api.TrackerData) api.GenericResponse {
	m.mu.Lock()
	defer m.mu.Unlock()

	uniqueID := d.ESP32ID
	td := model.MemoryTrackerData{
		MaxElevation:    d.MaxElevation,
		MinElevation:    d.MinElevation,
		ServoTowerAngle: d.ServoTowerAngle,
		SolarPanelTemp:  d.SolarPanelTemp,
		ESP32CoreTemp:   d.ESP32CoreTemp,
		Voltage:         d.Voltage,
		Current:         d.Current,
		CreatedAt:       time.Now(),
	}

	// Append data
	m.data[uniqueID] = append(m.data[uniqueID], td)

	// Update InsertCount
	meta := m.metadata[uniqueID]
	meta.InsertCount++
	m.metadata[uniqueID] = meta

	// Always cap memory to last 100 entries
	if len(m.data[uniqueID]) > 100 {
		m.data[uniqueID] = m.data[uniqueID][len(m.data[uniqueID])-100:]
	}

	// If InsertCount reaches 100, persist the 100 entries
	if meta.InsertCount == 100 {
		currentData := m.data[uniqueID]

		// Sanity check: keep only 100 recent
		if len(currentData) > 100 {
			currentData = currentData[len(currentData)-100:]
		}

		// Ensure we have the IDProductInstance
		idProductInstance := meta.IDProductInstance
		if idProductInstance == "" {
			// Try to fetch from DB
			id, err := m.repository.FetchProductInstanceID(uniqueID)
			if err != nil || id == "" {
				// Reset InsertCount and update metadata
				meta.InsertCount = 0
				m.metadata[uniqueID] = meta
				return api.GenericResponse{
					Status:  "not_found",
					Message: "Product instance not found for ESP32 ID",
				}
			}
			// Update metadata with found ID
			idProductInstance = id
			meta.IDProductInstance = idProductInstance
			m.metadata[uniqueID] = meta
		}

		// Save to DB using the IDProductInstance
		err := m.repository.SaveTrackerData(idProductInstance, currentData)
		if err != nil {
			return api.GenericResponse{
				Status:  "error",
				Message: "Failed to persist data to database: " + err.Error(),
			}
		}

		// Reset InsertCount
		meta.InsertCount = 0
		m.metadata[uniqueID] = meta

		// Retain only last 100 entries
		m.data[uniqueID] = currentData
		return api.GenericResponse{
			Status:  "created",
			Message: "Data stored in the database",
		}
	}

	return api.GenericResponse{
		Status:  "accepted",
		Message: "Data stored in memory",
	}
}

func (m *MemoryStorage) GetDeviceData(esp32IDs []string, maxPoints int) []api.DeviceData {
	m.mu.RLock()
	defer m.mu.RUnlock()
	var result []api.DeviceData
	for _, id := range esp32IDs {
		data := m.data[id]
		if len(data) > maxPoints {
			data = data[len(data)-maxPoints:]
		}
		meta := m.metadata[id]
		result = append(result, api.DeviceData{
			ESP32ID:  id,
			Metadata: meta,
			Data:     data,
		})
	}
	return result
}

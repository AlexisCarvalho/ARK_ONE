package tracker

import (
	"ark-one-websocket/api"
	"ark-one-websocket/internal/model"
	"ark-one-websocket/internal/repository"
	"log"
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
	log.Printf("[tracker] appended data for %s, total entries: %d", uniqueID, len(m.data[uniqueID]))

	// Update InsertCount
	meta := m.metadata[uniqueID]
	meta.InsertCount++
	m.metadata[uniqueID] = meta
	log.Printf("[tracker] InsertCount for %s is now %d", uniqueID, meta.InsertCount)

	// Always cap memory to last 100 entries
	if len(m.data[uniqueID]) > 100 {
		log.Printf("[tracker] capping memory for %s from %d to 100", uniqueID, len(m.data[uniqueID]))
		m.data[uniqueID] = m.data[uniqueID][len(m.data[uniqueID])-100:]
		log.Printf("[tracker] capped entries for %s now %d", uniqueID, len(m.data[uniqueID]))
	}

	// If InsertCount reaches 100, persist the 100 entries
	if meta.InsertCount == 100 {
		currentData := m.data[uniqueID]

		// Sanity check: keep only 100 recent
		if len(currentData) > 100 {
			currentData = currentData[len(currentData)-100:]
		}

		log.Printf("[tracker] InsertCount==100 for %s, attempting to persist %d entries", uniqueID, len(currentData))

		// Ensure we have the IDProductInstance
		idProductInstance := meta.IDProductInstance
		if idProductInstance == "" {
			// Try to fetch from DB
			id, err := m.repository.FetchProductInstanceID(uniqueID)
			log.Printf("[tracker] FetchProductInstanceID result for %s: id=%s, err=%v", uniqueID, id, err)
			if err != nil || id == "" {
				// Reset InsertCount and update metadata
				meta.InsertCount = 0
				m.metadata[uniqueID] = meta
				log.Printf("[tracker] could not find product instance id for %s, reset InsertCount and abort persist", uniqueID)
				return api.GenericResponse{
					Status:  "not_found",
					Message: "Product instance not found for ESP32 ID",
				}
			}
			// Update metadata with found ID
			idProductInstance = id
			meta.IDProductInstance = idProductInstance
			m.metadata[uniqueID] = meta
			log.Printf("[tracker] updated metadata IDProductInstance for %s -> %s", uniqueID, idProductInstance)
		}

		// Save to DB using the IDProductInstance
		log.Printf("[tracker] saving %d entries for product instance %s", len(currentData), idProductInstance)
		err := m.repository.SaveTrackerData(idProductInstance, currentData)
		if err != nil {
			log.Printf("[tracker] failed to persist data for %s: %v", idProductInstance, err)
			return api.GenericResponse{
				Status:  "error",
				Message: "Failed to persist data to database: " + err.Error(),
			}
		}

		log.Printf("[tracker] persisted data for product instance %s", idProductInstance)

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

	log.Printf("[tracker] data accepted in memory for %s (InsertCount %d)", uniqueID, m.metadata[uniqueID].InsertCount)
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

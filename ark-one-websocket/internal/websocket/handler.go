package websocket

import (
	"encoding/json"
	"net/http"
	"strings"
	"sync"
	"time"

	"ark-one-websocket/api"
	"ark-one-websocket/pkg/logger"

	"github.com/google/uuid"
	"github.com/gorilla/websocket"
)

// Hub manages all websocket clients and their subscriptions.
type Hub struct {
	clients       map[string]*Client  // Maps client IDs to Client structs
	subscriptions map[string][]string // Maps client IDs to a list of ESP32 device IDs they are subscribed to
	mu            sync.RWMutex        // Mutex to protect concurrent access to clients and subscriptions
	storage       DataStorage         // Interface for data storage operations
}

// DataStorage defines methods for sending and retrieving device data.
type DataStorage interface {
	SendData(data *api.TrackerData) api.GenericResponse
	GetDeviceData(esp32IDs []string, maxPoints int) []api.DeviceData
}

// NewHub creates and returns a new Hub instance.
func NewHub(storage DataStorage) *Hub {
	return &Hub{
		clients:       make(map[string]*Client),
		subscriptions: make(map[string][]string),
		storage:       storage,
	}
}

// upgrader is used to upgrade HTTP connections to WebSocket connections.
var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool { return true }, // Allow all origins (not secure for production)
}

// HandleWS handles new websocket connection requests.
func (h *Hub) HandleWS(w http.ResponseWriter, r *http.Request) {
	// Upgrade the HTTP connection to a WebSocket connection
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		logger.Error("Upgrade failed: " + err.Error())
		return
	}

	// Generate a unique ID for the new client
	connID := uuid.NewString()
	client := &Client{
		ID:   connID,
		Conn: conn,
		Send: make(chan []byte, 256),
	}

	// Register the new client
	h.mu.Lock()
	h.clients[connID] = client
	h.mu.Unlock()

	logger.Info("Client " + connID + " connected.")

	// Start goroutines for reading and writing
	go h.writePump(client)
	h.readPump(client)
}

// readPump reads messages from the client and processes them.
func (h *Hub) readPump(client *Client) {
	defer func() {
		// On disconnect, remove the client
		h.mu.Lock()
		delete(h.clients, client.ID)
		delete(h.subscriptions, client.ID)
		h.mu.Unlock()
		client.Conn.Close()
		logger.Info("Client " + client.ID + " disconnected")
	}()
	for {
		// Read a message from the WebSocket connection
		_, msg, err := client.Conn.ReadMessage()
		if err != nil {
			logger.Error("Read error: " + err.Error())
			break
		}

		var m api.Message
		// Try to parse the message as JSON
		if err := json.Unmarshal(msg, &m); err != nil {
			logger.Error("Invalid message: " + err.Error())
			continue
		}

		switch m.Type {
		case "solar_tracker_data":
			var data api.TrackerData
			if err := json.Unmarshal(m.Payload, &data); err != nil {
				logger.Error("Failed to decode TrackerData: " + err.Error())
				resp, _ := json.Marshal(map[string]string{"status": "error", "message": "Invalid TrackerData"})
				client.Send <- resp
				continue
			}

			// Store the data using the storage interface
			respObj := h.storage.SendData(&data)
			resp, _ := json.Marshal(respObj)
			client.Send <- resp

		case "request_data":
			// Define a struct for the request payload
			var req struct {
				RequestedESP32IDs []string `json:"esp32_ids"`
			}
			if err := json.Unmarshal(m.Payload, &req); err != nil {
				logger.Error("Invalid request_data payload: " + err.Error())
				resp, _ := json.Marshal(map[string]string{"status": "error", "message": "Invalid request_data payload"})
				client.Send <- resp
				continue
			}
			h.mu.Lock()
			h.subscriptions[client.ID] = req.RequestedESP32IDs
			h.mu.Unlock()
			logger.Info("Client " + client.ID + " subscribed to: " + joinIDs(req.RequestedESP32IDs))

		default:
			logger.Error("Unknown message type: " + m.Type)
			resp, _ := json.Marshal(map[string]string{"status": "error", "message": "Unknown message type"})
			client.Send <- resp
		}
	}
}

// writePump sends messages from the server to the client.
func (h *Hub) writePump(client *Client) {
	defer client.Conn.Close()
	for msg := range client.Send {
		err := client.Conn.WriteMessage(websocket.TextMessage, msg)
		if err != nil {
			logger.Error("Write error: " + err.Error())
			break
		}
	}
}

// StartBroadcaster periodically sends device data to subscribed clients.
func (h *Hub) StartBroadcaster(maxPoints int, interval time.Duration) {
	go func() {
		for {
			h.mu.RLock()
			// Iterate over all connected clients
			for connID, client := range h.clients {
				ids := h.subscriptions[connID]
				if len(ids) == 0 {
					continue // Skip clients with no subscriptions
				}
				// Get the latest device data for the subscribed IDs
				deviceData := h.storage.GetDeviceData(ids, maxPoints)
				if len(deviceData) > 0 {
					// Prepare the payload to send to the client
					payload := api.OutgoingPayload{
						Type: "device_data",
						Data: deviceData,
					}
					b, _ := json.Marshal(payload)
					client.Send <- b
				}
			}
			h.mu.RUnlock()
			time.Sleep(interval) // Wait before broadcasting again
		}
	}()
}

// joinIDs joins a slice of ESP32 IDs into a comma-separated string.
func joinIDs(ids []string) string {
	return strings.Join(ids, ",")
}

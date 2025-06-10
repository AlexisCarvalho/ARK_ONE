package server

import (
	"ark-one-websocket/internal/websocket"
	"net/http"
)

func NewRouter(hub *websocket.Hub) http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("/ws", hub.HandleWS)
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte("WebSocket server is running. Connect to /ws"))
	})
	return mux
}

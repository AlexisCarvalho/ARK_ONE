package main

import (
	"database/sql"
	"log"
	"net/http"
	"time"

	_ "github.com/lib/pq"

	"ark-one-websocket/internal/repository"
	"ark-one-websocket/internal/server"
	"ark-one-websocket/internal/tracker"
	"ark-one-websocket/internal/websocket"
	"ark-one-websocket/pkg/logger"
)

func main() {
	// Setup DB connection (adjust DSN as needed)
	db, err := sql.Open("postgres", "host=172.17.0.2 user=postgres password=user1232025 dbname=one_database sslmode=disable")
	if err != nil {
		log.Fatal("Failed to connect to DB: ", err)
	}
	defer db.Close()

	repo := repository.NewTrackerRepository(db)
	storage := tracker.NewMemoryStorage(repo)
	hub := websocket.NewHub(storage)
	hub.StartBroadcaster(30, 2*time.Second)
	router := server.NewRouter(hub)
	addr := ":8080"
	logger.Info("Starting server on " + addr)
	if err := http.ListenAndServe(addr, router); err != nil {
		log.Fatal("ListenAndServe: ", err)
	}
}

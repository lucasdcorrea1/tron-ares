package handlers

import (
	"context"
	"encoding/json"
	"log/slog"
	"net/http"
	"sync"
	"time"

	"github.com/gorilla/websocket"
	"github.com/imperium/backend/internal/database"
	"github.com/imperium/backend/internal/middleware"
	"github.com/imperium/backend/internal/models"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin: func(r *http.Request) bool {
		return true // Allow all origins for development
	},
}

// TronWSClient represents a connected WebSocket client
type TronWSClient struct {
	conn      *websocket.Conn
	projectID primitive.ObjectID
	userID    primitive.ObjectID
	send      chan []byte
}

// TronWSHub manages WebSocket connections
type TronWSHub struct {
	clients    map[*TronWSClient]bool
	broadcast  chan TronWSMessage
	register   chan *TronWSClient
	unregister chan *TronWSClient
	mutex      sync.RWMutex
}

// TronWSMessage represents a WebSocket message
type TronWSMessage struct {
	Type      string      `json:"type"` // "task_update", "agent_log", "decision", "metrics"
	ProjectID string      `json:"project_id"`
	Data      interface{} `json:"data"`
	Timestamp time.Time   `json:"timestamp"`
}

// Global hub instance
var tronHub *TronWSHub

func init() {
	tronHub = &TronWSHub{
		clients:    make(map[*TronWSClient]bool),
		broadcast:  make(chan TronWSMessage, 256),
		register:   make(chan *TronWSClient),
		unregister: make(chan *TronWSClient),
	}
	go tronHub.run()
}

func (h *TronWSHub) run() {
	for {
		select {
		case client := <-h.register:
			h.mutex.Lock()
			h.clients[client] = true
			h.mutex.Unlock()
			slog.Info("tron_ws_client_connected",
				"project_id", client.projectID.Hex(),
				"user_id", client.userID.Hex(),
			)

		case client := <-h.unregister:
			h.mutex.Lock()
			if _, ok := h.clients[client]; ok {
				delete(h.clients, client)
				close(client.send)
			}
			h.mutex.Unlock()
			slog.Info("tron_ws_client_disconnected",
				"project_id", client.projectID.Hex(),
			)

		case message := <-h.broadcast:
			h.mutex.RLock()
			for client := range h.clients {
				// Only send to clients subscribed to this project
				if client.projectID.Hex() == message.ProjectID {
					select {
					case client.send <- mustMarshal(message):
					default:
						// Client buffer full, disconnect
						close(client.send)
						delete(h.clients, client)
					}
				}
			}
			h.mutex.RUnlock()
		}
	}
}

func mustMarshal(v interface{}) []byte {
	data, _ := json.Marshal(v)
	return data
}

// BroadcastTronMessage broadcasts a message to all clients of a project
func BroadcastTronMessage(projectID primitive.ObjectID, msgType string, data interface{}) {
	tronHub.broadcast <- TronWSMessage{
		Type:      msgType,
		ProjectID: projectID.Hex(),
		Data:      data,
		Timestamp: time.Now(),
	}
}

// HandleTronWebSocket godoc
// @Summary WebSocket endpoint for real-time updates
// @Description Establishes a WebSocket connection for real-time project updates
// @Tags tron-websocket
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Project ID"
// @Router /tron/projects/{id}/ws [get]
func HandleTronWebSocket(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r)
	if userID == primitive.NilObjectID {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	projectID, err := extractProjectID(r.URL.Path)
	if err != nil {
		http.Error(w, "Invalid project ID", http.StatusBadRequest)
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	// Verify project ownership
	count, err := database.TronProjects().CountDocuments(ctx, bson.M{
		"_id":     projectID,
		"user_id": userID,
	})
	if err != nil || count == 0 {
		http.Error(w, "Project not found", http.StatusNotFound)
		return
	}

	// Upgrade HTTP to WebSocket
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		slog.Error("failed to upgrade websocket", "error", err)
		return
	}

	client := &TronWSClient{
		conn:      conn,
		projectID: projectID,
		userID:    userID,
		send:      make(chan []byte, 256),
	}

	tronHub.register <- client

	// Start goroutines for reading and writing
	go client.writePump()
	go client.readPump()
}

func (c *TronWSClient) readPump() {
	defer func() {
		tronHub.unregister <- c
		c.conn.Close()
	}()

	c.conn.SetReadLimit(512) // Small messages expected
	c.conn.SetReadDeadline(time.Now().Add(60 * time.Second))
	c.conn.SetPongHandler(func(string) error {
		c.conn.SetReadDeadline(time.Now().Add(60 * time.Second))
		return nil
	})

	for {
		_, message, err := c.conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				slog.Error("websocket read error", "error", err)
			}
			break
		}

		// Handle incoming messages (ping/pong, subscription changes, etc.)
		var msg map[string]interface{}
		if json.Unmarshal(message, &msg) == nil {
			if msgType, ok := msg["type"].(string); ok {
				switch msgType {
				case "ping":
					c.send <- mustMarshal(map[string]string{"type": "pong"})
				case "subscribe":
					// Already subscribed via projectID
				}
			}
		}
	}
}

func (c *TronWSClient) writePump() {
	ticker := time.NewTicker(30 * time.Second)
	defer func() {
		ticker.Stop()
		c.conn.Close()
	}()

	for {
		select {
		case message, ok := <-c.send:
			c.conn.SetWriteDeadline(time.Now().Add(10 * time.Second))
			if !ok {
				c.conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}

			w, err := c.conn.NextWriter(websocket.TextMessage)
			if err != nil {
				return
			}
			w.Write(message)

			// Add queued messages to current write
			n := len(c.send)
			for i := 0; i < n; i++ {
				w.Write([]byte{'\n'})
				w.Write(<-c.send)
			}

			if err := w.Close(); err != nil {
				return
			}

		case <-ticker.C:
			c.conn.SetWriteDeadline(time.Now().Add(10 * time.Second))
			if err := c.conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}

// Helper functions for broadcasting different message types

// BroadcastTaskUpdate broadcasts a task update to all clients
func BroadcastTaskUpdate(task *models.TronTask) {
	BroadcastTronMessage(task.ProjectID, "task_update", task)
}

// BroadcastAgentLog broadcasts an agent log to all clients
func BroadcastAgentLog(log *models.TronAgentLog) {
	BroadcastTronMessage(log.ProjectID, "agent_log", log)
}

// BroadcastDecision broadcasts a new decision to all clients
func BroadcastDecision(decision *models.TronDecision) {
	BroadcastTronMessage(decision.ProjectID, "decision", decision)
}

// BroadcastMetricsUpdate broadcasts metrics update to all clients
func BroadcastMetricsUpdate(projectID primitive.ObjectID, metrics interface{}) {
	BroadcastTronMessage(projectID, "metrics", metrics)
}

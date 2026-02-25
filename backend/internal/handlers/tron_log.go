package handlers

import (
	"context"
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	"github.com/imperium/backend/internal/database"
	"github.com/imperium/backend/internal/middleware"
	"github.com/imperium/backend/internal/models"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// ListTronLogs godoc
// @Summary List agent logs for a project
// @Description Returns agent activity logs for a TRON project
// @Tags tron-logs
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Project ID"
// @Param agent_type query string false "Filter by agent type"
// @Param success query bool false "Filter by success status"
// @Param page query int false "Page number" default(1)
// @Param limit query int false "Items per page" default(50)
// @Success 200 {object} models.TronAgentLogListResponse
// @Failure 401 {string} string "Unauthorized"
// @Router /tron/projects/{id}/logs [get]
func ListTronLogs(w http.ResponseWriter, r *http.Request) {
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

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
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

	// Build filter
	filter := bson.M{"project_id": projectID}

	// Optional agent_type filter
	if agentType := r.URL.Query().Get("agent_type"); agentType != "" {
		filter["agent_type"] = agentType
	}

	// Optional success filter
	if successStr := r.URL.Query().Get("success"); successStr != "" {
		filter["success"] = successStr == "true"
	}

	// Pagination
	page, _ := strconv.Atoi(r.URL.Query().Get("page"))
	if page < 1 {
		page = 1
	}
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if limit < 1 || limit > 100 {
		limit = 50
	}
	skip := (page - 1) * limit

	// Get total count
	total, err := database.TronAgentLogs().CountDocuments(ctx, filter)
	if err != nil {
		http.Error(w, "Failed to count logs", http.StatusInternalServerError)
		return
	}

	// Get logs sorted by created_at descending (most recent first)
	opts := options.Find().
		SetSort(bson.D{{Key: "created_at", Value: -1}}).
		SetSkip(int64(skip)).
		SetLimit(int64(limit)).
		SetProjection(bson.M{
			"full_prompt":   0, // Exclude large fields by default
			"full_response": 0,
		})

	cursor, err := database.TronAgentLogs().Find(ctx, filter, opts)
	if err != nil {
		http.Error(w, "Failed to list logs", http.StatusInternalServerError)
		return
	}
	defer cursor.Close(ctx)

	var logs []models.TronAgentLog
	if err := cursor.All(ctx, &logs); err != nil {
		http.Error(w, "Failed to decode logs", http.StatusInternalServerError)
		return
	}

	if logs == nil {
		logs = []models.TronAgentLog{}
	}

	response := models.TronAgentLogListResponse{
		Logs:  logs,
		Total: total,
		Page:  page,
		Limit: limit,
	}

	json.NewEncoder(w).Encode(response)
}

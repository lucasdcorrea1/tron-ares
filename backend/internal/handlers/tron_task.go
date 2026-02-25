package handlers

import (
	"context"
	"encoding/json"
	"log/slog"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/imperium/backend/internal/database"
	"github.com/imperium/backend/internal/middleware"
	"github.com/imperium/backend/internal/models"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// ListTronTasks godoc
// @Summary List tasks for a project
// @Description Returns all tasks for a specific TRON project
// @Tags tron-tasks
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Project ID"
// @Param status query string false "Filter by status"
// @Param repo_id query string false "Filter by repo ID"
// @Param page query int false "Page number" default(1)
// @Param limit query int false "Items per page" default(50)
// @Success 200 {object} models.TronTaskListResponse
// @Failure 401 {string} string "Unauthorized"
// @Router /tron/projects/{id}/tasks [get]
func ListTronTasks(w http.ResponseWriter, r *http.Request) {
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

	// Optional status filter
	if status := r.URL.Query().Get("status"); status != "" {
		filter["status"] = status
	}

	// Optional repo filter
	if repoIDStr := r.URL.Query().Get("repo_id"); repoIDStr != "" {
		if repoID, err := primitive.ObjectIDFromHex(repoIDStr); err == nil {
			filter["repo_id"] = repoID
		}
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
	total, err := database.TronTasks().CountDocuments(ctx, filter)
	if err != nil {
		http.Error(w, "Failed to count tasks", http.StatusInternalServerError)
		return
	}

	// Get tasks
	opts := options.Find().
		SetSort(bson.D{
			{Key: "priority", Value: -1}, // High priority first
			{Key: "created_at", Value: -1},
		}).
		SetSkip(int64(skip)).
		SetLimit(int64(limit))

	cursor, err := database.TronTasks().Find(ctx, filter, opts)
	if err != nil {
		http.Error(w, "Failed to list tasks", http.StatusInternalServerError)
		return
	}
	defer cursor.Close(ctx)

	var tasks []models.TronTask
	if err := cursor.All(ctx, &tasks); err != nil {
		http.Error(w, "Failed to decode tasks", http.StatusInternalServerError)
		return
	}

	if tasks == nil {
		tasks = []models.TronTask{}
	}

	response := models.TronTaskListResponse{
		Tasks: tasks,
		Total: total,
		Page:  page,
		Limit: limit,
	}

	json.NewEncoder(w).Encode(response)
}

// GetTronTask godoc
// @Summary Get a specific task
// @Description Returns details of a specific task
// @Tags tron-tasks
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param tid path string true "Task ID"
// @Success 200 {object} models.TronTask
// @Failure 401 {string} string "Unauthorized"
// @Failure 404 {string} string "Not found"
// @Router /tron/tasks/{tid} [get]
func GetTronTask(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r)
	if userID == primitive.NilObjectID {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	taskID, err := extractTaskID(r.URL.Path)
	if err != nil {
		http.Error(w, "Invalid task ID", http.StatusBadRequest)
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	var task models.TronTask
	err = database.TronTasks().FindOne(ctx, bson.M{
		"_id":     taskID,
		"user_id": userID,
	}).Decode(&task)
	if err != nil {
		http.Error(w, "Task not found", http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(task)
}

// UpdateTronTask godoc
// @Summary Update a task
// @Description Updates status or priority of a task
// @Tags tron-tasks
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param tid path string true "Task ID"
// @Param request body models.UpdateTronTaskRequest true "Update data"
// @Success 200 {object} models.TronTask
// @Failure 400 {string} string "Invalid request"
// @Failure 401 {string} string "Unauthorized"
// @Failure 404 {string} string "Not found"
// @Router /tron/tasks/{tid} [patch]
func UpdateTronTask(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r)
	if userID == primitive.NilObjectID {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	taskID, err := extractTaskID(r.URL.Path)
	if err != nil {
		http.Error(w, "Invalid task ID", http.StatusBadRequest)
		return
	}

	var req models.UpdateTronTaskRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// Build update
	update := bson.M{"updated_at": time.Now()}
	if req.Status != "" {
		update["status"] = req.Status

		// Set timestamps based on status
		now := time.Now()
		switch req.Status {
		case models.TaskStatusInDev:
			update["started_at"] = now
		case models.TaskStatusDone, models.TaskStatusRejected:
			update["completed_at"] = now
		}
	}
	if req.Priority != "" {
		update["priority"] = req.Priority
	}

	result, err := database.TronTasks().UpdateOne(ctx,
		bson.M{"_id": taskID, "user_id": userID},
		bson.M{"$set": update},
	)
	if err != nil {
		http.Error(w, "Failed to update task", http.StatusInternalServerError)
		return
	}
	if result.MatchedCount == 0 {
		http.Error(w, "Task not found", http.StatusNotFound)
		return
	}

	// Get updated task
	var task models.TronTask
	database.TronTasks().FindOne(ctx, bson.M{"_id": taskID}).Decode(&task)

	slog.Info("tron_task_updated",
		"task_id", taskID.Hex(),
		"user_id", userID.Hex(),
		"status", req.Status,
	)

	json.NewEncoder(w).Encode(task)
}

// Helper function
func extractTaskID(path string) (primitive.ObjectID, error) {
	// Path format: /tron/tasks/{tid}
	parts := strings.Split(path, "/")
	for i, part := range parts {
		if part == "tasks" && i+1 < len(parts) {
			return primitive.ObjectIDFromHex(parts[i+1])
		}
	}
	return primitive.NilObjectID, http.ErrNoLocation
}

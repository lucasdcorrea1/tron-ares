package handlers

import (
	"context"
	"encoding/json"
	"log/slog"
	"net/http"
	"strings"
	"time"

	"github.com/imperium/backend/internal/database"
	"github.com/imperium/backend/internal/middleware"
	"github.com/imperium/backend/internal/models"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// ListTronProjects godoc
// @Summary List all TRON projects
// @Description Returns all TRON projects for the authenticated user
// @Tags tron-projects
// @Accept json
// @Produce json
// @Security BearerAuth
// @Success 200 {array} models.TronProjectResponse
// @Failure 401 {string} string "Unauthorized"
// @Router /tron/projects [get]
func ListTronProjects(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r)
	if userID == primitive.NilObjectID {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	cursor, err := database.TronProjects().Find(ctx, bson.M{"user_id": userID})
	if err != nil {
		slog.Error("failed to list tron projects", "error", err, "user_id", userID.Hex())
		http.Error(w, "Failed to list projects", http.StatusInternalServerError)
		return
	}
	defer cursor.Close(ctx)

	var projects []models.TronProject
	if err := cursor.All(ctx, &projects); err != nil {
		http.Error(w, "Failed to decode projects", http.StatusInternalServerError)
		return
	}

	// Build response with stats
	var response []models.TronProjectResponse
	for _, p := range projects {
		// Get repos count
		reposCount, _ := database.TronRepos().CountDocuments(ctx, bson.M{"project_id": p.ID})

		// Get tasks stats
		tasksInBacklog, _ := database.TronTasks().CountDocuments(ctx, bson.M{
			"project_id": p.ID,
			"status":     models.TaskStatusBacklog,
		})
		tasksCompleted, _ := database.TronTasks().CountDocuments(ctx, bson.M{
			"project_id": p.ID,
			"status":     models.TaskStatusDone,
		})

		// Get today's cost
		today := time.Now().Truncate(24 * time.Hour)
		var todayMetrics models.TronMetrics
		database.TronMetrics().FindOne(ctx, bson.M{
			"project_id": p.ID,
			"date":       bson.M{"$gte": today},
			"repo_id":    nil,
		}).Decode(&todayMetrics)

		// Get active directive
		var activeDirective models.TronDirective
		database.TronDirectives().FindOne(ctx, bson.M{
			"project_id": p.ID,
			"active":     true,
			"priority":   bson.M{"$in": []string{"high", "critical"}},
		}, options.FindOne().SetSort(bson.D{{Key: "created_at", Value: -1}})).Decode(&activeDirective)

		response = append(response, models.TronProjectResponse{
			TronProject:     p,
			ReposCount:      int(reposCount),
			TasksInBacklog:  int(tasksInBacklog),
			TasksCompleted:  int(tasksCompleted),
			TodayCostUSD:    todayMetrics.APICostUSD,
			CommitsToday:    todayMetrics.CommitsCount,
			ActiveDirective: activeDirective.Content,
		})
	}

	if response == nil {
		response = []models.TronProjectResponse{}
	}

	json.NewEncoder(w).Encode(response)
}

// CreateTronProject godoc
// @Summary Create a new TRON project
// @Description Creates a new TRON project for the authenticated user
// @Tags tron-projects
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body models.CreateTronProjectRequest true "Project data"
// @Success 201 {object} models.TronProject
// @Failure 400 {string} string "Invalid request"
// @Failure 401 {string} string "Unauthorized"
// @Router /tron/projects [post]
func CreateTronProject(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r)
	if userID == primitive.NilObjectID {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	var req models.CreateTronProjectRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	if req.Name == "" {
		http.Error(w, "Name is required", http.StatusBadRequest)
		return
	}

	// Set defaults
	if req.Frequency == "" {
		req.Frequency = models.FrequencyNormal
	}
	if req.DailyBudget <= 0 {
		req.DailyBudget = 5.0 // $5 default
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	project := models.TronProject{
		ID:          primitive.NewObjectID(),
		UserID:      userID,
		Name:        req.Name,
		Description: req.Description,
		References:  req.References,
		Repos:       []primitive.ObjectID{},
		Frequency:   req.Frequency,
		Directives:  []primitive.ObjectID{},
		IsActive:    true,
		DailyBudget: req.DailyBudget,
		CreatedAt:   time.Now(),
		UpdatedAt:   time.Now(),
	}

	_, err := database.TronProjects().InsertOne(ctx, project)
	if err != nil {
		slog.Error("failed to create tron project", "error", err, "user_id", userID.Hex())
		http.Error(w, "Failed to create project", http.StatusInternalServerError)
		return
	}

	slog.Info("tron_project_created",
		"project_id", project.ID.Hex(),
		"user_id", userID.Hex(),
		"name", project.Name,
	)

	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(project)
}

// GetTronProject godoc
// @Summary Get a TRON project by ID
// @Description Returns a specific TRON project
// @Tags tron-projects
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Project ID"
// @Success 200 {object} models.TronProjectResponse
// @Failure 401 {string} string "Unauthorized"
// @Failure 404 {string} string "Not found"
// @Router /tron/projects/{id} [get]
func GetTronProject(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r)
	if userID == primitive.NilObjectID {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	// Extract ID from path
	path := r.URL.Path
	parts := strings.Split(path, "/")
	idStr := parts[len(parts)-1]

	projectID, err := primitive.ObjectIDFromHex(idStr)
	if err != nil {
		http.Error(w, "Invalid project ID", http.StatusBadRequest)
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	var project models.TronProject
	err = database.TronProjects().FindOne(ctx, bson.M{
		"_id":     projectID,
		"user_id": userID,
	}).Decode(&project)
	if err != nil {
		http.Error(w, "Project not found", http.StatusNotFound)
		return
	}

	// Get stats
	reposCount, _ := database.TronRepos().CountDocuments(ctx, bson.M{"project_id": projectID})
	tasksInBacklog, _ := database.TronTasks().CountDocuments(ctx, bson.M{
		"project_id": projectID,
		"status":     models.TaskStatusBacklog,
	})
	tasksCompleted, _ := database.TronTasks().CountDocuments(ctx, bson.M{
		"project_id": projectID,
		"status":     models.TaskStatusDone,
	})

	today := time.Now().Truncate(24 * time.Hour)
	var todayMetrics models.TronMetrics
	database.TronMetrics().FindOne(ctx, bson.M{
		"project_id": projectID,
		"date":       bson.M{"$gte": today},
		"repo_id":    nil,
	}).Decode(&todayMetrics)

	response := models.TronProjectResponse{
		TronProject:    project,
		ReposCount:     int(reposCount),
		TasksInBacklog: int(tasksInBacklog),
		TasksCompleted: int(tasksCompleted),
		TodayCostUSD:   todayMetrics.APICostUSD,
		CommitsToday:   todayMetrics.CommitsCount,
	}

	json.NewEncoder(w).Encode(response)
}

// UpdateTronProject godoc
// @Summary Update a TRON project
// @Description Updates a specific TRON project
// @Tags tron-projects
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Project ID"
// @Param request body models.UpdateTronProjectRequest true "Update data"
// @Success 200 {object} models.TronProject
// @Failure 400 {string} string "Invalid request"
// @Failure 401 {string} string "Unauthorized"
// @Failure 404 {string} string "Not found"
// @Router /tron/projects/{id} [put]
func UpdateTronProject(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r)
	if userID == primitive.NilObjectID {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	path := r.URL.Path
	parts := strings.Split(path, "/")
	idStr := parts[len(parts)-1]

	projectID, err := primitive.ObjectIDFromHex(idStr)
	if err != nil {
		http.Error(w, "Invalid project ID", http.StatusBadRequest)
		return
	}

	var req models.UpdateTronProjectRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// Build update
	update := bson.M{"updated_at": time.Now()}
	if req.Name != "" {
		update["name"] = req.Name
	}
	if req.Description != "" {
		update["description"] = req.Description
	}
	if req.References != nil {
		update["references"] = req.References
	}
	if req.Frequency != "" {
		update["frequency"] = req.Frequency
	}
	if req.IsActive != nil {
		update["is_active"] = *req.IsActive
	}
	if req.DailyBudget != nil {
		update["daily_budget"] = *req.DailyBudget
	}

	result, err := database.TronProjects().UpdateOne(ctx,
		bson.M{"_id": projectID, "user_id": userID},
		bson.M{"$set": update},
	)
	if err != nil {
		http.Error(w, "Failed to update project", http.StatusInternalServerError)
		return
	}
	if result.MatchedCount == 0 {
		http.Error(w, "Project not found", http.StatusNotFound)
		return
	}

	// Get updated project
	var project models.TronProject
	database.TronProjects().FindOne(ctx, bson.M{"_id": projectID}).Decode(&project)

	slog.Info("tron_project_updated",
		"project_id", projectID.Hex(),
		"user_id", userID.Hex(),
	)

	json.NewEncoder(w).Encode(project)
}

// DeleteTronProject godoc
// @Summary Delete a TRON project
// @Description Deletes a specific TRON project and all associated data
// @Tags tron-projects
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Project ID"
// @Success 204 "No Content"
// @Failure 401 {string} string "Unauthorized"
// @Failure 404 {string} string "Not found"
// @Router /tron/projects/{id} [delete]
func DeleteTronProject(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r)
	if userID == primitive.NilObjectID {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	path := r.URL.Path
	parts := strings.Split(path, "/")
	idStr := parts[len(parts)-1]

	projectID, err := primitive.ObjectIDFromHex(idStr)
	if err != nil {
		http.Error(w, "Invalid project ID", http.StatusBadRequest)
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	// Delete project
	result, err := database.TronProjects().DeleteOne(ctx, bson.M{
		"_id":     projectID,
		"user_id": userID,
	})
	if err != nil {
		http.Error(w, "Failed to delete project", http.StatusInternalServerError)
		return
	}
	if result.DeletedCount == 0 {
		http.Error(w, "Project not found", http.StatusNotFound)
		return
	}

	// Delete associated data
	database.TronRepos().DeleteMany(ctx, bson.M{"project_id": projectID})
	database.TronTasks().DeleteMany(ctx, bson.M{"project_id": projectID})
	database.TronAgentLogs().DeleteMany(ctx, bson.M{"project_id": projectID})
	database.TronDecisions().DeleteMany(ctx, bson.M{"project_id": projectID})
	database.TronDirectives().DeleteMany(ctx, bson.M{"project_id": projectID})
	database.TronMetrics().DeleteMany(ctx, bson.M{"project_id": projectID})

	slog.Info("tron_project_deleted",
		"project_id", projectID.Hex(),
		"user_id", userID.Hex(),
	)

	w.WriteHeader(http.StatusNoContent)
}

package handlers

import (
	"context"
	"encoding/json"
	"log/slog"
	"net/http"
	"time"

	"github.com/imperium/backend/internal/database"
	"github.com/imperium/backend/internal/middleware"
	"github.com/imperium/backend/internal/models"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// ListTronDirectives godoc
// @Summary List directives for a project
// @Description Returns all CIO directives for a project
// @Tags tron-directives
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Project ID"
// @Param active query bool false "Filter by active status"
// @Success 200 {object} models.TronDirectiveListResponse
// @Failure 401 {string} string "Unauthorized"
// @Router /tron/projects/{id}/directives [get]
func ListTronDirectives(w http.ResponseWriter, r *http.Request) {
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

	// Optional active filter
	if activeStr := r.URL.Query().Get("active"); activeStr != "" {
		filter["active"] = activeStr == "true"
	}

	// Get directives sorted by priority then created_at
	opts := options.Find().SetSort(bson.D{
		{Key: "priority", Value: -1},
		{Key: "created_at", Value: -1},
	})

	cursor, err := database.TronDirectives().Find(ctx, filter, opts)
	if err != nil {
		http.Error(w, "Failed to list directives", http.StatusInternalServerError)
		return
	}
	defer cursor.Close(ctx)

	var directives []models.TronDirective
	if err := cursor.All(ctx, &directives); err != nil {
		http.Error(w, "Failed to decode directives", http.StatusInternalServerError)
		return
	}

	if directives == nil {
		directives = []models.TronDirective{}
	}

	// Get counts
	total := int64(len(directives))
	active, _ := database.TronDirectives().CountDocuments(ctx, bson.M{
		"project_id": projectID,
		"active":     true,
	})

	response := models.TronDirectiveListResponse{
		Directives: directives,
		Total:      total,
		Active:     active,
	}

	json.NewEncoder(w).Encode(response)
}

// CreateTronDirective godoc
// @Summary Create a new directive
// @Description CIO creates a new strategic directive for the project
// @Tags tron-directives
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Project ID"
// @Param request body models.CreateTronDirectiveRequest true "Directive data"
// @Success 201 {object} models.TronDirective
// @Failure 400 {string} string "Invalid request"
// @Failure 401 {string} string "Unauthorized"
// @Router /tron/projects/{id}/directives [post]
func CreateTronDirective(w http.ResponseWriter, r *http.Request) {
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

	var req models.CreateTronDirectiveRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	if req.Content == "" {
		http.Error(w, "Content is required", http.StatusBadRequest)
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// Verify project ownership
	var project models.TronProject
	err = database.TronProjects().FindOne(ctx, bson.M{
		"_id":     projectID,
		"user_id": userID,
	}).Decode(&project)
	if err != nil {
		http.Error(w, "Project not found", http.StatusNotFound)
		return
	}

	// Set defaults
	if req.Priority == "" {
		req.Priority = models.DirectivePriorityNormal
	}
	if req.Scope == "" {
		req.Scope = models.DirectiveScopeProject
	}

	// Parse repo_id if provided
	var repoID *primitive.ObjectID
	if req.RepoID != "" && req.Scope == models.DirectiveScopeRepo {
		rid, err := primitive.ObjectIDFromHex(req.RepoID)
		if err != nil {
			http.Error(w, "Invalid repo_id", http.StatusBadRequest)
			return
		}
		repoID = &rid
	}

	directive := models.TronDirective{
		ID:        primitive.NewObjectID(),
		UserID:    userID,
		ProjectID: projectID,
		RepoID:    repoID,
		Content:   req.Content,
		Priority:  req.Priority,
		Scope:     req.Scope,
		Active:    true,
		ExpiresAt: req.ExpiresAt,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	_, err = database.TronDirectives().InsertOne(ctx, directive)
	if err != nil {
		slog.Error("failed to create tron directive", "error", err)
		http.Error(w, "Failed to create directive", http.StatusInternalServerError)
		return
	}

	// Update project directives array
	database.TronProjects().UpdateOne(ctx,
		bson.M{"_id": projectID},
		bson.M{"$push": bson.M{"directives": directive.ID}},
	)

	slog.Info("tron_directive_created",
		"directive_id", directive.ID.Hex(),
		"project_id", projectID.Hex(),
		"priority", req.Priority,
	)

	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(directive)
}

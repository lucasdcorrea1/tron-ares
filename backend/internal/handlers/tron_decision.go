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

// ListTronDecisions godoc
// @Summary List decisions for a project
// @Description Returns all decisions requiring CIO input
// @Tags tron-decisions
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Project ID"
// @Param status query string false "Filter by status (pending, approved, rejected)"
// @Success 200 {object} models.TronDecisionListResponse
// @Failure 401 {string} string "Unauthorized"
// @Router /tron/projects/{id}/decisions [get]
func ListTronDecisions(w http.ResponseWriter, r *http.Request) {
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

	// Get decisions sorted by level (critical first) then by created_at
	opts := options.Find().SetSort(bson.D{
		{Key: "level", Value: -1},
		{Key: "created_at", Value: -1},
	})

	cursor, err := database.TronDecisions().Find(ctx, filter, opts)
	if err != nil {
		http.Error(w, "Failed to list decisions", http.StatusInternalServerError)
		return
	}
	defer cursor.Close(ctx)

	var decisions []models.TronDecision
	if err := cursor.All(ctx, &decisions); err != nil {
		http.Error(w, "Failed to decode decisions", http.StatusInternalServerError)
		return
	}

	if decisions == nil {
		decisions = []models.TronDecision{}
	}

	// Get total and pending counts
	total := int64(len(decisions))
	pending, _ := database.TronDecisions().CountDocuments(ctx, bson.M{
		"project_id": projectID,
		"status":     models.DecisionStatusPending,
	})

	response := models.TronDecisionListResponse{
		Decisions: decisions,
		Total:     total,
		Pending:   pending,
	}

	json.NewEncoder(w).Encode(response)
}

// ResolveTronDecision godoc
// @Summary Resolve a decision
// @Description CIO resolves a pending decision by choosing an option
// @Tags tron-decisions
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param did path string true "Decision ID"
// @Param request body models.ResolveDecisionRequest true "Resolution"
// @Success 200 {object} models.TronDecision
// @Failure 400 {string} string "Invalid request"
// @Failure 401 {string} string "Unauthorized"
// @Failure 404 {string} string "Not found"
// @Router /tron/decisions/{did}/resolve [post]
func ResolveTronDecision(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r)
	if userID == primitive.NilObjectID {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	decisionID, err := extractDecisionID(r.URL.Path)
	if err != nil {
		http.Error(w, "Invalid decision ID", http.StatusBadRequest)
		return
	}

	var req models.ResolveDecisionRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	if req.OptionID == "" {
		http.Error(w, "option_id is required", http.StatusBadRequest)
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// Get decision and verify ownership
	var decision models.TronDecision
	err = database.TronDecisions().FindOne(ctx, bson.M{
		"_id":     decisionID,
		"user_id": userID,
	}).Decode(&decision)
	if err != nil {
		http.Error(w, "Decision not found", http.StatusNotFound)
		return
	}

	// Check if already resolved
	if decision.Status != models.DecisionStatusPending {
		http.Error(w, "Decision already resolved", http.StatusBadRequest)
		return
	}

	// Validate option exists
	validOption := false
	for _, opt := range decision.Options {
		if opt.ID == req.OptionID {
			validOption = true
			break
		}
	}
	if !validOption {
		http.Error(w, "Invalid option_id", http.StatusBadRequest)
		return
	}

	// Update decision
	now := time.Now()
	_, err = database.TronDecisions().UpdateOne(ctx,
		bson.M{"_id": decisionID},
		bson.M{"$set": bson.M{
			"chosen_option": req.OptionID,
			"status":        models.DecisionStatusApproved,
			"resolved_at":   now,
			"resolved_by":   "user",
		}},
	)
	if err != nil {
		http.Error(w, "Failed to resolve decision", http.StatusInternalServerError)
		return
	}

	// Get updated decision
	database.TronDecisions().FindOne(ctx, bson.M{"_id": decisionID}).Decode(&decision)

	slog.Info("tron_decision_resolved",
		"decision_id", decisionID.Hex(),
		"user_id", userID.Hex(),
		"option", req.OptionID,
	)

	json.NewEncoder(w).Encode(decision)
}

// Helper function
func extractDecisionID(path string) (primitive.ObjectID, error) {
	// Path format: /tron/decisions/{did}/resolve
	parts := strings.Split(path, "/")
	for i, part := range parts {
		if part == "decisions" && i+1 < len(parts) {
			return primitive.ObjectIDFromHex(parts[i+1])
		}
	}
	return primitive.NilObjectID, http.ErrNoLocation
}

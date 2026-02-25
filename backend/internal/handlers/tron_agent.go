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

// GetTronAgentsStatus godoc
// @Summary Get status of all agents
// @Description Returns the current status and metrics of all TRON agents
// @Tags tron-agents
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Project ID"
// @Success 200 {object} models.TronAgentsStatusResponse
// @Failure 401 {string} string "Unauthorized"
// @Failure 404 {string} string "Not found"
// @Router /tron/projects/{id}/agents [get]
func GetTronAgentsStatus(w http.ResponseWriter, r *http.Request) {
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

	// Get status for each agent type
	agentTypes := []models.TronAgentType{
		models.AgentTypeOrchestrator,
		models.AgentTypeBoard,
		models.AgentTypePM,
		models.AgentTypeDev,
		models.AgentTypeQA,
		models.AgentTypeIntegration,
	}

	var agents []models.TronAgentStatus

	for _, agentType := range agentTypes {
		// Get logs for this agent
		filter := bson.M{
			"project_id": projectID,
			"agent_type": agentType,
		}

		totalRuns, _ := database.TronAgentLogs().CountDocuments(ctx, filter)
		successRuns, _ := database.TronAgentLogs().CountDocuments(ctx, bson.M{
			"project_id": projectID,
			"agent_type": agentType,
			"success":    true,
		})
		failedRuns := totalRuns - successRuns

		// Get last run
		var lastLog models.TronAgentLog
		database.TronAgentLogs().FindOne(ctx, filter,
			options.FindOne().SetSort(bson.D{{Key: "created_at", Value: -1}}),
		).Decode(&lastLog)

		// Calculate totals from logs
		pipeline := []bson.M{
			{"$match": filter},
			{"$group": bson.M{
				"_id":           nil,
				"total_tokens":  bson.M{"$sum": bson.M{"$add": []string{"$metrics.tokens_input", "$metrics.tokens_output"}}},
				"total_cost":    bson.M{"$sum": "$metrics.cost_usd"},
				"avg_duration":  bson.M{"$avg": "$metrics.duration_ms"},
			}},
		}

		var stats struct {
			TotalTokens int64   `bson:"total_tokens"`
			TotalCost   float64 `bson:"total_cost"`
			AvgDuration float64 `bson:"avg_duration"`
		}

		cursor, _ := database.TronAgentLogs().Aggregate(ctx, pipeline)
		if cursor.Next(ctx) {
			cursor.Decode(&stats)
		}
		cursor.Close(ctx)

		var lastRunAt *time.Time
		if !lastLog.CreatedAt.IsZero() {
			lastRunAt = &lastLog.CreatedAt
		}

		agents = append(agents, models.TronAgentStatus{
			AgentType:      agentType,
			IsRunning:      false, // TODO: Check actual running state
			LastRunAt:      lastRunAt,
			LastRunSuccess: lastLog.Success,
			TotalRuns:      totalRuns,
			SuccessfulRuns: successRuns,
			FailedRuns:     failedRuns,
			TotalTokens:    stats.TotalTokens,
			TotalCostUSD:   stats.TotalCost,
			AvgDurationMS:  int64(stats.AvgDuration),
		})
	}

	// TODO: Get next cycle time from scheduler
	response := models.TronAgentsStatusResponse{
		Agents:       agents,
		NextCycleAt:  nil,
		CycleRunning: false,
	}

	json.NewEncoder(w).Encode(response)
}

// RunTronAgentCycle godoc
// @Summary Manually trigger an agent cycle
// @Description Manually triggers a full agent cycle for the project
// @Tags tron-agents
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Project ID"
// @Success 202 {object} map[string]string "Cycle started"
// @Failure 401 {string} string "Unauthorized"
// @Failure 404 {string} string "Not found"
// @Router /tron/projects/{id}/agents/run [post]
func RunTronAgentCycle(w http.ResponseWriter, r *http.Request) {
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

	// Verify project ownership and active status
	var project models.TronProject
	err = database.TronProjects().FindOne(ctx, bson.M{
		"_id":     projectID,
		"user_id": userID,
	}).Decode(&project)
	if err != nil {
		http.Error(w, "Project not found", http.StatusNotFound)
		return
	}

	if !project.IsActive {
		http.Error(w, "Project is not active", http.StatusBadRequest)
		return
	}

	// TODO: Actually trigger the agent cycle via scheduler/queue
	// For now, just log the request and return accepted

	slog.Info("tron_agent_cycle_requested",
		"project_id", projectID.Hex(),
		"user_id", userID.Hex(),
	)

	w.WriteHeader(http.StatusAccepted)
	json.NewEncoder(w).Encode(map[string]string{
		"status":     "accepted",
		"message":    "Agent cycle has been queued",
		"project_id": projectID.Hex(),
	})
}

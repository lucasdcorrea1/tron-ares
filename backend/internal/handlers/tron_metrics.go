package handlers

import (
	"context"
	"encoding/json"
	"net/http"
	"time"

	"github.com/imperium/backend/internal/database"
	"github.com/imperium/backend/internal/middleware"
	"github.com/imperium/backend/internal/models"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// GetTronMetrics godoc
// @Summary Get metrics for a project
// @Description Returns aggregated metrics for a TRON project
// @Tags tron-metrics
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Project ID"
// @Success 200 {object} models.TronMetricsResponse
// @Failure 401 {string} string "Unauthorized"
// @Failure 404 {string} string "Not found"
// @Router /tron/projects/{id}/metrics [get]
func GetTronMetrics(w http.ResponseWriter, r *http.Request) {
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

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
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

	// Calculate date ranges
	now := time.Now()
	todayStart := now.Truncate(24 * time.Hour)
	weekStart := todayStart.AddDate(0, 0, -7)
	monthStart := todayStart.AddDate(0, -1, 0)

	// Get summary for each period
	todaySummary := getMetricsSummary(ctx, projectID, todayStart, now, "today")
	weekSummary := getMetricsSummary(ctx, projectID, weekStart, now, "week")
	monthSummary := getMetricsSummary(ctx, projectID, monthStart, now, "month")

	// Get daily metrics for last 30 days
	daily := getDailyMetrics(ctx, projectID, todayStart.AddDate(0, 0, -30), now)

	// Get metrics by repo
	byRepo := getRepoMetrics(ctx, projectID)

	// Get metrics by agent
	byAgent := getAgentMetrics(ctx, projectID)

	response := models.TronMetricsResponse{
		Today:   todaySummary,
		Week:    weekSummary,
		Month:   monthSummary,
		Daily:   daily,
		ByRepo:  byRepo,
		ByAgent: byAgent,
	}

	json.NewEncoder(w).Encode(response)
}

// GetTronDailyMetrics godoc
// @Summary Get daily metrics breakdown
// @Description Returns daily metrics for the last 30 days
// @Tags tron-metrics
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Project ID"
// @Success 200 {array} models.TronDailyMetrics
// @Failure 401 {string} string "Unauthorized"
// @Router /tron/projects/{id}/metrics/daily [get]
func GetTronDailyMetrics(w http.ResponseWriter, r *http.Request) {
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

	now := time.Now()
	todayStart := now.Truncate(24 * time.Hour)
	daily := getDailyMetrics(ctx, projectID, todayStart.AddDate(0, 0, -30), now)

	json.NewEncoder(w).Encode(daily)
}

// Helper functions

func getMetricsSummary(ctx context.Context, projectID primitive.ObjectID, start, end time.Time, period string) models.TronMetricsSummary {
	// Aggregate metrics from tron_metrics collection
	pipeline := []bson.M{
		{"$match": bson.M{
			"project_id": projectID,
			"repo_id":    nil, // Project-level metrics
			"date":       bson.M{"$gte": start, "$lte": end},
		}},
		{"$group": bson.M{
			"_id":              nil,
			"commits_total":    bson.M{"$sum": "$commits_count"},
			"tasks_completed":  bson.M{"$sum": "$tasks_completed"},
			"tasks_rejected":   bson.M{"$sum": "$tasks_rejected"},
			"total_cost":       bson.M{"$sum": "$api_cost_usd"},
			"total_tokens":     bson.M{"$sum": "$tokens_used"},
		}},
	}

	var result struct {
		CommitsTotal   int     `bson:"commits_total"`
		TasksCompleted int     `bson:"tasks_completed"`
		TasksRejected  int     `bson:"tasks_rejected"`
		TotalCost      float64 `bson:"total_cost"`
		TotalTokens    int64   `bson:"total_tokens"`
	}

	cursor, _ := database.TronMetrics().Aggregate(ctx, pipeline)
	if cursor.Next(ctx) {
		cursor.Decode(&result)
	}
	cursor.Close(ctx)

	// Calculate approval rate
	totalTasks := result.TasksCompleted + result.TasksRejected
	approvalRate := 0.0
	if totalTasks > 0 {
		approvalRate = float64(result.TasksCompleted) / float64(totalTasks) * 100
	}

	// Calculate avg cost per task
	avgCostPerTask := 0.0
	if result.TasksCompleted > 0 {
		avgCostPerTask = result.TotalCost / float64(result.TasksCompleted)
	}

	// Get commits streak (consecutive days with commits)
	streak := getCommitsStreak(ctx, projectID)

	return models.TronMetricsSummary{
		Period:         period,
		CommitsTotal:   result.CommitsTotal,
		TasksCompleted: result.TasksCompleted,
		TasksRejected:  result.TasksRejected,
		ApprovalRate:   approvalRate,
		TotalCostUSD:   result.TotalCost,
		TotalTokens:    result.TotalTokens,
		AvgCostPerTask: avgCostPerTask,
		CommitsStreak:  streak,
	}
}

func getDailyMetrics(ctx context.Context, projectID primitive.ObjectID, start, end time.Time) []models.TronDailyMetrics {
	opts := options.Find().SetSort(bson.D{{Key: "date", Value: 1}})

	cursor, err := database.TronMetrics().Find(ctx, bson.M{
		"project_id": projectID,
		"repo_id":    nil,
		"date":       bson.M{"$gte": start, "$lte": end},
	}, opts)
	if err != nil {
		return []models.TronDailyMetrics{}
	}
	defer cursor.Close(ctx)

	var metrics []models.TronMetrics
	cursor.All(ctx, &metrics)

	// Convert to daily format
	var daily []models.TronDailyMetrics
	for _, m := range metrics {
		daily = append(daily, models.TronDailyMetrics{
			Date:           m.Date.Format("2006-01-02"),
			Commits:        m.CommitsCount,
			TasksCompleted: m.TasksCompleted,
			CostUSD:        m.APICostUSD,
		})
	}

	if daily == nil {
		daily = []models.TronDailyMetrics{}
	}

	return daily
}

func getRepoMetrics(ctx context.Context, projectID primitive.ObjectID) []models.TronRepoMetrics {
	// Get all repos for this project
	cursor, err := database.TronRepos().Find(ctx, bson.M{"project_id": projectID})
	if err != nil {
		return []models.TronRepoMetrics{}
	}
	defer cursor.Close(ctx)

	var repos []models.TronRepo
	cursor.All(ctx, &repos)

	var metrics []models.TronRepoMetrics
	for _, repo := range repos {
		// Aggregate metrics for this repo
		pipeline := []bson.M{
			{"$match": bson.M{"repo_id": repo.ID}},
			{"$group": bson.M{
				"_id":              nil,
				"commits_total":    bson.M{"$sum": "$commits_count"},
				"tasks_completed":  bson.M{"$sum": "$tasks_completed"},
				"total_cost":       bson.M{"$sum": "$api_cost_usd"},
			}},
		}

		var result struct {
			CommitsTotal   int     `bson:"commits_total"`
			TasksCompleted int     `bson:"tasks_completed"`
			TotalCost      float64 `bson:"total_cost"`
		}

		aggCursor, _ := database.TronMetrics().Aggregate(ctx, pipeline)
		if aggCursor.Next(ctx) {
			aggCursor.Decode(&result)
		}
		aggCursor.Close(ctx)

		metrics = append(metrics, models.TronRepoMetrics{
			RepoID:         repo.ID,
			RepoName:       repo.Name,
			CommitsTotal:   result.CommitsTotal,
			TasksCompleted: result.TasksCompleted,
			CostUSD:        result.TotalCost,
			Health:         repo.Health,
		})
	}

	if metrics == nil {
		metrics = []models.TronRepoMetrics{}
	}

	return metrics
}

func getAgentMetrics(ctx context.Context, projectID primitive.ObjectID) []models.TronAgentMetrics {
	agentTypes := []models.TronAgentType{
		models.AgentTypeOrchestrator,
		models.AgentTypeBoard,
		models.AgentTypePM,
		models.AgentTypeDev,
		models.AgentTypeQA,
		models.AgentTypeIntegration,
	}

	var metrics []models.TronAgentMetrics

	for _, agentType := range agentTypes {
		pipeline := []bson.M{
			{"$match": bson.M{
				"project_id": projectID,
				"agent_type": agentType,
			}},
			{"$group": bson.M{
				"_id":           nil,
				"total_runs":    bson.M{"$sum": 1},
				"success_runs":  bson.M{"$sum": bson.M{"$cond": []interface{}{"$success", 1, 0}}},
				"total_cost":    bson.M{"$sum": "$metrics.cost_usd"},
				"total_tokens":  bson.M{"$sum": bson.M{"$add": []string{"$metrics.tokens_input", "$metrics.tokens_output"}}},
				"avg_duration":  bson.M{"$avg": "$metrics.duration_ms"},
			}},
		}

		var result struct {
			TotalRuns   int64   `bson:"total_runs"`
			SuccessRuns int64   `bson:"success_runs"`
			TotalCost   float64 `bson:"total_cost"`
			TotalTokens int64   `bson:"total_tokens"`
			AvgDuration float64 `bson:"avg_duration"`
		}

		cursor, _ := database.TronAgentLogs().Aggregate(ctx, pipeline)
		if cursor.Next(ctx) {
			cursor.Decode(&result)
		}
		cursor.Close(ctx)

		successRate := 0.0
		if result.TotalRuns > 0 {
			successRate = float64(result.SuccessRuns) / float64(result.TotalRuns) * 100
		}

		metrics = append(metrics, models.TronAgentMetrics{
			AgentType:     agentType,
			TotalRuns:     result.TotalRuns,
			SuccessRate:   successRate,
			TotalCostUSD:  result.TotalCost,
			TotalTokens:   result.TotalTokens,
			AvgDurationMS: int64(result.AvgDuration),
		})
	}

	return metrics
}

func getCommitsStreak(ctx context.Context, projectID primitive.ObjectID) int {
	// Get metrics ordered by date descending
	opts := options.Find().SetSort(bson.D{{Key: "date", Value: -1}}).SetLimit(365)

	cursor, err := database.TronMetrics().Find(ctx, bson.M{
		"project_id": projectID,
		"repo_id":    nil,
	}, opts)
	if err != nil {
		return 0
	}
	defer cursor.Close(ctx)

	var metrics []models.TronMetrics
	cursor.All(ctx, &metrics)

	streak := 0
	today := time.Now().Truncate(24 * time.Hour)

	for i, m := range metrics {
		expectedDate := today.AddDate(0, 0, -i)
		if m.Date.Truncate(24*time.Hour).Equal(expectedDate) && m.CommitsCount > 0 {
			streak++
		} else {
			break
		}
	}

	return streak
}

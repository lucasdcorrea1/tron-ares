package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// TronMetrics represents daily metrics for a project/repo
type TronMetrics struct {
	ID             primitive.ObjectID  `json:"id" bson:"_id,omitempty"`
	UserID         primitive.ObjectID  `json:"user_id" bson:"user_id"`
	ProjectID      primitive.ObjectID  `json:"project_id" bson:"project_id"`
	RepoID         *primitive.ObjectID `json:"repo_id,omitempty" bson:"repo_id,omitempty"` // If repo-specific
	Date           time.Time           `json:"date" bson:"date"`                           // Date (day only)
	CommitsCount   int                 `json:"commits_count" bson:"commits_count"`
	TasksCreated   int                 `json:"tasks_created" bson:"tasks_created"`
	TasksCompleted int                 `json:"tasks_completed" bson:"tasks_completed"`
	TasksRejected  int                 `json:"tasks_rejected" bson:"tasks_rejected"`
	TestCoverage   float64             `json:"test_coverage" bson:"test_coverage"`   // Percentage
	LinesAdded     int                 `json:"lines_added" bson:"lines_added"`
	LinesRemoved   int                 `json:"lines_removed" bson:"lines_removed"`
	APICostUSD     float64             `json:"api_cost_usd" bson:"api_cost_usd"`
	TokensUsed     int64               `json:"tokens_used" bson:"tokens_used"`
	AgentRuns      map[string]int      `json:"agent_runs" bson:"agent_runs"`         // By agent type
	BuildSuccess   int                 `json:"build_success" bson:"build_success"`
	BuildFailed    int                 `json:"build_failed" bson:"build_failed"`
	CreatedAt      time.Time           `json:"created_at" bson:"created_at"`
	UpdatedAt      time.Time           `json:"updated_at" bson:"updated_at"`
}

// TronMetricsSummary represents a summary of metrics over a period
type TronMetricsSummary struct {
	Period         string  `json:"period"` // "today", "week", "month"
	CommitsTotal   int     `json:"commits_total"`
	TasksCompleted int     `json:"tasks_completed"`
	TasksRejected  int     `json:"tasks_rejected"`
	ApprovalRate   float64 `json:"approval_rate"` // Percentage
	TotalCostUSD   float64 `json:"total_cost_usd"`
	TotalTokens    int64   `json:"total_tokens"`
	AvgCostPerTask float64 `json:"avg_cost_per_task"`
	CommitsStreak  int     `json:"commits_streak"` // Days
}

// TronDailyMetrics represents metrics for a single day
type TronDailyMetrics struct {
	Date           string  `json:"date"` // YYYY-MM-DD
	Commits        int     `json:"commits"`
	TasksCompleted int     `json:"tasks_completed"`
	CostUSD        float64 `json:"cost_usd"`
}

// TronMetricsResponse is the response for getting metrics
type TronMetricsResponse struct {
	Today       TronMetricsSummary   `json:"today"`
	Week        TronMetricsSummary   `json:"week"`
	Month       TronMetricsSummary   `json:"month"`
	Daily       []TronDailyMetrics   `json:"daily"` // Last 30 days
	ByRepo      []TronRepoMetrics    `json:"by_repo,omitempty"`
	ByAgent     []TronAgentMetrics   `json:"by_agent,omitempty"`
}

// TronRepoMetrics represents metrics for a specific repo
type TronRepoMetrics struct {
	RepoID         primitive.ObjectID `json:"repo_id"`
	RepoName       string             `json:"repo_name"`
	CommitsTotal   int                `json:"commits_total"`
	TasksCompleted int                `json:"tasks_completed"`
	CostUSD        float64            `json:"cost_usd"`
	Health         TronRepoHealth     `json:"health"`
}

// TronAgentMetrics represents metrics for a specific agent
type TronAgentMetrics struct {
	AgentType      TronAgentType `json:"agent_type"`
	TotalRuns      int64         `json:"total_runs"`
	SuccessRate    float64       `json:"success_rate"` // Percentage
	TotalCostUSD   float64       `json:"total_cost_usd"`
	TotalTokens    int64         `json:"total_tokens"`
	AvgDurationMS  int64         `json:"avg_duration_ms"`
}

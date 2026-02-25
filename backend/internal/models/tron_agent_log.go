package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// TronAgentType represents the type of agent
type TronAgentType string

const (
	AgentTypeOrchestrator TronAgentType = "orchestrator"
	AgentTypeBoard        TronAgentType = "board"
	AgentTypePM           TronAgentType = "pm"
	AgentTypeDev          TronAgentType = "dev"
	AgentTypeQA           TronAgentType = "qa"
	AgentTypeIntegration  TronAgentType = "integration"
)

// TronAgentLogMetrics represents metrics for a single agent run
type TronAgentLogMetrics struct {
	DurationMS   int64   `json:"duration_ms" bson:"duration_ms"`
	TokensInput  int64   `json:"tokens_input" bson:"tokens_input"`
	TokensOutput int64   `json:"tokens_output" bson:"tokens_output"`
	CostUSD      float64 `json:"cost_usd" bson:"cost_usd"`
	Model        string  `json:"model" bson:"model"` // claude-sonnet-4-5-20250929, etc
}

// TronAgentLog represents a log entry for agent activity
type TronAgentLog struct {
	ID            primitive.ObjectID   `json:"id" bson:"_id,omitempty"`
	UserID        primitive.ObjectID   `json:"user_id" bson:"user_id"`
	ProjectID     primitive.ObjectID   `json:"project_id" bson:"project_id"`
	RepoID        *primitive.ObjectID  `json:"repo_id,omitempty" bson:"repo_id,omitempty"`
	TaskID        *primitive.ObjectID  `json:"task_id,omitempty" bson:"task_id,omitempty"`
	AgentType     TronAgentType        `json:"agent_type" bson:"agent_type"`
	Action        string               `json:"action" bson:"action"`         // e.g., "generate_task", "implement", "review"
	InputSummary  string               `json:"input_summary" bson:"input_summary"`
	OutputSummary string               `json:"output_summary" bson:"output_summary"`
	Reasoning     string               `json:"reasoning" bson:"reasoning"`   // Agent's reasoning
	FullPrompt    string               `json:"full_prompt,omitempty" bson:"full_prompt,omitempty"`     // For debugging
	FullResponse  string               `json:"full_response,omitempty" bson:"full_response,omitempty"` // For debugging
	Metrics       TronAgentLogMetrics  `json:"metrics" bson:"metrics"`
	Success       bool                 `json:"success" bson:"success"`
	Error         string               `json:"error,omitempty" bson:"error,omitempty"`
	CreatedAt     time.Time            `json:"created_at" bson:"created_at"`
}

// TronAgentLogListResponse is the response for listing agent logs
type TronAgentLogListResponse struct {
	Logs  []TronAgentLog `json:"logs"`
	Total int64          `json:"total"`
	Page  int            `json:"page"`
	Limit int            `json:"limit"`
}

// TronAgentStatus represents the current status of an agent
type TronAgentStatus struct {
	AgentType       TronAgentType `json:"agent_type"`
	IsRunning       bool          `json:"is_running"`
	LastRunAt       *time.Time    `json:"last_run_at,omitempty"`
	LastRunSuccess  bool          `json:"last_run_success"`
	TotalRuns       int64         `json:"total_runs"`
	SuccessfulRuns  int64         `json:"successful_runs"`
	FailedRuns      int64         `json:"failed_runs"`
	TotalTokens     int64         `json:"total_tokens"`
	TotalCostUSD    float64       `json:"total_cost_usd"`
	AvgDurationMS   int64         `json:"avg_duration_ms"`
}

// TronAgentsStatusResponse is the response for getting all agents status
type TronAgentsStatusResponse struct {
	Agents       []TronAgentStatus `json:"agents"`
	NextCycleAt  *time.Time        `json:"next_cycle_at,omitempty"`
	CycleRunning bool              `json:"cycle_running"`
}

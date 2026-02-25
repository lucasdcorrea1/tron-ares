package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// TronFrequency represents how often the project should be worked on
type TronFrequency string

const (
	FrequencyNormal TronFrequency = "normal"
	FrequencyHigh   TronFrequency = "high"
	FrequencyLow    TronFrequency = "low"
)

// TronProject represents a TRON project with multiple repos
type TronProject struct {
	ID          primitive.ObjectID   `json:"id" bson:"_id,omitempty"`
	UserID      primitive.ObjectID   `json:"user_id" bson:"user_id"`
	Name        string               `json:"name" bson:"name"`
	Description string               `json:"description" bson:"description"`
	References  []string             `json:"references" bson:"references"`     // Market references (competitor URLs)
	Repos       []primitive.ObjectID `json:"repos" bson:"repos"`               // IDs of TronRepo
	Frequency   TronFrequency        `json:"frequency" bson:"frequency"`       // How often to run cycles
	Directives  []primitive.ObjectID `json:"directives" bson:"directives"`     // IDs of TronDirective
	IsActive    bool                 `json:"is_active" bson:"is_active"`       // Whether agents should run
	DailyBudget float64              `json:"daily_budget" bson:"daily_budget"` // Max daily spend in USD
	CreatedAt   time.Time            `json:"created_at" bson:"created_at"`
	UpdatedAt   time.Time            `json:"updated_at" bson:"updated_at"`
}

// CreateTronProjectRequest is the request body for creating a project
type CreateTronProjectRequest struct {
	Name        string        `json:"name"`
	Description string        `json:"description"`
	References  []string      `json:"references,omitempty"`
	Frequency   TronFrequency `json:"frequency,omitempty"`
	DailyBudget float64       `json:"daily_budget,omitempty"`
}

// UpdateTronProjectRequest is the request body for updating a project
type UpdateTronProjectRequest struct {
	Name        string        `json:"name,omitempty"`
	Description string        `json:"description,omitempty"`
	References  []string      `json:"references,omitempty"`
	Frequency   TronFrequency `json:"frequency,omitempty"`
	IsActive    *bool         `json:"is_active,omitempty"`
	DailyBudget *float64      `json:"daily_budget,omitempty"`
}

// TronProjectResponse is the response for a project with expanded data
type TronProjectResponse struct {
	TronProject
	ReposCount      int     `json:"repos_count"`
	TasksInBacklog  int     `json:"tasks_in_backlog"`
	TasksCompleted  int     `json:"tasks_completed"`
	TodayCostUSD    float64 `json:"today_cost_usd"`
	CommitsToday    int     `json:"commits_today"`
	ActiveDirective string  `json:"active_directive,omitempty"`
}

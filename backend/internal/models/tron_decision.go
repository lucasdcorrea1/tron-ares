package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// TronDecisionLevel represents the importance level of a decision
type TronDecisionLevel int

const (
	DecisionLevelInfo     TronDecisionLevel = 1 // Just informational
	DecisionLevelNormal   TronDecisionLevel = 2 // Normal decision
	DecisionLevelCritical TronDecisionLevel = 3 // Critical, needs attention
)

// TronDecisionStatus represents the status of a decision
type TronDecisionStatus string

const (
	DecisionStatusPending  TronDecisionStatus = "pending"
	DecisionStatusApproved TronDecisionStatus = "approved"
	DecisionStatusRejected TronDecisionStatus = "rejected"
	DecisionStatusTimeout  TronDecisionStatus = "timeout"  // Auto-resolved by default
	DecisionStatusAuto     TronDecisionStatus = "auto"     // Automatically resolved
)

// TronDecisionOption represents an option for a decision
type TronDecisionOption struct {
	ID          string `json:"id" bson:"id"`
	Label       string `json:"label" bson:"label"`
	Description string `json:"description" bson:"description"`
	IsDefault   bool   `json:"is_default" bson:"is_default"` // Used if timeout
	Impact      string `json:"impact" bson:"impact"`         // What happens if chosen
}

// TronDecision represents a decision that requires CIO input
type TronDecision struct {
	ID            primitive.ObjectID   `json:"id" bson:"_id,omitempty"`
	UserID        primitive.ObjectID   `json:"user_id" bson:"user_id"`
	ProjectID     primitive.ObjectID   `json:"project_id" bson:"project_id"`
	RepoID        *primitive.ObjectID  `json:"repo_id,omitempty" bson:"repo_id,omitempty"`
	TaskID        *primitive.ObjectID  `json:"task_id,omitempty" bson:"task_id,omitempty"`
	Level         TronDecisionLevel    `json:"level" bson:"level"`
	AgentType     TronAgentType        `json:"agent_type" bson:"agent_type"`
	Title         string               `json:"title" bson:"title"`
	Description   string               `json:"description" bson:"description"`
	Context       string               `json:"context" bson:"context"` // Additional context
	Options       []TronDecisionOption `json:"options" bson:"options"`
	ChosenOption  string               `json:"chosen_option,omitempty" bson:"chosen_option,omitempty"`
	Status        TronDecisionStatus   `json:"status" bson:"status"`
	TimeoutAt     time.Time            `json:"timeout_at" bson:"timeout_at"`       // When to auto-resolve
	DefaultOption string               `json:"default_option" bson:"default_option"` // Which option to use on timeout
	ResolvedAt    *time.Time           `json:"resolved_at,omitempty" bson:"resolved_at,omitempty"`
	ResolvedBy    string               `json:"resolved_by,omitempty" bson:"resolved_by,omitempty"` // "user" or "timeout" or "auto"
	CreatedAt     time.Time            `json:"created_at" bson:"created_at"`
}

// ResolveDecisionRequest is the request for resolving a decision
type ResolveDecisionRequest struct {
	OptionID string `json:"option_id"`
	Comment  string `json:"comment,omitempty"`
}

// TronDecisionListResponse is the response for listing decisions
type TronDecisionListResponse struct {
	Decisions []TronDecision `json:"decisions"`
	Total     int64          `json:"total"`
	Pending   int64          `json:"pending"`
}

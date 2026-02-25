package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// TronDirectivePriority represents the priority of a directive
type TronDirectivePriority string

const (
	DirectivePriorityNormal   TronDirectivePriority = "normal"
	DirectivePriorityHigh     TronDirectivePriority = "high"
	DirectivePriorityCritical TronDirectivePriority = "critical"
)

// TronDirectiveScope represents the scope of a directive
type TronDirectiveScope string

const (
	DirectiveScopeProject TronDirectiveScope = "project" // Applies to all repos
	DirectiveScopeRepo    TronDirectiveScope = "repo"    // Applies to specific repo
)

// TronDirective represents a strategic directive from the CIO
type TronDirective struct {
	ID        primitive.ObjectID    `json:"id" bson:"_id,omitempty"`
	UserID    primitive.ObjectID    `json:"user_id" bson:"user_id"`
	ProjectID primitive.ObjectID    `json:"project_id" bson:"project_id"`
	RepoID    *primitive.ObjectID   `json:"repo_id,omitempty" bson:"repo_id,omitempty"` // If scope is repo
	Content   string                `json:"content" bson:"content"`                     // The directive text
	Priority  TronDirectivePriority `json:"priority" bson:"priority"`
	Scope     TronDirectiveScope    `json:"scope" bson:"scope"`
	Active    bool                  `json:"active" bson:"active"`
	ExpiresAt *time.Time            `json:"expires_at,omitempty" bson:"expires_at,omitempty"` // Optional expiration
	CreatedAt time.Time             `json:"created_at" bson:"created_at"`
	UpdatedAt time.Time             `json:"updated_at" bson:"updated_at"`
}

// CreateTronDirectiveRequest is the request for creating a directive
type CreateTronDirectiveRequest struct {
	Content   string                `json:"content"`
	Priority  TronDirectivePriority `json:"priority,omitempty"`
	Scope     TronDirectiveScope    `json:"scope,omitempty"`
	RepoID    string                `json:"repo_id,omitempty"` // If scope is repo
	ExpiresAt *time.Time            `json:"expires_at,omitempty"`
}

// UpdateTronDirectiveRequest is the request for updating a directive
type UpdateTronDirectiveRequest struct {
	Content   string                `json:"content,omitempty"`
	Priority  TronDirectivePriority `json:"priority,omitempty"`
	Active    *bool                 `json:"active,omitempty"`
	ExpiresAt *time.Time            `json:"expires_at,omitempty"`
}

// TronDirectiveListResponse is the response for listing directives
type TronDirectiveListResponse struct {
	Directives []TronDirective `json:"directives"`
	Total      int64           `json:"total"`
	Active     int64           `json:"active"`
}

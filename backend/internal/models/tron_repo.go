package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// TronRepoHealth represents the health status of a repo
type TronRepoHealth string

const (
	HealthGreen  TronRepoHealth = "green"
	HealthYellow TronRepoHealth = "yellow"
	HealthRed    TronRepoHealth = "red"
)

// TronStack represents detected stack information
type TronStack struct {
	Language  string   `json:"language" bson:"language"`   // go, typescript, dart, python, etc
	Framework string   `json:"framework" bson:"framework"` // gin, nextjs, flutter, fastapi, etc
	Database  string   `json:"database" bson:"database"`   // mongodb, postgres, mysql, etc
	Tools     []string `json:"tools" bson:"tools"`         // docker, kubernetes, github-actions, etc
}

// TronRepoAnalysis represents the result of analyzing a repo
type TronRepoAnalysis struct {
	Summary        string            `json:"summary" bson:"summary"`                   // AI-generated summary
	Models         []string          `json:"models" bson:"models"`                     // Detected models/entities
	Endpoints      []string          `json:"endpoints" bson:"endpoints"`               // Detected API endpoints
	Features       []string          `json:"features" bson:"features"`                 // Detected features
	Patterns       []string          `json:"patterns" bson:"patterns"`                 // Detected patterns (MVC, Clean Arch, etc)
	FileCount      int               `json:"file_count" bson:"file_count"`             // Total files
	LinesOfCode    int               `json:"lines_of_code" bson:"lines_of_code"`       // Total LOC
	Todos          []string          `json:"todos" bson:"todos"`                       // Found TODOs/FIXMEs
	TestFiles      int               `json:"test_files" bson:"test_files"`             // Number of test files
	Dependencies   map[string]string `json:"dependencies" bson:"dependencies"`         // Major dependencies
	AnalyzedAt     time.Time         `json:"analyzed_at" bson:"analyzed_at"`
}

// TronRepo represents a GitHub repository in a TRON project
type TronRepo struct {
	ID              primitive.ObjectID   `json:"id" bson:"_id,omitempty"`
	UserID          primitive.ObjectID   `json:"user_id" bson:"user_id"`
	ProjectID       primitive.ObjectID   `json:"project_id" bson:"project_id"`
	GitHubURL       string               `json:"github_url" bson:"github_url"`
	Name            string               `json:"name" bson:"name"`
	Stack           TronStack            `json:"stack" bson:"stack"`
	Analysis        TronRepoAnalysis     `json:"analysis" bson:"analysis"`
	CurrentVersion  string               `json:"current_version" bson:"current_version"`
	Health          TronRepoHealth       `json:"health" bson:"health"`
	TestCoverage    float64              `json:"test_coverage" bson:"test_coverage"`
	CommitsStreak   int                  `json:"commits_streak" bson:"commits_streak"`     // Days with consecutive commits
	Dependencies    []primitive.ObjectID `json:"dependencies" bson:"dependencies"`         // Other repos this depends on
	LastCommitAt    time.Time            `json:"last_commit_at" bson:"last_commit_at"`
	LastAnalyzedAt  time.Time            `json:"last_analyzed_at" bson:"last_analyzed_at"`
	ClaudeMDExists  bool                 `json:"claude_md_exists" bson:"claude_md_exists"` // Has CLAUDE.md file
	LocalPath       string               `json:"local_path" bson:"local_path"`             // Path where repo is cloned
	CreatedAt       time.Time            `json:"created_at" bson:"created_at"`
	UpdatedAt       time.Time            `json:"updated_at" bson:"updated_at"`
}

// AddTronRepoRequest is the request for adding an existing repo
type AddTronRepoRequest struct {
	GitHubURL string `json:"github_url"`
}

// CreateTronRepoRequest is the request for creating a new repo from scratch
type CreateTronRepoRequest struct {
	Name        string   `json:"name"`
	Description string   `json:"description"`
	Stack       string   `json:"stack"`       // "go-api", "flutter-app", "nextjs-web", etc
	Features    []string `json:"features"`    // Initial features to scaffold
	Private     bool     `json:"private"`
}

// TronRepoResponse is the response for a repo with stats
type TronRepoResponse struct {
	TronRepo
	TasksInBacklog int `json:"tasks_in_backlog"`
	TasksCompleted int `json:"tasks_completed"`
	TasksInDev     int `json:"tasks_in_dev"`
}

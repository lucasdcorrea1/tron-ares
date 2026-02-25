package handlers

import (
	"context"
	"encoding/json"
	"log/slog"
	"net/http"
	"regexp"
	"strings"
	"time"

	"github.com/imperium/backend/internal/database"
	"github.com/imperium/backend/internal/middleware"
	"github.com/imperium/backend/internal/models"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// ListTronRepos godoc
// @Summary List repos in a project
// @Description Returns all repos for a specific TRON project
// @Tags tron-repos
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Project ID"
// @Success 200 {array} models.TronRepoResponse
// @Failure 401 {string} string "Unauthorized"
// @Router /tron/projects/{id}/repos [get]
func ListTronRepos(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r)
	if userID == primitive.NilObjectID {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	// Extract project ID from path: /tron/projects/{id}/repos
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

	cursor, err := database.TronRepos().Find(ctx, bson.M{"project_id": projectID})
	if err != nil {
		http.Error(w, "Failed to list repos", http.StatusInternalServerError)
		return
	}
	defer cursor.Close(ctx)

	var repos []models.TronRepo
	if err := cursor.All(ctx, &repos); err != nil {
		http.Error(w, "Failed to decode repos", http.StatusInternalServerError)
		return
	}

	// Build response with stats
	var response []models.TronRepoResponse
	for _, repo := range repos {
		tasksInBacklog, _ := database.TronTasks().CountDocuments(ctx, bson.M{
			"repo_id": repo.ID,
			"status":  models.TaskStatusBacklog,
		})
		tasksCompleted, _ := database.TronTasks().CountDocuments(ctx, bson.M{
			"repo_id": repo.ID,
			"status":  models.TaskStatusDone,
		})
		tasksInDev, _ := database.TronTasks().CountDocuments(ctx, bson.M{
			"repo_id": repo.ID,
			"status":  models.TaskStatusInDev,
		})

		response = append(response, models.TronRepoResponse{
			TronRepo:       repo,
			TasksInBacklog: int(tasksInBacklog),
			TasksCompleted: int(tasksCompleted),
			TasksInDev:     int(tasksInDev),
		})
	}

	if response == nil {
		response = []models.TronRepoResponse{}
	}

	json.NewEncoder(w).Encode(response)
}

// AddTronRepo godoc
// @Summary Add an existing GitHub repo to a project
// @Description Imports an existing GitHub repository to a TRON project
// @Tags tron-repos
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Project ID"
// @Param request body models.AddTronRepoRequest true "Repo URL"
// @Success 201 {object} models.TronRepo
// @Failure 400 {string} string "Invalid request"
// @Failure 401 {string} string "Unauthorized"
// @Router /tron/projects/{id}/repos [post]
func AddTronRepo(w http.ResponseWriter, r *http.Request) {
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

	var req models.AddTronRepoRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	if req.GitHubURL == "" {
		http.Error(w, "GitHub URL is required", http.StatusBadRequest)
		return
	}

	// Validate GitHub URL format
	if !isValidGitHubURL(req.GitHubURL) {
		http.Error(w, "Invalid GitHub URL format", http.StatusBadRequest)
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

	// Check if repo already exists
	count, _ := database.TronRepos().CountDocuments(ctx, bson.M{
		"project_id": projectID,
		"github_url": req.GitHubURL,
	})
	if count > 0 {
		http.Error(w, "Repo already added to this project", http.StatusConflict)
		return
	}

	// Extract repo name from URL
	repoName := extractRepoName(req.GitHubURL)

	repo := models.TronRepo{
		ID:             primitive.NewObjectID(),
		UserID:         userID,
		ProjectID:      projectID,
		GitHubURL:      req.GitHubURL,
		Name:           repoName,
		Stack:          models.TronStack{},
		Analysis:       models.TronRepoAnalysis{},
		CurrentVersion: "0.0.0",
		Health:         models.HealthYellow, // Unknown until analyzed
		Dependencies:   []primitive.ObjectID{},
		ClaudeMDExists: false,
		CreatedAt:      time.Now(),
		UpdatedAt:      time.Now(),
	}

	_, err = database.TronRepos().InsertOne(ctx, repo)
	if err != nil {
		slog.Error("failed to add tron repo", "error", err, "url", req.GitHubURL)
		http.Error(w, "Failed to add repo", http.StatusInternalServerError)
		return
	}

	// Update project repos array
	database.TronProjects().UpdateOne(ctx,
		bson.M{"_id": projectID},
		bson.M{"$push": bson.M{"repos": repo.ID}},
	)

	slog.Info("tron_repo_added",
		"repo_id", repo.ID.Hex(),
		"project_id", projectID.Hex(),
		"url", req.GitHubURL,
	)

	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(repo)
}

// AnalyzeTronRepo godoc
// @Summary Trigger analysis of a repo
// @Description Triggers AI analysis of the repository to detect stack, features, etc
// @Tags tron-repos
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Project ID"
// @Param rid path string true "Repo ID"
// @Success 200 {object} models.TronRepo
// @Failure 401 {string} string "Unauthorized"
// @Failure 404 {string} string "Not found"
// @Router /tron/projects/{id}/repos/{rid}/analyze [post]
func AnalyzeTronRepo(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r)
	if userID == primitive.NilObjectID {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	projectID, repoID, err := extractProjectAndRepoID(r.URL.Path)
	if err != nil {
		http.Error(w, "Invalid IDs", http.StatusBadRequest)
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	// Verify ownership
	var repo models.TronRepo
	err = database.TronRepos().FindOne(ctx, bson.M{
		"_id":        repoID,
		"project_id": projectID,
		"user_id":    userID,
	}).Decode(&repo)
	if err != nil {
		http.Error(w, "Repo not found", http.StatusNotFound)
		return
	}

	// TODO: Implement actual analysis with Claude API
	// For now, return a placeholder analysis
	analysis := models.TronRepoAnalysis{
		Summary:    "Analysis pending - will be performed by Analysis Service",
		Models:     []string{},
		Endpoints:  []string{},
		Features:   []string{},
		Patterns:   []string{},
		AnalyzedAt: time.Now(),
	}

	// Update repo with analysis
	_, err = database.TronRepos().UpdateOne(ctx,
		bson.M{"_id": repoID},
		bson.M{"$set": bson.M{
			"analysis":         analysis,
			"last_analyzed_at": time.Now(),
			"updated_at":       time.Now(),
		}},
	)
	if err != nil {
		http.Error(w, "Failed to update analysis", http.StatusInternalServerError)
		return
	}

	repo.Analysis = analysis
	repo.LastAnalyzedAt = time.Now()

	slog.Info("tron_repo_analysis_triggered",
		"repo_id", repoID.Hex(),
		"project_id", projectID.Hex(),
	)

	json.NewEncoder(w).Encode(repo)
}

// CreateNewTronRepo godoc
// @Summary Create a new repo from scratch
// @Description Creates a new GitHub repository with scaffold based on stack
// @Tags tron-repos
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Project ID"
// @Param request body models.CreateTronRepoRequest true "New repo data"
// @Success 201 {object} models.TronRepo
// @Failure 400 {string} string "Invalid request"
// @Failure 401 {string} string "Unauthorized"
// @Router /tron/projects/{id}/repos/new [post]
func CreateNewTronRepo(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r)
	if userID == primitive.NilObjectID {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	projectID, err := extractProjectIDFromNewPath(r.URL.Path)
	if err != nil {
		http.Error(w, "Invalid project ID", http.StatusBadRequest)
		return
	}

	var req models.CreateTronRepoRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	if req.Name == "" {
		http.Error(w, "Name is required", http.StatusBadRequest)
		return
	}
	if req.Stack == "" {
		http.Error(w, "Stack is required", http.StatusBadRequest)
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

	// TODO: Create repo on GitHub via API
	// For now, just create a placeholder

	stack := parseStack(req.Stack)

	repo := models.TronRepo{
		ID:             primitive.NewObjectID(),
		UserID:         userID,
		ProjectID:      projectID,
		GitHubURL:      "", // Will be set when created on GitHub
		Name:           req.Name,
		Stack:          stack,
		CurrentVersion: "0.1.0",
		Health:         models.HealthGreen,
		Dependencies:   []primitive.ObjectID{},
		ClaudeMDExists: true, // Will create CLAUDE.md
		CreatedAt:      time.Now(),
		UpdatedAt:      time.Now(),
	}

	_, err = database.TronRepos().InsertOne(ctx, repo)
	if err != nil {
		http.Error(w, "Failed to create repo", http.StatusInternalServerError)
		return
	}

	// Update project repos array
	database.TronProjects().UpdateOne(ctx,
		bson.M{"_id": projectID},
		bson.M{"$push": bson.M{"repos": repo.ID}},
	)

	slog.Info("tron_repo_created",
		"repo_id", repo.ID.Hex(),
		"project_id", projectID.Hex(),
		"name", req.Name,
		"stack", req.Stack,
	)

	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(repo)
}

// Helper functions

func extractProjectID(path string) (primitive.ObjectID, error) {
	// Path format: /tron/projects/{id}/repos or /tron/projects/{id}/repos/new
	parts := strings.Split(path, "/")
	for i, part := range parts {
		if part == "projects" && i+1 < len(parts) {
			return primitive.ObjectIDFromHex(parts[i+1])
		}
	}
	return primitive.NilObjectID, http.ErrNoLocation
}

func extractProjectIDFromNewPath(path string) (primitive.ObjectID, error) {
	return extractProjectID(path)
}

func extractProjectAndRepoID(path string) (primitive.ObjectID, primitive.ObjectID, error) {
	// Path format: /tron/projects/{id}/repos/{rid}/analyze
	parts := strings.Split(path, "/")
	var projectID, repoID primitive.ObjectID
	var err error

	for i, part := range parts {
		if part == "projects" && i+1 < len(parts) {
			projectID, err = primitive.ObjectIDFromHex(parts[i+1])
			if err != nil {
				return primitive.NilObjectID, primitive.NilObjectID, err
			}
		}
		if part == "repos" && i+1 < len(parts) && parts[i+1] != "new" {
			repoID, err = primitive.ObjectIDFromHex(parts[i+1])
			if err != nil {
				return primitive.NilObjectID, primitive.NilObjectID, err
			}
		}
	}

	return projectID, repoID, nil
}

func isValidGitHubURL(url string) bool {
	pattern := `^https?://(www\.)?github\.com/[\w-]+/[\w.-]+/?$`
	matched, _ := regexp.MatchString(pattern, url)
	return matched
}

func extractRepoName(url string) string {
	// Remove trailing slash
	url = strings.TrimSuffix(url, "/")
	parts := strings.Split(url, "/")
	if len(parts) > 0 {
		return parts[len(parts)-1]
	}
	return "unknown"
}

func parseStack(stackStr string) models.TronStack {
	stacks := map[string]models.TronStack{
		"go-api": {
			Language:  "go",
			Framework: "stdlib",
			Database:  "mongodb",
			Tools:     []string{"docker", "github-actions"},
		},
		"flutter-app": {
			Language:  "dart",
			Framework: "flutter",
			Database:  "",
			Tools:     []string{"firebase"},
		},
		"nextjs-web": {
			Language:  "typescript",
			Framework: "nextjs",
			Database:  "",
			Tools:     []string{"vercel"},
		},
		"fastapi": {
			Language:  "python",
			Framework: "fastapi",
			Database:  "postgresql",
			Tools:     []string{"docker"},
		},
	}

	if stack, ok := stacks[stackStr]; ok {
		return stack
	}
	return models.TronStack{Language: stackStr}
}

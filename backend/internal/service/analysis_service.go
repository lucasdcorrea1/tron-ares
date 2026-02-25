package service

import (
	"context"
	"encoding/json"
	"fmt"
	"path/filepath"
	"time"

	"github.com/imperium/backend/internal/database"
	"github.com/imperium/backend/internal/middleware"
	"github.com/imperium/backend/internal/models"
	"github.com/imperium/backend/internal/pkg/claude"
	"github.com/imperium/backend/internal/pkg/gitops"
	"go.mongodb.org/mongo-driver/bson"
)

// AnalysisService analyzes repositories
type AnalysisService struct {
	claudeClient *claude.Client
	gitService   *gitops.Service
}

// NewAnalysisService creates a new analysis service
func NewAnalysisService(claudeClient *claude.Client, gitService *gitops.Service) *AnalysisService {
	return &AnalysisService{
		claudeClient: claudeClient,
		gitService:   gitService,
	}
}

// AnalyzeRepo performs AI analysis on a repository
func (s *AnalysisService) AnalyzeRepo(ctx context.Context, repo *models.TronRepo) (*models.TronRepoAnalysis, error) {
	analysis := &models.TronRepoAnalysis{
		AnalyzedAt: time.Now(),
	}

	// Clone or update repo
	var localPath string
	if repo.LocalPath == "" {
		repoInfo, err := s.gitService.Clone(ctx, repo.GitHubURL)
		if err != nil {
			return nil, fmt.Errorf("failed to clone: %w", err)
		}
		localPath = repoInfo.LocalPath
		repo.LocalPath = localPath
	} else {
		localPath = repo.LocalPath
		s.gitService.Pull(ctx, localPath)
	}

	// Detect stack
	stack, err := s.gitService.DetectStack(ctx, localPath)
	if err == nil {
		repo.Stack = models.TronStack{
			Language:  stack.Language,
			Framework: stack.Framework,
			Database:  stack.Database,
			Tools:     stack.Tools,
		}
	}

	// Get file listing
	files, _ := s.gitService.ListFiles(ctx, localPath, "")
	analysis.FileCount = len(files)

	// Count test files
	for _, f := range files {
		if isTestFile(f, repo.Stack.Language) {
			analysis.TestFiles++
		}
	}

	// Count lines of code (simplified)
	analysis.LinesOfCode = estimateLineCount(files)

	// Find TODOs/FIXMEs
	analysis.Todos = findTodos(ctx, localPath, files)

	// Check for CLAUDE.md
	if _, err := s.gitService.ReadFile(ctx, localPath, "CLAUDE.md"); err == nil {
		repo.ClaudeMDExists = true
	}

	// AI analysis for summary and features
	if s.claudeClient != nil {
		aiAnalysis, err := s.performAIAnalysis(ctx, repo, localPath, files)
		if err == nil {
			analysis.Summary = aiAnalysis.Summary
			analysis.Models = aiAnalysis.Models
			analysis.Endpoints = aiAnalysis.Endpoints
			analysis.Features = aiAnalysis.Features
			analysis.Patterns = aiAnalysis.Patterns
		}
	}

	// Update repo in database
	database.TronRepos().UpdateOne(ctx,
		bson.M{"_id": repo.ID},
		bson.M{"$set": bson.M{
			"stack":            repo.Stack,
			"analysis":         analysis,
			"local_path":       repo.LocalPath,
			"claude_md_exists": repo.ClaudeMDExists,
			"last_analyzed_at": time.Now(),
			"updated_at":       time.Now(),
		}},
	)

	// Track metrics
	middleware.IncTronRepoAnalyzed()

	return analysis, nil
}

func (s *AnalysisService) performAIAnalysis(ctx context.Context, repo *models.TronRepo, localPath string, files []string) (*aiAnalysisResult, error) {
	// Read key files for context
	var keyFiles string

	// Read main files based on language
	switch repo.Stack.Language {
	case "go":
		keyFiles = readGoKeyFiles(ctx, s.gitService, localPath, files)
	case "typescript", "javascript":
		keyFiles = readJSKeyFiles(ctx, s.gitService, localPath, files)
	case "dart":
		keyFiles = readDartKeyFiles(ctx, s.gitService, localPath, files)
	case "python":
		keyFiles = readPythonKeyFiles(ctx, s.gitService, localPath, files)
	}

	prompt := fmt.Sprintf(`Analyze this codebase and provide a summary.

REPOSITORY: %s
STACK: %s / %s
FILES COUNT: %d

KEY FILES:
%s

FILE LISTING (first 100):
%v

Analyze and respond with JSON only:
{
  "summary": "2-3 sentence description of what this project does",
  "models": ["list of main data models/entities found"],
  "endpoints": ["list of API endpoints if applicable"],
  "features": ["list of main features implemented"],
  "patterns": ["architectural patterns used (MVC, Clean Architecture, etc)"]
}`,
		repo.Name, repo.Stack.Language, repo.Stack.Framework,
		len(files), keyFiles, truncateSlice(files, 100))

	result, err := s.claudeClient.Complete(ctx, prompt,
		claude.WithSystem("You are a code analyst AI. Always respond with valid JSON only."),
		claude.WithMaxTokens(1024),
		claude.WithTemperature(0.2),
	)
	if err != nil {
		return nil, err
	}

	var aiResult aiAnalysisResult
	// Try to parse, use defaults if failed
	if err := parseJSON(result.Content, &aiResult); err != nil {
		aiResult.Summary = "Analysis completed but couldn't parse details"
	}

	return &aiResult, nil
}

type aiAnalysisResult struct {
	Summary   string   `json:"summary"`
	Models    []string `json:"models"`
	Endpoints []string `json:"endpoints"`
	Features  []string `json:"features"`
	Patterns  []string `json:"patterns"`
}

// Helper functions

func isTestFile(path string, language string) bool {
	switch language {
	case "go":
		return filepath.Ext(path) == ".go" && contains(path, "_test.go")
	case "typescript", "javascript":
		return contains(path, ".test.") || contains(path, ".spec.") || contains(path, "__tests__")
	case "python":
		return contains(path, "test_") || contains(path, "_test.py")
	case "dart":
		return contains(path, "_test.dart")
	}
	return false
}

func estimateLineCount(files []string) int {
	// Rough estimate: average 50 lines per file
	return len(files) * 50
}

func findTodos(ctx context.Context, localPath string, files []string) []string {
	// Simplified - in real implementation would grep files
	return []string{}
}

func readGoKeyFiles(ctx context.Context, gitService *gitops.Service, localPath string, files []string) string {
	var content string
	keyPaths := []string{"main.go", "cmd/api/main.go", "internal/router/router.go"}

	for _, path := range keyPaths {
		if data, err := gitService.ReadFile(ctx, localPath, path); err == nil {
			content += fmt.Sprintf("=== %s ===\n%s\n\n", path, truncateString(string(data), 2000))
		}
	}
	return content
}

func readJSKeyFiles(ctx context.Context, gitService *gitops.Service, localPath string, files []string) string {
	var content string
	keyPaths := []string{"package.json", "src/index.ts", "src/app.ts", "pages/_app.tsx"}

	for _, path := range keyPaths {
		if data, err := gitService.ReadFile(ctx, localPath, path); err == nil {
			content += fmt.Sprintf("=== %s ===\n%s\n\n", path, truncateString(string(data), 2000))
		}
	}
	return content
}

func readDartKeyFiles(ctx context.Context, gitService *gitops.Service, localPath string, files []string) string {
	var content string
	keyPaths := []string{"pubspec.yaml", "lib/main.dart"}

	for _, path := range keyPaths {
		if data, err := gitService.ReadFile(ctx, localPath, path); err == nil {
			content += fmt.Sprintf("=== %s ===\n%s\n\n", path, truncateString(string(data), 2000))
		}
	}
	return content
}

func readPythonKeyFiles(ctx context.Context, gitService *gitops.Service, localPath string, files []string) string {
	var content string
	keyPaths := []string{"requirements.txt", "main.py", "app.py", "setup.py"}

	for _, path := range keyPaths {
		if data, err := gitService.ReadFile(ctx, localPath, path); err == nil {
			content += fmt.Sprintf("=== %s ===\n%s\n\n", path, truncateString(string(data), 2000))
		}
	}
	return content
}

func contains(s, substr string) bool {
	return len(s) >= len(substr) && (s == substr || len(s) > 0 && containsHelper(s, substr))
}

func containsHelper(s, substr string) bool {
	for i := 0; i <= len(s)-len(substr); i++ {
		if s[i:i+len(substr)] == substr {
			return true
		}
	}
	return false
}

func truncateString(s string, maxLen int) string {
	if len(s) <= maxLen {
		return s
	}
	return s[:maxLen] + "\n... (truncated)"
}

func truncateSlice(s []string, maxLen int) []string {
	if len(s) <= maxLen {
		return s
	}
	return s[:maxLen]
}

func parseJSON(content string, v interface{}) error {
	// Try direct parse first
	if err := json.Unmarshal([]byte(content), v); err == nil {
		return nil
	}

	// Try to find JSON in content
	start := 0
	for i, c := range content {
		if c == '{' {
			start = i
			break
		}
	}

	end := len(content)
	for i := len(content) - 1; i >= 0; i-- {
		if content[i] == '}' {
			end = i + 1
			break
		}
	}

	if start < end {
		return json.Unmarshal([]byte(content[start:end]), v)
	}

	return fmt.Errorf("no JSON found")
}

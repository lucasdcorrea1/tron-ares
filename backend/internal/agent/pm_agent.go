package agent

import (
	"context"
	"encoding/json"
	"fmt"
	"math/rand"
	"time"

	"github.com/imperium/backend/internal/models"
	"github.com/imperium/backend/internal/pkg/claude"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// PMAgent is the Product Manager agent that generates tasks
type PMAgent struct {
	client *claude.Client
}

// PMResult represents the output of the PM Agent
type PMResult struct {
	Task    *models.TronTask `json:"task"`
	CostUSD float64          `json:"-"`
}

// NewPMAgent creates a new PM Agent
func NewPMAgent(client *claude.Client) *PMAgent {
	return &PMAgent{client: client}
}

// Run executes the PM Agent
func (a *PMAgent) Run(ctx context.Context, project *models.TronProject, repo *models.TronRepo, workType string, directives []models.TronDirective) (*PMResult, error) {
	// Select lens based on weighted random + context
	lens := a.selectLens(repo, directives)

	// Build context
	features := "No features detected yet"
	if len(repo.Analysis.Features) > 0 {
		features = ""
		for _, f := range repo.Analysis.Features {
			features += "- " + f + "\n"
		}
	}

	directivesStr := ""
	for _, d := range directives {
		directivesStr += fmt.Sprintf("- [%s] %s\n", d.Priority, d.Content)
	}
	if directivesStr == "" {
		directivesStr = "No active directives"
	}

	prompt := fmt.Sprintf(`You are the Product Manager for this repo.

PROJECT: %s
REPO: %s
WORK TYPE (defined by CTO): %s
REFERENCES: %v
EXISTING FEATURES:
%s
CIO DIRECTIVES:
%s

Use the "%s" lens to generate ONE task.

Lenses explained:
- market: Compare with market references, find missing features
- expansion: What does the last feature unlock? Expand naturally
- persona: As a user, what's frustrating or missing?
- code: Technical debt, missing tests, refactoring needs

The task must:
- Be implementable in 1-3 commits
- Be concrete and specific (not "improve code")
- Have enough technical spec for a dev to implement

Respond ONLY with valid JSON (no markdown):
{
  "title": "...",
  "description": "...",
  "source_lens": "%s",
  "reasoning": "why this task now",
  "spec": {
    "what": "what to implement",
    "files_to_create": [],
    "files_to_modify": [],
    "acceptance_criteria": [],
    "tests_required": true,
    "edge_cases": []
  },
  "estimated_size": "small|medium|large",
  "depends_on": [],
  "unlocks": []
}`,
		project.Name, repo.Name, workType,
		project.References, features, directivesStr,
		lens, lens)

	result, err := a.client.Complete(ctx, prompt,
		claude.WithSystem("You are a Product Manager AI. Always respond with valid JSON only."),
		claude.WithMaxTokens(2048),
		claude.WithTemperature(0.5),
	)
	if err != nil {
		return nil, fmt.Errorf("claude api error: %w", err)
	}

	// Parse response
	var taskData struct {
		Title         string             `json:"title"`
		Description   string             `json:"description"`
		SourceLens    string             `json:"source_lens"`
		Reasoning     string             `json:"reasoning"`
		Spec          models.TronTaskSpec `json:"spec"`
		EstimatedSize string             `json:"estimated_size"`
		DependsOn     []string           `json:"depends_on"`
		Unlocks       []string           `json:"unlocks"`
	}

	if err := json.Unmarshal([]byte(result.Content), &taskData); err != nil {
		return nil, fmt.Errorf("failed to parse task: %w", err)
	}

	// Create task model
	task := &models.TronTask{
		ID:            primitive.NewObjectID(),
		RepoID:        repo.ID,
		Title:         taskData.Title,
		Description:   taskData.Description,
		Spec:          taskData.Spec,
		Status:        models.TaskStatusBacklog,
		SourceLens:    models.TronSourceLens(taskData.SourceLens),
		Reasoning:     taskData.Reasoning,
		Priority:      models.PriorityNormal,
		Unlocks:       taskData.Unlocks,
		EstimatedSize: models.TronTaskSize(taskData.EstimatedSize),
		CostUSD:       result.CostUSD,
		TokensUsed:    int64(result.InputTokens + result.OutputTokens),
	}

	// Upgrade priority if aligned with directive
	for _, d := range directives {
		if d.Priority == models.DirectivePriorityHigh || d.Priority == models.DirectivePriorityCritical {
			task.Priority = models.PriorityHigh
			break
		}
	}

	return &PMResult{
		Task:    task,
		CostUSD: result.CostUSD,
	}, nil
}

func (a *PMAgent) selectLens(repo *models.TronRepo, directives []models.TronDirective) string {
	rand.Seed(time.Now().UnixNano())

	// Check for high priority directive
	for _, d := range directives {
		if d.Priority == models.DirectivePriorityHigh || d.Priority == models.DirectivePriorityCritical {
			if rand.Float32() < 0.6 {
				return "directive"
			}
		}
	}

	// Check test coverage
	if repo.TestCoverage < 60 {
		if rand.Float32() < 0.4 {
			return "code"
		}
	}

	// Normal distribution
	r := rand.Float32()
	switch {
	case r < 0.30:
		return "market"
	case r < 0.60:
		return "expansion"
	case r < 0.80:
		return "persona"
	default:
		return "code"
	}
}

package agent

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/imperium/backend/internal/models"
	"github.com/imperium/backend/internal/pkg/claude"
)

// IntegrationAgent handles cross-repo updates
type IntegrationAgent struct {
	client *claude.Client
}

// IntegrationResult represents the output of the Integration Agent
type IntegrationResult struct {
	Updates []RepoUpdate `json:"updates"`
	CostUSD float64      `json:"-"`
}

// RepoUpdate represents an update needed for a dependent repo
type RepoUpdate struct {
	TargetRepo string      `json:"target_repo"`
	Tasks      []TaskBrief `json:"tasks"`
}

// TaskBrief is a brief task description
type TaskBrief struct {
	Title       string `json:"title"`
	Description string `json:"description"`
	Priority    string `json:"priority"`
}

// NewIntegrationAgent creates a new Integration Agent
func NewIntegrationAgent(client *claude.Client) *IntegrationAgent {
	return &IntegrationAgent{client: client}
}

// Run executes the Integration Agent
func (a *IntegrationAgent) Run(ctx context.Context, project *models.TronProject, repos []models.TronRepo) (*IntegrationResult, error) {
	if len(repos) <= 1 {
		// No cross-repo work needed
		return &IntegrationResult{}, nil
	}

	// Build dependency graph
	depGraph := buildDependencyGraph(repos)
	if len(depGraph) == 0 {
		return &IntegrationResult{}, nil
	}

	// Build repos state
	reposState := ""
	for _, r := range repos {
		reposState += fmt.Sprintf(`
Repo: %s
  Version: %s
  Last Commit: %s
  Dependencies: %v
`, r.Name, r.CurrentVersion, r.LastCommitAt.Format("2006-01-02"), getDependencyNames(r, repos))
	}

	prompt := fmt.Sprintf(`You are the Integration Agent for this project ecosystem.

PROJECT: %s

REPOS AND THEIR STATES:
%s

DEPENDENCY GRAPH:
%s

Your task:
1. Identify if any repo's update affects dependent repos
2. For each affected repo, suggest specific tasks to update dependencies
3. Consider:
   - API changes that need downstream updates
   - Shared types/interfaces that changed
   - Version bumps needed in go.mod/package.json
   - Breaking changes that need adaptation

If no cross-repo updates are needed, return empty updates.

Respond ONLY with valid JSON:
{
  "updates": [
    {
      "target_repo": "repo-name",
      "tasks": [
        {
          "title": "task title",
          "description": "what to do",
          "priority": "high|medium|low"
        }
      ]
    }
  ]
}`,
		project.Name, reposState, depGraph)

	result, err := a.client.Complete(ctx, prompt,
		claude.WithSystem("You are an Integration Engineer AI. Always respond with valid JSON only."),
		claude.WithMaxTokens(1024),
		claude.WithTemperature(0.3),
	)
	if err != nil {
		return nil, fmt.Errorf("claude api error: %w", err)
	}

	var intResult IntegrationResult
	if err := json.Unmarshal([]byte(result.Content), &intResult); err != nil {
		intResult = IntegrationResult{}
	}

	intResult.CostUSD = result.CostUSD

	return &intResult, nil
}

func buildDependencyGraph(repos []models.TronRepo) string {
	graph := ""
	for _, r := range repos {
		if len(r.Dependencies) > 0 {
			deps := getDependencyNames(r, repos)
			graph += fmt.Sprintf("%s -> %v\n", r.Name, deps)
		}
	}
	return graph
}

func getDependencyNames(repo models.TronRepo, allRepos []models.TronRepo) []string {
	var names []string
	for _, depID := range repo.Dependencies {
		for _, r := range allRepos {
			if r.ID == depID {
				names = append(names, r.Name)
				break
			}
		}
	}
	return names
}

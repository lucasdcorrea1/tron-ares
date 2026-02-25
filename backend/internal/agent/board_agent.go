package agent

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/imperium/backend/internal/models"
	"github.com/imperium/backend/internal/pkg/claude"
)

// BoardAgent is the CTO agent that decides the cycle plan
type BoardAgent struct {
	client *claude.Client
}

// BoardPlan represents the output of the Board Agent
type BoardPlan struct {
	TargetRepo     string   `json:"target_repo"`
	WorkType       string   `json:"work_type"` // feature, test, refactor, debt, migration
	Reasoning      string   `json:"reasoning"`
	CrossRepoTasks []string `json:"cross_repo_tasks"`
	EscalateToCIO  *struct {
		Title       string `json:"title"`
		Description string `json:"description"`
	} `json:"escalate_to_cio"`
	CostUSD float64 `json:"-"`
}

// NewBoardAgent creates a new Board Agent
func NewBoardAgent(client *claude.Client) *BoardAgent {
	return &BoardAgent{client: client}
}

// Run executes the Board Agent
func (a *BoardAgent) Run(ctx context.Context, project *models.TronProject, repos []models.TronRepo, directives []models.TronDirective) (*BoardPlan, error) {
	if len(repos) == 0 {
		return nil, fmt.Errorf("no repos to analyze")
	}

	// Build repos state
	reposState := buildReposState(repos)

	// Build directives list
	directivesStr := ""
	for _, d := range directives {
		directivesStr += fmt.Sprintf("- [%s] %s\n", d.Priority, d.Content)
	}
	if directivesStr == "" {
		directivesStr = "No active directives"
	}

	prompt := fmt.Sprintf(`You are the CTO of a software house. You manage multiple repos that form an ecosystem.

PROJECT: %s
DESCRIPTION: %s

CURRENT STATE OF REPOS:
%s

CIO DIRECTIVES:
%s

Your task:
1. Analyze the state of each repo
2. Consider the CIO directives
3. Decide which repo to prioritize this cycle
4. Define what type of work to do (feature, test, refactor, debt, migration)
5. If there are pending cross-repo updates, prioritize them

Respond ONLY with valid JSON (no markdown, no explanation):
{
  "target_repo": "repo-name",
  "work_type": "feature|test|refactor|debt|migration",
  "reasoning": "why this decision",
  "cross_repo_tasks": [],
  "escalate_to_cio": null
}`, project.Name, project.Description, reposState, directivesStr)

	result, err := a.client.Complete(ctx, prompt,
		claude.WithSystem("You are a technical CTO AI. Always respond with valid JSON only."),
		claude.WithMaxTokens(1024),
		claude.WithTemperature(0.3),
	)
	if err != nil {
		return nil, fmt.Errorf("claude api error: %w", err)
	}

	var plan BoardPlan
	if err := json.Unmarshal([]byte(result.Content), &plan); err != nil {
		// Try to extract JSON from response
		plan = BoardPlan{
			TargetRepo: repos[0].Name,
			WorkType:   "feature",
			Reasoning:  "Defaulting to first repo due to parse error",
		}
	}

	plan.CostUSD = result.CostUSD

	return &plan, nil
}

func buildReposState(repos []models.TronRepo) string {
	state := ""
	for _, r := range repos {
		state += fmt.Sprintf(`
Repo: %s
  URL: %s
  Stack: %s/%s
  Version: %s
  Health: %s
  Test Coverage: %.1f%%
  Last Commit: %s
  Commits Streak: %d days
`, r.Name, r.GitHubURL, r.Stack.Language, r.Stack.Framework,
			r.CurrentVersion, r.Health, r.TestCoverage,
			r.LastCommitAt.Format("2006-01-02"), r.CommitsStreak)
	}
	return state
}

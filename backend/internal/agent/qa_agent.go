package agent

import (
	"context"
	"encoding/json"
	"fmt"
	"os/exec"

	"github.com/imperium/backend/internal/database"
	"github.com/imperium/backend/internal/models"
	"github.com/imperium/backend/internal/pkg/claude"
	"github.com/imperium/backend/internal/pkg/gitops"
	"go.mongodb.org/mongo-driver/bson"
)

// QAAgent reviews code changes
type QAAgent struct {
	client     *claude.Client
	gitService *gitops.Service
}

// QAAgentResult represents the output of the QA Agent
type QAAgentResult struct {
	Approved bool
	QAResult *models.TronQAResult
	CostUSD  float64
}

// NewQAAgent creates a new QA Agent
func NewQAAgent(client *claude.Client, gitService *gitops.Service) *QAAgent {
	return &QAAgent{
		client:     client,
		gitService: gitService,
	}
}

// Run executes the QA Agent
func (a *QAAgent) Run(ctx context.Context, task *models.TronTask) (*QAAgentResult, error) {
	result := &QAAgentResult{
		QAResult: &models.TronQAResult{
			Checks: models.TronQAChecks{},
		},
	}

	// Get repo
	var repo models.TronRepo
	err := database.TronRepos().FindOne(ctx, bson.M{"_id": task.RepoID}).Decode(&repo)
	if err != nil {
		return nil, fmt.Errorf("repo not found: %w", err)
	}

	// Run automated checks
	result.QAResult.Checks.BuildPassed = a.checkBuild(ctx, repo.LocalPath, &repo)
	result.QAResult.Checks.TestsPassed = a.checkTests(ctx, repo.LocalPath, &repo)
	result.QAResult.Checks.LinterClean = a.checkLinter(ctx, repo.LocalPath, &repo)

	// Get diff
	diff, err := a.getDiff(ctx, repo.LocalPath, task.BranchName)
	if err != nil {
		return nil, fmt.Errorf("failed to get diff: %w", err)
	}

	// If automated checks fail, reject without AI review
	if !result.QAResult.Checks.BuildPassed {
		result.Approved = false
		result.QAResult.Result = "REJECTED"
		result.QAResult.Feedback = "Build failed. Please fix build errors."
		return result, nil
	}

	if !result.QAResult.Checks.TestsPassed {
		result.Approved = false
		result.QAResult.Result = "NEEDS_FIX"
		result.QAResult.Feedback = "Tests failed. Please fix failing tests."
		return result, nil
	}

	// AI Review
	prompt := fmt.Sprintf(`You are the QA reviewer for this project.

TASK ORIGINAL SPEC:
Title: %s
Description: %s
What to implement: %s
Acceptance Criteria: %v

DIFF (changes made):
%s

AUTOMATED CHECKS:
- Build: %s
- Tests: %s
- Linter: %s

CHECKLIST:
1. Does the code implement what the spec asks?
2. Does it follow project patterns?
3. Are there unhandled edge cases?
4. Are there obvious bugs?
5. Is there dead or unnecessary code?
6. Are the tests meaningful (not trivial)?
7. Are names clear and descriptive?
8. Is error handling adequate?

If minor issues (1-2): return NEEDS_FIX with specific feedback
If major issues: return REJECTED with reason
If all good: return APPROVED

Respond ONLY with valid JSON:
{
  "result": "APPROVED|NEEDS_FIX|REJECTED",
  "feedback": "overall feedback",
  "issues": [
    { "file": "path/to/file.go", "line": 42, "issue": "description", "severity": "minor|major" }
  ]
}`,
		task.Title, task.Description, task.Spec.What, task.Spec.AcceptanceCriteria,
		diff,
		boolToStatus(result.QAResult.Checks.BuildPassed),
		boolToStatus(result.QAResult.Checks.TestsPassed),
		boolToStatus(result.QAResult.Checks.LinterClean),
	)

	aiResult, err := a.client.Complete(ctx, prompt,
		claude.WithSystem("You are a QA Engineer AI. Always respond with valid JSON only."),
		claude.WithMaxTokens(1024),
		claude.WithTemperature(0.2),
	)
	if err != nil {
		return nil, fmt.Errorf("claude api error: %w", err)
	}

	result.CostUSD = aiResult.CostUSD

	// Parse AI response
	var qaResponse struct {
		Result   string `json:"result"`
		Feedback string `json:"feedback"`
		Issues   []struct {
			File     string `json:"file"`
			Line     int    `json:"line"`
			Issue    string `json:"issue"`
			Severity string `json:"severity"`
		} `json:"issues"`
	}

	if err := json.Unmarshal([]byte(aiResult.Content), &qaResponse); err != nil {
		// Default to needs fix if can't parse
		result.QAResult.Result = "NEEDS_FIX"
		result.QAResult.Feedback = "Review parse error - manual review needed"
		return result, nil
	}

	result.QAResult.Result = qaResponse.Result
	result.QAResult.Feedback = qaResponse.Feedback

	for _, issue := range qaResponse.Issues {
		result.QAResult.Issues = append(result.QAResult.Issues, models.TronQAIssue{
			File:     issue.File,
			Line:     issue.Line,
			Issue:    issue.Issue,
			Severity: issue.Severity,
		})
	}

	result.Approved = qaResponse.Result == "APPROVED"

	return result, nil
}

func (a *QAAgent) checkBuild(ctx context.Context, repoPath string, repo *models.TronRepo) bool {
	var cmd *exec.Cmd

	switch repo.Stack.Language {
	case "go":
		cmd = exec.CommandContext(ctx, "go", "build", "./...")
	case "typescript", "javascript":
		cmd = exec.CommandContext(ctx, "npm", "run", "build")
	default:
		return true
	}

	cmd.Dir = repoPath
	return cmd.Run() == nil
}

func (a *QAAgent) checkTests(ctx context.Context, repoPath string, repo *models.TronRepo) bool {
	var cmd *exec.Cmd

	switch repo.Stack.Language {
	case "go":
		cmd = exec.CommandContext(ctx, "go", "test", "./...")
	case "typescript", "javascript":
		cmd = exec.CommandContext(ctx, "npm", "test")
	case "python":
		cmd = exec.CommandContext(ctx, "pytest")
	default:
		return true
	}

	cmd.Dir = repoPath
	return cmd.Run() == nil
}

func (a *QAAgent) checkLinter(ctx context.Context, repoPath string, repo *models.TronRepo) bool {
	var cmd *exec.Cmd

	switch repo.Stack.Language {
	case "go":
		cmd = exec.CommandContext(ctx, "golangci-lint", "run")
	case "typescript", "javascript":
		cmd = exec.CommandContext(ctx, "npm", "run", "lint")
	default:
		return true
	}

	cmd.Dir = repoPath
	return cmd.Run() == nil
}

func (a *QAAgent) getDiff(ctx context.Context, repoPath, branchName string) (string, error) {
	// Get diff against main
	cmd := exec.CommandContext(ctx, "git", "-C", repoPath, "diff", "main..."+branchName)
	output, err := cmd.Output()
	if err != nil {
		// Try master
		cmd = exec.CommandContext(ctx, "git", "-C", repoPath, "diff", "master..."+branchName)
		output, err = cmd.Output()
		if err != nil {
			return "", err
		}
	}

	diff := string(output)

	// Truncate if too long
	if len(diff) > 10000 {
		diff = diff[:10000] + "\n... (truncated)"
	}

	return diff, nil
}

func boolToStatus(b bool) string {
	if b {
		return "PASSED"
	}
	return "FAILED"
}

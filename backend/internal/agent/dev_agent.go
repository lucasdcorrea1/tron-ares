package agent

import (
	"context"
	"fmt"
	"os/exec"
	"strings"
	"time"

	"github.com/imperium/backend/internal/database"
	"github.com/imperium/backend/internal/models"
	"github.com/imperium/backend/internal/pkg/claude"
	"github.com/imperium/backend/internal/pkg/gitops"
	"go.mongodb.org/mongo-driver/bson"
)

// DevAgent implements tasks using Claude Code CLI
type DevAgent struct {
	client     *claude.Client
	gitService *gitops.Service
}

// DevResult represents the output of the Dev Agent
type DevResult struct {
	Success   bool
	Commits   []models.TronTaskCommit
	CostUSD   float64
	Error     string
	Attempts  int
}

// NewDevAgent creates a new Dev Agent
func NewDevAgent(client *claude.Client, gitService *gitops.Service) *DevAgent {
	return &DevAgent{
		client:     client,
		gitService: gitService,
	}
}

// Run executes the Dev Agent
func (a *DevAgent) Run(ctx context.Context, task *models.TronTask) (*DevResult, error) {
	result := &DevResult{}

	// Get repo info
	var repo models.TronRepo
	err := database.TronRepos().FindOne(ctx, bson.M{"_id": task.RepoID}).Decode(&repo)
	if err != nil {
		return nil, fmt.Errorf("repo not found: %w", err)
	}

	// Ensure repo is cloned
	if repo.LocalPath == "" {
		repoInfo, err := a.gitService.Clone(ctx, repo.GitHubURL)
		if err != nil {
			return nil, fmt.Errorf("failed to clone repo: %w", err)
		}
		repo.LocalPath = repoInfo.LocalPath

		// Update repo with local path
		database.TronRepos().UpdateOne(ctx,
			bson.M{"_id": repo.ID},
			bson.M{"$set": bson.M{"local_path": repo.LocalPath}},
		)
	} else {
		// Pull latest
		a.gitService.Pull(ctx, repo.LocalPath)
	}

	// Generate branch name
	branchName := fmt.Sprintf("feat/%s-%s", task.ID.Hex()[:8], slugify(task.Title))
	task.BranchName = branchName

	// Create branch
	if err := a.gitService.CreateBranch(ctx, repo.LocalPath, branchName); err != nil {
		return nil, fmt.Errorf("failed to create branch: %w", err)
	}

	// Build the prompt for Claude Code
	prompt := buildDevPrompt(task)

	// Try up to 3 times
	maxAttempts := 3
	for attempt := 1; attempt <= maxAttempts; attempt++ {
		result.Attempts = attempt

		// Run Claude Code CLI
		err := a.runClaudeCode(ctx, repo.LocalPath, prompt)
		if err != nil {
			result.Error = err.Error()
			if attempt < maxAttempts {
				continue
			}
			return result, nil
		}

		// Run build
		buildErr := a.runBuild(ctx, repo.LocalPath, &repo)
		if buildErr != nil {
			result.Error = "Build failed: " + buildErr.Error()
			// Try to fix with Claude Code
			fixPrompt := fmt.Sprintf("The build failed with error:\n%s\n\nPlease fix the issue.", buildErr.Error())
			a.runClaudeCode(ctx, repo.LocalPath, fixPrompt)
			continue
		}

		// Run tests
		testErr := a.runTests(ctx, repo.LocalPath, &repo)
		if testErr != nil {
			result.Error = "Tests failed: " + testErr.Error()
			if attempt < maxAttempts {
				fixPrompt := fmt.Sprintf("Tests failed with error:\n%s\n\nPlease fix the failing tests.", testErr.Error())
				a.runClaudeCode(ctx, repo.LocalPath, fixPrompt)
				continue
			}
			return result, nil
		}

		// Success! Get commits
		commits, err := a.getCommits(ctx, repo.LocalPath)
		if err == nil {
			result.Commits = commits
		}

		// Push branch
		a.gitService.Push(ctx, repo.LocalPath, branchName)

		result.Success = true
		break
	}

	task.DevAttempts = result.Attempts

	return result, nil
}

func (a *DevAgent) runClaudeCode(ctx context.Context, repoPath, prompt string) error {
	// Use Claude Code CLI
	cmd := exec.CommandContext(ctx, "claude", "-p", prompt)
	cmd.Dir = repoPath

	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("claude code error: %s - %w", string(output), err)
	}

	return nil
}

func (a *DevAgent) runBuild(ctx context.Context, repoPath string, repo *models.TronRepo) error {
	var cmd *exec.Cmd

	switch repo.Stack.Language {
	case "go":
		cmd = exec.CommandContext(ctx, "go", "build", "./...")
	case "typescript", "javascript":
		cmd = exec.CommandContext(ctx, "npm", "run", "build")
	case "python":
		// Python doesn't need build usually
		return nil
	case "dart":
		cmd = exec.CommandContext(ctx, "flutter", "build")
	default:
		return nil
	}

	cmd.Dir = repoPath
	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("%s", string(output))
	}

	return nil
}

func (a *DevAgent) runTests(ctx context.Context, repoPath string, repo *models.TronRepo) error {
	var cmd *exec.Cmd

	switch repo.Stack.Language {
	case "go":
		cmd = exec.CommandContext(ctx, "go", "test", "./...")
	case "typescript", "javascript":
		cmd = exec.CommandContext(ctx, "npm", "test")
	case "python":
		cmd = exec.CommandContext(ctx, "pytest")
	case "dart":
		cmd = exec.CommandContext(ctx, "flutter", "test")
	default:
		return nil
	}

	cmd.Dir = repoPath
	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("%s", string(output))
	}

	return nil
}

func (a *DevAgent) getCommits(ctx context.Context, repoPath string) ([]models.TronTaskCommit, error) {
	// Get commits since branching from main
	cmd := exec.CommandContext(ctx, "git", "-C", repoPath, "log", "main..HEAD", "--format=%H|%s")
	output, err := cmd.Output()
	if err != nil {
		// Try master
		cmd = exec.CommandContext(ctx, "git", "-C", repoPath, "log", "master..HEAD", "--format=%H|%s")
		output, err = cmd.Output()
		if err != nil {
			return nil, err
		}
	}

	var commits []models.TronTaskCommit
	lines := strings.Split(strings.TrimSpace(string(output)), "\n")
	for _, line := range lines {
		if line == "" {
			continue
		}
		parts := strings.SplitN(line, "|", 2)
		if len(parts) == 2 {
			commits = append(commits, models.TronTaskCommit{
				SHA:       parts[0],
				Message:   parts[1],
				CreatedAt: time.Now(),
			})
		}
	}

	return commits, nil
}

func buildDevPrompt(task *models.TronTask) string {
	return fmt.Sprintf(`You are the developer for this project. Implement the following task:

TASK: %s

DESCRIPTION: %s

SPECIFICATION:
%s

FILES TO CREATE: %v
FILES TO MODIFY: %v

ACCEPTANCE CRITERIA:
%v

EDGE CASES TO HANDLE:
%v

RULES:
- Follow the project's existing patterns and CLAUDE.md if present
- Make small, focused commits
- Run build and tests before finishing
- Don't modify files outside the scope of this task
- If creating new files, follow the existing structure

Start implementing now.`,
		task.Title,
		task.Description,
		task.Spec.What,
		task.Spec.FilesToCreate,
		task.Spec.FilesToModify,
		task.Spec.AcceptanceCriteria,
		task.Spec.EdgeCases,
	)
}

func slugify(s string) string {
	s = strings.ToLower(s)
	s = strings.ReplaceAll(s, " ", "-")
	// Remove special characters
	result := ""
	for _, c := range s {
		if (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') || c == '-' {
			result += string(c)
		}
	}
	// Limit length
	if len(result) > 30 {
		result = result[:30]
	}
	return result
}

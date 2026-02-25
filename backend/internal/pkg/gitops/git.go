package gitops

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"
	"time"
)

// Service provides git operations
type Service struct {
	workDir     string
	githubToken string
	httpClient  *http.Client
}

// RepoInfo represents information about a repository
type RepoInfo struct {
	Owner       string
	Name        string
	FullName    string
	URL         string
	LocalPath   string
	DefaultBranch string
}

// CommitInfo represents information about a commit
type CommitInfo struct {
	SHA          string
	Message      string
	Author       string
	Date         time.Time
	FilesChanged int
	Additions    int
	Deletions    int
}

// DiffInfo represents a diff between two refs
type DiffInfo struct {
	Ref1       string
	Ref2       string
	Files      []FileDiff
	TotalAdded int
	TotalRemoved int
}

// FileDiff represents changes to a single file
type FileDiff struct {
	Path      string
	Status    string // "added", "modified", "deleted"
	Additions int
	Deletions int
	Patch     string
}

// StackDetection represents detected stack information
type StackDetection struct {
	Language    string
	Framework   string
	Database    string
	PackageFile string
	Tools       []string
}

// NewService creates a new git service
func NewService(workDir string) (*Service, error) {
	githubToken := os.Getenv("GITHUB_TOKEN")
	if githubToken == "" {
		slog.Warn("GITHUB_TOKEN not set, some operations may fail")
	}

	// Create work directory if it doesn't exist
	if err := os.MkdirAll(workDir, 0755); err != nil {
		return nil, fmt.Errorf("failed to create work directory: %w", err)
	}

	return &Service{
		workDir:     workDir,
		githubToken: githubToken,
		httpClient: &http.Client{
			Timeout: 60 * time.Second,
		},
	}, nil
}

// Clone clones a repository
func (s *Service) Clone(ctx context.Context, repoURL string) (*RepoInfo, error) {
	info := parseRepoURL(repoURL)
	info.LocalPath = filepath.Join(s.workDir, info.FullName)

	// Remove existing directory if it exists
	os.RemoveAll(info.LocalPath)

	// Prepare clone URL with token if available
	cloneURL := repoURL
	if s.githubToken != "" {
		cloneURL = fmt.Sprintf("https://%s@github.com/%s.git", s.githubToken, info.FullName)
	}

	// Clone
	cmd := exec.CommandContext(ctx, "git", "clone", "--depth=1", cloneURL, info.LocalPath)
	output, err := cmd.CombinedOutput()
	if err != nil {
		return nil, fmt.Errorf("git clone failed: %s - %w", string(output), err)
	}

	// Get default branch
	cmd = exec.CommandContext(ctx, "git", "-C", info.LocalPath, "rev-parse", "--abbrev-ref", "HEAD")
	branchOutput, err := cmd.Output()
	if err == nil {
		info.DefaultBranch = strings.TrimSpace(string(branchOutput))
	} else {
		info.DefaultBranch = "main"
	}

	slog.Info("git_clone_success",
		"repo", info.FullName,
		"path", info.LocalPath,
	)

	return info, nil
}

// Pull pulls latest changes
func (s *Service) Pull(ctx context.Context, localPath string) error {
	cmd := exec.CommandContext(ctx, "git", "-C", localPath, "pull", "--rebase")
	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("git pull failed: %s - %w", string(output), err)
	}
	return nil
}

// CreateBranch creates a new branch
func (s *Service) CreateBranch(ctx context.Context, localPath, branchName string) error {
	// Checkout main first
	cmd := exec.CommandContext(ctx, "git", "-C", localPath, "checkout", "main")
	cmd.Run() // Ignore error, might be "master"

	cmd = exec.CommandContext(ctx, "git", "-C", localPath, "checkout", "master")
	cmd.Run()

	// Create and checkout new branch
	cmd = exec.CommandContext(ctx, "git", "-C", localPath, "checkout", "-b", branchName)
	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("git checkout -b failed: %s - %w", string(output), err)
	}

	slog.Info("git_branch_created",
		"path", localPath,
		"branch", branchName,
	)

	return nil
}

// Commit creates a commit with the given message
func (s *Service) Commit(ctx context.Context, localPath, message string) (*CommitInfo, error) {
	// Add all changes
	cmd := exec.CommandContext(ctx, "git", "-C", localPath, "add", "-A")
	output, err := cmd.CombinedOutput()
	if err != nil {
		return nil, fmt.Errorf("git add failed: %s - %w", string(output), err)
	}

	// Check if there are changes to commit
	cmd = exec.CommandContext(ctx, "git", "-C", localPath, "status", "--porcelain")
	statusOutput, _ := cmd.Output()
	if len(strings.TrimSpace(string(statusOutput))) == 0 {
		return nil, fmt.Errorf("no changes to commit")
	}

	// Commit
	cmd = exec.CommandContext(ctx, "git", "-C", localPath, "commit", "-m", message)
	output, err = cmd.CombinedOutput()
	if err != nil {
		return nil, fmt.Errorf("git commit failed: %s - %w", string(output), err)
	}

	// Get commit info
	cmd = exec.CommandContext(ctx, "git", "-C", localPath, "log", "-1", "--format=%H|%s|%an|%ai")
	logOutput, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("git log failed: %w", err)
	}

	parts := strings.SplitN(strings.TrimSpace(string(logOutput)), "|", 4)
	if len(parts) < 4 {
		return nil, fmt.Errorf("unexpected git log format")
	}

	commitDate, _ := time.Parse("2006-01-02 15:04:05 -0700", parts[3])

	// Get stats
	cmd = exec.CommandContext(ctx, "git", "-C", localPath, "diff", "--stat", "HEAD~1", "HEAD")
	statOutput, _ := cmd.Output()
	additions, deletions, files := parseGitStat(string(statOutput))

	info := &CommitInfo{
		SHA:          parts[0],
		Message:      parts[1],
		Author:       parts[2],
		Date:         commitDate,
		FilesChanged: files,
		Additions:    additions,
		Deletions:    deletions,
	}

	slog.Info("git_commit_success",
		"sha", info.SHA[:8],
		"message", info.Message,
	)

	return info, nil
}

// Push pushes changes to remote
func (s *Service) Push(ctx context.Context, localPath, branchName string) error {
	cmd := exec.CommandContext(ctx, "git", "-C", localPath, "push", "-u", "origin", branchName)
	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("git push failed: %s - %w", string(output), err)
	}

	slog.Info("git_push_success",
		"path", localPath,
		"branch", branchName,
	)

	return nil
}

// GetDiff returns the diff between two refs
func (s *Service) GetDiff(ctx context.Context, localPath, ref1, ref2 string) (*DiffInfo, error) {
	cmd := exec.CommandContext(ctx, "git", "-C", localPath, "diff", ref1+"..."+ref2)
	output, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("git diff failed: %w", err)
	}

	// Parse diff output
	diff := &DiffInfo{
		Ref1:  ref1,
		Ref2:  ref2,
		Files: parseDiffOutput(string(output)),
	}

	for _, f := range diff.Files {
		diff.TotalAdded += f.Additions
		diff.TotalRemoved += f.Deletions
	}

	return diff, nil
}

// DetectStack analyzes a repository and detects the tech stack
func (s *Service) DetectStack(ctx context.Context, localPath string) (*StackDetection, error) {
	stack := &StackDetection{}

	// Check for Go
	if _, err := os.Stat(filepath.Join(localPath, "go.mod")); err == nil {
		stack.Language = "go"
		stack.PackageFile = "go.mod"
		stack.Tools = append(stack.Tools, "go-modules")

		// Check for common frameworks
		content, _ := os.ReadFile(filepath.Join(localPath, "go.mod"))
		if bytes.Contains(content, []byte("gin-gonic")) {
			stack.Framework = "gin"
		} else if bytes.Contains(content, []byte("gorilla/mux")) {
			stack.Framework = "gorilla"
		} else if bytes.Contains(content, []byte("labstack/echo")) {
			stack.Framework = "echo"
		} else {
			stack.Framework = "stdlib"
		}

		// Check for database
		if bytes.Contains(content, []byte("mongo-driver")) {
			stack.Database = "mongodb"
		} else if bytes.Contains(content, []byte("lib/pq")) || bytes.Contains(content, []byte("pgx")) {
			stack.Database = "postgresql"
		}
	}

	// Check for Node.js/TypeScript
	if _, err := os.Stat(filepath.Join(localPath, "package.json")); err == nil {
		content, _ := os.ReadFile(filepath.Join(localPath, "package.json"))

		if bytes.Contains(content, []byte("typescript")) {
			stack.Language = "typescript"
		} else {
			stack.Language = "javascript"
		}
		stack.PackageFile = "package.json"
		stack.Tools = append(stack.Tools, "npm")

		// Check for frameworks
		if bytes.Contains(content, []byte("next")) {
			stack.Framework = "nextjs"
		} else if bytes.Contains(content, []byte("express")) {
			stack.Framework = "express"
		} else if bytes.Contains(content, []byte("react")) {
			stack.Framework = "react"
		} else if bytes.Contains(content, []byte("vue")) {
			stack.Framework = "vue"
		}
	}

	// Check for Flutter/Dart
	if _, err := os.Stat(filepath.Join(localPath, "pubspec.yaml")); err == nil {
		stack.Language = "dart"
		stack.Framework = "flutter"
		stack.PackageFile = "pubspec.yaml"
	}

	// Check for Python
	if _, err := os.Stat(filepath.Join(localPath, "requirements.txt")); err == nil {
		stack.Language = "python"
		stack.PackageFile = "requirements.txt"

		content, _ := os.ReadFile(filepath.Join(localPath, "requirements.txt"))
		if bytes.Contains(content, []byte("fastapi")) {
			stack.Framework = "fastapi"
		} else if bytes.Contains(content, []byte("django")) {
			stack.Framework = "django"
		} else if bytes.Contains(content, []byte("flask")) {
			stack.Framework = "flask"
		}
	}

	// Check for Docker
	if _, err := os.Stat(filepath.Join(localPath, "Dockerfile")); err == nil {
		stack.Tools = append(stack.Tools, "docker")
	}
	if _, err := os.Stat(filepath.Join(localPath, "docker-compose.yml")); err == nil {
		stack.Tools = append(stack.Tools, "docker-compose")
	}

	// Check for GitHub Actions
	if _, err := os.Stat(filepath.Join(localPath, ".github", "workflows")); err == nil {
		stack.Tools = append(stack.Tools, "github-actions")
	}

	return stack, nil
}

// ListFiles returns a list of files in the repository
func (s *Service) ListFiles(ctx context.Context, localPath string, pattern string) ([]string, error) {
	cmd := exec.CommandContext(ctx, "git", "-C", localPath, "ls-files")
	if pattern != "" {
		cmd = exec.CommandContext(ctx, "git", "-C", localPath, "ls-files", pattern)
	}

	output, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("git ls-files failed: %w", err)
	}

	files := strings.Split(strings.TrimSpace(string(output)), "\n")
	if len(files) == 1 && files[0] == "" {
		return []string{}, nil
	}

	return files, nil
}

// ReadFile reads a file from the repository
func (s *Service) ReadFile(ctx context.Context, localPath, filePath string) ([]byte, error) {
	fullPath := filepath.Join(localPath, filePath)
	return os.ReadFile(fullPath)
}

// GetCurrentBranch returns the current branch name
func (s *Service) GetCurrentBranch(ctx context.Context, localPath string) (string, error) {
	cmd := exec.CommandContext(ctx, "git", "-C", localPath, "rev-parse", "--abbrev-ref", "HEAD")
	output, err := cmd.Output()
	if err != nil {
		return "", fmt.Errorf("git rev-parse failed: %w", err)
	}
	return strings.TrimSpace(string(output)), nil
}

// CreateGitHubRepo creates a new repository on GitHub
func (s *Service) CreateGitHubRepo(ctx context.Context, name, description string, private bool) (string, error) {
	if s.githubToken == "" {
		return "", fmt.Errorf("GITHUB_TOKEN not set")
	}

	body := map[string]interface{}{
		"name":        name,
		"description": description,
		"private":     private,
		"auto_init":   true,
	}

	jsonBody, _ := json.Marshal(body)

	req, err := http.NewRequestWithContext(ctx, "POST", "https://api.github.com/user/repos", bytes.NewReader(jsonBody))
	if err != nil {
		return "", err
	}

	req.Header.Set("Authorization", "Bearer "+s.githubToken)
	req.Header.Set("Accept", "application/vnd.github+json")
	req.Header.Set("Content-Type", "application/json")

	resp, err := s.httpClient.Do(req)
	if err != nil {
		return "", fmt.Errorf("github api request failed: %w", err)
	}
	defer resp.Body.Close()

	respBody, _ := io.ReadAll(resp.Body)

	if resp.StatusCode != http.StatusCreated {
		return "", fmt.Errorf("github api error (%d): %s", resp.StatusCode, string(respBody))
	}

	var result struct {
		HTMLURL string `json:"html_url"`
	}
	json.Unmarshal(respBody, &result)

	slog.Info("github_repo_created",
		"name", name,
		"url", result.HTMLURL,
	)

	return result.HTMLURL, nil
}

// Helper functions

func parseRepoURL(url string) *RepoInfo {
	// Handle both https and git@ formats
	info := &RepoInfo{URL: url}

	// Extract owner/name from URL
	re := regexp.MustCompile(`github\.com[/:]([^/]+)/([^/.]+)`)
	matches := re.FindStringSubmatch(url)
	if len(matches) >= 3 {
		info.Owner = matches[1]
		info.Name = strings.TrimSuffix(matches[2], ".git")
		info.FullName = info.Owner + "/" + info.Name
	}

	return info
}

func parseGitStat(stat string) (additions, deletions, files int) {
	lines := strings.Split(stat, "\n")
	for _, line := range lines {
		if strings.Contains(line, "insertions") || strings.Contains(line, "deletions") {
			// Parse summary line
			re := regexp.MustCompile(`(\d+) files? changed`)
			if m := re.FindStringSubmatch(line); len(m) > 1 {
				fmt.Sscanf(m[1], "%d", &files)
			}

			re = regexp.MustCompile(`(\d+) insertions?`)
			if m := re.FindStringSubmatch(line); len(m) > 1 {
				fmt.Sscanf(m[1], "%d", &additions)
			}

			re = regexp.MustCompile(`(\d+) deletions?`)
			if m := re.FindStringSubmatch(line); len(m) > 1 {
				fmt.Sscanf(m[1], "%d", &deletions)
			}
		}
	}
	return
}

func parseDiffOutput(diff string) []FileDiff {
	var files []FileDiff

	// Simple parsing - split by "diff --git"
	chunks := strings.Split(diff, "diff --git ")
	for _, chunk := range chunks[1:] { // Skip first empty chunk
		lines := strings.Split(chunk, "\n")
		if len(lines) == 0 {
			continue
		}

		// Parse file name
		re := regexp.MustCompile(`a/(.+) b/(.+)`)
		matches := re.FindStringSubmatch(lines[0])
		if len(matches) < 3 {
			continue
		}

		file := FileDiff{
			Path: matches[2],
		}

		// Determine status
		for _, line := range lines {
			if strings.HasPrefix(line, "new file") {
				file.Status = "added"
			} else if strings.HasPrefix(line, "deleted file") {
				file.Status = "deleted"
			}
			if strings.HasPrefix(line, "+") && !strings.HasPrefix(line, "+++") {
				file.Additions++
			}
			if strings.HasPrefix(line, "-") && !strings.HasPrefix(line, "---") {
				file.Deletions++
			}
		}

		if file.Status == "" {
			file.Status = "modified"
		}

		file.Patch = chunk
		files = append(files, file)
	}

	return files
}

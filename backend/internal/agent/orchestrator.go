package agent

import (
	"context"
	"fmt"
	"log/slog"
	"sync"
	"time"

	"github.com/imperium/backend/internal/database"
	"github.com/imperium/backend/internal/handlers"
	"github.com/imperium/backend/internal/middleware"
	"github.com/imperium/backend/internal/models"
	"github.com/imperium/backend/internal/pkg/claude"
	"github.com/imperium/backend/internal/pkg/gitops"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// Orchestrator coordinates all agents for a project
type Orchestrator struct {
	projectID   primitive.ObjectID
	userID      primitive.ObjectID
	claudeClient *claude.Client
	gitService  *gitops.Service

	// Agents
	boardAgent       *BoardAgent
	pmAgent          *PMAgent
	devAgent         *DevAgent
	qaAgent          *QAAgent
	integrationAgent *IntegrationAgent

	// State
	isRunning bool
	mu        sync.Mutex

	// Limits
	maxRetries    int
	dailyBudget   float64
	currentCost   float64
}

// CycleResult represents the result of a cycle
type CycleResult struct {
	ProjectID      primitive.ObjectID
	CycleID        string
	StartTime      time.Time
	EndTime        time.Time
	TasksCreated   int
	TasksCompleted int
	TasksRejected  int
	Commits        int
	CostUSD        float64
	Errors         []string
}

// NewOrchestrator creates a new orchestrator for a project
func NewOrchestrator(projectID, userID primitive.ObjectID, claudeClient *claude.Client, gitService *gitops.Service) *Orchestrator {
	o := &Orchestrator{
		projectID:    projectID,
		userID:       userID,
		claudeClient: claudeClient,
		gitService:   gitService,
		maxRetries:   3,
		dailyBudget:  5.0, // Default $5/day
	}

	// Initialize agents
	o.boardAgent = NewBoardAgent(claudeClient)
	o.pmAgent = NewPMAgent(claudeClient)
	o.devAgent = NewDevAgent(claudeClient, gitService)
	o.qaAgent = NewQAAgent(claudeClient, gitService)
	o.integrationAgent = NewIntegrationAgent(claudeClient)

	return o
}

// RunCycle executes a full agent cycle
func (o *Orchestrator) RunCycle(ctx context.Context) (*CycleResult, error) {
	o.mu.Lock()
	if o.isRunning {
		o.mu.Unlock()
		return nil, fmt.Errorf("cycle already running")
	}
	o.isRunning = true
	o.mu.Unlock()

	defer func() {
		o.mu.Lock()
		o.isRunning = false
		o.mu.Unlock()
	}()

	result := &CycleResult{
		ProjectID: o.projectID,
		CycleID:   primitive.NewObjectID().Hex(),
		StartTime: time.Now(),
	}

	slog.Info("tron_cycle_started",
		"project_id", o.projectID.Hex(),
		"cycle_id", result.CycleID,
	)

	// Increment cycle metric
	middleware.IncTronCycle()

	// Get project with repos
	project, repos, err := o.loadProjectData(ctx)
	if err != nil {
		result.Errors = append(result.Errors, err.Error())
		return result, err
	}

	// Check budget
	if o.currentCost >= project.DailyBudget {
		slog.Warn("tron_cycle_budget_exceeded",
			"project_id", o.projectID.Hex(),
			"current_cost", o.currentCost,
			"budget", project.DailyBudget,
		)
		result.Errors = append(result.Errors, "daily budget exceeded")
		return result, nil
	}

	// Get active directives
	directives := o.getActiveDirectives(ctx)

	// Step 1: Board Agent decides the plan
	slog.Info("tron_cycle_step", "step", "board_agent", "project_id", o.projectID.Hex())
	middleware.IncTronAgentRun("board")
	boardPlan, err := o.boardAgent.Run(ctx, project, repos, directives)
	if err != nil {
		o.logAgentError(ctx, models.AgentTypeBoard, "run", err)
		result.Errors = append(result.Errors, fmt.Sprintf("board agent: %v", err))
	} else {
		o.logAgentSuccess(ctx, models.AgentTypeBoard, "run", boardPlan)
		result.CostUSD += boardPlan.CostUSD
		middleware.AddTronAPICost(boardPlan.CostUSD)
	}

	// Step 2: PM Agent generates tasks
	if boardPlan != nil && boardPlan.TargetRepo != "" {
		slog.Info("tron_cycle_step", "step", "pm_agent", "target_repo", boardPlan.TargetRepo)
		middleware.IncTronAgentRun("pm")

		targetRepo := o.findRepo(repos, boardPlan.TargetRepo)
		if targetRepo != nil {
			pmResult, err := o.pmAgent.Run(ctx, project, targetRepo, boardPlan.WorkType, directives)
			if err != nil {
				o.logAgentError(ctx, models.AgentTypePM, "run", err)
				result.Errors = append(result.Errors, fmt.Sprintf("pm agent: %v", err))
			} else {
				o.logAgentSuccess(ctx, models.AgentTypePM, "run", pmResult)
				result.TasksCreated++
				result.CostUSD += pmResult.CostUSD
				middleware.AddTronAPICost(pmResult.CostUSD)
				middleware.IncTronTaskCreated()

				// Save the task
				if pmResult.Task != nil {
					o.saveTask(ctx, pmResult.Task)
					handlers.BroadcastTaskUpdate(pmResult.Task)
				}
			}
		}
	}

	// Step 3: Dev Agent implements ready tasks
	readyTasks := o.getReadyTasks(ctx)
	for _, task := range readyTasks {
		if o.currentCost+result.CostUSD >= project.DailyBudget {
			slog.Warn("tron_cycle_budget_limit", "remaining_tasks", len(readyTasks))
			break
		}

		slog.Info("tron_cycle_step", "step", "dev_agent", "task_id", task.ID.Hex())
		middleware.IncTronAgentRun("dev")

		devResult, err := o.devAgent.Run(ctx, &task)
		if err != nil {
			o.logAgentError(ctx, models.AgentTypeDev, "run", err)
			result.Errors = append(result.Errors, fmt.Sprintf("dev agent: %v", err))
			continue
		}

		o.logAgentSuccess(ctx, models.AgentTypeDev, "run", devResult)
		result.CostUSD += devResult.CostUSD
		result.Commits += len(devResult.Commits)
		middleware.AddTronAPICost(devResult.CostUSD)

		// Update task status
		task.Status = models.TaskStatusInReview
		task.Commits = devResult.Commits
		o.updateTask(ctx, &task)
		handlers.BroadcastTaskUpdate(&task)
	}

	// Step 4: QA Agent reviews tasks in review
	reviewTasks := o.getTasksInReview(ctx)
	for _, task := range reviewTasks {
		slog.Info("tron_cycle_step", "step", "qa_agent", "task_id", task.ID.Hex())
		middleware.IncTronAgentRun("qa")

		qaResult, err := o.qaAgent.Run(ctx, &task)
		if err != nil {
			o.logAgentError(ctx, models.AgentTypeQA, "run", err)
			result.Errors = append(result.Errors, fmt.Sprintf("qa agent: %v", err))
			continue
		}

		o.logAgentSuccess(ctx, models.AgentTypeQA, "run", qaResult)
		result.CostUSD += qaResult.CostUSD
		middleware.AddTronAPICost(qaResult.CostUSD)
		middleware.IncTronQAReview(qaResult.QAResult.Result)

		// Update task based on QA result
		task.QAResult = qaResult.QAResult
		if qaResult.Approved {
			task.Status = models.TaskStatusDone
			result.TasksCompleted++
			middleware.IncTronTaskCompleted()
		} else {
			if task.DevAttempts >= 3 {
				task.Status = models.TaskStatusRejected
				result.TasksRejected++
				middleware.IncTronTaskFailed()
			} else {
				task.Status = models.TaskStatusReady // Back to dev
			}
		}
		o.updateTask(ctx, &task)
		handlers.BroadcastTaskUpdate(&task)
	}

	// Step 5: Integration Agent (if there were completions)
	if result.TasksCompleted > 0 {
		slog.Info("tron_cycle_step", "step", "integration_agent")
		middleware.IncTronAgentRun("integration")
		intResult, err := o.integrationAgent.Run(ctx, project, repos)
		if err != nil {
			o.logAgentError(ctx, models.AgentTypeIntegration, "run", err)
		} else {
			o.logAgentSuccess(ctx, models.AgentTypeIntegration, "run", intResult)
			result.CostUSD += intResult.CostUSD
			middleware.AddTronAPICost(intResult.CostUSD)
		}
	}

	result.EndTime = time.Now()

	// Update daily metrics
	o.updateMetrics(ctx, result)

	slog.Info("tron_cycle_completed",
		"project_id", o.projectID.Hex(),
		"cycle_id", result.CycleID,
		"duration_ms", result.EndTime.Sub(result.StartTime).Milliseconds(),
		"tasks_created", result.TasksCreated,
		"tasks_completed", result.TasksCompleted,
		"cost_usd", result.CostUSD,
	)

	return result, nil
}

// Helper methods

func (o *Orchestrator) loadProjectData(ctx context.Context) (*models.TronProject, []models.TronRepo, error) {
	var project models.TronProject
	err := database.TronProjects().FindOne(ctx, bson.M{
		"_id":     o.projectID,
		"user_id": o.userID,
	}).Decode(&project)
	if err != nil {
		return nil, nil, fmt.Errorf("project not found: %w", err)
	}

	cursor, err := database.TronRepos().Find(ctx, bson.M{"project_id": o.projectID})
	if err != nil {
		return nil, nil, fmt.Errorf("failed to load repos: %w", err)
	}
	defer cursor.Close(ctx)

	var repos []models.TronRepo
	if err := cursor.All(ctx, &repos); err != nil {
		return nil, nil, err
	}

	return &project, repos, nil
}

func (o *Orchestrator) getActiveDirectives(ctx context.Context) []models.TronDirective {
	cursor, _ := database.TronDirectives().Find(ctx, bson.M{
		"project_id": o.projectID,
		"active":     true,
	})
	defer cursor.Close(ctx)

	var directives []models.TronDirective
	cursor.All(ctx, &directives)
	return directives
}

func (o *Orchestrator) getReadyTasks(ctx context.Context) []models.TronTask {
	cursor, _ := database.TronTasks().Find(ctx, bson.M{
		"project_id": o.projectID,
		"status":     models.TaskStatusReady,
	})
	defer cursor.Close(ctx)

	var tasks []models.TronTask
	cursor.All(ctx, &tasks)
	return tasks
}

func (o *Orchestrator) getTasksInReview(ctx context.Context) []models.TronTask {
	cursor, _ := database.TronTasks().Find(ctx, bson.M{
		"project_id": o.projectID,
		"status":     models.TaskStatusInReview,
	})
	defer cursor.Close(ctx)

	var tasks []models.TronTask
	cursor.All(ctx, &tasks)
	return tasks
}

func (o *Orchestrator) findRepo(repos []models.TronRepo, name string) *models.TronRepo {
	for i := range repos {
		if repos[i].Name == name {
			return &repos[i]
		}
	}
	return nil
}

func (o *Orchestrator) saveTask(ctx context.Context, task *models.TronTask) {
	task.UserID = o.userID
	task.ProjectID = o.projectID
	task.CreatedAt = time.Now()
	task.UpdatedAt = time.Now()
	database.TronTasks().InsertOne(ctx, task)
}

func (o *Orchestrator) updateTask(ctx context.Context, task *models.TronTask) {
	task.UpdatedAt = time.Now()
	database.TronTasks().UpdateOne(ctx,
		bson.M{"_id": task.ID},
		bson.M{"$set": task},
	)
}

func (o *Orchestrator) logAgentError(ctx context.Context, agentType models.TronAgentType, action string, err error) {
	log := &models.TronAgentLog{
		ID:        primitive.NewObjectID(),
		UserID:    o.userID,
		ProjectID: o.projectID,
		AgentType: agentType,
		Action:    action,
		Success:   false,
		Error:     err.Error(),
		CreatedAt: time.Now(),
	}
	database.TronAgentLogs().InsertOne(ctx, log)
	handlers.BroadcastAgentLog(log)
}

func (o *Orchestrator) logAgentSuccess(ctx context.Context, agentType models.TronAgentType, action string, result interface{}) {
	log := &models.TronAgentLog{
		ID:            primitive.NewObjectID(),
		UserID:        o.userID,
		ProjectID:     o.projectID,
		AgentType:     agentType,
		Action:        action,
		OutputSummary: fmt.Sprintf("%+v", result),
		Success:       true,
		CreatedAt:     time.Now(),
	}
	database.TronAgentLogs().InsertOne(ctx, log)
	handlers.BroadcastAgentLog(log)
}

func (o *Orchestrator) updateMetrics(ctx context.Context, result *CycleResult) {
	today := time.Now().Truncate(24 * time.Hour)

	// Upsert today's metrics
	database.TronMetrics().UpdateOne(ctx,
		bson.M{
			"project_id": o.projectID,
			"repo_id":    nil,
			"date":       today,
		},
		bson.M{
			"$inc": bson.M{
				"commits_count":   result.Commits,
				"tasks_created":   result.TasksCreated,
				"tasks_completed": result.TasksCompleted,
				"tasks_rejected":  result.TasksRejected,
				"api_cost_usd":    result.CostUSD,
			},
			"$setOnInsert": bson.M{
				"_id":        primitive.NewObjectID(),
				"user_id":    o.userID,
				"project_id": o.projectID,
				"date":       today,
				"created_at": time.Now(),
			},
			"$set": bson.M{
				"updated_at": time.Now(),
			},
		},
	)
}

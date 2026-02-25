package agent

import (
	"context"
	"log/slog"
	"sync"
	"time"

	"github.com/imperium/backend/internal/database"
	"github.com/imperium/backend/internal/models"
	"github.com/imperium/backend/internal/pkg/claude"
	"github.com/imperium/backend/internal/pkg/gitops"
	"github.com/robfig/cron/v3"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// Scheduler manages scheduled agent cycles
type Scheduler struct {
	cron         *cron.Cron
	orchestrators map[primitive.ObjectID]*Orchestrator
	gitService   *gitops.Service
	mu           sync.RWMutex
	running      bool
}

// ScheduleConfig represents scheduling configuration
type ScheduleConfig struct {
	// Normal frequency: 4 times per day
	// High frequency: 8 times per day
	// Low frequency: 2 times per day
	NormalCron string
	HighCron   string
	LowCron    string
}

// DefaultScheduleConfig returns default scheduling
func DefaultScheduleConfig() ScheduleConfig {
	return ScheduleConfig{
		// Normal: 6am, 12pm, 6pm, 11pm
		NormalCron: "0 6,12,18,23 * * *",
		// High: every 3 hours
		HighCron: "0 */3 * * *",
		// Low: 9am and 9pm
		LowCron: "0 9,21 * * *",
	}
}

var (
	globalScheduler *Scheduler
	schedulerOnce   sync.Once
)

// GetScheduler returns the global scheduler instance
func GetScheduler() *Scheduler {
	schedulerOnce.Do(func() {
		gitService, err := gitops.NewService("/tmp/tron-repos")
		if err != nil {
			slog.Error("failed to create git service", "error", err)
		}

		globalScheduler = &Scheduler{
			cron:          cron.New(),
			orchestrators: make(map[primitive.ObjectID]*Orchestrator),
			gitService:    gitService,
		}
	})
	return globalScheduler
}

// Start starts the scheduler
func (s *Scheduler) Start() error {
	s.mu.Lock()
	defer s.mu.Unlock()

	if s.running {
		return nil
	}

	// Load all active projects and schedule them
	ctx := context.Background()
	cursor, err := database.TronProjects().Find(ctx, bson.M{"is_active": true})
	if err != nil {
		return err
	}
	defer cursor.Close(ctx)

	var projects []models.TronProject
	if err := cursor.All(ctx, &projects); err != nil {
		return err
	}

	for _, project := range projects {
		if err := s.scheduleProject(project); err != nil {
			slog.Error("failed to schedule project",
				"project_id", project.ID.Hex(),
				"error", err,
			)
		}
	}

	// Add cleanup job (runs daily at 3am)
	s.cron.AddFunc("0 3 * * *", func() {
		s.cleanupOldLogs()
	})

	// Add metrics aggregation job (runs every hour)
	s.cron.AddFunc("0 * * * *", func() {
		s.aggregateMetrics()
	})

	s.cron.Start()
	s.running = true

	slog.Info("tron_scheduler_started", "projects", len(projects))

	return nil
}

// Stop stops the scheduler
func (s *Scheduler) Stop() {
	s.mu.Lock()
	defer s.mu.Unlock()

	if !s.running {
		return
	}

	s.cron.Stop()
	s.running = false

	slog.Info("tron_scheduler_stopped")
}

// ScheduleProject adds or updates scheduling for a project
func (s *Scheduler) ScheduleProject(project models.TronProject) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	return s.scheduleProject(project)
}

func (s *Scheduler) scheduleProject(project models.TronProject) error {
	config := DefaultScheduleConfig()

	var cronExpr string
	switch project.Frequency {
	case models.FrequencyHigh:
		cronExpr = config.HighCron
	case models.FrequencyLow:
		cronExpr = config.LowCron
	default:
		cronExpr = config.NormalCron
	}

	// Add some jitter to prevent all projects running at exactly the same time
	// Add random minute offset (0-59)
	jitter := int(project.ID.Timestamp().Unix() % 60)
	cronExpr = cronExpr[:2] + string(rune('0'+jitter/10)) + string(rune('0'+jitter%10)) + cronExpr[2:]

	_, err := s.cron.AddFunc(cronExpr, func() {
		s.runProjectCycle(project.ID, project.UserID)
	})

	if err != nil {
		return err
	}

	slog.Info("tron_project_scheduled",
		"project_id", project.ID.Hex(),
		"frequency", project.Frequency,
		"cron", cronExpr,
	)

	return nil
}

// UnscheduleProject removes scheduling for a project
func (s *Scheduler) UnscheduleProject(projectID primitive.ObjectID) {
	s.mu.Lock()
	defer s.mu.Unlock()

	// Remove orchestrator
	delete(s.orchestrators, projectID)

	slog.Info("tron_project_unscheduled", "project_id", projectID.Hex())
}

// RunProjectCycleNow triggers an immediate cycle for a project
func (s *Scheduler) RunProjectCycleNow(projectID, userID primitive.ObjectID) error {
	go s.runProjectCycle(projectID, userID)
	return nil
}

func (s *Scheduler) runProjectCycle(projectID, userID primitive.ObjectID) {
	s.mu.RLock()
	orchestrator, exists := s.orchestrators[projectID]
	s.mu.RUnlock()

	if !exists {
		// Create new orchestrator
		claudeClient, err := claude.NewClient()
		if err != nil {
			slog.Error("failed to create claude client",
				"project_id", projectID.Hex(),
				"error", err,
			)
			return
		}

		orchestrator = NewOrchestrator(projectID, userID, claudeClient, s.gitService)

		s.mu.Lock()
		s.orchestrators[projectID] = orchestrator
		s.mu.Unlock()
	}

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Minute)
	defer cancel()

	result, err := orchestrator.RunCycle(ctx)
	if err != nil {
		slog.Error("tron_cycle_error",
			"project_id", projectID.Hex(),
			"error", err,
		)
		return
	}

	slog.Info("tron_cycle_result",
		"project_id", projectID.Hex(),
		"tasks_created", result.TasksCreated,
		"tasks_completed", result.TasksCompleted,
		"cost_usd", result.CostUSD,
	)
}

func (s *Scheduler) cleanupOldLogs() {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Minute)
	defer cancel()

	// Delete logs older than 30 days
	cutoff := time.Now().AddDate(0, 0, -30)

	result, err := database.TronAgentLogs().DeleteMany(ctx, bson.M{
		"created_at": bson.M{"$lt": cutoff},
	})

	if err != nil {
		slog.Error("failed to cleanup old logs", "error", err)
		return
	}

	if result.DeletedCount > 0 {
		slog.Info("tron_logs_cleaned", "deleted", result.DeletedCount)
	}
}

func (s *Scheduler) aggregateMetrics() {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Minute)
	defer cancel()

	// Get all active projects
	cursor, err := database.TronProjects().Find(ctx, bson.M{"is_active": true})
	if err != nil {
		return
	}
	defer cursor.Close(ctx)

	var projects []models.TronProject
	cursor.All(ctx, &projects)

	today := time.Now().Truncate(24 * time.Hour)

	for _, project := range projects {
		// Aggregate today's metrics from agent logs
		pipeline := []bson.M{
			{"$match": bson.M{
				"project_id": project.ID,
				"created_at": bson.M{"$gte": today},
			}},
			{"$group": bson.M{
				"_id":          nil,
				"total_cost":   bson.M{"$sum": "$metrics.cost_usd"},
				"total_tokens": bson.M{"$sum": bson.M{"$add": []string{"$metrics.tokens_input", "$metrics.tokens_output"}}},
				"agent_runs":   bson.M{"$sum": 1},
			}},
		}

		var result struct {
			TotalCost   float64 `bson:"total_cost"`
			TotalTokens int64   `bson:"total_tokens"`
			AgentRuns   int     `bson:"agent_runs"`
		}

		aggCursor, _ := database.TronAgentLogs().Aggregate(ctx, pipeline)
		if aggCursor.Next(ctx) {
			aggCursor.Decode(&result)
		}
		aggCursor.Close(ctx)

		// Update metrics
		database.TronMetrics().UpdateOne(ctx,
			bson.M{
				"project_id": project.ID,
				"repo_id":    nil,
				"date":       today,
			},
			bson.M{
				"$set": bson.M{
					"api_cost_usd": result.TotalCost,
					"tokens_used":  result.TotalTokens,
					"updated_at":   time.Now(),
				},
				"$setOnInsert": bson.M{
					"_id":        primitive.NewObjectID(),
					"user_id":    project.UserID,
					"project_id": project.ID,
					"date":       today,
					"created_at": time.Now(),
				},
			},
		)
	}
}

// GetNextCycleTime returns the next scheduled cycle time for a project
func (s *Scheduler) GetNextCycleTime(projectID primitive.ObjectID) *time.Time {
	entries := s.cron.Entries()
	for _, entry := range entries {
		// Note: cron library doesn't provide easy way to map entries to projects
		// This is a simplified implementation
		next := entry.Next
		return &next
	}
	return nil
}

// IsProjectRunning checks if a project cycle is currently running
func (s *Scheduler) IsProjectRunning(projectID primitive.ObjectID) bool {
	s.mu.RLock()
	defer s.mu.RUnlock()

	if orchestrator, exists := s.orchestrators[projectID]; exists {
		orchestrator.mu.Lock()
		defer orchestrator.mu.Unlock()
		return orchestrator.isRunning
	}
	return false
}

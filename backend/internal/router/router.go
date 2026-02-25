package router

import (
	"net/http"
	"strings"

	"github.com/imperium/backend/internal/handlers"
	"github.com/imperium/backend/internal/middleware"
	httpSwagger "github.com/swaggo/http-swagger"
)

func New() http.Handler {
	mux := http.NewServeMux()

	// ==========================================
	// PUBLIC ROUTES (no auth required)
	// ==========================================

	// Swagger UI
	mux.HandleFunc("/swagger/", httpSwagger.WrapHandler)

	// Health check
	mux.HandleFunc("GET /api/v1/health", func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte(`{"status":"ok"}`))
	})

	// Prometheus metrics endpoint
	mux.Handle("GET /metrics", middleware.PrometheusHandler())

	// Auth routes (public)
	mux.HandleFunc("POST /api/v1/auth/register", handlers.Register)
	mux.HandleFunc("POST /api/v1/auth/login", handlers.Login)

	// ==========================================
	// PROTECTED ROUTES (auth required)
	// ==========================================

	// Auth - Me (protected)
	mux.Handle("GET /api/v1/auth/me", middleware.Auth(http.HandlerFunc(handlers.Me)))

	// Profile routes (protected)
	mux.Handle("GET /api/v1/profile", middleware.Auth(http.HandlerFunc(handlers.GetProfile)))
	mux.Handle("PUT /api/v1/profile", middleware.Auth(http.HandlerFunc(handlers.UpdateProfile)))
	mux.Handle("POST /api/v1/profile/avatar", middleware.Auth(http.HandlerFunc(handlers.UploadAvatar)))

	// Profile Stats routes (protected) - for charts and analytics
	mux.Handle("GET /api/v1/profile/stats", middleware.Auth(http.HandlerFunc(handlers.GetProfileStats)))
	mux.Handle("GET /api/v1/profile/stats/breakdown", middleware.Auth(http.HandlerFunc(handlers.GetExpenseBreakdown)))
	mux.Handle("GET /api/v1/profile/stats/income", middleware.Auth(http.HandlerFunc(handlers.GetIncomeBreakdown)))
	mux.Handle("GET /api/v1/profile/stats/daily", middleware.Auth(http.HandlerFunc(handlers.GetDailyStats)))

	// Connected Accounts routes (protected)
	mux.Handle("GET /api/v1/accounts", middleware.Auth(http.HandlerFunc(handlers.GetConnectedAccounts)))
	mux.Handle("POST /api/v1/accounts", middleware.Auth(http.HandlerFunc(handlers.ConnectAccount)))
	mux.Handle("GET /api/v1/accounts/providers", http.HandlerFunc(handlers.GetBankProviders))
	mux.Handle("GET /api/v1/accounts/summary", middleware.Auth(http.HandlerFunc(handlers.GetAccountsSummary)))

	// Connected Account by ID (protected)
	mux.Handle("/api/v1/accounts/", middleware.Auth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		path := r.URL.Path

		// Handle /accounts/providers and /accounts/summary
		if strings.HasSuffix(path, "/providers") {
			handlers.GetBankProviders(w, r)
			return
		}
		if strings.HasSuffix(path, "/summary") {
			handlers.GetAccountsSummary(w, r)
			return
		}

		// Handle /accounts/{id}/sync
		if strings.HasSuffix(path, "/sync") && r.Method == http.MethodPost {
			handlers.SyncAccountBalance(w, r)
			return
		}

		switch r.Method {
		case http.MethodGet:
			handlers.GetConnectedAccount(w, r)
		case http.MethodPut:
			handlers.UpdateConnectedAccount(w, r)
		case http.MethodDelete:
			handlers.DeleteConnectedAccount(w, r)
		default:
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		}
	})))

	// Transactions routes (protected)
	mux.Handle("GET /api/v1/transactions", middleware.Auth(http.HandlerFunc(handlers.GetTransactions)))
	mux.Handle("POST /api/v1/transactions", middleware.Auth(http.HandlerFunc(handlers.CreateTransaction)))
	mux.Handle("GET /api/v1/transactions/balance", middleware.Auth(http.HandlerFunc(handlers.GetBalance)))

	// Transaction by ID (protected, custom routing for path params)
	mux.Handle("/api/v1/transactions/", middleware.Auth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Skip if it's the balance endpoint
		if strings.HasSuffix(r.URL.Path, "/balance") {
			handlers.GetBalance(w, r)
			return
		}

		switch r.Method {
		case http.MethodGet:
			handlers.GetTransaction(w, r)
		case http.MethodPut:
			handlers.UpdateTransaction(w, r)
		case http.MethodDelete:
			handlers.DeleteTransaction(w, r)
		default:
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		}
	})))

	// ==========================================
	// TRON ROUTES (protected)
	// ==========================================

	// TRON Projects
	mux.Handle("GET /api/v1/tron/projects", middleware.Auth(http.HandlerFunc(handlers.ListTronProjects)))
	mux.Handle("POST /api/v1/tron/projects", middleware.Auth(http.HandlerFunc(handlers.CreateTronProject)))

	// TRON Project by ID and nested routes
	mux.Handle("/api/v1/tron/projects/", middleware.Auth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		path := r.URL.Path

		// Handle /tron/projects/{id}/repos
		if strings.Contains(path, "/repos") {
			// Handle /repos/new
			if strings.HasSuffix(path, "/repos/new") && r.Method == http.MethodPost {
				handlers.CreateNewTronRepo(w, r)
				return
			}
			// Handle /repos/{rid}/analyze
			if strings.HasSuffix(path, "/analyze") && r.Method == http.MethodPost {
				handlers.AnalyzeTronRepo(w, r)
				return
			}
			// Handle /repos
			if strings.HasSuffix(path, "/repos") {
				switch r.Method {
				case http.MethodGet:
					handlers.ListTronRepos(w, r)
				case http.MethodPost:
					handlers.AddTronRepo(w, r)
				default:
					http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
				}
				return
			}
			return
		}

		// Handle /tron/projects/{id}/tasks
		if strings.HasSuffix(path, "/tasks") {
			if r.Method == http.MethodGet {
				handlers.ListTronTasks(w, r)
				return
			}
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
			return
		}

		// Handle /tron/projects/{id}/agents
		if strings.Contains(path, "/agents") {
			if strings.HasSuffix(path, "/agents/run") && r.Method == http.MethodPost {
				handlers.RunTronAgentCycle(w, r)
				return
			}
			if strings.HasSuffix(path, "/agents") && r.Method == http.MethodGet {
				handlers.GetTronAgentsStatus(w, r)
				return
			}
			return
		}

		// Handle /tron/projects/{id}/decisions
		if strings.HasSuffix(path, "/decisions") && r.Method == http.MethodGet {
			handlers.ListTronDecisions(w, r)
			return
		}

		// Handle /tron/projects/{id}/directives
		if strings.HasSuffix(path, "/directives") {
			switch r.Method {
			case http.MethodGet:
				handlers.ListTronDirectives(w, r)
			case http.MethodPost:
				handlers.CreateTronDirective(w, r)
			default:
				http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
			}
			return
		}

		// Handle /tron/projects/{id}/metrics
		if strings.Contains(path, "/metrics") {
			if strings.HasSuffix(path, "/metrics/daily") {
				handlers.GetTronDailyMetrics(w, r)
				return
			}
			if strings.HasSuffix(path, "/metrics") {
				handlers.GetTronMetrics(w, r)
				return
			}
			return
		}

		// Handle /tron/projects/{id}/logs
		if strings.HasSuffix(path, "/logs") && r.Method == http.MethodGet {
			handlers.ListTronLogs(w, r)
			return
		}

		// Handle /tron/projects/{id}/ws
		if strings.HasSuffix(path, "/ws") {
			handlers.HandleTronWebSocket(w, r)
			return
		}

		// Handle /tron/projects/{id} - single project CRUD
		switch r.Method {
		case http.MethodGet:
			handlers.GetTronProject(w, r)
		case http.MethodPut:
			handlers.UpdateTronProject(w, r)
		case http.MethodDelete:
			handlers.DeleteTronProject(w, r)
		default:
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		}
	})))

	// TRON Tasks by ID
	mux.Handle("/api/v1/tron/tasks/", middleware.Auth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case http.MethodGet:
			handlers.GetTronTask(w, r)
		case http.MethodPatch:
			handlers.UpdateTronTask(w, r)
		default:
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		}
	})))

	// TRON Decisions by ID
	mux.Handle("/api/v1/tron/decisions/", middleware.Auth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if strings.HasSuffix(r.URL.Path, "/resolve") && r.Method == http.MethodPost {
			handlers.ResolveTronDecision(w, r)
			return
		}
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
	})))

	// ==========================================
	// GLOBAL MIDDLEWARES
	// ==========================================

	var handler http.Handler = mux
	handler = middleware.JSON(handler)
	handler = middleware.CORS(handler)
	handler = middleware.MetricsMiddleware(handler)
	handler = middleware.Logger(handler)

	return handler
}

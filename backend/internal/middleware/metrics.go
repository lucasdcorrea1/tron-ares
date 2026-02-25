package middleware

import (
	"net/http"
	"strconv"
	"sync"
	"time"
)

// Metrics stores HTTP metrics
type Metrics struct {
	mu              sync.RWMutex
	requestsTotal   map[string]int64
	requestDuration map[string][]float64
	responseSizes   map[string][]int
	activeRequests  int64
	startTime       time.Time

	// User metrics
	usersRegistered   int64
	usersLoginSuccess int64
	usersLoginFailed  int64
	authErrors        int64
	profileUpdates    int64
	avatarUploads     int64

	// Account metrics
	accountsConnected    int64
	accountsDisconnected int64
	accountsSynced       int64

	// Stats metrics
	statsRequests int64

	// TRON metrics
	tronCyclesTotal       int64
	tronTasksCreated      int64
	tronTasksCompleted    int64
	tronTasksFailed       int64
	tronAgentRuns         map[string]int64 // keyed by agent type
	tronAPICostUSD        float64
	tronTokensUsed        int64
	tronReposAnalyzed     int64
	tronQAReviews         map[string]int64 // keyed by result (approved, needs_fix, rejected)
	tronActiveProjects    int64
	tronDecisionsPending  int64
	tronDecisionsResolved int64
}

var metrics = &Metrics{
	requestsTotal:   make(map[string]int64),
	requestDuration: make(map[string][]float64),
	responseSizes:   make(map[string][]int),
	startTime:       time.Now(),
	tronAgentRuns:   make(map[string]int64),
	tronQAReviews:   make(map[string]int64),
}

// GetMetrics returns the global metrics instance
func GetMetrics() *Metrics {
	return metrics
}

// User metrics increment functions
func IncUserRegistered() {
	metrics.mu.Lock()
	metrics.usersRegistered++
	metrics.mu.Unlock()
}

func IncLoginSuccess() {
	metrics.mu.Lock()
	metrics.usersLoginSuccess++
	metrics.mu.Unlock()
}

func IncLoginFailed() {
	metrics.mu.Lock()
	metrics.usersLoginFailed++
	metrics.mu.Unlock()
}

func IncAuthError() {
	metrics.mu.Lock()
	metrics.authErrors++
	metrics.mu.Unlock()
}

func IncProfileUpdate() {
	metrics.mu.Lock()
	metrics.profileUpdates++
	metrics.mu.Unlock()
}

func IncAvatarUpload() {
	metrics.mu.Lock()
	metrics.avatarUploads++
	metrics.mu.Unlock()
}

func IncAccountConnected() {
	metrics.mu.Lock()
	metrics.accountsConnected++
	metrics.mu.Unlock()
}

func IncAccountDisconnected() {
	metrics.mu.Lock()
	metrics.accountsDisconnected++
	metrics.mu.Unlock()
}

func IncAccountSynced() {
	metrics.mu.Lock()
	metrics.accountsSynced++
	metrics.mu.Unlock()
}

func IncStatsRequest() {
	metrics.mu.Lock()
	metrics.statsRequests++
	metrics.mu.Unlock()
}

// TRON metrics increment functions

func IncTronCycle() {
	metrics.mu.Lock()
	metrics.tronCyclesTotal++
	metrics.mu.Unlock()
}

func IncTronTaskCreated() {
	metrics.mu.Lock()
	metrics.tronTasksCreated++
	metrics.mu.Unlock()
}

func IncTronTaskCompleted() {
	metrics.mu.Lock()
	metrics.tronTasksCompleted++
	metrics.mu.Unlock()
}

func IncTronTaskFailed() {
	metrics.mu.Lock()
	metrics.tronTasksFailed++
	metrics.mu.Unlock()
}

func IncTronAgentRun(agentType string) {
	metrics.mu.Lock()
	metrics.tronAgentRuns[agentType]++
	metrics.mu.Unlock()
}

func AddTronAPICost(cost float64) {
	metrics.mu.Lock()
	metrics.tronAPICostUSD += cost
	metrics.mu.Unlock()
}

func AddTronTokens(tokens int64) {
	metrics.mu.Lock()
	metrics.tronTokensUsed += tokens
	metrics.mu.Unlock()
}

func IncTronRepoAnalyzed() {
	metrics.mu.Lock()
	metrics.tronReposAnalyzed++
	metrics.mu.Unlock()
}

func IncTronQAReview(result string) {
	metrics.mu.Lock()
	metrics.tronQAReviews[result]++
	metrics.mu.Unlock()
}

func SetTronActiveProjects(count int64) {
	metrics.mu.Lock()
	metrics.tronActiveProjects = count
	metrics.mu.Unlock()
}

func IncTronDecisionPending() {
	metrics.mu.Lock()
	metrics.tronDecisionsPending++
	metrics.mu.Unlock()
}

func DecTronDecisionPending() {
	metrics.mu.Lock()
	if metrics.tronDecisionsPending > 0 {
		metrics.tronDecisionsPending--
	}
	metrics.mu.Unlock()
}

func IncTronDecisionResolved() {
	metrics.mu.Lock()
	metrics.tronDecisionsResolved++
	metrics.mu.Unlock()
}

// MetricsMiddleware collects HTTP metrics
func MetricsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Skip metrics endpoint itself
		if r.URL.Path == "/metrics" {
			next.ServeHTTP(w, r)
			return
		}

		start := time.Now()

		metrics.mu.Lock()
		metrics.activeRequests++
		metrics.mu.Unlock()

		rw := &responseWriter{ResponseWriter: w, status: http.StatusOK}
		next.ServeHTTP(rw, r)

		duration := time.Since(start).Seconds()

		metrics.mu.Lock()
		metrics.activeRequests--

		key := r.Method + "_" + normalizePathForMetrics(r.URL.Path) + "_" + strconv.Itoa(rw.status)
		metrics.requestsTotal[key]++
		metrics.requestDuration[key] = append(metrics.requestDuration[key], duration)
		metrics.responseSizes[key] = append(metrics.responseSizes[key], rw.size)
		metrics.mu.Unlock()
	})
}

// normalizePathForMetrics removes IDs from paths for grouping
func normalizePathForMetrics(path string) string {
	// Normalize paths like /api/v1/transactions/123 to /api/v1/transactions/:id
	// This prevents cardinality explosion in metrics
	segments := []string{}
	for _, seg := range splitPath(path) {
		if isID(seg) {
			segments = append(segments, ":id")
		} else {
			segments = append(segments, seg)
		}
	}
	if len(segments) == 0 {
		return "/"
	}
	result := ""
	for _, s := range segments {
		result += "/" + s
	}
	return result
}

func splitPath(path string) []string {
	var result []string
	current := ""
	for _, c := range path {
		if c == '/' {
			if current != "" {
				result = append(result, current)
				current = ""
			}
		} else {
			current += string(c)
		}
	}
	if current != "" {
		result = append(result, current)
	}
	return result
}

func isID(s string) bool {
	// Check if it's a MongoDB ObjectID (24 hex chars) or UUID
	if len(s) == 24 {
		for _, c := range s {
			if !((c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F')) {
				return false
			}
		}
		return true
	}
	return false
}

// PrometheusHandler returns metrics in Prometheus format
func PrometheusHandler() http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		metrics.mu.RLock()
		defer metrics.mu.RUnlock()

		w.Header().Set("Content-Type", "text/plain; version=0.0.4")

		// Help and type declarations
		w.Write([]byte("# HELP http_requests_total Total number of HTTP requests\n"))
		w.Write([]byte("# TYPE http_requests_total counter\n"))

		for key, count := range metrics.requestsTotal {
			method, path, status := parseKey(key)
			line := "http_requests_total{method=\"" + method + "\",path=\"" + path + "\",status=\"" + status + "\"} " + strconv.FormatInt(count, 10) + "\n"
			w.Write([]byte(line))
		}

		w.Write([]byte("\n# HELP http_request_duration_seconds HTTP request duration in seconds\n"))
		w.Write([]byte("# TYPE http_request_duration_seconds summary\n"))

		for key, durations := range metrics.requestDuration {
			if len(durations) == 0 {
				continue
			}
			method, path, status := parseKey(key)
			avg := average(durations)
			line := "http_request_duration_seconds{method=\"" + method + "\",path=\"" + path + "\",status=\"" + status + "\"} " + strconv.FormatFloat(avg, 'f', 6, 64) + "\n"
			w.Write([]byte(line))
		}

		w.Write([]byte("\n# HELP http_active_requests Current number of active requests\n"))
		w.Write([]byte("# TYPE http_active_requests gauge\n"))
		w.Write([]byte("http_active_requests " + strconv.FormatInt(metrics.activeRequests, 10) + "\n"))

		w.Write([]byte("\n# HELP app_uptime_seconds Application uptime in seconds\n"))
		w.Write([]byte("# TYPE app_uptime_seconds counter\n"))
		uptime := time.Since(metrics.startTime).Seconds()
		w.Write([]byte("app_uptime_seconds " + strconv.FormatFloat(uptime, 'f', 0, 64) + "\n"))

		// User metrics
		w.Write([]byte("\n# HELP users_registered_total Total number of user registrations\n"))
		w.Write([]byte("# TYPE users_registered_total counter\n"))
		w.Write([]byte("users_registered_total " + strconv.FormatInt(metrics.usersRegistered, 10) + "\n"))

		w.Write([]byte("\n# HELP users_login_total Total number of login attempts\n"))
		w.Write([]byte("# TYPE users_login_total counter\n"))
		w.Write([]byte("users_login_total{result=\"success\"} " + strconv.FormatInt(metrics.usersLoginSuccess, 10) + "\n"))
		w.Write([]byte("users_login_total{result=\"failed\"} " + strconv.FormatInt(metrics.usersLoginFailed, 10) + "\n"))

		w.Write([]byte("\n# HELP auth_errors_total Total number of authentication errors (invalid/expired tokens)\n"))
		w.Write([]byte("# TYPE auth_errors_total counter\n"))
		w.Write([]byte("auth_errors_total " + strconv.FormatInt(metrics.authErrors, 10) + "\n"))

		w.Write([]byte("\n# HELP profile_updates_total Total number of profile updates\n"))
		w.Write([]byte("# TYPE profile_updates_total counter\n"))
		w.Write([]byte("profile_updates_total " + strconv.FormatInt(metrics.profileUpdates, 10) + "\n"))

		w.Write([]byte("\n# HELP avatar_uploads_total Total number of avatar uploads\n"))
		w.Write([]byte("# TYPE avatar_uploads_total counter\n"))
		w.Write([]byte("avatar_uploads_total " + strconv.FormatInt(metrics.avatarUploads, 10) + "\n"))

		w.Write([]byte("\n# HELP accounts_connected_total Total number of bank accounts connected\n"))
		w.Write([]byte("# TYPE accounts_connected_total counter\n"))
		w.Write([]byte("accounts_connected_total " + strconv.FormatInt(metrics.accountsConnected, 10) + "\n"))

		w.Write([]byte("\n# HELP accounts_disconnected_total Total number of bank accounts disconnected\n"))
		w.Write([]byte("# TYPE accounts_disconnected_total counter\n"))
		w.Write([]byte("accounts_disconnected_total " + strconv.FormatInt(metrics.accountsDisconnected, 10) + "\n"))

		w.Write([]byte("\n# HELP accounts_synced_total Total number of account balance syncs\n"))
		w.Write([]byte("# TYPE accounts_synced_total counter\n"))
		w.Write([]byte("accounts_synced_total " + strconv.FormatInt(metrics.accountsSynced, 10) + "\n"))

		w.Write([]byte("\n# HELP stats_requests_total Total number of stats/analytics requests\n"))
		w.Write([]byte("# TYPE stats_requests_total counter\n"))
		w.Write([]byte("stats_requests_total " + strconv.FormatInt(metrics.statsRequests, 10) + "\n"))

		// TRON metrics
		w.Write([]byte("\n# HELP tron_cycles_total Total number of TRON agent cycles\n"))
		w.Write([]byte("# TYPE tron_cycles_total counter\n"))
		w.Write([]byte("tron_cycles_total " + strconv.FormatInt(metrics.tronCyclesTotal, 10) + "\n"))

		w.Write([]byte("\n# HELP tron_tasks_total Total number of TRON tasks by status\n"))
		w.Write([]byte("# TYPE tron_tasks_total counter\n"))
		w.Write([]byte("tron_tasks_total{status=\"created\"} " + strconv.FormatInt(metrics.tronTasksCreated, 10) + "\n"))
		w.Write([]byte("tron_tasks_total{status=\"completed\"} " + strconv.FormatInt(metrics.tronTasksCompleted, 10) + "\n"))
		w.Write([]byte("tron_tasks_total{status=\"failed\"} " + strconv.FormatInt(metrics.tronTasksFailed, 10) + "\n"))

		w.Write([]byte("\n# HELP tron_agent_runs_total Total number of TRON agent runs by type\n"))
		w.Write([]byte("# TYPE tron_agent_runs_total counter\n"))
		for agentType, count := range metrics.tronAgentRuns {
			w.Write([]byte("tron_agent_runs_total{agent=\"" + agentType + "\"} " + strconv.FormatInt(count, 10) + "\n"))
		}

		w.Write([]byte("\n# HELP tron_api_cost_usd Total Claude API cost in USD\n"))
		w.Write([]byte("# TYPE tron_api_cost_usd counter\n"))
		w.Write([]byte("tron_api_cost_usd " + strconv.FormatFloat(metrics.tronAPICostUSD, 'f', 6, 64) + "\n"))

		w.Write([]byte("\n# HELP tron_tokens_used_total Total tokens used by TRON agents\n"))
		w.Write([]byte("# TYPE tron_tokens_used_total counter\n"))
		w.Write([]byte("tron_tokens_used_total " + strconv.FormatInt(metrics.tronTokensUsed, 10) + "\n"))

		w.Write([]byte("\n# HELP tron_repos_analyzed_total Total repos analyzed by TRON\n"))
		w.Write([]byte("# TYPE tron_repos_analyzed_total counter\n"))
		w.Write([]byte("tron_repos_analyzed_total " + strconv.FormatInt(metrics.tronReposAnalyzed, 10) + "\n"))

		w.Write([]byte("\n# HELP tron_qa_reviews_total Total QA reviews by result\n"))
		w.Write([]byte("# TYPE tron_qa_reviews_total counter\n"))
		for result, count := range metrics.tronQAReviews {
			w.Write([]byte("tron_qa_reviews_total{result=\"" + result + "\"} " + strconv.FormatInt(count, 10) + "\n"))
		}

		w.Write([]byte("\n# HELP tron_active_projects Number of active TRON projects\n"))
		w.Write([]byte("# TYPE tron_active_projects gauge\n"))
		w.Write([]byte("tron_active_projects " + strconv.FormatInt(metrics.tronActiveProjects, 10) + "\n"))

		w.Write([]byte("\n# HELP tron_decisions_pending Number of pending CIO decisions\n"))
		w.Write([]byte("# TYPE tron_decisions_pending gauge\n"))
		w.Write([]byte("tron_decisions_pending " + strconv.FormatInt(metrics.tronDecisionsPending, 10) + "\n"))

		w.Write([]byte("\n# HELP tron_decisions_resolved_total Total CIO decisions resolved\n"))
		w.Write([]byte("# TYPE tron_decisions_resolved_total counter\n"))
		w.Write([]byte("tron_decisions_resolved_total " + strconv.FormatInt(metrics.tronDecisionsResolved, 10) + "\n"))
	})
}

func parseKey(key string) (method, path, status string) {
	// Parse key like "GET_/api/v1/transactions_200"
	first := -1
	last := -1
	for i, c := range key {
		if c == '_' {
			if first == -1 {
				first = i
			} else {
				last = i
			}
		}
	}
	if first > 0 && last > first {
		method = key[:first]
		path = key[first+1 : last]
		status = key[last+1:]
	}
	return
}

func average(nums []float64) float64 {
	if len(nums) == 0 {
		return 0
	}
	sum := 0.0
	for _, n := range nums {
		sum += n
	}
	return sum / float64(len(nums))
}

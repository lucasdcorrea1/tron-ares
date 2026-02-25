package claude

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"os"
	"sync"
	"time"
)

const (
	BaseURL = "https://api.anthropic.com/v1"

	// Models
	ModelSonnet    = "claude-sonnet-4-5-20250929"
	ModelOpus      = "claude-opus-4-5-20251101"
	ModelHaiku     = "claude-3-5-haiku-20241022"

	// Default model for TRON agents
	DefaultModel = ModelSonnet
)

// Client is the Claude API client
type Client struct {
	apiKey     string
	httpClient *http.Client
	baseURL    string

	// Rate limiting
	rateLimiter *RateLimiter

	// Metrics tracking
	metrics *MetricsTracker
}

// RateLimiter handles API rate limiting
type RateLimiter struct {
	mu            sync.Mutex
	requestsPerMin int
	requestCount   int
	resetTime      time.Time
}

// MetricsTracker tracks API usage metrics
type MetricsTracker struct {
	mu           sync.Mutex
	TotalTokens  int64
	TotalCost    float64
	TotalCalls   int64
	ByModel      map[string]*ModelMetrics
}

// ModelMetrics tracks metrics per model
type ModelMetrics struct {
	InputTokens  int64
	OutputTokens int64
	Cost         float64
	Calls        int64
}

// Message represents a message in the conversation
type Message struct {
	Role    string `json:"role"` // "user" or "assistant"
	Content string `json:"content"`
}

// Request represents an API request
type Request struct {
	Model       string    `json:"model"`
	MaxTokens   int       `json:"max_tokens"`
	Messages    []Message `json:"messages"`
	System      string    `json:"system,omitempty"`
	Temperature float64   `json:"temperature,omitempty"`
}

// Response represents an API response
type Response struct {
	ID           string       `json:"id"`
	Type         string       `json:"type"`
	Role         string       `json:"role"`
	Content      []ContentBlock `json:"content"`
	Model        string       `json:"model"`
	StopReason   string       `json:"stop_reason"`
	Usage        Usage        `json:"usage"`
}

// ContentBlock represents a content block in the response
type ContentBlock struct {
	Type string `json:"type"`
	Text string `json:"text"`
}

// Usage represents token usage
type Usage struct {
	InputTokens  int `json:"input_tokens"`
	OutputTokens int `json:"output_tokens"`
}

// Error represents an API error
type Error struct {
	Type    string `json:"type"`
	Message string `json:"message"`
}

// APIError represents the full error response
type APIError struct {
	Error Error `json:"error"`
}

// CompletionResult represents the result of a completion with metadata
type CompletionResult struct {
	Content      string
	InputTokens  int
	OutputTokens int
	CostUSD      float64
	Model        string
	DurationMS   int64
}

// NewClient creates a new Claude API client
func NewClient() (*Client, error) {
	apiKey := os.Getenv("ANTHROPIC_API_KEY")
	if apiKey == "" {
		return nil, fmt.Errorf("ANTHROPIC_API_KEY environment variable not set")
	}

	return &Client{
		apiKey: apiKey,
		httpClient: &http.Client{
			Timeout: 120 * time.Second, // Long timeout for completions
		},
		baseURL: BaseURL,
		rateLimiter: &RateLimiter{
			requestsPerMin: 50, // Conservative default
			resetTime:      time.Now(),
		},
		metrics: &MetricsTracker{
			ByModel: make(map[string]*ModelMetrics),
		},
	}, nil
}

// NewClientWithKey creates a new Claude API client with a specific API key
func NewClientWithKey(apiKey string) *Client {
	return &Client{
		apiKey: apiKey,
		httpClient: &http.Client{
			Timeout: 120 * time.Second,
		},
		baseURL: BaseURL,
		rateLimiter: &RateLimiter{
			requestsPerMin: 50,
			resetTime:      time.Now(),
		},
		metrics: &MetricsTracker{
			ByModel: make(map[string]*ModelMetrics),
		},
	}
}

// Complete sends a completion request to the Claude API
func (c *Client) Complete(ctx context.Context, prompt string, opts ...Option) (*CompletionResult, error) {
	// Apply options
	cfg := &completionConfig{
		Model:       DefaultModel,
		MaxTokens:   4096,
		System:      "",
		Temperature: 0.7,
	}
	for _, opt := range opts {
		opt(cfg)
	}

	// Wait for rate limit
	c.waitForRateLimit()

	// Build request
	req := Request{
		Model:       cfg.Model,
		MaxTokens:   cfg.MaxTokens,
		System:      cfg.System,
		Temperature: cfg.Temperature,
		Messages: []Message{
			{Role: "user", Content: prompt},
		},
	}

	// Track timing
	start := time.Now()

	// Make request with retries
	var resp *Response
	var err error
	maxRetries := 3

	for attempt := 0; attempt < maxRetries; attempt++ {
		resp, err = c.doRequest(ctx, req)
		if err == nil {
			break
		}

		// Check if retryable
		if !isRetryable(err) {
			return nil, err
		}

		// Exponential backoff
		backoff := time.Duration(1<<attempt) * time.Second
		slog.Warn("claude_api_retry",
			"attempt", attempt+1,
			"backoff", backoff,
			"error", err,
		)

		select {
		case <-time.After(backoff):
		case <-ctx.Done():
			return nil, ctx.Err()
		}
	}

	if err != nil {
		return nil, fmt.Errorf("claude api failed after %d retries: %w", maxRetries, err)
	}

	duration := time.Since(start).Milliseconds()

	// Extract text from response
	var text string
	for _, block := range resp.Content {
		if block.Type == "text" {
			text += block.Text
		}
	}

	// Calculate cost
	cost := calculateCost(cfg.Model, resp.Usage.InputTokens, resp.Usage.OutputTokens)

	// Track metrics
	c.trackMetrics(cfg.Model, resp.Usage.InputTokens, resp.Usage.OutputTokens, cost)

	return &CompletionResult{
		Content:      text,
		InputTokens:  resp.Usage.InputTokens,
		OutputTokens: resp.Usage.OutputTokens,
		CostUSD:      cost,
		Model:        cfg.Model,
		DurationMS:   duration,
	}, nil
}

// Chat sends a multi-turn conversation to the Claude API
func (c *Client) Chat(ctx context.Context, messages []Message, opts ...Option) (*CompletionResult, error) {
	cfg := &completionConfig{
		Model:       DefaultModel,
		MaxTokens:   4096,
		System:      "",
		Temperature: 0.7,
	}
	for _, opt := range opts {
		opt(cfg)
	}

	c.waitForRateLimit()

	req := Request{
		Model:       cfg.Model,
		MaxTokens:   cfg.MaxTokens,
		System:      cfg.System,
		Temperature: cfg.Temperature,
		Messages:    messages,
	}

	start := time.Now()
	resp, err := c.doRequest(ctx, req)
	if err != nil {
		return nil, err
	}

	duration := time.Since(start).Milliseconds()

	var text string
	for _, block := range resp.Content {
		if block.Type == "text" {
			text += block.Text
		}
	}

	cost := calculateCost(cfg.Model, resp.Usage.InputTokens, resp.Usage.OutputTokens)
	c.trackMetrics(cfg.Model, resp.Usage.InputTokens, resp.Usage.OutputTokens, cost)

	return &CompletionResult{
		Content:      text,
		InputTokens:  resp.Usage.InputTokens,
		OutputTokens: resp.Usage.OutputTokens,
		CostUSD:      cost,
		Model:        cfg.Model,
		DurationMS:   duration,
	}, nil
}

func (c *Client) doRequest(ctx context.Context, req Request) (*Response, error) {
	body, err := json.Marshal(req)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal request: %w", err)
	}

	httpReq, err := http.NewRequestWithContext(ctx, "POST", c.baseURL+"/messages", bytes.NewReader(body))
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	httpReq.Header.Set("Content-Type", "application/json")
	httpReq.Header.Set("x-api-key", c.apiKey)
	httpReq.Header.Set("anthropic-version", "2023-06-01")

	httpResp, err := c.httpClient.Do(httpReq)
	if err != nil {
		return nil, fmt.Errorf("request failed: %w", err)
	}
	defer httpResp.Body.Close()

	respBody, err := io.ReadAll(httpResp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}

	if httpResp.StatusCode != http.StatusOK {
		var apiErr APIError
		if json.Unmarshal(respBody, &apiErr) == nil {
			return nil, fmt.Errorf("api error (%d): %s - %s", httpResp.StatusCode, apiErr.Error.Type, apiErr.Error.Message)
		}
		return nil, fmt.Errorf("api error (%d): %s", httpResp.StatusCode, string(respBody))
	}

	var resp Response
	if err := json.Unmarshal(respBody, &resp); err != nil {
		return nil, fmt.Errorf("failed to unmarshal response: %w", err)
	}

	return &resp, nil
}

func (c *Client) waitForRateLimit() {
	c.rateLimiter.mu.Lock()
	defer c.rateLimiter.mu.Unlock()

	now := time.Now()
	if now.After(c.rateLimiter.resetTime) {
		c.rateLimiter.requestCount = 0
		c.rateLimiter.resetTime = now.Add(time.Minute)
	}

	if c.rateLimiter.requestCount >= c.rateLimiter.requestsPerMin {
		waitTime := c.rateLimiter.resetTime.Sub(now)
		time.Sleep(waitTime)
		c.rateLimiter.requestCount = 0
		c.rateLimiter.resetTime = time.Now().Add(time.Minute)
	}

	c.rateLimiter.requestCount++
}

func (c *Client) trackMetrics(model string, inputTokens, outputTokens int, cost float64) {
	c.metrics.mu.Lock()
	defer c.metrics.mu.Unlock()

	c.metrics.TotalTokens += int64(inputTokens + outputTokens)
	c.metrics.TotalCost += cost
	c.metrics.TotalCalls++

	if _, ok := c.metrics.ByModel[model]; !ok {
		c.metrics.ByModel[model] = &ModelMetrics{}
	}

	c.metrics.ByModel[model].InputTokens += int64(inputTokens)
	c.metrics.ByModel[model].OutputTokens += int64(outputTokens)
	c.metrics.ByModel[model].Cost += cost
	c.metrics.ByModel[model].Calls++
}

// GetMetrics returns the current metrics
func (c *Client) GetMetrics() *MetricsTracker {
	return c.metrics
}

// calculateCost calculates the cost in USD for the given model and tokens
func calculateCost(model string, inputTokens, outputTokens int) float64 {
	// Pricing per 1M tokens (as of Feb 2025)
	var inputPrice, outputPrice float64

	switch model {
	case ModelOpus:
		inputPrice = 15.0  // $15 per 1M input tokens
		outputPrice = 75.0 // $75 per 1M output tokens
	case ModelSonnet:
		inputPrice = 3.0   // $3 per 1M input tokens
		outputPrice = 15.0 // $15 per 1M output tokens
	case ModelHaiku:
		inputPrice = 0.25  // $0.25 per 1M input tokens
		outputPrice = 1.25 // $1.25 per 1M output tokens
	default:
		inputPrice = 3.0
		outputPrice = 15.0
	}

	inputCost := (float64(inputTokens) / 1_000_000) * inputPrice
	outputCost := (float64(outputTokens) / 1_000_000) * outputPrice

	return inputCost + outputCost
}

func isRetryable(err error) bool {
	if err == nil {
		return false
	}
	errStr := err.Error()
	return bytes.Contains([]byte(errStr), []byte("429")) ||
		bytes.Contains([]byte(errStr), []byte("500")) ||
		bytes.Contains([]byte(errStr), []byte("502")) ||
		bytes.Contains([]byte(errStr), []byte("503"))
}

// Option configures a completion request
type Option func(*completionConfig)

type completionConfig struct {
	Model       string
	MaxTokens   int
	System      string
	Temperature float64
}

// WithModel sets the model to use
func WithModel(model string) Option {
	return func(cfg *completionConfig) {
		cfg.Model = model
	}
}

// WithMaxTokens sets the max tokens
func WithMaxTokens(n int) Option {
	return func(cfg *completionConfig) {
		cfg.MaxTokens = n
	}
}

// WithSystem sets the system prompt
func WithSystem(system string) Option {
	return func(cfg *completionConfig) {
		cfg.System = system
	}
}

// WithTemperature sets the temperature
func WithTemperature(t float64) Option {
	return func(cfg *completionConfig) {
		cfg.Temperature = t
	}
}

package handlers

import (
	"context"
	"encoding/json"
	"net/http"
	"sort"
	"time"

	"github.com/imperium/backend/internal/database"
	"github.com/imperium/backend/internal/middleware"
	"github.com/imperium/backend/internal/models"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
)

// GetProfileStats godoc
// @Summary Obter estatísticas do perfil
// @Description Retorna estatísticas financeiras do usuário para exibição em gráficos
// @Tags profile
// @Accept json
// @Produce json
// @Security BearerAuth
// @Success 200 {object} models.ProfileStats
// @Failure 401 {string} string "Unauthorized"
// @Router /profile/stats [get]
func GetProfileStats(w http.ResponseWriter, r *http.Request) {
	middleware.IncStatsRequest()

	userID := middleware.GetUserID(r)
	if userID == primitive.NilObjectID {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	stats := models.ProfileStats{}

	// Get current month boundaries
	now := time.Now()
	currentMonthStart := time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, time.Local)
	currentMonthEnd := currentMonthStart.AddDate(0, 1, 0)
	lastMonthStart := currentMonthStart.AddDate(0, -1, 0)

	// 1. Get total balance (all time)
	balanceResult := calculateBalance(ctx, userID, time.Time{}, time.Time{})
	stats.TotalBalance = balanceResult.income - balanceResult.expenses

	// 2. Get current month income/expenses
	currentMonthResult := calculateBalance(ctx, userID, currentMonthStart, currentMonthEnd)
	stats.MonthlyIncome = currentMonthResult.income
	stats.MonthlyExpenses = currentMonthResult.expenses
	stats.MonthlySavings = currentMonthResult.income - currentMonthResult.expenses

	// 3. Get transaction count
	stats.TransactionCount, _ = database.Transactions().CountDocuments(ctx, bson.M{"user_id": userID})

	// 4. Get expenses by category (current month) - for pie chart
	stats.ExpensesByCategory = getExpensesByCategory(ctx, userID, currentMonthStart, currentMonthEnd)

	// 5. Get top categories
	stats.TopCategories = getTopCategories(stats.ExpensesByCategory, 5)

	// 6. Get monthly trend (last 6 months) - for line chart
	stats.MonthlyTrend = getMonthlyTrend(ctx, userID, 6)

	// 7. Compare with last month
	lastMonthResult := calculateBalance(ctx, userID, lastMonthStart, currentMonthStart)
	stats.ComparisonLastMonth = calculateComparison(currentMonthResult, lastMonthResult)

	// 8. Count connected accounts
	accountCount, _ := database.DB.Collection("connected_accounts").CountDocuments(ctx, bson.M{"user_id": userID, "is_active": true})
	stats.ConnectedAccounts = int(accountCount)

	json.NewEncoder(w).Encode(stats)
}

type balanceResult struct {
	income   float64
	expenses float64
}

func calculateBalance(ctx context.Context, userID primitive.ObjectID, start, end time.Time) balanceResult {
	filter := bson.M{"user_id": userID}
	if !start.IsZero() {
		filter["date"] = bson.M{"$gte": start, "$lt": end}
	}

	pipeline := mongo.Pipeline{
		{{Key: "$match", Value: filter}},
		{{Key: "$group", Value: bson.M{
			"_id":      "$type",
			"total":    bson.M{"$sum": "$amount"},
		}}},
	}

	cursor, err := database.Transactions().Aggregate(ctx, pipeline)
	if err != nil {
		return balanceResult{}
	}
	defer cursor.Close(ctx)

	result := balanceResult{}
	for cursor.Next(ctx) {
		var doc struct {
			ID    string  `bson:"_id"`
			Total float64 `bson:"total"`
		}
		if cursor.Decode(&doc) == nil {
			if doc.ID == "income" {
				result.income = doc.Total
			} else if doc.ID == "expense" {
				result.expenses = doc.Total
			}
		}
	}

	return result
}

func getExpensesByCategory(ctx context.Context, userID primitive.ObjectID, start, end time.Time) []models.CategoryStat {
	pipeline := mongo.Pipeline{
		{{Key: "$match", Value: bson.M{
			"user_id": userID,
			"type":    "expense",
			"date":    bson.M{"$gte": start, "$lt": end},
		}}},
		{{Key: "$group", Value: bson.M{
			"_id":   "$category",
			"total": bson.M{"$sum": "$amount"},
		}}},
		{{Key: "$sort", Value: bson.M{"total": -1}}},
	}

	cursor, err := database.Transactions().Aggregate(ctx, pipeline)
	if err != nil {
		return nil
	}
	defer cursor.Close(ctx)

	var categories []models.CategoryStat
	var totalExpenses float64

	// First pass: collect all categories
	var docs []struct {
		ID    string  `bson:"_id"`
		Total float64 `bson:"total"`
	}
	cursor.All(ctx, &docs)

	for _, doc := range docs {
		totalExpenses += doc.Total
	}

	// Second pass: calculate percentages
	for _, doc := range docs {
		percentage := 0.0
		if totalExpenses > 0 {
			percentage = (doc.Total / totalExpenses) * 100
		}

		color := models.CategoryColors[doc.ID]
		if color == "" {
			color = "#B0B0B0"
		}

		categories = append(categories, models.CategoryStat{
			Category:   doc.ID,
			Amount:     doc.Total,
			Percentage: percentage,
			Color:      color,
		})
	}

	return categories
}

func getTopCategories(categories []models.CategoryStat, limit int) []models.CategoryStat {
	if len(categories) <= limit {
		return categories
	}
	return categories[:limit]
}

func getMonthlyTrend(ctx context.Context, userID primitive.ObjectID, months int) []models.MonthlyTrendPoint {
	now := time.Now()
	points := make([]models.MonthlyTrendPoint, months)

	for i := months - 1; i >= 0; i-- {
		monthStart := time.Date(now.Year(), now.Month()-time.Month(i), 1, 0, 0, 0, 0, time.Local)
		monthEnd := monthStart.AddDate(0, 1, 0)

		result := calculateBalance(ctx, userID, monthStart, monthEnd)

		points[months-1-i] = models.MonthlyTrendPoint{
			Month:    monthStart.Format("2006-01"),
			Income:   result.income,
			Expenses: result.expenses,
			Balance:  result.income - result.expenses,
		}
	}

	return points
}

func calculateComparison(current, previous balanceResult) models.ComparisonStats {
	comparison := models.ComparisonStats{}

	if previous.income > 0 {
		comparison.IncomeChange = ((current.income - previous.income) / previous.income) * 100
	} else if current.income > 0 {
		comparison.IncomeChange = 100
	}

	if previous.expenses > 0 {
		comparison.ExpenseChange = ((current.expenses - previous.expenses) / previous.expenses) * 100
	} else if current.expenses > 0 {
		comparison.ExpenseChange = 100
	}

	currentSavings := current.income - current.expenses
	previousSavings := previous.income - previous.expenses
	if previousSavings != 0 {
		comparison.SavingsChange = ((currentSavings - previousSavings) / absFloat(previousSavings)) * 100
	} else if currentSavings != 0 {
		comparison.SavingsChange = 100
	}

	return comparison
}

func absFloat(x float64) float64 {
	if x < 0 {
		return -x
	}
	return x
}

// GetExpenseBreakdown godoc
// @Summary Obter breakdown de despesas
// @Description Retorna despesas detalhadas por categoria com sub-categorias
// @Tags profile
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param period query string false "Período: 'week', 'month', 'year', 'all'" default(month)
// @Success 200 {object} map[string]interface{}
// @Failure 401 {string} string "Unauthorized"
// @Router /profile/stats/breakdown [get]
func GetExpenseBreakdown(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r)
	if userID == primitive.NilObjectID {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	period := r.URL.Query().Get("period")
	if period == "" {
		period = "month"
	}

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	now := time.Now()
	var startDate time.Time

	switch period {
	case "week":
		startDate = now.AddDate(0, 0, -7)
	case "month":
		startDate = time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, time.Local)
	case "year":
		startDate = time.Date(now.Year(), 1, 1, 0, 0, 0, 0, time.Local)
	case "all":
		startDate = time.Time{}
	default:
		startDate = time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, time.Local)
	}

	filter := bson.M{"user_id": userID, "type": "expense"}
	if !startDate.IsZero() {
		filter["date"] = bson.M{"$gte": startDate}
	}

	pipeline := mongo.Pipeline{
		{{Key: "$match", Value: filter}},
		{{Key: "$group", Value: bson.M{
			"_id":   "$category",
			"total": bson.M{"$sum": "$amount"},
			"count": bson.M{"$sum": 1},
			"avg":   bson.M{"$avg": "$amount"},
			"max":   bson.M{"$max": "$amount"},
			"min":   bson.M{"$min": "$amount"},
			"transactions": bson.M{"$push": bson.M{
				"description": "$description",
				"amount":      "$amount",
				"date":        "$date",
			}},
		}}},
		{{Key: "$sort", Value: bson.M{"total": -1}}},
	}

	cursor, err := database.Transactions().Aggregate(ctx, pipeline)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer cursor.Close(ctx)

	type CategoryBreakdown struct {
		Category     string  `json:"category"`
		Total        float64 `json:"total"`
		Count        int     `json:"count"`
		Average      float64 `json:"average"`
		Max          float64 `json:"max"`
		Min          float64 `json:"min"`
		Color        string  `json:"color"`
		Transactions []struct {
			Description string    `json:"description"`
			Amount      float64   `json:"amount"`
			Date        time.Time `json:"date"`
		} `json:"recent_transactions"`
	}

	var breakdown []CategoryBreakdown
	var totalExpenses float64

	for cursor.Next(ctx) {
		var doc struct {
			ID           string  `bson:"_id"`
			Total        float64 `bson:"total"`
			Count        int     `bson:"count"`
			Avg          float64 `bson:"avg"`
			Max          float64 `bson:"max"`
			Min          float64 `bson:"min"`
			Transactions []struct {
				Description string    `bson:"description"`
				Amount      float64   `bson:"amount"`
				Date        time.Time `bson:"date"`
			} `bson:"transactions"`
		}
		if cursor.Decode(&doc) == nil {
			totalExpenses += doc.Total

			color := models.CategoryColors[doc.ID]
			if color == "" {
				color = "#B0B0B0"
			}

			// Sort transactions by date and get last 5
			sort.Slice(doc.Transactions, func(i, j int) bool {
				return doc.Transactions[i].Date.After(doc.Transactions[j].Date)
			})
			recentTxs := doc.Transactions
			if len(recentTxs) > 5 {
				recentTxs = recentTxs[:5]
			}

			cb := CategoryBreakdown{
				Category: doc.ID,
				Total:    doc.Total,
				Count:    doc.Count,
				Average:  doc.Avg,
				Max:      doc.Max,
				Min:      doc.Min,
				Color:    color,
			}
			cb.Transactions = make([]struct {
				Description string    `json:"description"`
				Amount      float64   `json:"amount"`
				Date        time.Time `json:"date"`
			}, len(recentTxs))
			for i, tx := range recentTxs {
				cb.Transactions[i].Description = tx.Description
				cb.Transactions[i].Amount = tx.Amount
				cb.Transactions[i].Date = tx.Date
			}

			breakdown = append(breakdown, cb)
		}
	}

	response := map[string]interface{}{
		"period":         period,
		"total_expenses": totalExpenses,
		"categories":     breakdown,
	}

	json.NewEncoder(w).Encode(response)
}

// GetIncomeBreakdown godoc
// @Summary Obter breakdown de receitas
// @Description Retorna receitas detalhadas por categoria
// @Tags profile
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param period query string false "Período: 'week', 'month', 'year', 'all'" default(month)
// @Success 200 {object} map[string]interface{}
// @Failure 401 {string} string "Unauthorized"
// @Router /profile/stats/income [get]
func GetIncomeBreakdown(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r)
	if userID == primitive.NilObjectID {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	period := r.URL.Query().Get("period")
	if period == "" {
		period = "month"
	}

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	now := time.Now()
	var startDate time.Time

	switch period {
	case "week":
		startDate = now.AddDate(0, 0, -7)
	case "month":
		startDate = time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, time.Local)
	case "year":
		startDate = time.Date(now.Year(), 1, 1, 0, 0, 0, 0, time.Local)
	case "all":
		startDate = time.Time{}
	default:
		startDate = time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, time.Local)
	}

	filter := bson.M{"user_id": userID, "type": "income"}
	if !startDate.IsZero() {
		filter["date"] = bson.M{"$gte": startDate}
	}

	pipeline := mongo.Pipeline{
		{{Key: "$match", Value: filter}},
		{{Key: "$group", Value: bson.M{
			"_id":   "$category",
			"total": bson.M{"$sum": "$amount"},
			"count": bson.M{"$sum": 1},
		}}},
		{{Key: "$sort", Value: bson.M{"total": -1}}},
	}

	cursor, err := database.Transactions().Aggregate(ctx, pipeline)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer cursor.Close(ctx)

	var categories []models.CategoryStat
	var totalIncome float64

	var docs []struct {
		ID    string  `bson:"_id"`
		Total float64 `bson:"total"`
		Count int     `bson:"count"`
	}
	cursor.All(ctx, &docs)

	for _, doc := range docs {
		totalIncome += doc.Total
	}

	for _, doc := range docs {
		percentage := 0.0
		if totalIncome > 0 {
			percentage = (doc.Total / totalIncome) * 100
		}

		color := models.CategoryColors[doc.ID]
		if color == "" {
			color = "#98D8C8"
		}

		categories = append(categories, models.CategoryStat{
			Category:   doc.ID,
			Amount:     doc.Total,
			Percentage: percentage,
			Color:      color,
		})
	}

	response := map[string]interface{}{
		"period":       period,
		"total_income": totalIncome,
		"categories":   categories,
	}

	json.NewEncoder(w).Encode(response)
}

// GetDailyStats godoc
// @Summary Obter estatísticas diárias
// @Description Retorna dados de gastos/receitas por dia para gráfico de barras
// @Tags profile
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param days query int false "Número de dias" default(30)
// @Success 200 {array} map[string]interface{}
// @Failure 401 {string} string "Unauthorized"
// @Router /profile/stats/daily [get]
func GetDailyStats(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r)
	if userID == primitive.NilObjectID {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	days := 30
	if d := r.URL.Query().Get("days"); d != "" {
		if _, err := json.Number(d).Int64(); err == nil {
			n, _ := json.Number(d).Int64()
			days = int(n)
			if days > 90 {
				days = 90
			}
		}
	}

	startDate := time.Now().AddDate(0, 0, -days)

	pipeline := mongo.Pipeline{
		{{Key: "$match", Value: bson.M{
			"user_id": userID,
			"date":    bson.M{"$gte": startDate},
		}}},
		{{Key: "$group", Value: bson.M{
			"_id": bson.M{
				"date": bson.M{"$dateToString": bson.M{"format": "%Y-%m-%d", "date": "$date"}},
				"type": "$type",
			},
			"total": bson.M{"$sum": "$amount"},
			"count": bson.M{"$sum": 1},
		}}},
		{{Key: "$sort", Value: bson.M{"_id.date": 1}}},
	}

	cursor, err := database.Transactions().Aggregate(ctx, pipeline)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer cursor.Close(ctx)

	// Map to aggregate by date
	dailyData := make(map[string]map[string]float64)

	for cursor.Next(ctx) {
		var doc struct {
			ID struct {
				Date string `bson:"date"`
				Type string `bson:"type"`
			} `bson:"_id"`
			Total float64 `bson:"total"`
		}
		if cursor.Decode(&doc) == nil {
			if dailyData[doc.ID.Date] == nil {
				dailyData[doc.ID.Date] = make(map[string]float64)
			}
			dailyData[doc.ID.Date][doc.ID.Type] = doc.Total
		}
	}

	// Convert to array sorted by date
	type DailyPoint struct {
		Date     string  `json:"date"`
		Income   float64 `json:"income"`
		Expenses float64 `json:"expenses"`
		Balance  float64 `json:"balance"`
	}

	var result []DailyPoint
	for date, data := range dailyData {
		income := data["income"]
		expenses := data["expense"]
		result = append(result, DailyPoint{
			Date:     date,
			Income:   income,
			Expenses: expenses,
			Balance:  income - expenses,
		})
	}

	sort.Slice(result, func(i, j int) bool {
		return result[i].Date < result[j].Date
	})

	json.NewEncoder(w).Encode(result)
}

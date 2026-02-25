package handlers

import (
	"context"
	"encoding/json"
	"net/http"
	"strings"
	"time"

	"github.com/imperium/backend/internal/database"
	"github.com/imperium/backend/internal/middleware"
	"github.com/imperium/backend/internal/models"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// GetTransactions godoc
// @Summary Lista todas as transações
// @Description Retorna todas as transações do usuário ordenadas por data (mais recente primeiro)
// @Tags transactions
// @Accept json
// @Produce json
// @Security BearerAuth
// @Success 200 {array} models.Transaction
// @Failure 401 {string} string "Unauthorized"
// @Router /transactions [get]
func GetTransactions(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r)
	if userID == primitive.NilObjectID {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	opts := options.Find().SetSort(bson.D{{Key: "date", Value: -1}})
	cursor, err := database.Transactions().Find(ctx, bson.M{"user_id": userID}, opts)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer cursor.Close(ctx)

	var transactions []models.Transaction
	if err := cursor.All(ctx, &transactions); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	if transactions == nil {
		transactions = []models.Transaction{}
	}

	json.NewEncoder(w).Encode(transactions)
}

// GetTransaction godoc
// @Summary Busca uma transação por ID
// @Description Retorna uma transação específica pelo seu ID
// @Tags transactions
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Transaction ID"
// @Success 200 {object} models.Transaction
// @Failure 400 {string} string "Invalid ID"
// @Failure 401 {string} string "Unauthorized"
// @Failure 404 {string} string "Transaction not found"
// @Router /transactions/{id} [get]
func GetTransaction(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r)
	if userID == primitive.NilObjectID {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	id := strings.TrimPrefix(r.URL.Path, "/api/v1/transactions/")
	objectID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		http.Error(w, "Invalid ID", http.StatusBadRequest)
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	var transaction models.Transaction
	err = database.Transactions().FindOne(ctx, bson.M{
		"_id":     objectID,
		"user_id": userID,
	}).Decode(&transaction)
	if err != nil {
		http.Error(w, "Transaction not found", http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(transaction)
}

// CreateTransaction godoc
// @Summary Cria uma nova transação
// @Description Adiciona uma nova transação (receita ou despesa)
// @Tags transactions
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param transaction body models.CreateTransactionRequest true "Dados da transação"
// @Success 201 {object} models.Transaction
// @Failure 400 {string} string "Invalid request body"
// @Failure 401 {string} string "Unauthorized"
// @Router /transactions [post]
func CreateTransaction(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r)
	if userID == primitive.NilObjectID {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	var req models.CreateTransactionRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	transaction := models.Transaction{
		ID:          primitive.NewObjectID(),
		UserID:      userID,
		Description: req.Description,
		Amount:      req.Amount,
		Type:        req.Type,
		Category:    req.Category,
		Date:        req.Date,
		CreatedAt:   time.Now(),
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	_, err := database.Transactions().InsertOne(ctx, transaction)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(transaction)
}

// UpdateTransaction godoc
// @Summary Atualiza uma transação
// @Description Atualiza os dados de uma transação existente
// @Tags transactions
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Transaction ID"
// @Param transaction body models.UpdateTransactionRequest true "Dados para atualizar"
// @Success 200 {object} models.Transaction
// @Failure 400 {string} string "Invalid ID or request body"
// @Failure 401 {string} string "Unauthorized"
// @Failure 404 {string} string "Transaction not found"
// @Router /transactions/{id} [put]
func UpdateTransaction(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r)
	if userID == primitive.NilObjectID {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	id := strings.TrimPrefix(r.URL.Path, "/api/v1/transactions/")
	objectID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		http.Error(w, "Invalid ID", http.StatusBadRequest)
		return
	}

	var req models.UpdateTransactionRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	update := bson.M{"$set": bson.M{}}
	setFields := update["$set"].(bson.M)

	if req.Description != "" {
		setFields["description"] = req.Description
	}
	if req.Amount != 0 {
		setFields["amount"] = req.Amount
	}
	if req.Type != "" {
		setFields["type"] = req.Type
	}
	if req.Category != "" {
		setFields["category"] = req.Category
	}
	if !req.Date.IsZero() {
		setFields["date"] = req.Date
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	result, err := database.Transactions().UpdateOne(ctx, bson.M{
		"_id":     objectID,
		"user_id": userID,
	}, update)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	if result.MatchedCount == 0 {
		http.Error(w, "Transaction not found", http.StatusNotFound)
		return
	}

	// Return updated transaction
	var transaction models.Transaction
	database.Transactions().FindOne(ctx, bson.M{"_id": objectID}).Decode(&transaction)
	json.NewEncoder(w).Encode(transaction)
}

// DeleteTransaction godoc
// @Summary Deleta uma transação
// @Description Remove uma transação pelo ID
// @Tags transactions
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Transaction ID"
// @Success 204 "No Content"
// @Failure 400 {string} string "Invalid ID"
// @Failure 401 {string} string "Unauthorized"
// @Failure 404 {string} string "Transaction not found"
// @Router /transactions/{id} [delete]
func DeleteTransaction(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r)
	if userID == primitive.NilObjectID {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	id := strings.TrimPrefix(r.URL.Path, "/api/v1/transactions/")
	objectID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		http.Error(w, "Invalid ID", http.StatusBadRequest)
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	result, err := database.Transactions().DeleteOne(ctx, bson.M{
		"_id":     objectID,
		"user_id": userID,
	})
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	if result.DeletedCount == 0 {
		http.Error(w, "Transaction not found", http.StatusNotFound)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// GetBalance godoc
// @Summary Retorna o saldo atual
// @Description Calcula o saldo total (receitas - despesas) do usuário
// @Tags transactions
// @Accept json
// @Produce json
// @Security BearerAuth
// @Success 200 {object} models.BalanceResponse
// @Failure 401 {string} string "Unauthorized"
// @Router /transactions/balance [get]
func GetBalance(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r)
	if userID == primitive.NilObjectID {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// Calculate total income
	incomePipeline := []bson.M{
		{"$match": bson.M{"type": "income", "user_id": userID}},
		{"$group": bson.M{"_id": nil, "total": bson.M{"$sum": "$amount"}}},
	}

	var incomeResult []struct {
		Total float64 `bson:"total"`
	}
	cursor, _ := database.Transactions().Aggregate(ctx, incomePipeline)
	cursor.All(ctx, &incomeResult)

	// Calculate total expenses
	expensePipeline := []bson.M{
		{"$match": bson.M{"type": "expense", "user_id": userID}},
		{"$group": bson.M{"_id": nil, "total": bson.M{"$sum": "$amount"}}},
	}

	var expenseResult []struct {
		Total float64 `bson:"total"`
	}
	cursor, _ = database.Transactions().Aggregate(ctx, expensePipeline)
	cursor.All(ctx, &expenseResult)

	totalIncome := 0.0
	if len(incomeResult) > 0 {
		totalIncome = incomeResult[0].Total
	}

	totalExpenses := 0.0
	if len(expenseResult) > 0 {
		totalExpenses = expenseResult[0].Total
	}

	response := models.BalanceResponse{
		Balance:       totalIncome - totalExpenses,
		TotalIncome:   totalIncome,
		TotalExpenses: totalExpenses,
	}

	json.NewEncoder(w).Encode(response)
}

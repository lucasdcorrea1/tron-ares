package handlers

import (
	"context"
	"encoding/json"
	"log/slog"
	"net/http"
	"regexp"
	"strings"
	"time"

	"github.com/imperium/backend/internal/database"
	"github.com/imperium/backend/internal/middleware"
	"github.com/imperium/backend/internal/models"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// GetConnectedAccounts godoc
// @Summary Listar contas conectadas
// @Description Retorna todas as contas bancárias conectadas do usuário
// @Tags accounts
// @Accept json
// @Produce json
// @Security BearerAuth
// @Success 200 {array} models.ConnectedAccount
// @Failure 401 {string} string "Unauthorized"
// @Router /accounts [get]
func GetConnectedAccounts(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r)
	if userID == primitive.NilObjectID {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	cursor, err := database.DB.Collection("connected_accounts").Find(ctx,
		bson.M{"user_id": userID},
		options.Find().SetSort(bson.M{"created_at": -1}),
	)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer cursor.Close(ctx)

	var accounts []models.ConnectedAccount
	if err := cursor.All(ctx, &accounts); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	if accounts == nil {
		accounts = []models.ConnectedAccount{}
	}

	json.NewEncoder(w).Encode(accounts)
}

// GetConnectedAccount godoc
// @Summary Obter conta conectada
// @Description Retorna detalhes de uma conta conectada específica
// @Tags accounts
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Account ID"
// @Success 200 {object} models.ConnectedAccount
// @Failure 401 {string} string "Unauthorized"
// @Failure 404 {string} string "Account not found"
// @Router /accounts/{id} [get]
func GetConnectedAccount(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r)
	if userID == primitive.NilObjectID {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	accountID, err := primitive.ObjectIDFromHex(extractAccountID(r.URL.Path))
	if err != nil {
		http.Error(w, "Invalid account ID", http.StatusBadRequest)
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	var account models.ConnectedAccount
	err = database.DB.Collection("connected_accounts").FindOne(ctx, bson.M{
		"_id":     accountID,
		"user_id": userID,
	}).Decode(&account)

	if err != nil {
		http.Error(w, "Account not found", http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(account)
}

// ConnectAccount godoc
// @Summary Conectar nova conta
// @Description Adiciona uma nova conta bancária ao perfil do usuário
// @Tags accounts
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body models.ConnectAccountRequest true "Dados da conta"
// @Success 201 {object} models.ConnectedAccount
// @Failure 400 {string} string "Invalid request"
// @Failure 401 {string} string "Unauthorized"
// @Router /accounts [post]
func ConnectAccount(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r)
	if userID == primitive.NilObjectID {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	var req models.ConnectAccountRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	// Validate required fields
	if req.Provider == "" {
		http.Error(w, "Provider is required", http.StatusBadRequest)
		return
	}
	if req.AccountType == "" {
		http.Error(w, "Account type is required", http.StatusBadRequest)
		return
	}
	if req.AccountName == "" {
		http.Error(w, "Account name is required", http.StatusBadRequest)
		return
	}

	// Validate last four digits
	if req.LastFour != "" && !isValidLastFour(req.LastFour) {
		http.Error(w, "Last four must be 4 digits", http.StatusBadRequest)
		return
	}

	// Set default color from provider if not provided
	if req.Color == "" {
		if providerInfo, ok := models.BankProviders[req.Provider]; ok {
			req.Color = providerInfo.Color
		} else {
			req.Color = "#808080"
		}
	}

	// Set default icon from provider if not provided
	if req.Icon == "" {
		if providerInfo, ok := models.BankProviders[req.Provider]; ok {
			req.Icon = providerInfo.Icon
		} else {
			req.Icon = "bank"
		}
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	now := time.Now()
	account := models.ConnectedAccount{
		ID:          primitive.NewObjectID(),
		UserID:      userID,
		Provider:    req.Provider,
		AccountType: req.AccountType,
		AccountName: req.AccountName,
		LastFour:    req.LastFour,
		Balance:     req.Balance,
		Color:       req.Color,
		Icon:        req.Icon,
		IsActive:    true,
		LastSync:    now,
		CreatedAt:   now,
		UpdatedAt:   now,
	}

	_, err := database.DB.Collection("connected_accounts").InsertOne(ctx, account)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	middleware.IncAccountConnected()
	slog.Info("account_connected",
		"user_id", userID.Hex(),
		"provider", req.Provider,
		"account_type", req.AccountType,
	)

	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(account)
}

// UpdateConnectedAccount godoc
// @Summary Atualizar conta conectada
// @Description Atualiza os dados de uma conta conectada
// @Tags accounts
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Account ID"
// @Param request body models.UpdateConnectedAccountRequest true "Dados para atualizar"
// @Success 200 {object} models.ConnectedAccount
// @Failure 400 {string} string "Invalid request"
// @Failure 401 {string} string "Unauthorized"
// @Failure 404 {string} string "Account not found"
// @Router /accounts/{id} [put]
func UpdateConnectedAccount(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r)
	if userID == primitive.NilObjectID {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	accountID, err := primitive.ObjectIDFromHex(extractAccountID(r.URL.Path))
	if err != nil {
		http.Error(w, "Invalid account ID", http.StatusBadRequest)
		return
	}

	var req models.UpdateConnectedAccountRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// Build update document
	update := bson.M{"$set": bson.M{"updated_at": time.Now()}}
	setFields := update["$set"].(bson.M)

	if req.AccountName != "" {
		setFields["account_name"] = req.AccountName
	}
	if req.Balance != 0 {
		setFields["balance"] = req.Balance
		setFields["last_sync"] = time.Now()
	}
	if req.Color != "" {
		setFields["color"] = req.Color
	}
	if req.Icon != "" {
		setFields["icon"] = req.Icon
	}
	if req.IsActive != nil {
		setFields["is_active"] = *req.IsActive
	}

	result, err := database.DB.Collection("connected_accounts").UpdateOne(ctx,
		bson.M{"_id": accountID, "user_id": userID},
		update,
	)

	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	if result.MatchedCount == 0 {
		http.Error(w, "Account not found", http.StatusNotFound)
		return
	}

	// Return updated account
	var account models.ConnectedAccount
	database.DB.Collection("connected_accounts").FindOne(ctx, bson.M{"_id": accountID}).Decode(&account)

	slog.Info("account_updated",
		"user_id", userID.Hex(),
		"account_id", accountID.Hex(),
	)

	json.NewEncoder(w).Encode(account)
}

// SyncAccountBalance godoc
// @Summary Sincronizar saldo da conta
// @Description Atualiza o saldo de uma conta conectada
// @Tags accounts
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Account ID"
// @Param request body map[string]float64 true "Novo saldo"
// @Success 200 {object} models.ConnectedAccount
// @Failure 400 {string} string "Invalid request"
// @Failure 401 {string} string "Unauthorized"
// @Failure 404 {string} string "Account not found"
// @Router /accounts/{id}/sync [post]
func SyncAccountBalance(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r)
	if userID == primitive.NilObjectID {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	accountID, err := primitive.ObjectIDFromHex(extractAccountID(r.URL.Path))
	if err != nil {
		http.Error(w, "Invalid account ID", http.StatusBadRequest)
		return
	}

	var req struct {
		Balance float64 `json:"balance"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	now := time.Now()
	result, err := database.DB.Collection("connected_accounts").UpdateOne(ctx,
		bson.M{"_id": accountID, "user_id": userID},
		bson.M{"$set": bson.M{
			"balance":    req.Balance,
			"last_sync":  now,
			"updated_at": now,
		}},
	)

	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	if result.MatchedCount == 0 {
		http.Error(w, "Account not found", http.StatusNotFound)
		return
	}

	var account models.ConnectedAccount
	database.DB.Collection("connected_accounts").FindOne(ctx, bson.M{"_id": accountID}).Decode(&account)

	middleware.IncAccountSynced()
	slog.Info("account_synced",
		"user_id", userID.Hex(),
		"account_id", accountID.Hex(),
		"balance", req.Balance,
	)

	json.NewEncoder(w).Encode(account)
}

// DeleteConnectedAccount godoc
// @Summary Remover conta conectada
// @Description Remove uma conta conectada do perfil do usuário
// @Tags accounts
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Account ID"
// @Success 204 "No Content"
// @Failure 401 {string} string "Unauthorized"
// @Failure 404 {string} string "Account not found"
// @Router /accounts/{id} [delete]
func DeleteConnectedAccount(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r)
	if userID == primitive.NilObjectID {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	accountID, err := primitive.ObjectIDFromHex(extractAccountID(r.URL.Path))
	if err != nil {
		http.Error(w, "Invalid account ID", http.StatusBadRequest)
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	result, err := database.DB.Collection("connected_accounts").DeleteOne(ctx, bson.M{
		"_id":     accountID,
		"user_id": userID,
	})

	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	if result.DeletedCount == 0 {
		http.Error(w, "Account not found", http.StatusNotFound)
		return
	}

	middleware.IncAccountDisconnected()
	slog.Info("account_disconnected",
		"user_id", userID.Hex(),
		"account_id", accountID.Hex(),
	)

	w.WriteHeader(http.StatusNoContent)
}

// GetBankProviders godoc
// @Summary Listar bancos disponíveis
// @Description Retorna a lista de bancos disponíveis para conexão
// @Tags accounts
// @Accept json
// @Produce json
// @Success 200 {object} map[string]models.BankProviderInfo
// @Router /accounts/providers [get]
func GetBankProviders(w http.ResponseWriter, r *http.Request) {
	json.NewEncoder(w).Encode(models.BankProviders)
}

// GetAccountsSummary godoc
// @Summary Resumo de todas as contas
// @Description Retorna um resumo consolidado de todas as contas conectadas
// @Tags accounts
// @Accept json
// @Produce json
// @Security BearerAuth
// @Success 200 {object} map[string]interface{}
// @Failure 401 {string} string "Unauthorized"
// @Router /accounts/summary [get]
func GetAccountsSummary(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r)
	if userID == primitive.NilObjectID {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	cursor, err := database.DB.Collection("connected_accounts").Find(ctx,
		bson.M{"user_id": userID, "is_active": true},
	)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer cursor.Close(ctx)

	var accounts []models.ConnectedAccount
	if err := cursor.All(ctx, &accounts); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Calculate summary
	summary := struct {
		TotalBalance    float64 `json:"total_balance"`
		TotalAccounts   int     `json:"total_accounts"`
		CheckingBalance float64 `json:"checking_balance"`
		SavingsBalance  float64 `json:"savings_balance"`
		CreditBalance   float64 `json:"credit_balance"`
		ByProvider      map[string]struct {
			Count   int     `json:"count"`
			Balance float64 `json:"balance"`
		} `json:"by_provider"`
	}{
		ByProvider: make(map[string]struct {
			Count   int     `json:"count"`
			Balance float64 `json:"balance"`
		}),
	}

	for _, acc := range accounts {
		summary.TotalBalance += acc.Balance
		summary.TotalAccounts++

		switch acc.AccountType {
		case "checking":
			summary.CheckingBalance += acc.Balance
		case "savings":
			summary.SavingsBalance += acc.Balance
		case "credit":
			summary.CreditBalance += acc.Balance
		}

		provider := summary.ByProvider[acc.Provider]
		provider.Count++
		provider.Balance += acc.Balance
		summary.ByProvider[acc.Provider] = provider
	}

	json.NewEncoder(w).Encode(summary)
}

func isValidLastFour(s string) bool {
	matched, _ := regexp.MatchString(`^\d{4}$`, s)
	return matched
}

// extractAccountID extracts the account ID from path like /api/v1/accounts/{id} or /api/v1/accounts/{id}/sync
func extractAccountID(path string) string {
	// Remove prefix
	path = strings.TrimPrefix(path, "/api/v1/accounts/")
	// Remove suffix if present
	path = strings.TrimSuffix(path, "/sync")
	// Get first segment
	parts := strings.Split(path, "/")
	if len(parts) > 0 {
		return parts[0]
	}
	return ""
}

package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

type DebtEntryType string

const (
	EntryInterest DebtEntryType = "interest"
	EntryPayment  DebtEntryType = "payment"
)

type DebtEntry struct {
	ID            primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	Type          DebtEntryType      `json:"type" bson:"type"`
	Amount        float64            `json:"amount" bson:"amount"`
	BalanceBefore float64            `json:"balance_before" bson:"balance_before"`
	BalanceAfter  float64            `json:"balance_after" bson:"balance_after"`
	Date          time.Time          `json:"date" bson:"date"`
	Note          string             `json:"note,omitempty" bson:"note,omitempty"`
	CreatedAt     time.Time          `json:"created_at" bson:"created_at"`
}

type Debt struct {
	ID            primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	Name          string             `json:"name" bson:"name"`
	Description   string             `json:"description" bson:"description"`
	InitialAmount float64            `json:"initial_amount" bson:"initial_amount"`
	CurrentAmount float64            `json:"current_amount" bson:"current_amount"`
	InterestRate  float64            `json:"interest_rate" bson:"interest_rate"` // 0.01 = 1%
	StartDate     time.Time          `json:"start_date" bson:"start_date"`
	EndDate       *time.Time         `json:"end_date,omitempty" bson:"end_date,omitempty"`
	IsActive      bool               `json:"is_active" bson:"is_active"`
	Entries       []DebtEntry        `json:"entries" bson:"entries"`
	CreatedAt     time.Time          `json:"created_at" bson:"created_at"`
	UpdatedAt     time.Time          `json:"updated_at" bson:"updated_at"`
}

type CreateDebtRequest struct {
	Name          string    `json:"name"`
	Description   string    `json:"description"`
	InitialAmount float64   `json:"initial_amount"`
	InterestRate  float64   `json:"interest_rate"`
	StartDate     time.Time `json:"start_date"`
}

type PaymentRequest struct {
	Amount float64   `json:"amount"`
	Date   time.Time `json:"date"`
	Note   string    `json:"note,omitempty"`
}

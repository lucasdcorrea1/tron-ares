package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

type TransactionType string

const (
	Income  TransactionType = "income"
	Expense TransactionType = "expense"
)

type TransactionCategory string

const (
	CategoryFood      TransactionCategory = "food"
	CategoryTransport TransactionCategory = "transport"
	CategoryHousing   TransactionCategory = "housing"
	CategoryLeisure   TransactionCategory = "leisure"
	CategoryHealth    TransactionCategory = "health"
	CategoryEducation TransactionCategory = "education"
	CategorySalary    TransactionCategory = "salary"
	CategoryFreelance TransactionCategory = "freelance"
	CategoryOther     TransactionCategory = "other"
)

type Transaction struct {
	ID          primitive.ObjectID  `json:"id" bson:"_id,omitempty"`
	UserID      primitive.ObjectID  `json:"user_id" bson:"user_id"`
	Description string              `json:"description" bson:"description"`
	Amount      float64             `json:"amount" bson:"amount"`
	Type        TransactionType     `json:"type" bson:"type"`
	Category    TransactionCategory `json:"category" bson:"category"`
	Date        time.Time           `json:"date" bson:"date"`
	CreatedAt   time.Time           `json:"created_at" bson:"created_at"`
}

type CreateTransactionRequest struct {
	Description string              `json:"description"`
	Amount      float64             `json:"amount"`
	Type        TransactionType     `json:"type"`
	Category    TransactionCategory `json:"category"`
	Date        time.Time           `json:"date"`
}

type UpdateTransactionRequest struct {
	Description string              `json:"description,omitempty"`
	Amount      float64             `json:"amount,omitempty"`
	Type        TransactionType     `json:"type,omitempty"`
	Category    TransactionCategory `json:"category,omitempty"`
	Date        time.Time           `json:"date,omitempty"`
}

type BalanceResponse struct {
	Balance       float64 `json:"balance"`
	TotalIncome   float64 `json:"total_income"`
	TotalExpenses float64 `json:"total_expenses"`
}

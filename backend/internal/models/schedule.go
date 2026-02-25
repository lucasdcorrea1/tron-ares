package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

type Schedule struct {
	ID          primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	Title       string             `json:"title" bson:"title"`
	Description string             `json:"description,omitempty" bson:"description,omitempty"`
	DateTime    time.Time          `json:"date_time" bson:"date_time"`
	IsCompleted bool               `json:"is_completed" bson:"is_completed"`
	HasReminder bool               `json:"has_reminder" bson:"has_reminder"`
	Category    string             `json:"category,omitempty" bson:"category,omitempty"`
	CreatedAt   time.Time          `json:"created_at" bson:"created_at"`
	UpdatedAt   time.Time          `json:"updated_at" bson:"updated_at"`
}

type CreateScheduleRequest struct {
	Title       string    `json:"title"`
	Description string    `json:"description,omitempty"`
	DateTime    time.Time `json:"date_time"`
	HasReminder bool      `json:"has_reminder"`
	Category    string    `json:"category,omitempty"`
}

type UpdateScheduleRequest struct {
	Title       string    `json:"title,omitempty"`
	Description string    `json:"description,omitempty"`
	DateTime    time.Time `json:"date_time,omitempty"`
	IsCompleted bool      `json:"is_completed,omitempty"`
	HasReminder bool      `json:"has_reminder,omitempty"`
	Category    string    `json:"category,omitempty"`
}

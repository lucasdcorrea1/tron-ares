package database

import (
	"context"
	"log"
	"time"

	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

var Client *mongo.Client
var DB *mongo.Database

func Connect(uri, dbName string) error {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	clientOptions := options.Client().ApplyURI(uri)
	client, err := mongo.Connect(ctx, clientOptions)
	if err != nil {
		return err
	}

	// Ping the database
	if err := client.Ping(ctx, nil); err != nil {
		return err
	}

	Client = client
	DB = client.Database(dbName)

	log.Printf("Connected to MongoDB: %s", dbName)
	return nil
}

func Disconnect() {
	if Client != nil {
		ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cancel()
		Client.Disconnect(ctx)
	}
}

// Collections
func Users() *mongo.Collection {
	return DB.Collection("users")
}

func Profiles() *mongo.Collection {
	return DB.Collection("profiles")
}

func Transactions() *mongo.Collection {
	return DB.Collection("transactions")
}

func Debts() *mongo.Collection {
	return DB.Collection("debts")
}

func Schedules() *mongo.Collection {
	return DB.Collection("schedules")
}

// TRON Collections
func TronProjects() *mongo.Collection {
	return DB.Collection("tron_projects")
}

func TronRepos() *mongo.Collection {
	return DB.Collection("tron_repos")
}

func TronTasks() *mongo.Collection {
	return DB.Collection("tron_tasks")
}

func TronAgentLogs() *mongo.Collection {
	return DB.Collection("tron_agent_logs")
}

func TronDecisions() *mongo.Collection {
	return DB.Collection("tron_decisions")
}

func TronDirectives() *mongo.Collection {
	return DB.Collection("tron_directives")
}

func TronMetrics() *mongo.Collection {
	return DB.Collection("tron_metrics")
}

func ConnectedAccounts() *mongo.Collection {
	return DB.Collection("connected_accounts")
}

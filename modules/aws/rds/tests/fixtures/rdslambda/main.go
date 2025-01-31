package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"log/slog"
	"os"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/secretsmanager"
	"github.com/joeshaw/envdecode"
	"gorm.io/driver/mysql"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

type envConfig struct {
	RDSHost              string `env:"RDS_HOST,required"`
	RDSPort              int    `env:"RDS_PORT,required"`
	RDSEngine            string `env:"RDS_ENGINE,required"`
	RDSMasterUser        string `env:"RDS_MASTER_USER,required"`
	RDSMasterPasswordArn string `env:"RDS_MASTER_PASSWORD_ARN,required"`
	RDSDatabaseName      string `env:"RDS_DATABASE_NAME,required"`
}

// The table we'll create
type HellowWorld struct {
	gorm.Model
	Hello string
}

var rdsConfig envConfig

func setup() error {
	rdsConfig = envConfig{}
	err := envdecode.StrictDecode(&rdsConfig)
	if err != nil {
		slog.Error("could not load environment variables", "error", err)
		return err
	}
	return nil
}

func getMasterPassword() (string, error) {
	ctx := context.Background()
	awsConfig, err := config.LoadDefaultConfig(ctx)
	if err != nil {
		slog.Error("could not load AWS config", "error", err)
		return "", err
	}
	slog.Info("Getting RDS master password from Secrets Manager", "arn", rdsConfig.RDSMasterPasswordArn)
	secretsClient := secretsmanager.NewFromConfig(awsConfig)
	secretData, err := secretsClient.GetSecretValue(ctx, &secretsmanager.GetSecretValueInput{
		SecretId: &rdsConfig.RDSMasterPasswordArn,
	})
	if err != nil {
		slog.Error("could not get RDS master password", "error", err)
		return "", err
	}
	slog.Info("Got password successfully")
	return aws.ToString(secretData.SecretString), nil
}

func HandleRequest(ctx context.Context, event json.RawMessage) error {
	password, err := getMasterPassword()
	if err != nil {
		slog.Error("could not get master password", "error", err)
		return err
	}
	var db *gorm.DB
	if rdsConfig.RDSEngine == "aurora-mysql" {
		slog.Info("Connecting to Aurora MySQL")
		db, err = connectMySQL(password)
	} else if rdsConfig.RDSEngine == "aurora-postgresql" {
		slog.Info("Connecting to Aurora PostgreSQL")
		db, err = connectPostgreSQL(password)
	} else {
		slog.Error("Unkonwn RDS engine", "engine", rdsConfig.RDSEngine)
		return errors.New("unknown RDS engine")
	}
	if err != nil {
		slog.Error("could not connect to the database", "error", err)
		return err
	}
	slog.Info("Successfully connected to the database")
	err = db.AutoMigrate(&HellowWorld{})
	if err != nil {
		slog.Error("could not migrate the database", "error", err)
		return err
	}
	slog.Info("Migrated the database")
	db.Create(&HellowWorld{Hello: "Hello World!"})
	db.Create(&HellowWorld{Hello: "Goodbye World!"})
	slog.Info("Created 2 records in the database")

	var helloWorld HellowWorld
	err = db.First(&helloWorld, "hello = ?", "Hello World!").Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		slog.Error("could not find the record", "error", err)
	}
	slog.Info("Done!")
	return nil
}

func connectMySQL(password string) (*gorm.DB, error) {
	// sample dsn: user:pass@tcp(127.0.0.1:3306)/dbname?charset=utf8mb4&parseTime=True&loc=Local"
	dsn := fmt.Sprintf("%s:%s@tcp(%s:%d)/%s?charset=utf8mb4",
		rdsConfig.RDSMasterUser, password, rdsConfig.RDSHost, rdsConfig.RDSPort, rdsConfig.RDSDatabaseName)
	slog.Info("Attempting to connect to MySQL", "dsn", dsn)
	db, err := gorm.Open(mysql.Open(dsn), &gorm.Config{})
	if err != nil {
		// We'll log the root password, but this is for a unit test so that's ok.
		slog.Error("could not connect to MySQL", "dsn", dsn, "error", err)
		return nil, err
	}
	return db, nil
}

func connectPostgreSQL(password string) (*gorm.DB, error) {
	//  sample dsn: host=localhost user=gorm password=gorm dbname=gorm port=9920 sslmode=disable TimeZone=Asia/Shanghai
	dsn := fmt.Sprintf("host=%s user=%s password=%s dbname=%s port=%d sslmode=disable TimeZone=UTC",
		rdsConfig.RDSHost, rdsConfig.RDSMasterUser, password, rdsConfig.RDSDatabaseName, rdsConfig.RDSPort)
	slog.Info("Attempting to connect to PostgreSQL", "dsn", dsn)
	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		// We'll log the root password, but this is for a unit test so that's ok.
		slog.Error("could not connect to PostgreSQL", "dsn", dsn, "error", err)
		return nil, err
	}
	return db, nil
}

func main() {
	err := setup()
	if err != nil {
		log.Fatalf("could not set up: %v", err)
		os.Exit(1)
	}
	level := slog.LevelInfo
	if len(os.Args) > 1 && os.Args[1] == "interactive" {
		// A useful debugging tool for running locally
		h := slog.NewTextHandler(os.Stdout, &slog.HandlerOptions{Level: level})
		slog.SetDefault(slog.New(h))
		err = HandleRequest(context.Background(), nil)
		if err != nil {
			os.Exit(1)
		}
	} else {
		// normal Lambda path
		h := slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{Level: level})
		slog.SetDefault(slog.New(h))
		lambda.Start(HandleRequest)
	}
	slog.Info("Success!")
}

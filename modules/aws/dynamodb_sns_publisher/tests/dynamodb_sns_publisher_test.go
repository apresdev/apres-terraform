package test

import (
	"context"
	"encoding/json"
	"fmt"
	"testing"
	"time"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/attributevalue"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/aws/aws-sdk-go-v2/service/sqs"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/suite"
)

type DynamoDbSnsPublisherTestSuite struct {
	suite.Suite
	ctx         context.Context
	ddb         *dynamodb.Client
	sqs         *sqs.Client
	awsRegion   string
	environment string
}

func TestDynamoDbSnsPublisherTestSuite(t *testing.T) {
	suite.Run(t, new(DynamoDbSnsPublisherTestSuite))
}

// Make sure that VariableThatShouldStartAtFive is set to five
// before each test
func (s *DynamoDbSnsPublisherTestSuite) SetupSuite() {
	s.ctx = context.Background()
	// Define the AWS region we want to test in
	s.awsRegion = "us-east-2"
	s.environment = "UnitTest"

	// Terratest has a handy way to create clients, but it's SDK v1, and doesn't place nice with SSO,
	// so we'll use the v2 SDK directly.
	cfg, err := config.LoadDefaultConfig(s.ctx, config.WithRegion(s.awsRegion))
	s.Require().NoError(err, "expected no error for LoadDefaultConfig creating AWS session")

	// Configure the AWS clients
	s.ddb = dynamodb.NewFromConfig(cfg)
	s.sqs = sqs.NewFromConfig(cfg)
}

// TODO: This should be pulled into a separate module

func (s *DynamoDbSnsPublisherTestSuite) TestRoundTrip() {
	// Variables for the terraform module
	now := time.Now().Unix()
	tableNameInput := fmt.Sprintf("testfunc%d", now)
	// Terraform options
	terraformOptions := &terraform.Options{
		// The path to where your Terraform code is located
		TerraformDir: "./fixtures",

		// Variables to pass to our Terraform code using -var options
		Vars: map[string]interface{}{
			"name":        tableNameInput,
			"environment": s.environment,
		},
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(s.T(), terraformOptions)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(s.T(), terraformOptions)

	// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Get the outputs
	// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// lambdaName := terraform.Output(t, terraformOptions, "lambda_arn")
	tableName := terraform.Output(s.T(), terraformOptions, "table_name")
	queueUrl := terraform.Output(s.T(), terraformOptions, "queue_url")

	// remove the delete protections at the end of the test but before `terraform destroy` is run
	defer s.removeDeleteProtections(tableName)

	s.createItem(tableName)
	s.pollMessage(queueUrl)
}

// removeDeleteProtections removes the delete protections from the given table.  This is necessary in order to propery tear down the test resources.
func (s *DynamoDbSnsPublisherTestSuite) createItem(tableName string) {
	input := TestModel{
		Pk: "testpk",
		Sk: "testsk",
	}

	item, err := attributevalue.MarshalMap(input)
	s.Require().NoError(err)

	_, err = s.ddb.PutItem(s.ctx, &dynamodb.PutItemInput{
		TableName: aws.String(tableName),
		Item:      item,
	})

	s.Require().NoError(err, "update table should pass")
}

// removeDeleteProtections removes the delete protections from the given table.  This is necessary in order to propery tear down the test resources.
func (s *DynamoDbSnsPublisherTestSuite) pollMessage(queueUrl string) {
	resp, err := s.sqs.ReceiveMessage(s.ctx, &sqs.ReceiveMessageInput{
		QueueUrl:        aws.String(queueUrl),
		WaitTimeSeconds: 20,
	})

	s.Require().NoError(err, "update table should pass")
	s.Assert().Len(resp.Messages, 1, "must receive one message")

	var record events.DynamoDBEventRecord
	err = json.Unmarshal([]byte(*resp.Messages[0].Body), &record)

	s.Assert().NotNil(record.Change.NewImage)
	s.Assert().Contains("testpk", record.Change.NewImage["pk"].String())
	s.Assert().Contains("testsk", record.Change.NewImage["sk"].String())
}

// removeDeleteProtections removes the delete protections from the given table.  This is necessary in order to propery tear down the test resources.
func (s *DynamoDbSnsPublisherTestSuite) removeDeleteProtections(tableName string) {

	s.T().Log("removing delete protections")

	_, err := s.ddb.UpdateTable(s.ctx, &dynamodb.UpdateTableInput{
		TableName:                 aws.String(tableName),
		DeletionProtectionEnabled: aws.Bool(false),
	})

	s.Require().NoError(err, "update table should pass")

	s.T().Log("delete protections removed")
}

type TestModel struct {
	Pk string `dynamodbav:"pk"`
	Sk string `dynamodbav:"sk"`
}

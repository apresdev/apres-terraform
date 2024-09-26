package test

import (
	"context"
	"fmt"
	"strings"
	"testing"
	"time"

	"apres.dev/awstagging"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/applicationautoscaling"
	aastypes "github.com/aws/aws-sdk-go-v2/service/applicationautoscaling/types"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/suite"
)

type DynamoDbTestSuite struct {
	suite.Suite
	ctx         context.Context
	ddb         *dynamodb.Client
	aas         *applicationautoscaling.Client
	awsRegion   string
	environment string
}

func TestDynamoDbSnsPublisherTestSuite(t *testing.T) {
	suite.Run(t, new(DynamoDbTestSuite))
}

// Make sure that VariableThatShouldStartAtFive is set to five
// before each test
func (s *DynamoDbTestSuite) SetupSuite() {
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
	s.aas = applicationautoscaling.NewFromConfig(cfg)
}

// TODO: This should be pulled into a separate module

func (s *DynamoDbTestSuite) TestProvisioned() {
	// Variables for the terraform module
	now := time.Now().Unix()
	tableNameInput := fmt.Sprintf("testtable%d", now)
	// Terraform options
	terraformOptions := &terraform.Options{
		// The path to where your Terraform code is located
		TerraformDir: "./fixtures",

		// Variables to pass to our Terraform code using -var options
		Vars: map[string]interface{}{
			"name":         tableNameInput,
			"environment":  s.environment,
			"billing_mode": "PROVISIONED",
		},
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(s.T(), terraformOptions)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(s.T(), terraformOptions)

	// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Get the outputs
	// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	tableName := terraform.Output(s.T(), terraformOptions, "table_name")
	tableArn := terraform.Output(s.T(), terraformOptions, "table_arn")
	streamArn := terraform.Output(s.T(), terraformOptions, "stream_arn")
	account := terraform.Output(s.T(), terraformOptions, "aws_account_id")

	// remove the delete protections at the end of the test but before `terraform destroy` is run
	defer s.removeDeleteProtections(tableName)

	// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Verify the outputs.
	// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	s.assertOutputs(account, tableNameInput, tableName, tableArn, streamArn)

	// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Describe the table.
	// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	resp, err := s.ddb.DescribeTable(s.ctx, &dynamodb.DescribeTableInput{TableName: &tableName})
	s.Require().NoError(err, "describe table not return an error")
	s.Require().NotNil(resp, "describe table should return a table descriptor")

	// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Check that all defaults are set correctly.
	// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	table := resp.Table
	s.assertAttributes(table)
	s.assertBillingMode(table, types.BillingModeProvisioned)
	s.assertProvisioning(table, int64(5), int64(5))
	s.assertTableClass(table)
	s.assertDeleteProtection(table)
	s.assertEncryption(table)
	s.assertTags(tableArn)

	// Should satisfy CKV_AWS_28 by default
	s.assertPointInTimeRecovery(tableName)

	// Should satisfy CKV2_AWS_16 by default.
	s.assertAutoScaling(tableName)
}

func (s *DynamoDbTestSuite) TestPayPerRequest() {
	// Variables for the terraform module
	now := time.Now().Unix()
	tableNameInput := fmt.Sprintf("testtable%d", now)
	// Terraform options
	terraformOptions := &terraform.Options{
		// The path to where your Terraform code is located
		TerraformDir: "./fixtures",

		// Variables to pass to our Terraform code using -var options
		Vars: map[string]interface{}{
			"name":         tableNameInput,
			"environment":  s.environment,
			"billing_mode": "PAY_PER_REQUEST",
		},
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(s.T(), terraformOptions)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(s.T(), terraformOptions)

	// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Get the outputs
	// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	tableName := terraform.Output(s.T(), terraformOptions, "table_name")
	tableArn := terraform.Output(s.T(), terraformOptions, "table_arn")
	streamArn := terraform.Output(s.T(), terraformOptions, "stream_arn")
	account := terraform.Output(s.T(), terraformOptions, "aws_account_id")

	// remove the delete protections at the end of the test but before `terraform destroy` is run
	defer s.removeDeleteProtections(tableName)

	// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Verify the outputs.
	// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	s.assertOutputs(account, tableNameInput, tableName, tableArn, streamArn)

	// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Describe the table.
	// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	resp, err := s.ddb.DescribeTable(s.ctx, &dynamodb.DescribeTableInput{TableName: &tableName})
	s.Require().NoError(err, "describe table not return an error")
	s.Require().NotNil(resp, "describe table should return a table descriptor")

	// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Check that all defaults are set correctly.
	// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	table := resp.Table
	s.assertAttributes(table)
	s.assertBillingMode(table, types.BillingModePayPerRequest)
	s.assertProvisioning(table, int64(0), int64(0))
	s.assertTableClass(table)
	s.assertDeleteProtection(table)
	s.assertEncryption(table)
	s.assertTags(tableArn)

	// Should satisfy CKV_AWS_28 by default
	s.assertPointInTimeRecovery(tableName)

	// Should satisfy CKV2_AWS_16 by default.
	s.assertNoAutoScaling(tableName)
}

// assertOutputs verifies that all output variables are set correctly.
func (s *DynamoDbTestSuite) assertOutputs(account string, tableNameInput string, tableName string, tableArn string, streamArn string) {
	expectedTableName := fmt.Sprintf("%s-%s-%s-%s", account, strings.ToLower(s.environment), s.awsRegion, strings.ToLower(tableNameInput))
	s.Assert().Equal(expectedTableName, tableName, "expected bucket name to match")

	expectedTableArn := fmt.Sprintf("arn:aws:dynamodb:%s:%s:table/%s", s.awsRegion, account, expectedTableName)
	s.Assert().Equal(expectedTableArn, tableArn, "expected Table ARN to match")

	expectedStreamArn := fmt.Sprintf("arn:aws:dynamodb:%s:%s:table/%s/stream/", s.awsRegion, account, expectedTableName)
	s.Assert().True(strings.HasPrefix(streamArn, expectedStreamArn), "expected Stream ARN to have prefix %s", expectedStreamArn)
}

// assertBillingMode ensures that the billing mode is either nil (default PROVISIONED) or is explicitly set to PROVISIONED.
func (s *DynamoDbTestSuite) assertBillingMode(table *types.TableDescription, expected types.BillingMode) {
	// According to the dynamoDB client docs "You may need to switch to on-demand mode at least once in order to return a BillingModeSummary response"
	if nil != table.BillingModeSummary {
		// Check billing mode if given.
		s.Assert().Equal(expected, table.BillingModeSummary.BillingMode, "table should use specified billing_mode")
	} else {
		// If BillingModeSummary is nil then we should be able to guarantee that the mode is PROVISIONED. See comment above.
		s.Assert().Equal(expected, types.BillingModeProvisioned)
	}

}

// assertProvisioning ensures that the table was both the RCU and WCU set with the initial default of 5.
func (s *DynamoDbTestSuite) assertProvisioning(table *types.TableDescription, expectedRCU int64, expectedWCU int64) {
	s.Require().NotNil(table.ProvisionedThroughput, "table should have nil ProvisionedThroughput")
	s.Require().NotNil(table.ProvisionedThroughput.ReadCapacityUnits, "table should have non-nil RCUs")
	s.Assert().Equal(expectedRCU, *table.ProvisionedThroughput.ReadCapacityUnits, "table should have expected RCUs provisioned")
	s.Require().NotNil(table.ProvisionedThroughput.WriteCapacityUnits, "table should have non-nil WCUs")
	s.Assert().Equal(expectedWCU, *table.ProvisionedThroughput.WriteCapacityUnits, "table should have expected WCUs provisioned")
}

// assertTableClass ensures that the table class is either nil (default STANDARD) or is explicitly set to STANDARD,
func (s *DynamoDbTestSuite) assertTableClass(table *types.TableDescription) {
	if nil != table.TableClassSummary {
		// Check table class.  If table class summary is nil then we should be able to guarantee that the class is STANDARD
		s.Assert().Equal(types.TableClassStandard, table.TableClassSummary.TableClass, "table should use STANDARD table_class by default")
	}
}

// assertDeleteProtection ensures that the table has delete protections enabled by default.
func (s *DynamoDbTestSuite) assertDeleteProtection(table *types.TableDescription) {
	s.Require().NotNil(table.DeletionProtectionEnabled, "delete protection must be defined")
	s.Assert().Equal(true, *table.DeletionProtectionEnabled, "table should have delete protection enabled by default")
}

// assertAttributes ensures that the table attributes are defined correctly.
func (s *DynamoDbTestSuite) assertAttributes(table *types.TableDescription) {
	s.Require().Len(table.KeySchema, 2, "table expected to have hash_key and sort key")

	s.Assert().Equal("pk", *table.KeySchema[0].AttributeName)
	s.Assert().Equal(types.KeyTypeHash, table.KeySchema[0].KeyType)
	s.Assert().Equal("sk", *table.KeySchema[1].AttributeName)
	s.Assert().Equal(types.KeyTypeRange, table.KeySchema[1].KeyType)

	s.Require().Len(table.AttributeDefinitions, 2, "table expected to have two attributes")
	s.Assert().Equal("pk", *table.AttributeDefinitions[0].AttributeName)
	s.Assert().Equal(types.ScalarAttributeTypeS, table.AttributeDefinitions[0].AttributeType)
	s.Assert().Equal("sk", *table.AttributeDefinitions[1].AttributeName)
	s.Assert().Equal(types.ScalarAttributeTypeS, table.AttributeDefinitions[1].AttributeType)
}

// assertPointInTimeRecovery ensures that the table has point-in-time-recovery enabled by default.
func (s *DynamoDbTestSuite) assertPointInTimeRecovery(tableName string) {
	resp, err := s.ddb.DescribeContinuousBackups(s.ctx, &dynamodb.DescribeContinuousBackupsInput{TableName: &tableName})
	s.Require().NoError(err, "describe continuous backups not return an error")
	s.Require().NotNil(resp, "describe continuous backups should return a table descriptor")

	s.Require().NotNil(types.ContinuousBackupsStatusEnabled, resp.ContinuousBackupsDescription.ContinuousBackupsStatus, "table should have continuous backups defined")
	s.Assert().Equal(types.ContinuousBackupsStatusEnabled, resp.ContinuousBackupsDescription.ContinuousBackupsStatus, "table should have continuous backups enabled by default")

	s.Require().NotNil(types.ContinuousBackupsStatusEnabled, resp.ContinuousBackupsDescription.PointInTimeRecoveryDescription, "table should have point-in-time-recovery defined")
	s.Assert().Equal(types.PointInTimeRecoveryStatusEnabled, resp.ContinuousBackupsDescription.PointInTimeRecoveryDescription.PointInTimeRecoveryStatus, "table should have point-in-time-recovery enabled by default")
}

// assertEncryptionEnabled ensures that the table has encryption enabled by default.
func (s *DynamoDbTestSuite) assertEncryption(table *types.TableDescription) {
	s.Require().NotNil(table.SSEDescription)
	s.Assert().Equal(types.SSEStatusEnabled, table.SSEDescription.Status)
}

// assertAutoScaling ensures that the table has auto-scaling enabled on it by default.
func (s *DynamoDbTestSuite) assertAutoScaling(tableName string) {
	resourceId := fmt.Sprintf("table/%s", tableName)

	s.assertScalingTargets(resourceId)
	s.assertScalingPolicies(resourceId)

}

// assertNoAutoScaling ensures that the table has auto-scaling disabled on it.
func (s *DynamoDbTestSuite) assertNoAutoScaling(tableName string) {
	resourceId := fmt.Sprintf("table/%s", tableName)

	s.assertNoScalingTargets(resourceId)
	s.assertNoScalingPolicies(resourceId)

}

// assertScalingTargets ensures that the dynamoDb table has scaling targets for both RCU and WCU
func (s *DynamoDbTestSuite) assertScalingTargets(resourceId string) {
	targets, err := s.aas.DescribeScalableTargets(s.ctx, &applicationautoscaling.DescribeScalableTargetsInput{
		ServiceNamespace: aastypes.ServiceNamespaceDynamodb,
		ResourceIds:      []string{resourceId},
	})

	s.Require().NoError(err, "decribe autoscaling targets should pass")
	s.Assert().NotNil(targets, "expected result to describe scalable targets")

	s.Assert().Len(targets.ScalableTargets, 2, "expected two auto-scaling targets on the table by default")

	hasRCU := false
	hasWCU := false

	for _, target := range targets.ScalableTargets {

		switch target.ScalableDimension {
		case aastypes.ScalableDimensionDynamoDBTableReadCapacityUnits:
			hasRCU = true
		case aastypes.ScalableDimensionDynamoDBTableWriteCapacityUnits:
			hasWCU = true
		}

		s.Require().NotNil(target.MinCapacity)
		s.Assert().Equal(int32(5), *target.MinCapacity, "min capacity should default to 5")

		s.Require().NotNil(target.MaxCapacity)
		s.Assert().Equal(int32(1000), *target.MaxCapacity, "max capacity should default to 1,000")

	}

	s.Assert().True(hasRCU, "must have a scaling target on RCU")
	s.Assert().True(hasWCU, "must have a scaling target on WCU")
}

// assertScalingPolicies ensures that the default scaling policy is target tracking at 70.0
func (s *DynamoDbTestSuite) assertScalingPolicies(resourceId string) {
	policies, err := s.aas.DescribeScalingPolicies(s.ctx, &applicationautoscaling.DescribeScalingPoliciesInput{
		ServiceNamespace: aastypes.ServiceNamespaceDynamodb,
		ResourceId:       aws.String(resourceId),
	})

	s.Require().NoError(err, "decribe autoscaling policies should pass")
	s.Assert().NotNil(policies, "expected result to describe policies")

	hasRCU := false
	hasWCU := false

	for _, policy := range policies.ScalingPolicies {

		switch policy.ScalableDimension {
		case aastypes.ScalableDimensionDynamoDBTableReadCapacityUnits:
			hasRCU = true
		case aastypes.ScalableDimensionDynamoDBTableWriteCapacityUnits:
			hasWCU = true
		}

		s.Require().NotNil(policy.TargetTrackingScalingPolicyConfiguration, "should use target tracking by default")
		s.Require().NotNil(policy.TargetTrackingScalingPolicyConfiguration.TargetValue, "should have a target trackng value")
		s.Assert().Equal(float64(70.0), *policy.TargetTrackingScalingPolicyConfiguration.TargetValue, "target tracking should default to 70")

	}

	s.Assert().True(hasRCU, "must have a scaling policy on RCU")
	s.Assert().True(hasWCU, "must have a scaling policy on WCU")
}

// assertNoScalingTargets ensures that the dynamoDb table has no scaling targets.
func (s *DynamoDbTestSuite) assertNoScalingTargets(resourceId string) {
	targets, err := s.aas.DescribeScalableTargets(s.ctx, &applicationautoscaling.DescribeScalableTargetsInput{
		ServiceNamespace: aastypes.ServiceNamespaceDynamodb,
		ResourceIds:      []string{resourceId},
	})

	s.Require().NoError(err, "decribe autoscaling targets should pass")
	s.Assert().NotNil(targets, "expected result to describe scalable targets")

	s.Assert().Len(targets.ScalableTargets, 0, "expected no auto-scaling targets on the table by default")
}

// assertNoScalingPolicies ensures that no scaling polices exist
func (s *DynamoDbTestSuite) assertNoScalingPolicies(resourceId string) {
	policies, err := s.aas.DescribeScalingPolicies(s.ctx, &applicationautoscaling.DescribeScalingPoliciesInput{
		ServiceNamespace: aastypes.ServiceNamespaceDynamodb,
		ResourceId:       aws.String(resourceId),
	})

	s.Require().NoError(err, "decribe autoscaling policies should pass")
	s.Assert().NotNil(policies, "expected result to describe policies")

	s.Assert().Len(policies.ScalingPolicies, 0, "expected no auto-scaling policies on the table by default")
}

// assertTags ensures that the table has all required tags set with appropriate values by default.
func (s *DynamoDbTestSuite) assertTags(tableArn string) {
	resp, err := s.ddb.ListTagsOfResource(s.ctx, &dynamodb.ListTagsOfResourceInput{ResourceArn: &tableArn})
	s.Assert().NoError(err, "expected no error on GetBucketTagging")

	// Tag structs are specific to the service, so convert to awstagging.TagItem
	tags := make([]awstagging.TagItem, 0)
	for _, tag := range resp.Tags {
		tags = append(tags, awstagging.TagItem{Key: tag.Key, Value: tag.Value})
	}
	valid, missing := awstagging.VerifyTagsExist(tags)
	s.Assert().True(valid, fmt.Sprintf("expected tags not found: %v", missing))

	valid, bad := awstagging.VerifyTagsValueFormat(tags)
	s.Assert().True(valid, fmt.Sprintf("Tags have invalid values: %v", bad))
}

// removeDeleteProtections removes the delete protections from the given table.  This is necessary in order to propery tear down the test resources.
func (s *DynamoDbTestSuite) removeDeleteProtections(tableName string) {

	s.T().Log("removing delete protections")

	_, err := s.ddb.UpdateTable(s.ctx, &dynamodb.UpdateTableInput{
		TableName:                 &tableName,
		DeletionProtectionEnabled: aws.Bool(false),
	})

	s.Require().NoError(err, "update table should pass")

	s.T().Log("delete protections removed")
}

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
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TODO: This should be pulled into a separate module

func TestDynamoDb(t *testing.T) {
	// Define the AWS region we want to test in
	awsRegion := "us-east-2"
	environment := "UnitTest"

	ctx := context.Background()

	// Terratest has a handy way to create clients, but it's SDK v1, and doesn't place nice with SSO,
	// so we'll use the v2 SDK directly.
	cfg, err := config.LoadDefaultConfig(ctx, config.WithRegion(awsRegion))
	require.NoError(t, err, "expected no error for LoadDefaultConfig creating AWS session")

	svc := dynamodb.NewFromConfig(cfg)

	// Variables for the terraform module
	now := time.Now().Unix()
	tableNameInput := fmt.Sprintf("testtable%d", now)
	// Terraform options
	terraformOptions := &terraform.Options{
		// The path to where your Terraform code is located
		TerraformDir: "./fixtures",

		// Variables to pass to our Terraform code using -var options
		Vars: map[string]interface{}{
			"name":        tableNameInput,
			"environment": environment,
		},
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(t, terraformOptions)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(t, terraformOptions)

	// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Get the outputs
	// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	tableName := terraform.Output(t, terraformOptions, "table_name")
	tableArn := terraform.Output(t, terraformOptions, "table_arn")
	streamArn := terraform.Output(t, terraformOptions, "stream_arn")
	account := terraform.Output(t, terraformOptions, "aws_account_id")

	// remove the delete protections at the end of the test but before `terraform destroy` is run
	defer removeDeleteProtections(ctx, t, svc, tableName)

	// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Verify the outputs.
	// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	assertOutputs(t, account, environment, awsRegion, tableNameInput, tableName, tableArn, streamArn)

	// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Describe the table.
	// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	resp, err := svc.DescribeTable(ctx, &dynamodb.DescribeTableInput{TableName: &tableName})
	require.NoError(t, err, "describe table not return an error")
	require.NotNil(t, resp, "describe table should return a table descriptor")

	// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Check that all defaults are set correctly.
	// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	table := resp.Table
	assertAttributes(t, table)
	assertBillingMode(t, table)
	assertProvisioning(t, table)
	assertTableClass(t, table)
	assertDeleteProtection(t, table)
	assertEncryption(t, table)
	assertTags(ctx, t, svc, tableArn)

	// Should satisfy CKV_AWS_28 by default
	assertPointInTimeRecovery(ctx, t, svc, tableName)

	// Should satisfy CKV2_AWS_16 by default.
	assertAutoScaling(ctx, t, cfg, tableName)
}

// assertOutputs verifies that all output variables are set correctly.
func assertOutputs(t *testing.T, account string, environment string, awsRegion string, tableNameInput string, tableName string, tableArn string, streamArn string) {
	expectedTableName := fmt.Sprintf("%s-%s-%s-%s", account, strings.ToLower(environment), awsRegion, strings.ToLower(tableNameInput))
	assert.Equal(t, expectedTableName, tableName, "expected bucket name to match")

	expectedTableArn := fmt.Sprintf("arn:aws:dynamodb:%s:%s:table/%s", awsRegion, account, expectedTableName)
	assert.Equal(t, expectedTableArn, tableArn, "expected Table ARN to match")

	expectedStreamArn := fmt.Sprintf("arn:aws:dynamodb:%s:%s:table/%s/stream/", awsRegion, account, expectedTableName)
	assert.True(t, strings.HasPrefix(streamArn, expectedStreamArn), "expected Stream ARN to have prefix %s", expectedStreamArn)
}

// assertBillingMode ensures that the billing mode is either nil (default PROVISIONED) or is explicitly set to PROVISIONED.
func assertBillingMode(t *testing.T, table *types.TableDescription) {
	// According to the dynamoDB client docs "You may need to switch to on-demand mode at least once in order to return a BillingModeSummary response"
	if nil != table.BillingModeSummary {
		// Check billing mode if given.  If BillingModeSummary is nil then we should be able to guarantee that the mode is PROVISIONED. See comment above.
		assert.Equal(t, types.BillingModeProvisioned, table.BillingModeSummary.BillingMode, "table should use PROVISIONED billing_mode by default")
	}

}

// assertProvisioning ensures that the table was both the RCU and WCU set with the initial default of 5.
func assertProvisioning(t *testing.T, table *types.TableDescription) {
	require.NotNil(t, table.ProvisionedThroughput.ReadCapacityUnits, "table should hanve non-nil RCUs")
	assert.Equal(t, int64(5), *table.ProvisionedThroughput.ReadCapacityUnits, "table should use 5 RCU by default")
	require.NotNil(t, table.ProvisionedThroughput.WriteCapacityUnits, "table should hanve non-nil WCUs")
	assert.Equal(t, int64(5), *table.ProvisionedThroughput.WriteCapacityUnits, "table should use 5 WCY by default")
}

// assertTableClass ensures that the table class is either nil (default STANDARD) or is explicitly set to STANDARD,
func assertTableClass(t *testing.T, table *types.TableDescription) {
	if nil != table.TableClassSummary {
		// Check table class.  If table class summary is nil then we should be able to guarantee that the class is STANDARD
		assert.Equal(t, types.TableClassStandard, table.TableClassSummary.TableClass, "table should use STANDARD table_class by default")
	}
}

// assertDeleteProtection ensures that the table has delete protections enabled by default.
func assertDeleteProtection(t *testing.T, table *types.TableDescription) {
	require.NotNil(t, table.DeletionProtectionEnabled, "delete protection must be defined")
	assert.Equal(t, true, *table.DeletionProtectionEnabled, "table should have delete protection enabled by default")
}

// assertAttributes ensures that the table attributes are defined correctly.
func assertAttributes(t *testing.T, table *types.TableDescription) {
	require.Len(t, table.KeySchema, 2, "table expected to have hash_key and sort key")

	assert.Equal(t, "pk", *table.KeySchema[0].AttributeName)
	assert.Equal(t, types.KeyTypeHash, table.KeySchema[0].KeyType)
	assert.Equal(t, "sk", *table.KeySchema[1].AttributeName)
	assert.Equal(t, types.KeyTypeRange, table.KeySchema[1].KeyType)

	require.Len(t, table.AttributeDefinitions, 2, "table expected to have two attributes")
	assert.Equal(t, "pk", *table.AttributeDefinitions[0].AttributeName)
	assert.Equal(t, types.ScalarAttributeTypeS, table.AttributeDefinitions[0].AttributeType)
	assert.Equal(t, "sk", *table.AttributeDefinitions[1].AttributeName)
	assert.Equal(t, types.ScalarAttributeTypeS, table.AttributeDefinitions[1].AttributeType)
}

// assertPointInTimeRecovery ensures that the table has point-in-time-recovery enabled by default.
func assertPointInTimeRecovery(ctx context.Context, t *testing.T, svc *dynamodb.Client, tableName string) {
	resp, err := svc.DescribeContinuousBackups(ctx, &dynamodb.DescribeContinuousBackupsInput{TableName: &tableName})
	require.NoError(t, err, "describe continuous backups not return an error")
	require.NotNil(t, resp, "describe continuous backups should return a table descriptor")

	require.NotNil(t, types.ContinuousBackupsStatusEnabled, resp.ContinuousBackupsDescription.ContinuousBackupsStatus, "table should have continuous backups defined")
	assert.Equal(t, types.ContinuousBackupsStatusEnabled, resp.ContinuousBackupsDescription.ContinuousBackupsStatus, "table should have continuous backups enabled by default")

	require.NotNil(t, types.ContinuousBackupsStatusEnabled, resp.ContinuousBackupsDescription.PointInTimeRecoveryDescription, "table should have point-in-time-recovery defined")
	assert.Equal(t, types.PointInTimeRecoveryStatusEnabled, resp.ContinuousBackupsDescription.PointInTimeRecoveryDescription.PointInTimeRecoveryStatus, "table should have point-in-time-recovery enabled by default")
}

// assertEncryptionEnabled ensures that the table has encryption enabled by default.
func assertEncryption(t *testing.T, table *types.TableDescription) {
	require.NotNil(t, table.SSEDescription)
	assert.Equal(t, types.SSEStatusEnabled, table.SSEDescription.Status)
}

// assertAutoScaling ensures that the table has auto-scaling enabled on it by default.
func assertAutoScaling(ctx context.Context, t *testing.T, cfg aws.Config, tableName string) {
	svc := applicationautoscaling.NewFromConfig(cfg)
	resourceId := fmt.Sprintf("table/%s", tableName)

	assertScalingTargets(ctx, svc, resourceId, t)
	assertScalingPolicies(ctx, svc, resourceId, t)

}

// assertScalingTargets ensures that the dynamoDb table has scaling targets for both RCU and WCU
func assertScalingTargets(ctx context.Context, svc *applicationautoscaling.Client, resourceId string, t *testing.T) {
	targets, err := svc.DescribeScalableTargets(ctx, &applicationautoscaling.DescribeScalableTargetsInput{
		ServiceNamespace: aastypes.ServiceNamespaceDynamodb,
		ResourceIds:      []string{resourceId},
	})

	require.NoError(t, err, "decribe autoscaling targets should pass")
	assert.NotNil(t, targets, "expected result to describe scalable targets")

	assert.Len(t, targets.ScalableTargets, 2, "expected two auto-scaling targets on the table by default")

	hasRCU := false
	hasWCU := false

	for _, target := range targets.ScalableTargets {

		switch target.ScalableDimension {
		case aastypes.ScalableDimensionDynamoDBTableReadCapacityUnits:
			hasRCU = true
		case aastypes.ScalableDimensionDynamoDBTableWriteCapacityUnits:
			hasWCU = true
		}

		require.NotNil(t, target.MinCapacity)
		assert.Equal(t, int32(5), *target.MinCapacity, "min capacity should default to 5")

		require.NotNil(t, target.MaxCapacity)
		assert.Equal(t, int32(1000), *target.MaxCapacity, "max capacity should default to 1,000")

	}

	assert.True(t, hasRCU, "must have a scaling target on RCU")
	assert.True(t, hasWCU, "must have a scaling target on WCU")
}

// assertScalingPolicies ensures that the default scaling policy is target tracking at 70.0
func assertScalingPolicies(ctx context.Context, svc *applicationautoscaling.Client, resourceId string, t *testing.T) {
	policies, err := svc.DescribeScalingPolicies(ctx, &applicationautoscaling.DescribeScalingPoliciesInput{
		ServiceNamespace: aastypes.ServiceNamespaceDynamodb,
		ResourceId:       aws.String(resourceId),
	})

	require.NoError(t, err, "decribe autoscaling policies should pass")
	assert.NotNil(t, policies, "expected result to describe policies")

	hasRCU := false
	hasWCU := false

	for _, policy := range policies.ScalingPolicies {

		switch policy.ScalableDimension {
		case aastypes.ScalableDimensionDynamoDBTableReadCapacityUnits:
			hasRCU = true
		case aastypes.ScalableDimensionDynamoDBTableWriteCapacityUnits:
			hasWCU = true
		}

		require.NotNil(t, policy.TargetTrackingScalingPolicyConfiguration, "should use target tracking by default")
		require.NotNil(t, policy.TargetTrackingScalingPolicyConfiguration.TargetValue, "should have a target trackng value")
		assert.Equal(t, float64(70.0), *policy.TargetTrackingScalingPolicyConfiguration.TargetValue, "target tracking should default to 70")

	}

	assert.True(t, hasRCU, "must have a scaling policy on RCU")
	assert.True(t, hasWCU, "must have a scaling policy on WCU")
}

// assertTags ensures that the table has all required tags set with appropriate values by default.
func assertTags(ctx context.Context, t *testing.T, svc *dynamodb.Client, tableArn string) {
	resp, err := svc.ListTagsOfResource(ctx, &dynamodb.ListTagsOfResourceInput{ResourceArn: &tableArn})
	assert.NoError(t, err, "expected no error on GetBucketTagging")

	// Tag structs are specific to the service, so convert to awstagging.TagItem
	tags := make([]awstagging.TagItem, 0)
	for _, tag := range resp.Tags {
		tags = append(tags, awstagging.TagItem{Key: tag.Key, Value: tag.Value})
	}
	valid, missing := awstagging.VerifyTagsExist(tags)
	assert.True(t, valid, fmt.Sprintf("expected tags not found: %v", missing))

	valid, bad := awstagging.VerifyTagsValueFormat(tags)
	assert.True(t, valid, fmt.Sprintf("Tags have invalid values: %v", bad))
}

// removeDeleteProtections removes the delete protections from the given table.  This is necessary in order to propery tear down the test resources.
func removeDeleteProtections(ctx context.Context, t *testing.T, svc *dynamodb.Client, tableName string) {

	t.Log("removing delete protections")

	_, err := svc.UpdateTable(ctx, &dynamodb.UpdateTableInput{
		TableName:                 &tableName,
		DeletionProtectionEnabled: aws.Bool(false),
	})

	require.NoError(t, err, "update table should pass")

	t.Log("delete protections removed")
}

package test

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"
	"testing"
	"time"

	"apres.dev/awstagging"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/cloudwatch"
	"github.com/aws/aws-sdk-go-v2/service/sqs"
	"github.com/aws/aws-sdk-go-v2/service/sqs/types"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/stretchr/testify/suite"
)

type AttributeAssertion func(*testing.T, map[string]string)

type SqsTestSuite struct {
	suite.Suite
	ctx         context.Context
	sqs         *sqs.Client
	cloudwatch  *cloudwatch.Client
	awsRegion   string
	environment string
}

func TestSqsTestSuite(t *testing.T) {
	suite.Run(t, new(SqsTestSuite))
}

// Make sure that VariableThatShouldStartAtFive is set to five
// before each test
func (s *SqsTestSuite) SetupSuite() {
	s.ctx = context.Background()
	// Define the AWS region we want to test in
	s.awsRegion = "us-east-2"
	s.environment = "UnitTest"

	// Terratest has a handy way to create clients, but it's SDK v1, and doesn't place nice with SSO,
	// so we'll use the v2 SDK directly.
	cfg, err := config.LoadDefaultConfig(s.ctx, config.WithRegion(s.awsRegion))
	s.Require().NoError(err, "expected no error for LoadDefaultConfig creating AWS session")

	// Configure the AWS clients
	s.sqs = sqs.NewFromConfig(cfg)
	s.cloudwatch = cloudwatch.NewFromConfig(cfg)
}

func (s *SqsTestSuite) TestSqs() {

	// Variables for the terraform module
	now := time.Now().Unix()
	queueNameInput := fmt.Sprintf("testqueue%d", now)
	// Terraform options
	terraformOptions := &terraform.Options{
		// The path to where your Terraform code is located
		TerraformDir: "./fixtures",

		// Variables to pass to our Terraform code using -var options
		Vars: map[string]interface{}{
			"name":        queueNameInput,
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
	account := terraform.Output(s.T(), terraformOptions, "aws_account_id")
	queueName := terraform.Output(s.T(), terraformOptions, "queue_name")
	queueArn := terraform.Output(s.T(), terraformOptions, "queue_arn")
	deadletterQueueName := terraform.Output(s.T(), terraformOptions, "deadletter_queue_name")
	deadletterQueueArn := terraform.Output(s.T(), terraformOptions, "deadletter_queue_arn")
	error_rate_alarm_arns := terraform.Output(s.T(), terraformOptions, "error_rate_alarm_arns")
	historical_latency_alarm_arns := terraform.Output(s.T(), terraformOptions, "historical_latency_alarm_arns")
	projected_latency_alarm_arns := terraform.Output(s.T(), terraformOptions, "projected_latency_alarm_arns")

	// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Verify the outputs.
	// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	s.assertQueueNameAndArn(account, queueNameInput, queueName, queueArn)
	s.assertQueueNameAndArn(account, queueNameInput+"-deadletter", deadletterQueueName, deadletterQueueArn)

	s.assertAlarmArns(account, queueName, "error-rate", 3, error_rate_alarm_arns)
	s.assertAlarmArns(account, queueName, "historical-latency", 2, historical_latency_alarm_arns)
	s.assertAlarmArns(account, queueName, "projected-latency", 3, projected_latency_alarm_arns)

	// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Apply the common assertions to both the main queue and the deadletter queue.
	// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	commonAttributes := []AttributeAssertion{
		assertEncryption,
		assertMaxMessageSize,
		assertDelaySeconds,
		assertMessageRetentionPeriod,
		assertVisibilityTimeout,
	}

	// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Verify the main queue.
	// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	s.assertTagsAndAttributes(queueName,
		append(
			commonAttributes,
			assertRedrivePolicy(deadletterQueueArn), // Main queue needs a redrive policy
		)...,
	)

	// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Verify the deadletter queue.
	// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	s.assertTagsAndAttributes(deadletterQueueName,
		append(
			commonAttributes,
			assertRedriveAllowPolicy(queueArn), // DQL needs a redrive allow policy
		)...,
	)

	for _, arn := range append(splitArns(error_rate_alarm_arns), append(splitArns(historical_latency_alarm_arns), splitArns(projected_latency_alarm_arns)...)...) {
		s.assertAlarm(arn)
	}

}

func (s *SqsTestSuite) assertAlarm(arn string) {

	resp, err := s.cloudwatch.ListTagsForResource(s.ctx, &cloudwatch.ListTagsForResourceInput{
		ResourceARN: &arn,
	})

	s.Require().NoError(err, "list alarm tags must pass")
	s.Require().NotNil(resp, "list tags response must not be nil")

	// Tag structs are specific to the service, so convert to awstagging.TagItem
	tags := make([]awstagging.TagItem, 0)
	for _, tag := range resp.Tags {
		tags = append(tags, awstagging.TagItem{Key: tag.Key, Value: tag.Value})
	}
	valid, missing := awstagging.VerifyTagsExist(tags)
	s.Assert().True(valid, "expected tags not found: %v on %v", missing, arn)

	valid, bad := awstagging.VerifyTagsValueFormat(tags)
	s.Assert().True(valid, "Tags have invalid values: %v on %v", bad, arn)
}

// assertQueueName verifies that all output variables are set correctly.
func (s *SqsTestSuite) assertQueueNameAndArn(account string, queueNameInput string, queueName string, queueArn string) {
	expectedQueueName := s.asQueueName(queueNameInput)
	s.Assert().Equal(expectedQueueName, queueName, "expected queue name to match")

	expectedQueueArn := s.asQueueArn(account, expectedQueueName)
	s.Assert().Equal(expectedQueueArn, queueArn, "expected queue ARN to match")
}

// asQueueName generates the expected structure of a queue name.
func (s *SqsTestSuite) asQueueName(queueName string) string {
	return fmt.Sprintf("%s-%s", strings.ToLower(s.environment), strings.ToLower(queueName))
}

// asQueueArn generates the expected structure of a queue ARN.
func (s *SqsTestSuite) asQueueArn(account string, queueName string) string {
	return fmt.Sprintf("arn:aws:sqs:%s:%s:%s", s.awsRegion, account, queueName)
}

// assertAlarmArns verifies the alarm ARNs are correct.
func (s *SqsTestSuite) assertAlarmArns(account string, queueName string, metric string, severity int, arns string) {

	arnArray := splitArns(arns)

	for _, arn := range arnArray {
		expectedQueueName := fmt.Sprintf("arn:aws:cloudwatch:%s:%s:alarm:%s-%s-1-sev%d", s.awsRegion, account, strings.ToLower(queueName), metric, severity)
		s.Assert().Equal(expectedQueueName, arn, "expected alarm ARN to match")
	}
}

// assertTagsAndAttributes ensures that all apres tags are applied to the given queue and that all attribute assertions pass.
func (s *SqsTestSuite) assertTagsAndAttributes(queueName string, attributeAssertions ...AttributeAssertion) {
	queueUrl := s.getQueueUrl(queueName)

	s.assertTags(queueUrl)

	attributes := s.getAttributes(queueUrl)
	for _, assertion := range attributeAssertions {
		assertion(s.T(), attributes)
	}
}

// getQueueUrl fetches the queue URL from AWS.
func (s *SqsTestSuite) getQueueUrl(queueName string) *string {
	resp, err := s.sqs.GetQueueUrl(s.ctx, &sqs.GetQueueUrlInput{
		QueueName: &queueName,
	})
	s.Require().NoError(err, "should be able to get queue url")
	s.Require().NotNil(resp, "queue url must not be nil")

	return resp.QueueUrl
}

// getAttributes fetches the queue attributes from AWS.
func (s *SqsTestSuite) getAttributes(queueUrl *string) map[string]string {

	resp, err := s.sqs.GetQueueAttributes(s.ctx, &sqs.GetQueueAttributesInput{
		QueueUrl:       queueUrl,
		AttributeNames: []types.QueueAttributeName{types.QueueAttributeNameAll},
	})
	s.Require().NoError(err, "should be able to get queue url")
	s.Require().NotNil(resp, "attributes must not be nil")

	return resp.Attributes
}

// assertTags ensures that the table has all required tags set with appropriate values by default.
func (s *SqsTestSuite) assertTags(queueUrl *string) {
	resp, err := s.sqs.ListQueueTags(s.ctx, &sqs.ListQueueTagsInput{QueueUrl: queueUrl})
	s.Assert().NoError(err, "expected no error on GetBucketTagging")

	// Tag structs are specific to the service, so convert to awstagging.TagItem
	tags := make([]awstagging.TagItem, 0)
	for key, value := range resp.Tags {
		clonedKey := strings.Clone(key)
		clonedValue := strings.Clone(value)

		tags = append(tags, awstagging.TagItem{Key: &clonedKey, Value: &clonedValue})
	}
	valid, missing := awstagging.VerifyTagsExist(tags)
	s.Assert().True(valid, "expected tags not found: %v", missing)

	valid, bad := awstagging.VerifyTagsValueFormat(tags)
	s.Assert().True(valid, "Tags have invalid values: %v", bad)
}

func splitArns(arns string) []string {
	return strings.Split(arns[1:len(arns)-1], ",")
}

// assertEncryption verifies that encryption is always enabled on all queues.
func assertEncryption(t *testing.T, attributes map[string]string) {

	sseEnabled := required(t, "SqsManagedSseEnabled", attributes)
	assert.Equal(t, "false", sseEnabled, "expected SQS managed encryption to be disabled")

	keyId := optional("KmsMasterKeyId", attributes, "")
	assert.Equal(t, "alias/apres/messaging", keyId, "expected to use KMS encryption with the messaging key by default")
}

// assertMaxMessageSize verifies that the max message size defaults to 256K.
func assertMaxMessageSize(t *testing.T, attributes map[string]string) {
	size := required(t, "MaximumMessageSize", attributes)
	assert.Equal(t, "262144", size, "max message size to default to 256K")
}

// assertMaxMessageSize verifies that the delay defaults to 0 seconds
func assertDelaySeconds(t *testing.T, attributes map[string]string) {
	size := required(t, "DelaySeconds", attributes)
	assert.Equal(t, "0", size, "expected delay to default to 0")
}

// assertMaxMessageSize verifies that the message retention period defaults to 14 days.
func assertMessageRetentionPeriod(t *testing.T, attributes map[string]string) {
	size := required(t, "MessageRetentionPeriod", attributes)
	assert.Equal(t, "1209600", size, "expected message retention period to default to 14 days")
}

// assertVisibilityTimeout verifies that the visibility timeout defaults to 30 seconds.
func assertVisibilityTimeout(t *testing.T, attributes map[string]string) {
	size := required(t, "VisibilityTimeout", attributes)
	assert.Equal(t, "30", size, "expected visibility timeout to default to 30 seconds")
}

// required retrieves a required attribute or fails if the attribute is missing.
func required(t *testing.T, name string, attributes map[string]string) string {
	value, exists := attributes[name]
	assert.True(t, exists, "expected %s to be defined in attributes", name)
	return value
}

// optional retrieves an optional attribute or returns the default value if no attribute exists.
func optional(name string, attributes map[string]string, defaultValue string) string {
	value, exists := attributes[name]
	if exists {
		return value
	}
	return defaultValue
}

// assertRedrivePolicy verifies that the redrive policy is set on the main queue and that the dead letter target ARN matches the DLQ ARN.
func assertRedrivePolicy(expectedArn string) AttributeAssertion {

	return func(t *testing.T, attributes map[string]string) {
		s := required(t, "RedrivePolicy", attributes)

		var policy RedrivePolicy
		err := json.Unmarshal([]byte(s), &policy)
		require.NoError(t, err, "policy must be a map")

		assert.Equal(t, expectedArn, policy.DeadLetterTargetArn, "must have deadletter queue as target arn")
		assert.Equal(t, 4, policy.MaxReceiveCount)
	}

}

// assertRedriveAllowPolicy verifies that the redrive allow policy is set on the DQL and that the main queue ARN is set as the sole source queue ARN.
func assertRedriveAllowPolicy(expectedArn string) AttributeAssertion {

	return func(t *testing.T, attributes map[string]string) {
		s := required(t, "RedriveAllowPolicy", attributes)

		var policy RedriveAllowPolicy
		err := json.Unmarshal([]byte(s), &policy)
		require.NoError(t, err, "policy must be a map")

		assert.Len(t, policy.SourceQueueArns, 1, "must have one and only one source queue")
		assert.Equal(t, expectedArn, policy.SourceQueueArns[0], "must have main queue as source queue")
		assert.Equal(t, "byQueue", policy.RedrivePermission, "must have allow redrive byQueue")
	}

}

// RedrivePolicy defines the structure of a RedrivePolicy in the AWS Queue Attributes.
// This is expected to exist on the main queue.
type RedrivePolicy struct {
	DeadLetterTargetArn string `json:"deadLetterTargetArn"`
	MaxReceiveCount     int    `json:"maxReceiveCount"`
}

// RedriveAllowPolicy defines the structure of a RedriveAllowPolicy in the AWS Queue Attributes
// This is expected to exist on the deadletter queue.
type RedriveAllowPolicy struct {
	RedrivePermission string   `json:"redrivePermission"`
	SourceQueueArns   []string `json:"sourceQueueArns"`
}

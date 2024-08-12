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
	"github.com/aws/aws-sdk-go-v2/service/cloudwatch"
	"github.com/aws/aws-sdk-go-v2/service/sns"
	"github.com/aws/aws-sdk-go-v2/service/sqs"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/suite"
)

type AttributeAssertion func(*testing.T, map[string]string)

type SnsTestSuite struct {
	suite.Suite
	ctx         context.Context
	sns         *sns.Client
	sqs         *sqs.Client
	cloudwatch  *cloudwatch.Client
	awsRegion   string
	environment string
}

func TestSnsTestSuite(t *testing.T) {
	suite.Run(t, new(SnsTestSuite))
}

// Make sure that VariableThatShouldStartAtFive is set to five
// before each test
func (s *SnsTestSuite) SetupSuite() {
	s.ctx = context.Background()
	// Define the AWS region we want to test in
	s.awsRegion = "us-east-2"
	s.environment = "UnitTest"

	// Terratest has a handy way to create clients, but it's SDK v1, and doesn't place nice with SSO,
	// so we'll use the v2 SDK directly.
	cfg, err := config.LoadDefaultConfig(s.ctx, config.WithRegion(s.awsRegion))
	s.Require().NoError(err, "expected no error for LoadDefaultConfig creating AWS session")

	// Configure the AWS clients
	s.sns = sns.NewFromConfig(cfg)
	s.sqs = sqs.NewFromConfig(cfg)
	s.cloudwatch = cloudwatch.NewFromConfig(cfg)
}

func (s *SnsTestSuite) TestSqs() {

	// Variables for the terraform module
	now := time.Now().Unix()
	topicNameInput := fmt.Sprintf("testqueue%d", now)
	// Terraform options
	terraformOptions := &terraform.Options{
		// The path to where your Terraform code is located
		TerraformDir: "./fixtures",

		// Variables to pass to our Terraform code using -var options
		Vars: map[string]interface{}{
			"name":         topicNameInput,
			"display_name": "Test Topic",
			"environment":  s.environment,
		},
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(s.T(), terraformOptions)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(s.T(), terraformOptions)

	// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Get the outputs
	// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	accountId := terraform.Output(s.T(), terraformOptions, "aws_account_id")
	topicArn := terraform.Output(s.T(), terraformOptions, "topic_arn")
	topicName := terraform.Output(s.T(), terraformOptions, "topic_name")

	// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Verify the outputs.
	// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	s.assertTopicNameAndArn(accountId, topicNameInput, topicName, topicArn)

	// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Verify the main queue.
	// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	s.assertTagsAndAttributes(topicArn,
		assertEncryption,
		assertDisplayName,
	)

}

// assertQueueName verifies that all output variables are set correctly.
func (s *SnsTestSuite) assertTopicNameAndArn(account string, topicNameInput string, topicName string, topicArn string) {
	expectedQueueName := s.asTopicName(topicNameInput)
	s.Assert().Equal(expectedQueueName, topicName, "expected queue name to match")

	expectedQueueArn := s.asTopicArn(account, expectedQueueName)
	s.Assert().Equal(expectedQueueArn, topicArn, "expected queue ARN to match")
}

// asTopicName generates the expected structure of a queue name.
func (s *SnsTestSuite) asTopicName(queueName string) string {
	return fmt.Sprintf("%s-%s", strings.ToLower(s.environment), strings.ToLower(queueName))
}

// asTopicArn generates the expected structure of a queue ARN.
func (s *SnsTestSuite) asTopicArn(account string, queueName string) string {
	return fmt.Sprintf("arn:aws:sns:%s:%s:%s", s.awsRegion, account, queueName)
}

// assertTagsAndAttributes ensures that all apres tags are applied to the given queue and that all attribute assertions pass.
func (s *SnsTestSuite) assertTagsAndAttributes(topicArn string, attributeAssertions ...AttributeAssertion) {

	s.assertTags(topicArn)

	attributes := s.getAttributes(topicArn)
	for _, assertion := range attributeAssertions {
		assertion(s.T(), attributes)
	}
}

// getAttributes fetches the queue attributes from AWS.
func (s *SnsTestSuite) getAttributes(topicArn string) map[string]string {

	resp, err := s.sns.GetTopicAttributes(s.ctx, &sns.GetTopicAttributesInput{
		TopicArn: aws.String(topicArn),
	})
	s.Require().NoError(err, "should be able to get queue url")
	s.Require().NotNil(resp, "attributes must not be nil")

	return resp.Attributes
}

// assertTags ensures that the topic has all required tags set with appropriate values by default.
func (s *SnsTestSuite) assertTags(topicArn string) {
	resp, err := s.sns.ListTagsForResource(s.ctx, &sns.ListTagsForResourceInput{ResourceArn: aws.String(topicArn)})
	s.Assert().NoError(err, "expected no error on GetBucketTagging")

	// Tag structs are specific to the service, so convert to awstagging.TagItem
	tags := make([]awstagging.TagItem, 0)
	for _, tag := range resp.Tags {
		tags = append(tags, awstagging.TagItem{Key: tag.Key, Value: tag.Value})
	}
	valid, missing := awstagging.VerifyTagsExist(tags)
	s.Assert().True(valid, "expected tags not found: %v", missing)

	valid, bad := awstagging.VerifyTagsValueFormat(tags)
	s.Assert().True(valid, "Tags have invalid values: %v", bad)
}

// assertEncryption verifies that encryption is always enabled on all queues.
func assertEncryption(t *testing.T, attributes map[string]string) {
	keyId := optional("KmsMasterKeyId", attributes, "")
	assert.Equal(t, "alias/apres/messaging", keyId, "expected to use SNS KMS key by default")
}

// assertDisplayName verifies that display name is set correctly.
func assertDisplayName(t *testing.T, attributes map[string]string) {
	keyId := optional("DisplayName", attributes, "")
	assert.Equal(t, "Test Topic", keyId, "expected to use given display name")
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

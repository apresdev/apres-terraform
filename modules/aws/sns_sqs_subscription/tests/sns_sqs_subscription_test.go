package test

import (
	"context"
	"encoding/json"
	"fmt"
	"testing"
	"time"

	"apres.dev/awspolicy"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/sns"
	"github.com/aws/aws-sdk-go-v2/service/sqs"
	"github.com/aws/aws-sdk-go-v2/service/sqs/types"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/suite"
)

type AttributeAssertion func(*testing.T, map[string]string)

type SnsSqsSubscriptionTestSuite struct {
	suite.Suite
	ctx         context.Context
	sns         *sns.Client
	sqs         *sqs.Client
	awsRegion   string
	environment string
}

func TestSnsSqsSubscriptionTestSuite(t *testing.T) {
	suite.Run(t, new(SnsSqsSubscriptionTestSuite))
}

// Make sure that VariableThatShouldStartAtFive is set to five
// before each test
func (s *SnsSqsSubscriptionTestSuite) SetupSuite() {
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
}

func (s *SnsSqsSubscriptionTestSuite) TestSqs() {

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
	topicArn := terraform.Output(s.T(), terraformOptions, "topic_arn")
	queueUrl := terraform.Output(s.T(), terraformOptions, "queue_url")

	// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Ensure that we are testing encrypted SNS topics and SQS queues
	// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	attributes := s.getQueueAttributes(queueUrl)

	s.assertTopicEncrypted(topicArn)
	s.assertQueueEncrypted(attributes)

	// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Publish a message to the topic and ensure the queue receives the message
	// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	s.assertMessageArrival(topicArn, queueUrl)
}

// assertMessageArrival publishes a message to the topic then ensures that the message is received at the queue.
func (s *SnsSqsSubscriptionTestSuite) assertMessageArrival(topicArn string, queueUrl string) {

	published, err := s.sns.Publish(s.ctx, &sns.PublishInput{
		TargetArn: aws.String(topicArn),
		Message:   aws.String("this is a test message"),
	})

	s.Require().NoError(err, "publish should pass")
	s.Require().NotNil(published, "publish should return non nil response")
	s.Require().NotNil(published.MessageId, "publish should return a message identifier")
	s.Assert().NotEmpty(*published.MessageId, "publish should return a non-empty message identifier")

	received, err := s.sqs.ReceiveMessage(s.ctx, &sqs.ReceiveMessageInput{
		QueueUrl:            aws.String(queueUrl),
		MaxNumberOfMessages: 1,
		WaitTimeSeconds:     20,
	})

	s.Require().NoError(err, "receive message should pass")
	s.Require().NotNil(received, "receive message should return non nil response")

	s.Require().Len(received.Messages, 1, "expected one message to be received")
	s.Require().NotNil(received.Messages[0].MessageId, "received message should return a message identifier")
	s.Assert().NotEmpty(*received.Messages[0].MessageId, "received message should return a non-empty message identifier")
	s.Require().NotNil(received.Messages[0].Body, 1, "expected received message to have a body")
	s.Assert().Equal("this is a test message", *received.Messages[0].Body, "expected raw message body to have been sent")
}

func (s *SnsSqsSubscriptionTestSuite) getQueueAttributes(queueUrl string) map[string]string {
	resp, err := s.sqs.GetQueueAttributes(s.ctx, &sqs.GetQueueAttributesInput{
		QueueUrl:       aws.String(queueUrl),
		AttributeNames: []types.QueueAttributeName{types.QueueAttributeNameAll},
	})

	s.Require().NoError(err, "get queue attributes should pass")
	s.Require().NotNil(resp, "get queue attributes should return non nil response")

	return resp.Attributes
}

// assertTopicEncrypted ensures that the topic is encrypted
func (s *SnsSqsSubscriptionTestSuite) assertTopicEncrypted(topicArn string) {

	resp, err := s.sns.GetTopicAttributes(s.ctx, &sns.GetTopicAttributesInput{
		TopicArn: aws.String(topicArn),
	})
	s.Require().NoError(err, "should be able to get queue url")
	s.Require().NotNil(resp, "attributes must not be nil")

	keyId := optional("KmsMasterKeyId", resp.Attributes, "")
	s.Assert().Equal("alias/apres/messaging", keyId, "expected to use KMS key")
}

// assertQueueEncrypted ensures that the queue is encrypted
func (s *SnsSqsSubscriptionTestSuite) assertQueueEncrypted(attributes map[string]string) {
	keyId := optional("KmsMasterKeyId", attributes, "")
	s.Assert().Equal("alias/apres/messaging", keyId, "expected to use KMS key")
}

// assertQueuePolicy ensures that the queue policy is created
func (s *SnsSqsSubscriptionTestSuite) assertQueuePolicy(queueArn string, topicArn string, attributes map[string]string) {

	policyDocument := optional("Policy", attributes, "")
	s.Assert().NotEmpty(policyDocument, "expected to use KMS key")

	var policy awspolicy.Policy
	s.Require().NoError(json.Unmarshal([]byte(policyDocument), &policy))

	s.Require().Len(policy.Statement, 1)
	s.Assert().Equal("Grant SNS Access", policy.Statement[0].Sid)
	s.Assert().ElementsMatch([]string{"SQS:SendMessage"}, policy.Statement[0].Action)
	s.Assert().ElementsMatch([]string{queueArn}, policy.Statement[0].Resource)
}

// optional retrieves an optional attribute or returns the default value if no attribute exists.
func optional(name string, attributes map[string]string, defaultValue string) string {
	value, exists := attributes[name]
	if exists {
		return value
	}
	return defaultValue
}

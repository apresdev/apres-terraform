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
	"github.com/aws/aws-sdk-go-v2/service/kms"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/suite"
)

type AttributeAssertion func(*testing.T, map[string]string)

type KmsMessagingTestSuite struct {
	suite.Suite
	ctx         context.Context
	kms         *kms.Client
	awsRegion   string
	environment string
}

func TestKmsMessagingTestSuite(t *testing.T) {
	suite.Run(t, new(KmsMessagingTestSuite))
}

// Make sure that VariableThatShouldStartAtFive is set to five
// before each test
func (s *KmsMessagingTestSuite) SetupSuite() {
	s.ctx = context.Background()
	// Define the AWS region we want to test in
	s.awsRegion = "us-east-2"
	s.environment = "UnitTest"

	// Terratest has a handy way to create clients, but it's SDK v1, and doesn't place nice with SSO,
	// so we'll use the v2 SDK directly.
	cfg, err := config.LoadDefaultConfig(s.ctx, config.WithRegion(s.awsRegion))
	s.Require().NoError(err, "expected no error for LoadDefaultConfig creating AWS session")

	// Configure the AWS clients
	s.kms = kms.NewFromConfig(cfg)
}

func (s *KmsMessagingTestSuite) TestKmsMessaging() {

	// Variables for the terraform module
	now := time.Now().Unix()
	keyNameInput := fmt.Sprintf("testkey%d", now)
	// Terraform options
	terraformOptions := &terraform.Options{
		// The path to where your Terraform code is located
		TerraformDir: "./fixtures",

		// Variables to pass to our Terraform code using -var options
		Vars: map[string]interface{}{
			"name":        keyNameInput,
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
	keyAlias := terraform.Output(s.T(), terraformOptions, "cmk_alias")
	keyArn := terraform.Output(s.T(), terraformOptions, "cmk_arn")

	// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Verify the outputs.
	// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	s.assertKeyNameAndArn(account, keyNameInput, keyAlias, keyArn)

	// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Verify the main key.
	// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	s.assertTags(keyArn)

	s.assertKeyRotationEnabled(keyArn)
	s.assertKeyPolicy(account, keyArn)
	s.assertKeyAlias(keyArn, keyAlias)
}

// assertkeyName verifies that all output variables are set correctly.
func (s *KmsMessagingTestSuite) assertKeyNameAndArn(account string, keyNameInput string, keyName string, keyArn string) {
	expectedkeyName := s.keyAlias(account, keyNameInput)
	s.Assert().Equal(expectedkeyName, keyName, "expected key name to match")

	// Note, we cannot pre-compute the expected ARN here since KMS using the Key UUID as the arn which is server-side generated.
	// The best we can do is check the account and regions are correct.
	expectedkeyArn := s.arnPrefix(account)
	s.Assert().True(strings.HasPrefix(keyArn, expectedkeyArn), "expected key ARN to match prefix")
}

// keyAlias generates the expected key alias.
func (s *KmsMessagingTestSuite) keyAlias(account string, keyNameInput string) string {
	return fmt.Sprintf("alias/%s-%s-%s-%s-messaging", account, strings.ToLower(s.environment), strings.ToLower(s.awsRegion), strings.ToLower(keyNameInput))
}

// arnPrefix generates the expected prefix for the key ARN.
func (s *KmsMessagingTestSuite) arnPrefix(account string) string {
	return fmt.Sprintf("arn:aws:kms:%s:%s:key", s.awsRegion, account)
}

// assertKeyRotationEnabled verifies that key rotation is enabled by default
func (s *KmsMessagingTestSuite) assertKeyRotationEnabled(keyArn string) {
	resp, err := s.kms.GetKeyRotationStatus(s.ctx, &kms.GetKeyRotationStatusInput{KeyId: aws.String(keyArn)})
	s.Require().NoError(err, "get key rotation status must pass")
	s.Require().NotNil(resp, "get key rotation status response must not be nil")

	s.Assert().Equal(resp.KeyRotationEnabled, true, "key rotation should be enabled by default")
}

func (s *KmsMessagingTestSuite) assertKeyAlias(keyArn string, keyAlias string) {
	resp, err := s.kms.ListAliases(s.ctx, &kms.ListAliasesInput{
		KeyId: aws.String(keyArn),
	})

	s.Require().NoError(err, "list key aliases must pass")
	s.Require().NotNil(resp, "list key aliases response must not be nil")

	s.Assert().Len(resp.Aliases, 1, "expected to have one key alias")
	s.Assert().Equal(keyAlias, *resp.Aliases[0].AliasName, "expected key alias to match")
}

// assertKeyPolicy verifies that the key is accessible to the root user and can be used by SNS for communicating with SQS
func (s *KmsMessagingTestSuite) assertKeyPolicy(account string, keyArn string) {
	resp, err := s.kms.GetKeyPolicy(s.ctx, &kms.GetKeyPolicyInput{KeyId: aws.String(keyArn)})
	s.Require().NoError(err, "get key policy must pass")
	s.Require().NotNil(resp, "get key policy response must not be nil")

	s.Assert().NotNil(resp.Policy, "key policy must not be nil")

	var policy Policy
	s.Require().NoError(json.Unmarshal([]byte(*resp.Policy), &policy), "failed to parse policy document")

	s.Assert().Len(policy.Statement, 2, "default policy expected to have two statements")

	enableIam := policy.Statement[0]
	s.Assert().Equal("Enable IAM User Permissions", enableIam.Sid)
	s.Assert().Equal("Allow", enableIam.Effect)
	s.Assert().Equal(principal("AWS", fmt.Sprintf("arn:aws:iam::%v:root", account)), enableIam.Principal)
	s.Assert().Equal([]string{"kms:*"}, enableIam.Action)
	s.Assert().Equal([]string{keyArn}, enableIam.Resource)

	enableSNS := policy.Statement[1]
	s.Assert().Equal("SNS decrypt permission", enableSNS.Sid)
	s.Assert().Equal("Allow", enableSNS.Effect)
	s.Assert().Equal(principal("Service", "sns.amazonaws.com"), enableSNS.Principal)
	s.Assert().Equal([]string{"kms:GenerateDataKey*", "kms:Decrypt"}, enableSNS.Action)
	s.Assert().Equal([]string{keyArn}, enableSNS.Resource)
}

// principal is a helper function to generate expected principal values
func principal(typeName string, identifier string) []map[string]string {
	return []map[string]string{{
		typeName: identifier,
	}}
}

// assertTags ensures that the key has all required tags set with appropriate values by default.
func (s *KmsMessagingTestSuite) assertTags(keyArn string) {
	resp, err := s.kms.ListResourceTags(s.ctx, &kms.ListResourceTagsInput{KeyId: aws.String(keyArn)})
	s.Assert().NoError(err, "expected no error on GetBucketTagging")

	// Tag structs are specific to the service, so convert to awstagging.TagItem
	tags := make([]awstagging.TagItem, 0)
	for _, tag := range resp.Tags {
		tags = append(tags, awstagging.TagItem{Key: tag.TagKey, Value: tag.TagValue})
	}
	valid, missing := awstagging.VerifyTagsExist(tags)
	s.Assert().True(valid, "expected tags not found: %v", missing)

	valid, bad := awstagging.VerifyTagsValueFormat(tags)
	s.Assert().True(valid, "Tags have invalid values: %v", bad)
}

type Policy struct {
	Version   string
	Statement []Statement
}

type Statement struct {
	Sid       string
	Effect    string
	Principal []map[string]string
	Action    []string
	Resource  []string
}

func (s *Statement) UnmarshalJSON(data []byte) (err error) {
	var temp map[string]interface{}
	if err := json.Unmarshal(data, &temp); err != nil {
		return nil
	}

	if sid, exists := temp["Sid"]; exists {
		var ok bool
		if s.Sid, ok = sid.(string); !ok {
			return fmt.Errorf("Sid must be a string")
		}
	}

	if effect, exists := temp["Effect"]; exists {
		var ok bool
		if s.Effect, ok = effect.(string); !ok {
			return fmt.Errorf("Effect must be a string")
		}
	}

	if principal, exists := temp["Principal"]; exists {

		switch v := principal.(type) {
		case map[string]interface{}:
			if s.Principal, err = wrapMapArray(v, stringMap); err != nil {
				return err
			}
		case []map[string]interface{}:
			if s.Principal, err = mapArray(v, stringMap); err != nil {
				return err
			}
		default:
			return fmt.Errorf("Principal must be either a map or array of maps")
		}
	}

	if action, exists := temp["Action"]; exists {

		switch v := action.(type) {
		case string:
			s.Action = wrapArray(v)
		case []interface{}:
			if s.Action, err = stringArray(v); err != nil {
				return err
			}
		default:
			return fmt.Errorf("Action must be either a string or array of string")
		}
	}

	if resource, exists := temp["Resource"]; exists {

		switch v := resource.(type) {
		case string:
			s.Resource = wrapArray(v)
		case []interface{}:
			if s.Resource, err = stringArray(v); err != nil {
				return err
			}
		default:
			return fmt.Errorf("Resource must be either a string or array of string")
		}
	}

	return nil
}

func stringMap(input map[string]interface{}) (map[string]string, error) {
	return mapMap(input, identity, toString)
}

func stringArray(items []interface{}) ([]string, error) {
	return mapArray(items, toString)
}

type TransformFn[I any, O any] func(input I) (O, error)

func mapMap[IK comparable, IV any, OK comparable, OV any](input map[IK]IV, keyTransformFn TransformFn[IK, OK], valueTransformFn TransformFn[IV, OV]) (result map[OK]OV, err error) {
	result = make(map[OK]OV)

	for ik, iv := range input {

		var ok OK
		var ov OV

		if ok, err = keyTransformFn(ik); err != nil {
			return nil, err
		}
		if ov, err = valueTransformFn(iv); err != nil {
			return nil, err
		}

		result[ok] = ov

	}

	return result, nil
}

func mapArray[I any, O any](input []I, transformFn TransformFn[I, O]) (result []O, err error) {

	result = make([]O, len(input))

	for i, v := range input {
		if result[i], err = transformFn(v); err != nil {
			return nil, err
		}
	}

	return result, nil
}

func toString(input interface{}) (string, error) {
	if v, ok := input.(string); ok {
		return v, nil
	}

	return "", fmt.Errorf("encountered non string %v", input)
}

func identity[I any](input I) (I, error) {
	return input, nil
}

func wrapMapArray[I any, O any](item I, transformFn TransformFn[I, O]) (result []O, err error) {
	v, err := transformFn(item)
	if err != nil {
		return nil, err
	}

	return wrapArray(v), nil

}

func wrapArray[T any](item T) []T {
	return []T{item}

}

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
	"github.com/aws/aws-sdk-go-v2/service/lambda"
	"github.com/aws/aws-sdk-go-v2/service/lambda/types"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/stretchr/testify/suite"
)

type LambdaTestSuite struct {
	suite.Suite
	ctx         context.Context
	lambda      *lambda.Client
	awsRegion   string
	environment string
}

func TestLambdaTestSuite(t *testing.T) {
	suite.Run(t, new(LambdaTestSuite))
}

// Make sure that VariableThatShouldStartAtFive is set to five
// before each test
func (s *LambdaTestSuite) SetupSuite() {
	s.ctx = context.Background()
	// Define the AWS region we want to test in
	s.awsRegion = "us-east-2"
	s.environment = "UnitTest"
}

func (s *LambdaTestSuite) TestLambdaAtEdgeSourceFile() {
	now := time.Now().Unix()
	functionNameInput := fmt.Sprintf("test-%d", now)
	// Terraform options
	terraformOptions := &terraform.Options{
		TerraformBinary: "tofu",
		TerraformDir:    "./fixtures",

		// Variables to pass to our Terraform code using -var options
		Vars: map[string]interface{}{
			"name":              functionNameInput,
			"environment":       s.environment,
			"enable_vpc":        false,
			"use_zip":           false,
			"is_lambda_at_edge": true,
		},
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(s.T(), terraformOptions)
	terraform.InitAndApply(s.T(), terraformOptions)

	lambdaFunctionName := terraform.Output(s.T(), terraformOptions, "lambda_function_name")
	lambdaFunctionArn := terraform.Output(s.T(), terraformOptions, "lambda_function_arn")
	account := terraform.Output(s.T(), terraformOptions, "aws_account_id")

	// Since this is Lambda@Edge which must be in us-east-1, recreate the lambda client
	// with the correct region.
	cfg, err := config.LoadDefaultConfig(s.ctx, config.WithRegion("us-east-1"))
	s.Require().NoError(err)
	s.lambda = lambda.NewFromConfig(cfg)

	// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Verify the outputs. Lambda@Edge must be us-east-1
	// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	s.assertOutputs(account, functionNameInput, lambdaFunctionName, lambdaFunctionArn, "us-east-1")

	s.assertFunction(
		lambdaFunctionArn,

		// Assertions
		mustNotHaveEnvironmentVariables,
		mustHaveCodeSigning,
		mustHaveTracingEnabled,
		mustNotHaveDeadLetterQueue,
		mustNotUseVpcByDefault,
		mustHaveApresTags,
		mustHaveLogGroup(lambdaFunctionName),
		mustHaveX86Architecture,
	)
	s.assertInvokeFunction(lambdaFunctionArn)
}

func (s *LambdaTestSuite) TestLambdaNoVPCSourceFile() {
	// Variables for the terraform module
	now := time.Now().Unix()
	functionNameInput := fmt.Sprintf("test-%d", now)
	// Terraform options
	terraformOptions := &terraform.Options{
		// The path to where your Terraform code is located
		TerraformDir: "./fixtures",

		// Variables to pass to our Terraform code using -var options
		Vars: map[string]interface{}{
			"name":        functionNameInput,
			"environment": s.environment,
			"enable_vpc":  false,
			"use_zip":     false,
		},
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(s.T(), terraformOptions)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(s.T(), terraformOptions)

	// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Get the outputs
	// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	lambdaFunctionName := terraform.Output(s.T(), terraformOptions, "lambda_function_name")
	lambdaFunctionArn := terraform.Output(s.T(), terraformOptions, "lambda_function_arn")
	account := terraform.Output(s.T(), terraformOptions, "aws_account_id")

	cfg, err := config.LoadDefaultConfig(s.ctx, config.WithRegion(s.awsRegion))
	s.Require().NoError(err)
	s.lambda = lambda.NewFromConfig(cfg)

	// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Verify the outputs.
	// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	s.assertOutputs(account, functionNameInput, lambdaFunctionName, lambdaFunctionArn, s.awsRegion)

	// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Get the function attributes.
	// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	s.assertFunction(
		lambdaFunctionArn,

		// Assertions
		mustHaveEncryptedEnvironmentVariables,
		mustHaveCodeSigning,
		mustHaveTracingEnabled,
		mustHaveDeadLetterQueue,
		mustNotUseVpcByDefault,
		mustHaveApresTags,
		mustHaveLogGroup(lambdaFunctionName),
		mustHaveEnvironmentVariables(map[string]string{
			"AWS_ACCOUNT_ID": account,
			"ENVIRONMENT":    s.environment,
			"APPLICATION":    "UnitTests",
			"COMPONENT":      "LambdaTest",
			"OTHER":          "true",
		}),
	)

	// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Test the function attributes.
	// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	s.assertInvokeFunction(lambdaFunctionArn)
}

func (s *LambdaTestSuite) TestLambdaWithVPCZipFile() {
	// Variables for the terraform module
	now := time.Now().Unix()
	functionNameInput := fmt.Sprintf("test-%d", now)
	// Terraform options
	terraformOptions := &terraform.Options{
		// The path to where your Terraform code is located
		TerraformDir: "./fixtures",

		// Variables to pass to our Terraform code using -var options
		Vars: map[string]interface{}{
			"name":        functionNameInput,
			"environment": s.environment,
			"enable_vpc":  true,
			"use_zip":     true,
		},
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(s.T(), terraformOptions)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(s.T(), terraformOptions)

	// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Get the outputs
	// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	lambdaFunctionName := terraform.Output(s.T(), terraformOptions, "lambda_function_name")
	lambdaFunctionArn := terraform.Output(s.T(), terraformOptions, "lambda_function_arn")
	account := terraform.Output(s.T(), terraformOptions, "aws_account_id")

	cfg, err := config.LoadDefaultConfig(s.ctx, config.WithRegion(s.awsRegion))
	s.Require().NoError(err)
	s.lambda = lambda.NewFromConfig(cfg)
	// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Verify the outputs.
	// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	s.assertOutputs(account, functionNameInput, lambdaFunctionName, lambdaFunctionArn, s.awsRegion)

	// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Get the function attributes.
	// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	s.assertFunction(
		lambdaFunctionArn,

		// Assertions
		mustHaveEncryptedEnvironmentVariables,
		mustHaveCodeSigning,
		mustHaveTracingEnabled,
		mustHaveDeadLetterQueue,
		mustUseVpc,
		mustHaveApresTags,
		mustHaveLogGroup(lambdaFunctionName),
		mustHaveEnvironmentVariables(map[string]string{
			"AWS_ACCOUNT_ID": account,
			"ENVIRONMENT":    s.environment,
			"APPLICATION":    "UnitTests",
			"COMPONENT":      "LambdaTest",
			"OTHER":          "true",
		}),
	)

	// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Test the function attributes.
	// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	s.assertInvokeFunction(lambdaFunctionArn)
}

// assertOutputs verifies that all output variables are set correctly.
func (s *LambdaTestSuite) assertOutputs(account string, functionNameInput string, functionName string, functionArn string, region string) {
	expectedFunctionName := fmt.Sprintf("%s-%s", s.environment, functionNameInput)
	s.Assert().Equal(expectedFunctionName, functionName, "expected bucket name to match")

	expectedTableArn := fmt.Sprintf("arn:aws:lambda:%s:%s:function:%s", region, account, expectedFunctionName)
	s.Assert().Equal(expectedTableArn, functionArn, "expected Table ARN to match")
}

func (s *LambdaTestSuite) assertFunction(functionArn string, assertions ...LambdaAssertion) {
	resp, err := s.lambda.GetFunction(s.ctx, &lambda.GetFunctionInput{
		FunctionName: aws.String(functionArn),
	})

	s.Require().NoError(err, "get function must pass")
	s.Require().NotNil(resp, "get function response must not be nil")

	for _, assertion := range assertions {
		assertion(s.T(), resp)
	}
}

func (s *LambdaTestSuite) assertInvokeFunction(functionArn string) {
	resp, err := s.lambda.Invoke(s.ctx, &lambda.InvokeInput{
		FunctionName: aws.String(functionArn),
		Payload:      []byte("[]"),
	})

	s.Require().NoError(err, "invoke function must pass")
	s.Require().NotNil(resp, "invoke function response must not be nil")

	s.Assert().Equal(int32(200), resp.StatusCode, "function should return 200 OK")
	s.Assert().Equal("{\"status\": 200, \"body\": \"success\"}", string(resp.Payload), "function should return 'success'")

}

type LambdaAssertion func(*testing.T, *lambda.GetFunctionOutput)

// mustHaveEncryptedEnvironmentVariables ensures that the Lambda function's environment variables are encrypted with a KMS key
func mustHaveEncryptedEnvironmentVariables(t *testing.T, output *lambda.GetFunctionOutput) {
	require.NotNil(t, output.Configuration)
	assert.NotEmpty(t, output.Configuration.KMSKeyArn, "must have a KMS key to encrypt environment variables")
}

func mustHaveX86Architecture(t *testing.T, output *lambda.GetFunctionOutput) {
	require.NotNil(t, output.Configuration)
	require.Len(t, output.Configuration.Architectures, 1)
	require.Equal(t, types.ArchitectureX8664, output.Configuration.Architectures[0], "Lambda@Edge only supports x86_64 architecture")
}

func mustNotHaveEnvironmentVariables(t *testing.T, output *lambda.GetFunctionOutput) {
	require.NotNil(t, output.Configuration)
	assert.Empty(t, output.Configuration.Environment, "Lambda@Edge must not have environment variables")
}

// mustHaveCodeSigning ensures that the Lambda function's has code signing enabled
func mustHaveCodeSigning(t *testing.T, output *lambda.GetFunctionOutput) {
	require.NotNil(t, output.Configuration)
	assert.NotEmpty(t, output.Configuration.SigningJobArn, "must have a code signing job")
	assert.NotEmpty(t, output.Configuration.SigningProfileVersionArn, "must have a code signing profile")
}

// mustHaveCodeSigning ensures that the Lambda function's has code signing enabled
func mustHaveTracingEnabled(t *testing.T, output *lambda.GetFunctionOutput) {
	require.NotNil(t, output.Configuration)
	require.NotNil(t, output.Configuration.TracingConfig)
	assert.Equal(t, types.TracingModePassThrough, output.Configuration.TracingConfig.Mode, "must have a code signing job")
}

// mustHaveDeadLetterQueue ensures that the Lambda function has a dead letter queue assigned to it
func mustHaveDeadLetterQueue(t *testing.T, output *lambda.GetFunctionOutput) {
	require.NotNil(t, output.Configuration)
	require.NotNil(t, output.Configuration.DeadLetterConfig)
	assert.NotEmpty(t, output.Configuration.DeadLetterConfig.TargetArn, "must have a code signing job")
}

func mustNotHaveDeadLetterQueue(t *testing.T, output *lambda.GetFunctionOutput) {
	require.NotNil(t, output.Configuration)
	require.Nil(t, output.Configuration.DeadLetterConfig)
}

// mustHaveLogGroup ensures that the Lambda function has a log group setup
func mustHaveLogGroup(functionName string) LambdaAssertion {
	return func(t *testing.T, output *lambda.GetFunctionOutput) {
		require.NotNil(t, output.Configuration)
		require.NotNil(t, output.Configuration.LoggingConfig)
		require.NotNil(t, output.Configuration.LoggingConfig.LogGroup)
		assert.Equal(t, fmt.Sprintf("/apres/lambda/%s", functionName), *output.Configuration.LoggingConfig.LogGroup)
	}
}

// mustHaveEnvironmentVariables ensures that the Lambda function has the environment variables set correctly
func mustHaveEnvironmentVariables(expected map[string]string) LambdaAssertion {
	return func(t *testing.T, output *lambda.GetFunctionOutput) {
		require.NotNil(t, output.Configuration)
		require.NotNil(t, output.Configuration.Environment)
		require.NotNil(t, output.Configuration.Environment.Variables)

		assert.Equal(t, expected, output.Configuration.Environment.Variables)
	}
}

// mustNotUseVpcByDefault ensures that the Lambda function is NOT connected to the VPC by default
func mustNotUseVpcByDefault(t *testing.T, output *lambda.GetFunctionOutput) {
	require.NotNil(t, output.Configuration)
	assert.Nil(t, output.Configuration.VpcConfig)
}

// mustUseVpc ensures that the Lambda function has a VPC connection
func mustUseVpc(t *testing.T, output *lambda.GetFunctionOutput) {
	require.NotNil(t, output.Configuration)
	assert.NotNil(t, output.Configuration.VpcConfig)
}

// mustTags ensures that the Lambda function has the apres tags
func mustHaveApresTags(t *testing.T, output *lambda.GetFunctionOutput) {
	require.NotNil(t, output.Configuration)

	// Tag structs are specific to the service, so convert to awstagging.TagItem
	tags := make([]awstagging.TagItem, 0)
	for key, value := range output.Tags {
		clonedKey := strings.Clone(key)
		clonedValue := strings.Clone(value)

		tags = append(tags, awstagging.TagItem{Key: &clonedKey, Value: &clonedValue})
	}
	valid, missing := awstagging.VerifyTagsExist(tags)
	assert.True(t, valid, "expected tags not found: %v", missing)

	valid, bad := awstagging.VerifyTagsValueFormat(tags)
	assert.True(t, valid, "Tags have invalid values: %v", bad)
}

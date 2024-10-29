package test

import (
	"context"
	"fmt"
	"testing"
	"time"

	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/sts"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/suite"
)

type ApresNamesTestSuite struct {
	suite.Suite
	ctx          context.Context
	awsRegion    string
	environment  string
	name         string
	awsAccountId string
	sts          *sts.Client
}

func TestApresNamesTestSuite(t *testing.T) {
	suite.Run(t, new(ApresNamesTestSuite))
}

func (s *ApresNamesTestSuite) SetupSuite() {
	s.ctx = context.Background()
	// Define the AWS region we want to test in
	s.awsRegion = "us-east-2"
	s.environment = "UnitTest"
	now := time.Now().Unix()
	s.name = fmt.Sprintf("unittest%d", now)

	cfg, err := config.LoadDefaultConfig(s.ctx, config.WithRegion(s.awsRegion))
	s.Require().NoError(err, "expected no error for LoadDefaultConfig creating AWS session")

	// Configure the AWS client for STS
	s.sts = sts.NewFromConfig(cfg)
}

func setTfOpts(name string, environment string, awsAccountId string, awsRegion string) *terraform.Options {
	return &terraform.Options{
		TerraformDir: "./fixtures",
		Vars: map[string]interface{}{
			"name":           name,
			"environment":    environment,
			"aws_account_id": awsAccountId,
			"aws_region":     awsRegion,
		},
	}
}

func (s *ApresNamesTestSuite) TestApresNamesDefault() {
	terraformOptions := setTfOpts(s.name, s.environment, "", "")

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(s.T(), terraformOptions)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(s.T(), terraformOptions)

	// outputs
	local_name := terraform.Output(s.T(), terraformOptions, "local_name")
	global_name := terraform.Output(s.T(), terraformOptions, "global_name")

	// Expected local name
	expected_name := fmt.Sprintf("%s-%s", s.environment, s.name)
	s.Equal(expected_name, local_name, "Expected local_name to be %s, but got %s", expected_name, local_name)

	identity, err := s.sts.GetCallerIdentity(s.ctx, &sts.GetCallerIdentityInput{})
	s.Require().NoError(err, "expected no error for GetCallerIdentity")
	account_id := identity.Account
	expected_global_name := fmt.Sprintf("%s-%s-%s-%s", *account_id, s.environment, s.awsRegion, s.name)
	s.Equal(expected_global_name, global_name, "Expected global_name to match %s, but got %s", expected_global_name, global_name)
}

func (s *ApresNamesTestSuite) TestApresNamesCustom() {
	fake_account := "123456789012"
	fake_region := "us-test-9"
	terraformOptions := setTfOpts(s.name, s.environment, fake_account, fake_region)

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(s.T(), terraformOptions)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(s.T(), terraformOptions)

	// outputs
	local_name := terraform.Output(s.T(), terraformOptions, "local_name")
	global_name := terraform.Output(s.T(), terraformOptions, "global_name")

	// Expected local name
	expected_name := fmt.Sprintf("%s-%s", s.environment, s.name)
	s.Equal(expected_name, local_name, "Expected local_name to be %s, but got %s", expected_name, local_name)

	expected_global_name := fmt.Sprintf("%s-%s-%s-%s", fake_account, s.environment, fake_region, s.name)
	s.Equal(expected_global_name, global_name, "Expected global_name to match %s, but got %s", expected_global_name, global_name)
}
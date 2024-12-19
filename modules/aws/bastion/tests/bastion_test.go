package test

import (
	"context"
	"fmt"
	"strings"
	"testing"
	"time"

	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/ec2"
	"github.com/aws/aws-sdk-go-v2/service/sts"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/suite"

	"apres.dev/awstagging"
)

type BastionTestSuite struct {
	suite.Suite
	ctx         context.Context
	awsRegion   string
	environment string
	name        string
	sts         *sts.Client
	ec2Client   *ec2.Client
}

func TestBastionTestSuite(t *testing.T) {
	suite.Run(t, new(BastionTestSuite))
}

func (s *BastionTestSuite) SetupSuite() {
	s.ctx = context.Background()
	// Define the AWS region we want to test in
	s.awsRegion = "us-east-2"
	s.environment = "Test"
	now := time.Now().Unix()
	s.name = fmt.Sprintf("unittest%d", now)

	cfg, err := config.LoadDefaultConfig(s.ctx, config.WithRegion(s.awsRegion))
	s.Require().NoError(err, "expected no error for LoadDefaultConfig creating AWS session")

	// Configure the AWS client for STS
	s.sts = sts.NewFromConfig(cfg)
	s.ec2Client = ec2.NewFromConfig(cfg)
}

func (s *BastionTestSuite) TestBastion() {
	terraformOptions := &terraform.Options{
		TerraformDir: "./fixtures",
		Vars: map[string]interface{}{
			"name":        s.name,
			"environment": s.environment,
		},
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(s.T(), terraformOptions)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(s.T(), terraformOptions)

	// outputs
	iamRoleArn := terraform.Output(s.T(), terraformOptions, "iam_role_arn")
	s.Require().NotEmpty(iamRoleArn)
	securityGroupId := terraform.Output(s.T(), terraformOptions, "security_group_id")
	s.Require().NotEmpty(securityGroupId)
	ids := terraform.Output(s.T(), terraformOptions, "instance_ids")
	// output is a string that can't be unmarshalled directly.
	ids = strings.TrimLeft(ids, "[")
	ids = strings.TrimRight(ids, "]")
	instanceIds := strings.Fields(ids)
	s.Require().NotEmpty(instanceIds)

	resp, err := s.ec2Client.DescribeInstances(s.ctx, &ec2.DescribeInstancesInput{
		InstanceIds: []string{instanceIds[0]},
	})
	s.Require().NoError(err, "Expected no error for DescribeInstances")

	// Should only be one reservation with one instance since we queried by instance ID
	// and we only created one.
	s.Require().NotEmpty(resp.Reservations)
	s.Require().NotEmpty(resp.Reservations[0].Instances)
	instance := resp.Reservations[0].Instances[0]
	s.Require().Equal(iamRoleArn, *instance.IamInstanceProfile.Arn)
	s.Require().Equal(securityGroupId, *instance.SecurityGroups[0].GroupId)

	// Do tags
	tags := make([]awstagging.TagItem, 0)
	for _, tag := range instance.Tags {
		tags = append(tags, awstagging.TagItem{Key: tag.Key, Value: tag.Value})
	}

	valid, missing := awstagging.VerifyTagsExist(tags)
	s.Require().True(valid, fmt.Sprintf("Expected tags not found: %v", missing))
	valid, bad := awstagging.VerifyTagsValueFormat(tags)
	s.Require().True(valid, fmt.Sprintf("Tags have invalid values: %v", bad))

}

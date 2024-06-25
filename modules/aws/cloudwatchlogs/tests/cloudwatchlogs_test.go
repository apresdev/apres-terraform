package test

import (
	"context"
	"fmt"
	"strings"
	"testing"
	"time"

	"apres.dev/awstagging"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/cloudwatchlogs"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestCloudWatchLogs(t *testing.T) {
	// Define the AWS region we want to test in
	awsRegion := "us-east-2"

	// Variables for the terraform module
	now := time.Now().Unix()
	cwlName := fmt.Sprintf("unit-test-log-group-%d", now)
	cwlPath := fmt.Sprintf("/%s/%d", cwlName, now)
	var retentionInDays int32 = 3
	// Terraform options
	terraformOptions := &terraform.Options{
		// The path to where your Terraform code is located
		TerraformDir: "./fixtures",

		// Variables to pass to our Terraform code using -var options
		Vars: map[string]interface{}{
			"name":              cwlName,
			"path":			  cwlPath,
			"retention_in_days": retentionInDays,
		},
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(t, terraformOptions)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(t, terraformOptions)

	// Get the outputs
	cwlArn := terraform.Output(t, terraformOptions, "cwl_arn")
	// The ARN we get back from the describe includes a ":*" at the end
	expectedCwlArn := fmt.Sprintf("%s:*", cwlArn)

	assert.True(t, len(cwlArn) > 1, "Expected a non-empty ARN")

	// Terratest has a handy way to create clients, but it's SDK v1, and doesn't place nice with SSO,
	// so we'll use the v2 SDK directly.
	cfg, err := config.LoadDefaultConfig(context.TODO(), config.WithRegion(awsRegion))
	assert.Nil(t, err, "Expected no error for LoadDefaultConfig creating AWS session")

	svc := cloudwatchlogs.NewFromConfig(cfg)
	resp, err := svc.DescribeLogGroups(context.TODO(), &cloudwatchlogs.DescribeLogGroupsInput{LogGroupNamePrefix: &cwlPath})
	assert.NoError(t, err, "Expected no error for DescribeLogGroups")
	found := false
	for _, logGroup := range resp.LogGroups {
		if *logGroup.LogGroupName == cwlPath {
			found = true
			t.Logf("Found log group: %s with ARN %s", *logGroup.LogGroupName, *logGroup.Arn)
			assert.Equal(t, *logGroup.Arn, expectedCwlArn, "Expected ARN to match: %s != %s", *logGroup.Arn, expectedCwlArn)
			assert.Equal(t, *logGroup.RetentionInDays, retentionInDays, "Expected retention to match")
			assert.NotEmpty(t, *logGroup.KmsKeyId, "Expected KMS key ID to be set")
		}
	}
	assert.True(t, found, "Did not find the CloudWatch log group in the list of log groups")

	// Use the ARN without the ":*" appended
	tagsResp, err := svc.ListTagsForResource(context.TODO(), &cloudwatchlogs.ListTagsForResourceInput{ResourceArn: &cwlArn})
	assert.NoError(t, err, "Expected no error for ListTagsForResource")

	tags := make([]awstagging.TagItem, 0)
	for k, v := range tagsResp.Tags {
		// Need to clone the strings or we end up with a map of points to the same thing
		key := strings.Clone(k)
		val := strings.Clone(v)
		tags = append(tags, awstagging.TagItem{Key: &key, Value: &val})
	}

	valid, missing := awstagging.VerifyTagsExist(tags)
	assert.True(t, valid, fmt.Sprintf("Expected tags not found: %v", missing))

	valid, bad := awstagging.VerifyTagsValueFormat(tags)
	assert.True(t, valid, fmt.Sprintf("Tags have invalid values: %v", bad))

}

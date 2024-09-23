package test

import (
	"context"
	"fmt"
	"testing"
	"time"

	"apres.dev/awstagging"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/wafv2"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

type AttributeAssertion func(*testing.T, map[string]string)

func TestWaf(t *testing.T) {
	// Define the AWS region we want to test in
	awsRegion := "us-east-2"
	environment := "UnitTest"

	// Variables for the terraform module
	now := time.Now().Unix()
	wafName := fmt.Sprintf("testwaf%d", now)
	// Terraform options
	terraformOptions := &terraform.Options{
		// The path to where your Terraform code is located
		TerraformDir: "./fixtures",

		// Variables to pass to our Terraform code using -var options
		Vars: map[string]interface{}{
			"name":           wafName,
			"environment":    environment,
		},
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(t, terraformOptions)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(t, terraformOptions)

	// Get the outputs
	wafArn := terraform.Output(t, terraformOptions, "waf_arn")

	// Terratest has a handy way to create clients, but it's SDK v1, and doesn't place nice with SSO,
	// so we'll use the v2 SDK directly.
	cfg, err := config.LoadDefaultConfig(context.TODO(), config.WithRegion(awsRegion))
	assert.NoError(t, err, "Expected no error for LoadDefaultConfig creating AWS session")

	svc := wafv2.NewFromConfig(cfg)

	// Check Tags
	tagsResp, err := svc.ListTagsForResource(context.TODO(), &wafv2.ListTagsForResourceInput{
		ResourceARN: &wafArn,
	})
	assert.NoError(t, err, "Expected no error on GetBucketTagging")

	// Tag structs are specific to the service, so convert to awstagging.TagItem
	tags := make([]awstagging.TagItem, 0)
	for _, tag := range tagsResp.TagInfoForResource.TagList {
		tags = append(tags, awstagging.TagItem{Key: tag.Key, Value: tag.Value})
	}
	valid, missing := awstagging.VerifyTagsExist(tags)
	assert.True(t, valid, fmt.Sprintf("Expected tags not found: %v", missing))

	valid, bad := awstagging.VerifyTagsValueFormat(tags)
	assert.True(t, valid, fmt.Sprintf("Tags have invalid values: %v", bad))
}
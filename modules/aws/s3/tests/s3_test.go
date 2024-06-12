package test

import (
	"context"
	"fmt"
	"strings"
	"testing"
	"time"

	"apres.dev/awstagging"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/aws/aws-sdk-go-v2/service/s3/types"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TODO: This should be pulled into a separate module

func TestS3(t *testing.T) {
	// Define the AWS region we want to test in
	awsRegion := "us-east-2"
	environment := "UnitTest"

	// Variables for the terraform module
	now := time.Now().Unix()
	bucketNameInput := fmt.Sprintf("testbucket%d", now)
	// Terraform options
	terraformOptions := &terraform.Options{
		// The path to where your Terraform code is located
		TerraformDir: "./fixtures",

		// Variables to pass to our Terraform code using -var options
		Vars: map[string]interface{}{
			"name":           bucketNameInput,
			"environment":    environment,
		},
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(t, terraformOptions)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(t, terraformOptions)

	// Get the outputs
	bucketArn := terraform.Output(t, terraformOptions, "bucket_arn")
	bucketName := terraform.Output(t, terraformOptions, "bucket_name")
	bucketDomainName := terraform.Output(t, terraformOptions, "bucket_domain_name")
	bucketAccount := terraform.Output(t, terraformOptions, "aws_account_id")
	bucketRegion := terraform.Output(t, terraformOptions, "aws_region")

	// regions should match or things are weird
	assert.Equal(t, bucketRegion, awsRegion, "Expected regions to match")

	// Check expected bucket name pattern
	expectedBucketName := fmt.Sprintf("%s-%s-%s-%s", bucketAccount, strings.ToLower(environment), awsRegion, strings.ToLower(bucketNameInput))
	assert.Equal(t, bucketName, expectedBucketName, "Expected bucket name to match")

	// Check the ARN. No reason to think this should change, but it's a good sanity check
	expectedArn := fmt.Sprintf("arn:aws:s3:::%s", expectedBucketName)
	assert.Equal(t, bucketArn, expectedArn, "Expected ARN to match")

	// Check the domain
	expectedDomainName := fmt.Sprintf("%s.s3.amazonaws.com", expectedBucketName)
	assert.Equal(t, bucketDomainName, expectedDomainName, "Expected domain name to match")

	// TODO: go to S3 and check versioning, public, etc.
	// Terratest has a handy way to create clients, but it's SDK v1, and doesn't place nice with SSO,
	// so we'll use the v2 SDK directly.
	cfg, err := config.LoadDefaultConfig(context.TODO(), config.WithRegion(awsRegion))
	assert.True(t, err == nil, "Expected no error for LoadDefaultConfig creating AWS session")

	svc := s3.NewFromConfig(cfg)

	// Check versioning
	versionResp, err := svc.GetBucketVersioning(context.TODO(), &s3.GetBucketVersioningInput{Bucket: &expectedBucketName})
	assert.Nil(t, err)
	assert.Equal(t, versionResp.Status, types.BucketVersioningStatusEnabled, "Expected versioning to be enabled")
	assert.Equal(t, versionResp.MFADelete, types.MFADeleteStatusDisabled, "Expected MFA delete to be disabled for testing")

	// Public access
	publicResp, err := svc.GetPublicAccessBlock(context.TODO(), &s3.GetPublicAccessBlockInput{Bucket: &expectedBucketName})
	assert.Nil(t, err)
	assert.True(t, *publicResp.PublicAccessBlockConfiguration.BlockPublicAcls, "Expected public ACLs to be blocked")

	// Encryption
	encResp, err := svc.GetBucketEncryption(context.TODO(), &s3.GetBucketEncryptionInput{Bucket: &expectedBucketName})
	assert.Nil(t, err)
	assert.True(t, len(encResp.ServerSideEncryptionConfiguration.Rules) > 0, "Expected server-side encryption to be enabled")
	assert.True(t, encResp.ServerSideEncryptionConfiguration.Rules[0].ApplyServerSideEncryptionByDefault.SSEAlgorithm == types.ServerSideEncryptionAwsKms, "Expected AWS KMS encryption")

	// Check Tags
	tagsResp, err := svc.GetBucketTagging(context.TODO(), &s3.GetBucketTaggingInput{Bucket: &expectedBucketName})
	assert.Nil(t, err)

	// Tag structs are specific to the service, so convert to awstagging.TagItem
	tags := make([]awstagging.TagItem, 0)
	for _, tag := range tagsResp.TagSet {
		tags = append(tags, awstagging.TagItem{Key: tag.Key, Value: tag.Value})
	}
	valid, missing := awstagging.VerifyTagsExist(tags)
	assert.True(t, valid, fmt.Sprintf("Expected tags not found: %v", missing))

	valid, bad := awstagging.VerifyTagsValueFormat(tags)
	assert.True(t, valid, fmt.Sprintf("Tags have invalid values: %v", bad))

}

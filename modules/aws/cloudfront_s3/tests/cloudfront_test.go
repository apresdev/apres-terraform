package test

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"testing"
	"time"

	"apres.dev/awstagging"
	"apres.dev/s3utils"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/cloudfront"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestCloudFrontS3(t *testing.T) {
	// Define the AWS region we want to test in
	awsRegion := "us-east-2"
	environment := "UnitTest"
	application := "TestApp"
	component := "TestComponent"

	// Variables for the terraform module
	now := time.Now().Unix()
	nameInput := fmt.Sprintf("cftest%d", now)
	// Terraform options
	terraformOptions := &terraform.Options{
		// The path to where your Terraform code is located
		TerraformDir: "./fixtures",

		// Variables to pass to our Terraform code using -var options
		Vars: map[string]interface{}{
			"name":        nameInput,
			"environment": environment,
			"application": application,
			"component":   component,
		},
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(t, terraformOptions)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(t, terraformOptions)

	// Get the outputs
	cloudfrontDistId := terraform.Output(t, terraformOptions, "cloudfront_distribution_id")
	cloudfrontDistDomainName := terraform.Output(t, terraformOptions, "cloudfront_distribution_domain_name")
	cloudfrontDistArn := terraform.Output(t, terraformOptions, "cloudfront_distribution_arn")
	s3BucketName := terraform.Output(t, terraformOptions, "s3_bucket_name")

	// Terratest has a handy way to create clients, but it's SDK v1, and doesn't place nice with SSO,
	// so we'll use the v2 SDK directly.
	cfg, err := config.LoadDefaultConfig(context.Background(), config.WithRegion(awsRegion))
	assert.NoError(t, err, "Expected no error for LoadDefaultConfig creating AWS session")

	// create cloudfront client
	cfSvc := cloudfront.NewFromConfig(cfg)

	distResp, err := cfSvc.GetDistribution(context.Background(), &cloudfront.GetDistributionInput{Id: &cloudfrontDistId})
	assert.NoError(t, err, "Expected no error on GetDistribution")

	assert.Equal(t, *distResp.Distribution.DomainName, cloudfrontDistDomainName, "Expected domain name to match")

	tagsResp, err := cfSvc.ListTagsForResource(context.Background(), &cloudfront.ListTagsForResourceInput{Resource: &cloudfrontDistArn})
	assert.NoError(t, err, "Expected no error on ListTagsForResource")

	tags := make([]awstagging.TagItem, 0)
	// Tag structs are specific to the service, so convert to awstagging.TagItem
	for _, tag := range tagsResp.Tags.Items {
		tags = append(tags, awstagging.TagItem{Key: tag.Key, Value: tag.Value})
	}

	valid, missing := awstagging.VerifyTagsExist(tags)
	assert.True(t, valid, fmt.Sprintf("Expected tags not found: %v", missing))

	valid, bad := awstagging.VerifyTagsValueFormat(tags)
	assert.True(t, valid, fmt.Sprintf("Tags have invalid values: %v", bad))

	// upload file to the s3 bucket
	fileName := "index.html"
	s3svc := s3.NewFromConfig(cfg)
	file, err := os.Open(fileName)
	assert.NoError(t, err, "Expected no error opening file index.html")
	_, err = s3svc.PutObject(context.Background(), &s3.PutObjectInput{
		Bucket: &s3BucketName,
		Key: &fileName,
		Body: file,
	})
	assert.NoError(t, err, "Expected no error uploading file to S3")

	// check the URL to make sure we can get it
	url := fmt.Sprintf("https://%s/%s", cloudfrontDistDomainName, fileName)
	resp, err := http.Get(url)
	assert.NoErrorf(t, err, "Expected no error getting URL: %s", url)
	assert.Equal(t, http.StatusOK, resp.StatusCode, "Expected 200 OK response from CloudFront")

	// check that a missing file is redirected to the default path
	missingUrl := fmt.Sprintf("https://%s/missing", cloudfrontDistDomainName)
	resp, err = http.Get(missingUrl)
	assert.NoErrorf(t, err, "Expected no error getting URL: %s", missingUrl)
	// todo assert.Equal(t, http.StatusOK, resp.StatusCode, "Expected 200 OK response from CloudFront for missing path")

	// empty the buckets.
	err = s3utils.S3EmptyBucket(s3svc, s3BucketName)
	assert.NoError(t, err, "Expected no error emptying S3 bucket")
}

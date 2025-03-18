package test

import (
	"context"
	"fmt"
	"math/rand"
	"strings"
	"testing"
	"time"
	"apres.dev/awstagging"

	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/aws/aws-sdk-go-v2/service/s3/types"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/suite"
)

type S3TestSuite struct {
	suite.Suite
	ctx         context.Context
	s3          *s3.Client
	awsRegion   string
	environment string
}
type Outputs struct {
	bucketArn             string
	bucketName            string
	bucketDomainName      string
	accountId             string
	region                string
	destinationBucketName string
	destinationBucketArn  string
}

func TestS3TestSuite(t *testing.T) {
	suite.Run(t, new(S3TestSuite))
}

func (s *S3TestSuite) SetupSuite() {
	s.ctx = context.Background()
	s.awsRegion = "us-east-2"
	s.environment = "UnitTest"
	cfg, err := config.LoadDefaultConfig(s.ctx, config.WithRegion(s.awsRegion))
	s.Require().NoError(err, "expected no error for LoadDefaultConfig creating AWS session")

	// Configure the AWS clients
	s.s3 = s3.NewFromConfig(cfg)
}

func (s *S3TestSuite) getTfOpts(name string, environment string, replication bool) *terraform.Options {
	// Terraform options
	terraformOptions := &terraform.Options{
		// The path to where your Terraform code is located
		TerraformDir: "./fixtures",

		// Variables to pass to our Terraform code using -var options
		Vars: map[string]interface{}{
			"name":             name,
			"environment":      environment,
			"test_replication": replication,
		},
	}
	return terraformOptions
}

func (s *S3TestSuite) getOutputs(terraformOptions *terraform.Options) Outputs {
	bucketArn := terraform.Output(s.T(), terraformOptions, "bucket_arn")
	bucketName := terraform.Output(s.T(), terraformOptions, "bucket_name")
	bucketDomainName := terraform.Output(s.T(), terraformOptions, "bucket_domain_name")
	bucketAccount := terraform.Output(s.T(), terraformOptions, "aws_account_id")
	bucketRegion := terraform.Output(s.T(), terraformOptions, "aws_region")
	destinationBucketName := terraform.Output(s.T(), terraformOptions, "destination_bucket_name")
	destinationBucketArn := terraform.Output(s.T(), terraformOptions, "destination_bucket_arn")
	return Outputs{
		bucketArn:             bucketArn,
		bucketName:            bucketName,
		bucketDomainName:      bucketDomainName,
		accountId:             bucketAccount,
		region:                bucketRegion,
		destinationBucketName: destinationBucketName,
		destinationBucketArn:  destinationBucketArn,
	}
}

func (s *S3TestSuite) verifyVersioning(bucketName string) {
	versionResp, err := s.s3.GetBucketVersioning(s.ctx, &s3.GetBucketVersioningInput{Bucket: &bucketName})
	s.Require().NoError(err, "Expected no error for GetBucketVersioning")
	s.Assert().Equal(versionResp.Status, types.BucketVersioningStatusEnabled, "Expected versioning to be enabled on bucket %s", bucketName)
	s.Assert().Equal(versionResp.MFADelete, types.MFADeleteStatusDisabled, "Expected MFA delete to be disabled for testing on bucket %s", bucketName)
}

func (s *S3TestSuite) verifyPublicAccess(bucketName string) {
	publicResp, err := s.s3.GetPublicAccessBlock(s.ctx, &s3.GetPublicAccessBlockInput{Bucket: &bucketName})
	s.Require().NoError(err, "Expected no error on GetPublicAccessBlock")
	s.Assert().True(*publicResp.PublicAccessBlockConfiguration.BlockPublicAcls, "Expected public ACLs to be blocked")
}

func (s *S3TestSuite) TestS3Simple() {
	// Define the AWS region we want to test in
	awsRegion := "us-east-2"
	environment := "UnitTest"

	// Terraform options
	bucketNameInput := fmt.Sprintf("test%d", rand.Intn(1000))
	terraformOptions := s.getTfOpts(bucketNameInput, environment, false)

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(s.T(), terraformOptions)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(s.T(), terraformOptions)

	// Get the outputs
	outputs := s.getOutputs(terraformOptions)

	// regions should match or things are weird
	s.Assert().Equal(outputs.region, awsRegion, "Expected regions to match")

	// Check expected bucket name pattern
	expectedBucketName := fmt.Sprintf("%s-%s-%s-%s", outputs.accountId, strings.ToLower(environment), awsRegion, strings.ToLower(bucketNameInput))
	s.Assert().Equal(outputs.bucketName, expectedBucketName, "Expected bucket name to match")

	// Check the ARN. No reason to think this should change, but it's a good sanity check
	expectedArn := fmt.Sprintf("arn:aws:s3:::%s", expectedBucketName)
	s.Assert().Equal(outputs.bucketArn, expectedArn, "Expected ARN to match")

	// Check the domain
	expectedDomainName := fmt.Sprintf("%s.s3.amazonaws.com", expectedBucketName)
	s.Assert().Equal(outputs.bucketDomainName, expectedDomainName, "Expected domain name to match")

	cfg, err := config.LoadDefaultConfig(context.TODO(), config.WithRegion(awsRegion))
	s.Require().NoError(err, "Expected no error for LoadDefaultConfig creating AWS session")
	svc := s3.NewFromConfig(cfg)

	// Check versioning
	s.verifyVersioning(expectedBucketName)

	// Public access
	s.verifyPublicAccess(expectedBucketName)

	// Encryption
	encResp, err := svc.GetBucketEncryption(context.TODO(), &s3.GetBucketEncryptionInput{Bucket: &expectedBucketName})
	s.Require().NoError(err, "Expected no error on GetBucketEncryption")
	s.Assert().True(len(encResp.ServerSideEncryptionConfiguration.Rules) > 0, "Expected server-side encryption to be enabled")
	s.Assert().True(encResp.ServerSideEncryptionConfiguration.Rules[0].ApplyServerSideEncryptionByDefault.SSEAlgorithm == types.ServerSideEncryptionAwsKms, "Expected AWS KMS encryption")

	// Check Tags
	tagsResp, err := svc.GetBucketTagging(context.TODO(), &s3.GetBucketTaggingInput{Bucket: &expectedBucketName})
	s.Require().NoError(err, "Expected no error on GetBucketTagging")

	// Tag structs are specific to the service, so convert to awstagging.TagItem
	tags := make([]awstagging.TagItem, 0)
	for _, tag := range tagsResp.TagSet {
		tags = append(tags, awstagging.TagItem{Key: tag.Key, Value: tag.Value})
	}
	valid, missing := awstagging.VerifyTagsExist(tags)
	s.Assert().True(valid, fmt.Sprintf("Expected tags not found: %v", missing))

	valid, bad := awstagging.VerifyTagsValueFormat(tags)
	s.Assert().True(valid, fmt.Sprintf("Tags have invalid values: %v", bad))

	// Check Lifecycle Rule
	lfcResp, err := svc.GetBucketLifecycleConfiguration(context.TODO(), &s3.GetBucketLifecycleConfigurationInput{Bucket: &expectedBucketName})
	s.Require().NoError(err, "Expected no error on GetBucketLifecycleConfiguration")
	s.Assert().Len(lfcResp.Rules, 1, "Expected one lifecycle rule")
	rule := lfcResp.Rules[0]
	s.Assert().Equal(rule.Status, types.ExpirationStatusEnabled, "Expected lifecycle rule to be enabled")
	s.Assert().Nil(rule.Filter, "Expected nil filter on lifecycle rule")
	s.Assert().Equal(int32(7), *rule.AbortIncompleteMultipartUpload.DaysAfterInitiation, "Expected 7 days for incomplete multipart upload")
	s.Assert().Nil(rule.Expiration.Date, "Expected no expiration date")
	s.Assert().Nil(rule.NoncurrentVersionTransitions, "Expected no noncurrent version transitions")
	s.Assert().Len(rule.Transitions, 1, "Expected one transition")
	s.Assert().Equal(int32(1), *rule.Transitions[0].Days, "Expected 1 day for transition")
	s.Assert().Equal(types.TransitionStorageClassIntelligentTiering, rule.Transitions[0].StorageClass, "Expected Intelligent Tiering for transition")

	// Check Lifecycle Rule
	corsResp, err := svc.GetBucketCors(context.TODO(), &s3.GetBucketCorsInput{Bucket: &expectedBucketName})
	s.Assert().NoError(err, "Expected no error on GetBucketLifecycleConfiguration")

	// Check CORS Rules
	s.Assert().Len(corsResp.CORSRules, 1, "Expected one CORS rule")
	corsRule := corsResp.CORSRules[0]
	s.Assert().Equal(corsRule.AllowedHeaders, []string{"*"}, "Expected AllowedHeaders ['*'] by default")
	s.Assert().Equal(corsRule.AllowedMethods, []string{"PUT"}, "Expected AllowedMethods ['PUT']")
	s.Assert().Equal(corsRule.AllowedOrigins, []string{"localhost"}, "Expected AllowedOrigins ['localhost']")
	s.Assert().Empty(corsRule.ExposeHeaders, "Expected ExposeHeaders [] by default")
}

func (s *S3TestSuite) TestS3replication() {
	// Define the AWS region we want to test in
	awsRegion := "us-east-2"
	environment := "UnitTest"

	// Variables for the terraform module. Use a random number to avoid collisions
	bucketNameInput := fmt.Sprintf("rep%d", rand.Intn(1000))
	terraformOptions := s.getTfOpts(bucketNameInput, environment, true)

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(s.T(), terraformOptions)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(s.T(), terraformOptions)

	// Get the outputs
	outputs := s.getOutputs(terraformOptions)

	cfg, err := config.LoadDefaultConfig(context.TODO(), config.WithRegion(awsRegion))
	s.Require().NoError(err, "Expected no error for LoadDefaultConfig creating AWS session")
	svc := s3.NewFromConfig(cfg)

	// Check versioning
	s.verifyVersioning(outputs.bucketName)
	s.verifyVersioning(outputs.destinationBucketName)

	// Public access
	s.verifyPublicAccess(outputs.bucketName)
	s.verifyPublicAccess(outputs.destinationBucketName)

	// verify replication config
	repResp, err := svc.GetBucketReplication(context.TODO(), &s3.GetBucketReplicationInput{Bucket: &outputs.bucketName})
	s.Require().NoError(err, "Expected no error on GetBucketReplication")
	s.Assert().Len(repResp.ReplicationConfiguration.Rules, 1, "Expected one replication rule")
	rule := repResp.ReplicationConfiguration.Rules[0]
	s.Assert().Equal(rule.Status, types.ReplicationRuleStatusEnabled, "Expected replication rule to be enabled")
	s.Assert().Equal(*rule.Destination.Bucket, outputs.destinationBucketArn, "Expected destination bucket to match")

	// defer empty both buckets, if there's an error later we'll empty first and then
	// tear down the stack in the deferred terraform destroy.
	defer s.emptyBucket(outputs.destinationBucketName)
	defer s.emptyBucket(outputs.bucketName)

	key := "testfile"
	s.uploadFile(outputs.bucketName, key)

	// The only way to get replication status is from GetObject, wait up to 15 minutes. typically it's within 1 minute
	replicated := false
	for i := 0; i < 60; i++ {
		time.Sleep(15 * time.Second)
		object, err := svc.GetObject(context.TODO(), &s3.GetObjectInput{Bucket: &outputs.bucketName, Key: &key})
		s.Require().NoError(err, "Expected no error on GetObject bucket %s key %s", outputs.bucketName, key)
		if object.ReplicationStatus == types.ReplicationStatusComplete || object.ReplicationStatus == types.ReplicationStatusCompleted {
			replicated = true
			break
		} else if object.ReplicationStatus == types.ReplicationStatusFailed {
			s.Fail("Replication failed for bucket %s key %s", outputs.bucketName, key)
			break
		} else if object.ReplicationStatus == types.ReplicationStatusPending {
			continue
		} else if object.ReplicationStatus == types.ReplicationStatusReplica {
			s.Fail("Replication status is replica, should never happend!")
			break
		}
	}
	s.Assert().True(replicated, "Expected replication to complete for bucket %s key %s", outputs.bucketName, key)

}

func (s *S3TestSuite) uploadFile(bucketName string, key string) {
	// Upload a file
	_, err := s.s3.PutObject(context.TODO(), &s3.PutObjectInput{
		Bucket: &bucketName,
		Key:    &key,
		Body:   strings.NewReader("Hello, World!"),
	})
	s.Require().NoError(err, "Expected no error on PutObject")
}

func (s *S3TestSuite) emptyBucket(bucketName string) {
	// List and delete versions. If we just delete objects without versions the delete markers get
	// replicated and causes all sorts of fun. no need for pagination because there
	// was only one object.
	listVerResp, err := s.s3.ListObjectVersions(s.ctx, &s3.ListObjectVersionsInput{Bucket: &bucketName})
	s.Require().NoError(err, "Expected no error on ListObjectVersions")
	for _, obj := range listVerResp.Versions {
		_, err := s.s3.DeleteObject(s.ctx, &s3.DeleteObjectInput{Bucket: &bucketName, Key: obj.Key, VersionId: obj.VersionId})
		s.Require().NoError(err, "Expected no error on DeleteObject")
	}
}

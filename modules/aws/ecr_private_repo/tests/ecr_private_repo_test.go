package test

import (
	"context"
	"fmt"
	"testing"
	"time"

	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/ecr"

	//"github.com/aws/aws-sdk-go/service/ecr"
	//"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestEcrPrivateRepo(t *testing.T) {
	// Define the AWS region we want to test in
	awsRegion := "us-east-2"

	// Variables for the terraform module
	name := fmt.Sprintf("test-repo-%d", time.Now().Unix())
	envName := "testing"
	awsOrg := "o-a1b2c3d4e5/r-de78/*"
	awsOrgList := []string{awsOrg}
	claimFilter := "repo:apresdev/testing:ref:refs/heads/main"

	// Terraform options
	terraformOptions := &terraform.Options{
		// The path to where your Terraform code is located
		TerraformDir: "./fixtures",

		// Variables to pass to our Terraform code using -var options
		Vars: map[string]interface{}{
			"name":                             name,
			"environment":                      envName,
			"shared_aws_org_for_pull":          awsOrgList,
			"github_repo_subject_claim_filter": claimFilter,
		},
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(t, terraformOptions)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(t, terraformOptions)

	// Get the outputs
	repoArn := terraform.Output(t, terraformOptions, "repository_arn")
	assert.True(t, len(repoArn) > 1, "Expected a non-empty Repo ARN")

	repoUrl := terraform.Output(t, terraformOptions, "repository_url")
	assert.True(t, len(repoUrl) > 1, "Expected a non-empty Repo URL")

	githubRoleArn := terraform.Output(t, terraformOptions, "github_iam_role_arn")
	assert.True(t, len(githubRoleArn) > 1, "Expected a non-empty Role ARN")

	githubRoleName := terraform.Output(t, terraformOptions, "github_iam_role_name")
	assert.True(t, len(githubRoleName) > 1, "Expected a non-empty Role Name")


	// Terratest has a handy way to create clients, but it's SDK v1, and doesn't place nice with SSO,
	// so we'll use the v2 SDK directly.
	cfg, err := config.LoadDefaultConfig(context.TODO(), config.WithRegion(awsRegion))
	assert.True(t, err == nil, "Expected no error for LoadDefaultConfig creating AWS session")

	svc := ecr.NewFromConfig(cfg)
	input := &ecr.DescribeRepositoriesInput{
		RepositoryNames: []string{name},
	}
	resp, err := svc.DescribeRepositories(context.TODO(), input)
	assert.True(t, err == nil, "Expected no error for DesribeRepositories")
	found := false
	for _, repo := range resp.Repositories {
		if *repo.RepositoryName == name {
			found = true
			t.Logf("Found repo: %s", *repo.RepositoryName)
			assert.True(t, *repo.RepositoryArn == repoArn, "Expected ARN to match")
			assert.True(t, *repo.RepositoryUri == repoUrl, "Expected URI to match")
			t.Logf("ImageScanImmutability: %v", repo.ImageTagMutability)
			assert.True(t, repo.ImageTagMutability == "IMMUTABLE", "Expected ImageTagMutability to be IMMUTABLE")
		}
	}
	assert.True(t, found, "Did not find the ECR repo in the list of repos")
}

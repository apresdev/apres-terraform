package test

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
	"testing"
	"time"

	"apres.dev/awstagging"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/apigateway"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

type AttributeAssertion func(*testing.T, map[string]string)

type helloworld struct {
	Id      int
	Message string
}

func TestAPIGw(t *testing.T) {
	// Define the AWS region we want to test in
	awsRegion := "us-east-2"
	environment := "UnitTest"

	// Variables for the terraform module
	now := time.Now().Unix()
	gwName := fmt.Sprintf("testgw%d", now)
	expectedMessage := fmt.Sprintf("Hello World %d!", now)
	// Terraform options
	terraformOptions := &terraform.Options{
		// The path to where your Terraform code is located
		TerraformDir: "./fixtures",

		// Variables to pass to our Terraform code using -var options
		Vars: map[string]interface{}{
			"name":        gwName,
			"description": gwName, //use the same thing for description
			"environment": environment,
			"timestamp":   now,
		},
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(t, terraformOptions)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(t, terraformOptions)

	// Get the outputs
	apigwArn := terraform.Output(t, terraformOptions, "arn")
	//apigwId := terraform.Output(t, terraformOptions, "id")
	apigwInvokeUrl := terraform.Output(t, terraformOptions, "invoke_url")

	// Terratest has a handy way to create clients, but it's SDK v1, and doesn't place nice with SSO,
	// so we'll use the v2 SDK directly.
	cfg, err := config.LoadDefaultConfig(context.TODO(), config.WithRegion(awsRegion))
	assert.NoError(t, err, "Expected no error for LoadDefaultConfig creating AWS session")

	svc := apigateway.NewFromConfig(cfg)

	// Check Tags
	tagsResp, err := svc.GetTags(context.TODO(), &apigateway.GetTagsInput{
		ResourceArn: &apigwArn,
	})
	assert.NoError(t, err, "Expected no error on GetBucketTagging")

	// Tag structs are specific to the service, so convert to awstagging.TagItem
	tags := make([]awstagging.TagItem, 0)
	for key, value := range tagsResp.Tags {
		clonedKey := strings.Clone(key)
		clonedValue := strings.Clone(value)

		tags = append(tags, awstagging.TagItem{Key: &clonedKey, Value: &clonedValue})
	}
	valid, missing := awstagging.VerifyTagsExist(tags)
	assert.True(t, valid, fmt.Sprintf("Expected tags not found: %v", missing))

	valid, bad := awstagging.VerifyTagsValueFormat(tags)
	assert.True(t, valid, fmt.Sprintf("Tags have invalid values: %v", bad))

	// Test the API Gateway, it's mocked and gives back a hardcoded response
	url := fmt.Sprintf("%s/helloworld/", apigwInvokeUrl)
	resp, err := http.Get(url)
	assert.NoError(t, err, "Expected no error on Get request to %s", url)
	assert.Equal(t, 200, resp.StatusCode, "Expected status code 200 on Get request to %s", url)
	defer resp.Body.Close()
	var hw helloworld
	decoder := json.NewDecoder(resp.Body)
	decoderErr := decoder.Decode(&hw)
	assert.NoError(t, decoderErr, "Expected no error on decoding response body")
	fmt.Printf("id: %d message: %s\n", hw.Id, hw.Message)
	assert.Equal(t, 123, hw.Id, "Expected id to be 123")
	assert.Equal(t, expectedMessage, hw.Message, "Expected message to be 'Hello, World!'")
}

package test

import (
	"context"
	"fmt"
	"testing"
	"time"

	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/ecs"
	ecstypes "github.com/aws/aws-sdk-go-v2/service/ecs/types"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"

	"apres.dev/awstagging"
)

const awsRegion = "us-east-2"
const environmentName = "Test"

func getName() string {
	return fmt.Sprintf("test%d", time.Now().Unix())
}

// Get Terraform Options for all tests
func getTfOpts(name string, makeVolume bool, createSecret bool) *terraform.Options {
	return &terraform.Options{
		// The path to where your Terraform code is located
		TerraformDir: "./fixtures",

		// Variables to pass to our Terraform code using -var options
		Vars: map[string]interface{}{
			"name":          name,
			"environment":   environmentName,
			"make_volume":   makeVolume,
			"create_secret": createSecret,
		},
	}
}

type tfOutputs struct {
	ecsTaskDefinitionArn string
	ecsClusterArn        string
	ecsClusterName       string
	privateSubnetIds     []string
	securityGroupId      string
}

// Get and verify Terraform Outputs for all tests.
func getAndVerifyOutputs(t *testing.T, terraformOptions *terraform.Options) *tfOutputs {
	// Get outputs
	ecsTaskDefinitionArn := terraform.Output(t, terraformOptions, "ecs_task_definition_arn")
	assert.NotEmpty(t, ecsTaskDefinitionArn, "Expected a non-empty ECS Task Definition ARN")

	ecsClusterArn := terraform.Output(t, terraformOptions, "ecs_cluster_arn")
	assert.NotEmpty(t, ecsClusterArn, "Expected a non-empty ECS Cluster ARN")

	ecsClusterName := terraform.Output(t, terraformOptions, "ecs_cluster_name")
	assert.NotEmpty(t, ecsClusterName, "Expected a non-empty ECS Cluster Name")

	privateSubnetIds := terraform.OutputList(t, terraformOptions, "private_subnet_ids")
	assert.NotEmpty(t, privateSubnetIds, "Expected a non-empty list of private subnets ids")

	securityGroupId := terraform.Output(t, terraformOptions, "ecs_service_security_group_id")
	assert.NotEmpty(t, privateSubnetIds, "Expected a non-empty security group id")

	tfOut := tfOutputs{
		ecsTaskDefinitionArn: ecsTaskDefinitionArn,
		ecsClusterArn:        ecsClusterArn,
		ecsClusterName:       ecsClusterName,
		privateSubnetIds:     privateSubnetIds,
		securityGroupId:      securityGroupId,
	}
	return &tfOut
}

// Validate Tags on any ECS resource that is supported with ListTagsForResource
func validateEcsTags(t *testing.T, ecsClient *ecs.Client, arn string, description string) {
	tagsResp, err := ecsClient.ListTagsForResource(context.Background(), &ecs.ListTagsForResourceInput{ResourceArn: &arn})
	assert.NoError(t, err, "Expected no error for ListTagsForResource for %s: %s", description, arn)
	tags := make([]awstagging.TagItem, 0)
	for _, tag := range tagsResp.Tags {
		tags = append(tags, awstagging.TagItem{Key: tag.Key, Value: tag.Value})
	}
	valid, missing := awstagging.VerifyTagsExist(tags)
	assert.True(t, valid, fmt.Sprintf("Expected tags not found for %s (%s): %v", description, arn, missing))

	valid, bad := awstagging.VerifyTagsValueFormat(tags)
	assert.True(t, valid, fmt.Sprintf("Tags have invalid values for %s (%s): %v", description, arn, bad))
}

// TestStandaloneTask tests creating a standalone ECS task and then running it.
func TestStandaloneTask(t *testing.T) {
	// Variables for the terraform module, includes a timestamp
	name := getName()

	// Terraform options
	terraformOptions := getTfOpts(name, false, true)

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(t, terraformOptions)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(t, terraformOptions)

	tfOut := getAndVerifyOutputs(t, terraformOptions)

	expectedClusterName := fmt.Sprintf("%s-%s", environmentName, name)
	assert.Equal(t, tfOut.ecsClusterName, expectedClusterName, "Expected ECS Cluster Name to match the name passed to the stack")

	cfg, err := config.LoadDefaultConfig(context.TODO(), config.WithRegion(awsRegion))
	assert.NoError(t, err, "Expected no error for LoadDefaultConfig creating AWS session")

	ecsClient := ecs.NewFromConfig(cfg)
	clusters, err := ecsClient.DescribeClusters(context.Background(), &ecs.DescribeClustersInput{
		Clusters: []string{tfOut.ecsClusterName},
	})
	assert.NoError(t, err, "Expected no error for DescribeClusters")
	assert.Equal(t, 1, len(clusters.Clusters), "Expected exactly one cluster returned")
	cluster := clusters.Clusters[0]

	assert.Equal(t, tfOut.ecsClusterArn, *cluster.ClusterArn, "Expected the cluster ARN to match the output")
	assert.Equal(t, tfOut.ecsClusterName, *cluster.ClusterName, "Expected the cluster Name to match the output")

	// validate tags
	validateEcsTags(t, ecsClient, tfOut.ecsClusterArn, "ECS Cluster")
	validateEcsTags(t, ecsClient, tfOut.ecsTaskDefinitionArn, "ECS Task")

	// Get the task definition
	tdResp, err := ecsClient.DescribeTaskDefinition(context.Background(),
		&ecs.DescribeTaskDefinitionInput{
			TaskDefinition: &tfOut.ecsTaskDefinitionArn})
	assert.NoError(t, err, "Expected no error for DescribeTaskDefinition")

	// CPU and memory are hardcoded in the test fixture
	assert.Equal(t, *tdResp.TaskDefinition.Cpu, "256", "Expected 256 CPU units")
	assert.Equal(t, *tdResp.TaskDefinition.Memory, "512", "Expected 256 CPU units")
	assert.Len(t, tdResp.TaskDefinition.ContainerDefinitions, 1, "Expected exactly one container definition")

	// check environment variables on the first container
	assert.Len(t, tdResp.TaskDefinition.ContainerDefinitions[0].Environment, 6, "Expected exactly six environment variable in container definition")

	// check secrets
	assert.Len(t, tdResp.TaskDefinition.ContainerDefinitions[0].Secrets, 1, "Expected exactly one secret in container definition")
	assert.Equal(t, *tdResp.TaskDefinition.ContainerDefinitions[0].Secrets[0].Name, name, "Expected secret name to be %s", name)

	// Start the task, wait for it to stabilize
	runTask(t, ecsClient, tfOut)
}

func runTask(t *testing.T, ecsClient *ecs.Client, tfOut *tfOutputs) {
	// Run the task
	runResp, err := ecsClient.RunTask(context.Background(), &ecs.RunTaskInput{
		Cluster:        &tfOut.ecsClusterArn,
		TaskDefinition: &tfOut.ecsTaskDefinitionArn,
		LaunchType:     ecstypes.LaunchTypeFargate,
		NetworkConfiguration: &ecstypes.NetworkConfiguration{
			AwsvpcConfiguration: &ecstypes.AwsVpcConfiguration{
				Subnets:        tfOut.privateSubnetIds,
				AssignPublicIp: ecstypes.AssignPublicIpDisabled,
				SecurityGroups: []string{tfOut.securityGroupId},
			},
		},
	})
	assert.NoError(t, err, "Expected no error for RunTask")
	assert.Equal(t, 1, len(runResp.Tasks), "Expected exactly one task to be started")

	// Wait for the task to complete. We know it runs for 10 seconds and exits with a status code of 1.
	taskArn := *runResp.Tasks[0].TaskArn

	// it can take a bit for a task to start, we'll wait up to a minute
	exitted := false
	for i := 0; i < 60; i++ {
		time.Sleep(1 * time.Second)
		describeResp, err := ecsClient.DescribeTasks(context.Background(), &ecs.DescribeTasksInput{
			Cluster: &tfOut.ecsClusterArn,
			Tasks:   []string{taskArn},
		})
		assert.NoError(t, err, "Expected no error for DescribeTasks")
		assert.Equal(t, 1, len(describeResp.Tasks), "Expected exactly one task to be described")
		status := describeResp.Tasks[0].LastStatus
		if *status == "STOPPED" {
			exitted = true
			assert.Equal(t, int32(1), *describeResp.Tasks[0].Containers[0].ExitCode, "Expected task to exit with code 1")
			break
		}
	}
	assert.True(t, exitted, "Expected task to exit after 60 seconds!")
}

package test

import (
	"context"
	"fmt"
	"testing"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/autoscaling"
	"github.com/aws/aws-sdk-go-v2/service/ec2"
	"github.com/aws/aws-sdk-go-v2/service/ecs"
	ecsTypes "github.com/aws/aws-sdk-go-v2/service/ecs/types"
	"github.com/aws/aws-sdk-go-v2/service/elasticloadbalancingv2"
	elbTypes "github.com/aws/aws-sdk-go-v2/service/elasticloadbalancingv2/types"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"

	"apres.dev/awstagging"
)

const awsRegion = "us-east-2"
const environmentName = "Testing"

func getName() string {
	return fmt.Sprintf("test%d", time.Now().Unix())
}

// Get Terraform Options for all tests
func getTfOpts(name string, target string, enableLB bool, ec2UseNVMe bool, ec2InstanceType string, makeVolume bool, port int) *terraform.Options {
	return &terraform.Options{
		// The path to where your Terraform code is located
		TerraformDir: "./fixtures",

		// Variables to pass to our Terraform code using -var options
		Vars: map[string]interface{}{
			"name":                          name,
			"environment":                   environmentName,
			"target":                        target,
			"ec2_use_instance_nvme_storage": ec2UseNVMe,
			"ec2_instance_type":             ec2InstanceType,
			"make_volume":                   makeVolume,
			"container_port":                port,
			"create_load_balancer":          enableLB,
		},
	}
}

type tfOutputs struct {
	ecsTaskDefinitionArn       string
	ecsServiceArn              string
	ecsServiceName             string
	ecsClusterArn              string
	ecsClusterName             string
	ec2AsgArn                  string
	ec2AsgName                 string
	loadBalancerArn            string
	loadBalancerDnsName        string
	loadBalancerTargetGroupArn string
}

// Get and verify Terraform Outputs for all tests.
func getAndVerifyOutputs(t *testing.T, terraformOptions *terraform.Options) *tfOutputs {
	// Get outputs
	ecsTaskDefinitionArn := terraform.Output(t, terraformOptions, "ecs_task_definition_arn")
	assert.NotEmpty(t, ecsTaskDefinitionArn, "Expected a non-empty ECS Task Definition ARN")

	ecsServiceArn := terraform.Output(t, terraformOptions, "ecs_service_arn")
	assert.NotEmpty(t, ecsServiceArn, "Expected a non-empty ECS Service ARN")

	ecsServiceName := terraform.Output(t, terraformOptions, "ecs_service_name")
	assert.NotEmpty(t, ecsServiceName, "Expected a non-empty ECS Service Name")

	ecsClusterArn := terraform.Output(t, terraformOptions, "ecs_cluster_arn")
	assert.NotEmpty(t, ecsClusterArn, "Expected a non-empty ECS Cluster ARN")

	ecsClusterName := terraform.Output(t, terraformOptions, "ecs_cluster_name")
	assert.NotEmpty(t, ecsClusterName, "Expected a non-empty ECS Cluster Name")

	// these will be empty strings if we're using Fargate
	ec2AsgArn := terraform.Output(t, terraformOptions, "ec2_asg_arn")
	ec2AsgName := terraform.Output(t, terraformOptions, "ec2_asg_name")

	// these will be empty if we don't create an LB
	loadBalancerArn := terraform.Output(t, terraformOptions, "load_balancer_arn")
	loadBalancerDnsName := terraform.Output(t, terraformOptions, "load_balancer_dns_name")
	loadBalancerTargetGroupArn := terraform.Output(t, terraformOptions, "load_balancer_target_group_arn")

	tfOut := tfOutputs{
		ecsTaskDefinitionArn:       ecsTaskDefinitionArn,
		ecsServiceArn:              ecsServiceArn,
		ecsServiceName:             ecsServiceName,
		ecsClusterArn:              ecsClusterArn,
		ecsClusterName:             ecsClusterName,
		ec2AsgArn:                  ec2AsgArn,
		ec2AsgName:                 ec2AsgName,
		loadBalancerArn:            loadBalancerArn,
		loadBalancerDnsName:        loadBalancerDnsName,
		loadBalancerTargetGroupArn: loadBalancerTargetGroupArn,
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

// Wait for service to stabilize
func waitForServiceToStabilize(t *testing.T, ecsClient *ecs.Client, clusterName string, serviceArn string) {
	waiter := ecs.NewServicesStableWaiter(ecsClient)
	waitParams := &ecs.DescribeServicesInput{
		Cluster:  &clusterName,
		Services: []string{serviceArn},
	}
	maxWaitTime := 300 * time.Second
	err := waiter.Wait(context.Background(), waitParams, maxWaitTime)
	assert.NoError(t, err, "Expected no error after waiting for service %s to stabilize", clusterName, serviceArn)
}

// Validate a load balancer deployment
func validateLoadBalancer(t *testing.T, lbClient *elasticloadbalancingv2.Client, tfOut *tfOutputs) {
	lbResp, err := lbClient.DescribeLoadBalancers(context.Background(),
		&elasticloadbalancingv2.DescribeLoadBalancersInput{
			LoadBalancerArns: []string{tfOut.loadBalancerArn},
		})
	assert.NoError(t, err, "Expected no error for DescribeLoadBalancers")
	assert.Equal(t, 1, len(lbResp.LoadBalancers), "Expected exactly one load balancer returned")
	assert.Equal(t, tfOut.loadBalancerDnsName, *lbResp.LoadBalancers[0].DNSName,
		"Expected the Load Balancer DNS Name to match the output")
	assert.Equal(t, "off", aws.ToString(lbResp.LoadBalancers[0].EnforceSecurityGroupInboundRulesOnPrivateLinkTraffic),
		"Expected EnforceSecurityGroupInboundRulesOnPrivateLinkTraffic to be true")
	assert.Equal(t, elbTypes.LoadBalancerSchemeEnum("internal"), lbResp.LoadBalancers[0].Scheme,
		"Expected the Load Balancer Scheme to be internet-facing")

	// check tags, can do both at once
	tagsResp, err := lbClient.DescribeTags(context.Background(), &elasticloadbalancingv2.DescribeTagsInput{
		ResourceArns: []string{tfOut.loadBalancerArn, tfOut.loadBalancerTargetGroupArn},
	})
	assert.NoError(t, err, "Expected no error for DescribeTags")

	for _, tagDescription := range tagsResp.TagDescriptions {
		tags := make([]awstagging.TagItem, 0)
		for _, tag := range tagDescription.Tags {
			tags = append(tags, awstagging.TagItem{Key: tag.Key, Value: tag.Value})
		}
		valid, missing := awstagging.VerifyTagsExist(tags)
		assert.True(t, valid, fmt.Sprintf("Expected tags not found for %s: %v", *tagDescription.ResourceArn, missing))

		valid, bad := awstagging.VerifyTagsValueFormat(tags)
		assert.True(t, valid, fmt.Sprintf("Tags have invalid values for %s: %v", *tagDescription.ResourceArn, bad))
	}
}

// Test ECS running on Fargate with no volumes or load balancer
func TestECSFargateNoLoadBalancer(t *testing.T) {
	// Variables for the terraform module, includes a timestamp
	name := getName()

	// Terraform options
	terraformOptions := getTfOpts(name, "FARGATE", false, false, "", false, -1)

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(t, terraformOptions)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(t, terraformOptions)

	tfOut := getAndVerifyOutputs(t, terraformOptions)

	expectedClusterName := fmt.Sprintf("%s-%s", name, environmentName)
	assert.Equal(t, tfOut.ecsClusterName, expectedClusterName, "Expected ECS Cluster Name to match the name passed to the stack")

	// Terratest has a handy way to create clients, but it's SDK v1, and doesn't place nice with SSO,
	// so we'll use the v2 SDK directly.
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
	validateEcsTags(t, ecsClient, tfOut.ecsServiceArn, "ECS Service")
	validateEcsTags(t, ecsClient, tfOut.ecsTaskDefinitionArn, "ECS Task")

	// Wait for the service to stabilize
	waitForServiceToStabilize(t, ecsClient, tfOut.ecsClusterName, tfOut.ecsServiceArn)

	assert.Equal(t, "ACTIVE", *cluster.Status, "Expected the cluster to have ACTIVE Status")
}

// Test ECS on Fargate with ephemeral volumes  - no LB for now
func TestECSFargateEphemeralVolumeLoadBalancer(t *testing.T) {
	name := getName()
	terraformOptions := getTfOpts(name, "FARGATE", true, false, "", true, 8080)
	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	tfOut := getAndVerifyOutputs(t, terraformOptions)

	// verify the lb params here
	assert.NotEmpty(t, tfOut.loadBalancerArn, "Expected a non-empty Load Balancer ARN")
	assert.NotEmpty(t, tfOut.loadBalancerDnsName, "Expected a non-empty Load Balancer DNS Name")
	assert.NotEmpty(t, tfOut.loadBalancerTargetGroupArn, "Expected a non-empty Load Balancer Target Group ARN")

	expectedClusterName := fmt.Sprintf("%s-%s", name, environmentName)
	assert.Equal(t, expectedClusterName, tfOut.ecsClusterName,
		"Expected ECS Cluster Name to match the name passed to the stack")

	cfg, err := config.LoadDefaultConfig(context.TODO(), config.WithRegion(awsRegion))
	assert.NoError(t, err, "Expected no error for LoadDefaultConfig creating AWS session")
	ecsClient := ecs.NewFromConfig(cfg)

	// Basic validation, the rest was done in the previous test
	clusters, err := ecsClient.DescribeClusters(context.Background(), &ecs.DescribeClustersInput{
		Clusters: []string{tfOut.ecsClusterName},
	})
	assert.NoError(t, err, "Expected no error for DescribeClusters")
	assert.Equal(t, 1, len(clusters.Clusters), "Expected exactly one cluster returned")

	// Wait for the service to stabilize
	waitForServiceToStabilize(t, ecsClient, tfOut.ecsClusterName, tfOut.ecsServiceArn)

	// validate tags
	validateEcsTags(t, ecsClient, tfOut.ecsClusterArn, "ECS Cluster")
	validateEcsTags(t, ecsClient, tfOut.ecsServiceArn, "ECS Service")
	validateEcsTags(t, ecsClient, tfOut.ecsTaskDefinitionArn, "ECS Task")

	// Get a list of tasks to check
	tasksInput := &ecs.ListTasksInput{
		Cluster:     &tfOut.ecsClusterName,
		ServiceName: &tfOut.ecsServiceName,
	}
	listTasksResp, err := ecsClient.ListTasks(context.Background(), tasksInput)
	assert.NoError(t, err, "Expected no error for ListTasks")
	assert.Greater(t, len(listTasksResp.TaskArns), 0, "Expected at least one task running")

	// Use the first task to check the volume definition
	describeInput := &ecs.DescribeTasksInput{
		Cluster: &tfOut.ecsClusterName,
		Tasks:   []string{listTasksResp.TaskArns[0]},
	}
	taskResp, err := ecsClient.DescribeTasks(context.Background(), describeInput)
	assert.NoError(t, err, "Expected no error for DescribeTasks")
	assert.Greater(t, len(taskResp.Tasks), 0, "Expected at least one task running")

	// Look at first task. Yes CPU and memory are strings.
	assert.Equal(t, "256", aws.ToString(taskResp.Tasks[0].Cpu), "Expected 256 CPU units")
	assert.Equal(t, "512", aws.ToString(taskResp.Tasks[0].Memory), "Expected 512 Memory units")
	assert.Equal(t, int32(21), taskResp.Tasks[0].EphemeralStorage.SizeInGiB, "Expected 21 GiB ephemeral storage")
	assert.Equal(t, int32(21), taskResp.Tasks[0].FargateEphemeralStorage.SizeInGiB, "Expected 21 GiB Fargate ephemeral storage")
	assert.Equal(t, ecsTypes.LaunchType("FARGATE"), taskResp.Tasks[0].LaunchType, "Expected Fargate launch type")

	// Check the LB configs and tags
	lbClient := elasticloadbalancingv2.NewFromConfig(cfg)
	validateLoadBalancer(t, lbClient, tfOut)

}

// Test ECS on EC2 with no volumes and a load balancer
func TestECSEc2WithLoadBalancer(t *testing.T) {
	name := getName()
	terraformOptions := getTfOpts(name, "EC2", true, false, "t4g.small", false, 8080)
	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	cfg, err := config.LoadDefaultConfig(context.TODO(), config.WithRegion(awsRegion))
	assert.NoError(t, err, "Expected no error for LoadDefaultConfig creating AWS session")

	tfOut := getAndVerifyOutputs(t, terraformOptions)

	expectedClusterName := fmt.Sprintf("%s-%s", name, environmentName)
	assert.Equal(t, expectedClusterName, tfOut.ecsClusterName, "Expected ECS Cluster Name to match the name passed to the stack")

	assert.NotEmpty(t, tfOut.ec2AsgArn, "Expected a non-empty EC2 ASG ARN")

	ecsClient := ecs.NewFromConfig(cfg)

	// Basic validation, the rest was done in the previous test
	clusters, err := ecsClient.DescribeClusters(context.Background(), &ecs.DescribeClustersInput{
		Clusters: []string{tfOut.ecsClusterName},
	})
	assert.NoError(t, err, "Expected no error for DescribeClusters")
	assert.Equal(t, 1, len(clusters.Clusters), "Expected exactly one cluster returned")

	// Wait for the service to stabilize
	waitForServiceToStabilize(t, ecsClient, tfOut.ecsClusterName, tfOut.ecsServiceArn)

	// validate tags
	validateEcsTags(t, ecsClient, tfOut.ecsClusterArn, "ECS Cluster")
	validateEcsTags(t, ecsClient, tfOut.ecsServiceArn, "ECS Service")
	validateEcsTags(t, ecsClient, tfOut.ecsTaskDefinitionArn, "ECS Task")

	// Get a list of tasks to check
	tasksInput := &ecs.ListTasksInput{
		Cluster:     &tfOut.ecsClusterName,
		ServiceName: &tfOut.ecsServiceName,
	}
	listTasksResp, err := ecsClient.ListTasks(context.Background(), tasksInput)
	assert.NoError(t, err, "Expected no error for ListTasks")
	assert.Greater(t, len(listTasksResp.TaskArns), 0, "Expected at least one task running")

	// Use the first task to check the volume definition
	describeInput := &ecs.DescribeTasksInput{
		Cluster: &tfOut.ecsClusterName,
		Tasks:   []string{listTasksResp.TaskArns[0]},
	}
	taskResp, err := ecsClient.DescribeTasks(context.Background(), describeInput)
	assert.NoError(t, err, "Expected no error for DescribeTasks")
	assert.Greater(t, len(taskResp.Tasks), 0, "Expected at least one task running")

	// Look at first task. Yes CPU and memory are strings.
	assert.Equal(t, "256", aws.ToString(taskResp.Tasks[0].Cpu), "Expected 256 CPU units")
	assert.Equal(t, "512", aws.ToString(taskResp.Tasks[0].Memory), "Expected 512 Memory units")
	assert.Equal(t, ecsTypes.LaunchType("EC2"), taskResp.Tasks[0].LaunchType, "Expected Fargate launch type")

	// get the ASG and check it
	asgClient := autoscaling.NewFromConfig(cfg)
	ec2Client := ec2.NewFromConfig(cfg)

	asgResp, err := asgClient.DescribeAutoScalingGroups(context.Background(),
		&autoscaling.DescribeAutoScalingGroupsInput{
			AutoScalingGroupNames: []string{tfOut.ec2AsgName},
		})
	assert.NoError(t, err, "Expected no error for DescribeAutoScalingGroups")

	assert.Equal(t, 1, len(asgResp.AutoScalingGroups), "Expected exactly one ASG returned")
	assert.Equal(t, 3, len(asgResp.AutoScalingGroups[0].AvailabilityZones), "Expected exactly 3 Availability Zones in the ASG")
	assert.Equal(t, int32(1), *asgResp.AutoScalingGroups[0].MinSize, "Expected ASG MinSize to be 1")
	assert.Equal(t, int32(3), *asgResp.AutoScalingGroups[0].MaxSize, "Expected ASG MaxSize to be 3")

	// ASG tags are a bit different because they have a PropagateAtLaunch flag
	tags := make([]awstagging.TagItem, 0)
	for _, tag := range asgResp.AutoScalingGroups[0].Tags {
		tags = append(tags, awstagging.TagItem{Key: tag.Key, Value: tag.Value})
		assert.True(t, *tag.PropagateAtLaunch, "Expected all ASG tags to have PropogateAtLaunch flag set")
	}
	valid, missing := awstagging.VerifyTagsExist(tags)
	assert.True(t, valid, fmt.Sprintf("Expected tags not found for ASG (%s): %v", tfOut.ec2AsgName, missing))

	valid, bad := awstagging.VerifyTagsValueFormat(tags)
	assert.True(t, valid, fmt.Sprintf("Tags have invalid values for ASG (%s): %v", tfOut.ec2AsgName, bad))

	// Check the launch template
	ltId := aws.String(*asgResp.AutoScalingGroups[0].LaunchTemplate.LaunchTemplateId)
	ltResp, err := ec2Client.DescribeLaunchTemplates(context.Background(), &ec2.DescribeLaunchTemplatesInput{
		LaunchTemplateIds: []string{*ltId},
	})
	assert.NoError(t, err, "Expected no error for DescribeLaunchTemplates")
	assert.Equal(t, 1, len(ltResp.LaunchTemplates), "Expected exactly one Launch Template returned")

	// Check Launch Template tags
	tags = make([]awstagging.TagItem, 0)
	for _, tag := range ltResp.LaunchTemplates[0].Tags {
		tags = append(tags, awstagging.TagItem{Key: tag.Key, Value: tag.Value})
	}
	valid, missing = awstagging.VerifyTagsExist(tags)
	assert.True(t, valid, fmt.Sprintf("Expected tags not found for Launch Template (%s): %v", *ltId, missing))
	valid, bad = awstagging.VerifyTagsValueFormat(tags)
	assert.True(t, valid, fmt.Sprintf("Tags have invalid values for Launch Template (%s): %v", *ltId, bad))

	// Check the LB configs and tags
	lbClient := elasticloadbalancingv2.NewFromConfig(cfg)
	validateLoadBalancer(t, lbClient, tfOut)
}

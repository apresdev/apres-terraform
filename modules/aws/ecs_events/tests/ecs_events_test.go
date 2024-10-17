package test

import (
	"context"
	"fmt"
	"testing"
	"time"

	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/cloudwatch"
	"github.com/aws/aws-sdk-go-v2/service/cloudwatch/types"
	cloudwatchTypes "github.com/aws/aws-sdk-go-v2/service/cloudwatch/types"
	"github.com/aws/aws-sdk-go-v2/service/eventbridge"
	eventBridgeTypes "github.com/aws/aws-sdk-go-v2/service/eventbridge/types"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// Hard coded values
const apresCloudwatchNamespace = "Apres/ECS"
const taskMetricName = "TaskNonZeroExitCode"

func getName() string {
	return fmt.Sprintf("unittest%d", time.Now().Unix())
}

func TestEcsEvents(t *testing.T) {
	name := getName()
	awsRegion := "us-east-2"
	environment := "UnitTest"
	terraformOptions := &terraform.Options{
		TerraformDir: "./fixtures",
		Vars: map[string]interface{}{
			"name":        name,
			"environment": environment,
		},
	}
	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	// Need this start time for getting metrics later
	startTime := time.Now()

	// Get the outputs
	ruleName := terraform.Output(t, terraformOptions, "rule_name")
	lambdaFunctionName := terraform.Output(t, terraformOptions, "lambda_function_name")
	clusterName := terraform.Output(t, terraformOptions, "cluster_name")
	serviceName := terraform.Output(t, terraformOptions, "service_name")
	defaultBusName := "default"

	// Load config
	cfg, err := config.LoadDefaultConfig(context.Background(), config.WithRegion(awsRegion))
	assert.NoError(t, err, "Expected no error for LoadDefaultConfig creating AWS session")

	// Need the cloudwatch client to check metrics
	cloudwatchClient := cloudwatch.NewFromConfig(cfg)

	// Check EventBridge rule for basics and then validate metrics.
	eventBridgeClient := eventbridge.NewFromConfig(cfg)
	rule, err := eventBridgeClient.DescribeRule(context.Background(), &eventbridge.DescribeRuleInput{
		Name:         &ruleName,
		EventBusName: &defaultBusName,
	})
	assert.NoError(t, err, "Expected no error for DescribeRule")
	assert.Equal(t, eventBridgeTypes.RuleStateEnabled, rule.State, "Expected rule to be enabled")

	// Check the rule metrics. This may take up to 10 minutes for the metric to show up in CloudWatch.
	dimensions := []cloudwatchTypes.Dimension{
		{Name: aws.String("RuleName"), Value: aws.String(ruleName)},
	}
	validateMetrics(t, cloudwatchClient, startTime, "AWS/Events", "Invocations", "FailedInvocations", dimensions)

	// Now check the Lambda metrics.
	dimensions = []cloudwatchTypes.Dimension{
		{Name: aws.String("FunctionName"), Value: aws.String(lambdaFunctionName)},
	}
	validateMetrics(t, cloudwatchClient, startTime, "AWS/Lambda", "Invocations", "Errors", dimensions)

	// And finally check the metric the lambda is emitting. We don't have the task name but
	// in this test it's the same as the service name.
	dimensions = []cloudwatchTypes.Dimension{
		{Name: aws.String("Cluster"), Value: aws.String(clusterName)},
		{Name: aws.String("Service"), Value: aws.String(serviceName)},
		{Name: aws.String("Task"), Value: aws.String(serviceName)},
	}
	validateMetrics(t, cloudwatchClient, startTime, apresCloudwatchNamespace, taskMetricName, "", dimensions)
}

// Validate metrics for the given namespace, metric name, and dimensions. We'll wait up to 10 minutes for the metrics to
// show up in CloudWatch. If the failure metric is empty, we'll skip checking for it.
func validateMetrics(t *testing.T, cloudwatchClient *cloudwatch.Client, startTime time.Time,
	namespace string, successMetric string, failureMetric string,
	dimensions []cloudwatchTypes.Dimension) {

	mssg := fmt.Sprintf("Namespace %s, success %s, failure %s", namespace, successMetric, failureMetric)
	fmt.Printf("Validating metrics for %s\n", mssg)
	// Start a minute before start time, else if the metric does exist we end up waiting one minute.
	beginTime := startTime.Add(-1 * time.Minute)

	queryParams := &cloudwatch.GetMetricStatisticsInput{
		StartTime:  &beginTime,
		EndTime:    aws.Time(time.Now()),
		Namespace:  aws.String(namespace),
		MetricName: aws.String(successMetric),
		Period:     aws.Int32(60), // 1 minute
		Statistics: []cloudwatchTypes.Statistic{types.StatisticSum},
		Dimensions: dimensions,
	}
	// Loop waiting for data. If the metric does not exist yet, Datapoints will return empty.
	// We'll wait for five minutes.
	sleepTime := 15 * time.Second // wait 15 seconds between checks
	numLoops := 60 * 10 / 15      // 10 minutes
	found := false
	for i := 0; i < numLoops; i++ {
		// Need to update the end time for each query
		queryParams.EndTime = aws.Time(time.Now())
		fmt.Printf("Looking for metrics between %s and %s\n", queryParams.StartTime, queryParams.EndTime)
		data, err := cloudwatchClient.GetMetricStatistics(context.Background(), queryParams)
		assert.NoError(t, err, "Expected no error for GetMetricStatistics for %s", mssg)
		if len(data.Datapoints) == 0 {
			fmt.Printf("No data yet for %s\n", mssg)
			time.Sleep(sleepTime)
			continue
		} else {
			sum := 0.0
			for _, result := range data.Datapoints {
				sum += *result.Sum
			}
			assert.Greater(t, sum, 0.0, "Expected at least one success datapoint for %s", mssg)
			found = true
			break
		}
	}
	assert.True(t, found, "Expected to find at least one datapoint for %s", mssg)

	// Failures might be optional.
	if failureMetric == "" {
		return
	}
	// Now look for the failed invocations. No need to wait at this point for the metrics.
	queryParams.MetricName = aws.String(failureMetric)
	data, err := cloudwatchClient.GetMetricStatistics(context.Background(), queryParams)
	assert.NoError(t, err, "Expected no error for GetMetricStatistics for %s", mssg)
	// We may have no data, if there were no failed invocations
	if len(data.Datapoints) != 0 {
		sum := 0.0
		for _, result := range data.Datapoints {
			sum += *result.Sum
		}
		assert.Equal(t, 0.0, sum, "Expected no failures for %s", mssg)
	}
}
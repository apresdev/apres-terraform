package test

import (
	"context"
	"fmt"
	"testing"
	"time"

	"apres.dev/awstagging"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/cloudwatch"
	"github.com/aws/aws-sdk-go-v2/service/cloudwatch/types"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/suite"
)

// TODO:
// - Anomaly Detection is still a metric alarm!

type CWATestSuite struct {
	suite.Suite
	ctx               context.Context
	awsRegion         string
	alarmName         string
	description       string
	environment       string
	namespace         string
	metricName        string
	runbookUrl        string
	evaluationPeriods int
	severity          string
	threshold         int
	period            int32
	statistic         string
}

func TestCloudWatchAlarmsTestSuite(t *testing.T) {
	suite.Run(t, new(CWATestSuite))
}

func (s *CWATestSuite) SetupSuite() {
	s.ctx = context.Background()
	s.awsRegion = "us-east-2"
	s.environment = "UnitTest"
	now := time.Now().Unix()
	s.alarmName = fmt.Sprintf("unittest-%d", now)
	s.description = fmt.Sprintf("This is a test alarm %d", now)
	// These are made up values, but they still work because no data is alarmable.
	s.namespace = "Apres/Testing"
	s.metricName = fmt.Sprintf("UnitTestCloudWatchAlarms%d", now)
	s.evaluationPeriods = 1
	s.period = 60
	s.threshold = 1
	s.statistic = "Sum"
	s.runbookUrl = "https://apres.dev/runbooks/unittest"
	s.severity = "SEV1"
}

func setTfOpts(s *CWATestSuite, useAnomalyDetection bool, comparisonOperator string) *terraform.Options {
	return &terraform.Options{
		TerraformDir: "./fixtures",
		Vars: map[string]interface{}{
			"name":                  s.alarmName,
			"environment":           s.environment,
			"description":           s.description,
			"severity":              s.severity,
			"runbook":               s.runbookUrl,
			"comparison_operator":   comparisonOperator,
			"evaluation_periods":    s.evaluationPeriods,
			"use_anomaly_detection": useAnomalyDetection,
			"threshold":             s.threshold,
			"namespace":             s.namespace,
			"metric_name":           s.metricName,
			"period":                s.period,
			"statistic":             s.statistic,
			"dimensions":            map[string]string{"FakeDimension": "SomeValue"},
		},
	}
}

func getTfOutputs(s *CWATestSuite, tOpts *terraform.Options) (string, string) {
	arn := terraform.Output(s.T(), tOpts, "alarm_arn")
	assert.True(s.T(), len(arn) > 1, "Expected a non-empty ARN")

	id := terraform.Output(s.T(), tOpts, "alarm_id")
	assert.True(s.T(), len(id) > 1, "Expected a non-empty alarm ID")

	return arn, id
}

func getCloudwatchService(s *CWATestSuite) *cloudwatch.Client {
	cfg, err := config.LoadDefaultConfig(s.ctx, config.WithRegion(s.awsRegion))
	assert.NoError(s.T(), err, "Expected no error for LoadDefaultConfig creating AWS session")
	return cloudwatch.NewFromConfig(cfg)
}

func getAlarm(s *CWATestSuite, svc *cloudwatch.Client, alarmId string) *types.MetricAlarm {
	resp, err := svc.DescribeAlarms(s.ctx, &cloudwatch.DescribeAlarmsInput{AlarmNames: []string{alarmId}})
	assert.NoError(s.T(), err, "Expected no error for DescribeAlarms")
	assert.Equal(s.T(), 1, len(resp.MetricAlarms), "Expected 1 alarm")
	return &resp.MetricAlarms[0]
}

func assertCommon(s *CWATestSuite, alarm *types.MetricAlarm, alarmId string) {
	assert.Equal(s.T(), alarmId, *alarm.AlarmName, "Expected the alarm name to match")
	expectedDescription := fmt.Sprintf("%s\n***\nRunbook: %s", s.description, s.runbookUrl)
	assert.Equal(s.T(), expectedDescription, *alarm.AlarmDescription, "Expected the alarm description to match")
}

func waitForAlarm(s *CWATestSuite, alarmId string, svc *cloudwatch.Client) {
	// Wait for the alarm to go to ALARM state, up to ~3 minutes.
	// sleep for 10 seconds, 18 times.
	sleepTime := 10 * time.Second
	for i := 0; i < 18; i++ {
		resp, err := svc.DescribeAlarms(s.ctx, &cloudwatch.DescribeAlarmsInput{AlarmNames: []string{alarmId}})
		assert.NoError(s.T(), err, "Expected no error for DescribeAlarms")
		if len(resp.MetricAlarms) > 0 {
			alarm := resp.MetricAlarms[0]
			if alarm.StateValue == types.StateValueAlarm {
				assert.True(s.T(), true, "Alarm is in ALARM state")
				return
			}
			// We expect the alarm to start in the insuffienct data state so ignore that.
			if alarm.StateValue != types.StateValueInsufficientData {
				assert.Fail(s.T(), "Alarm is not in INSUFFICENT_DATA or ALARM_STATE, is in %s", alarm.StateValue)
			}
		}
		time.Sleep(sleepTime)
	}
	assert.Fail(s.T(), "Alarm did not go to ALARM state")
}

// Anomaly detection is not supported, this code left here for reference.
// func (s *CWATestSuite) TestMetricAnomalyAlarm() {
// 	terraformOptions := setTfOpts(s, true, "GreaterThanUpperThreshold")

// 	// At the end of the test, run `terraform destroy` to clean up any resources that were created
// 	defer terraform.Destroy(s.T(), terraformOptions)

// 	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
// 	terraform.InitAndApply(s.T(), terraformOptions)

// 	// Get the outputs
// 	_, alarmId := getTfOutputs(s, terraformOptions)

// 	svc := getCloudwatchService(s)

// 	resp, err := svc.DescribeAlarms(s.ctx, &cloudwatch.DescribeAlarmsInput{AlarmNames: []string{alarmId}})
// 	assert.NoError(s.T(), err, "Expected no error for DescribeAlarms")
// 	assert.Equal(s.T(), 1, len(resp.MetricAlarms), "Expected 1 alarm")

// 	alarm := getAlarm(s, svc, alarmId)

// 	assertCommon(s, alarm, alarmId)

// 	// Check fields specific to anomaly detection alerts
// 	assert.Equal(s.T(), 2, len(alarm.Metrics), "Expected 2 metric")

// 	// The two metrics we should back look like:
// 	// {'Id': 'ad1', 'Expression': 'ANOMALY_DETECTION_BAND(m1)', 'Label': 'UnitTestCloudWatchAlarms1730404014 (expected)', 'ReturnData': True}
//     //{'Id': 'm1', 'MetricStat': {'Metric': {'Namespace': 'Apres/Testing', 'MetricName': 'UnitTestCloudWatchAlarms1730404014', 'Dimensions': [{'Name': 'FakeDimension', 'Value': 'SomeValue'}]}, 'Period': 60, 'Stat': 'Sum'}, 'ReturnData': True}

// 	for _, metric := range alarm.Metrics {
// 		assert.True(s.T(), true, metric.ReturnData, "Expected ReturnData to be true")
// 		if *metric.Id == "ad1" {
// 			assert.Equal(s.T(), "ANOMALY_DETECTION_BAND(m1)", *metric.Expression, "Expected the expression to match")
// 			assert.True(s.T(), true, metric.ReturnData, "Expected ReturnData to be true")
// 		}
// 		if *metric.Id == "m1" {
// 			assert.Equal(s.T(), s.period, *metric.MetricStat.Period, "Expected the period to match")
// 			assert.Equal(s.T(), s.statistic, *metric.MetricStat.Stat, "Expected the statistic to match")
// 			assert.Equal(s.T(), s.namespace, *metric.MetricStat.Metric.Namespace, "Expected the namespace to match")
// 			assert.Equal(s.T(), s.metricName, *metric.MetricStat.Metric.MetricName, "Expected the metric name to match")
// 			assert.Equal(s.T(), 1, len(metric.MetricStat.Metric.Dimensions), "Expected 1 dimension")
// 		}
// 	}

// 	// Check StateValue, should be ALARM
// 	waitForAlarm(s, alarmId, svc)
// }

func (s *CWATestSuite) TestMetricAlarm() {
	terraformOptions := setTfOpts(s, false, "GreaterThanThreshold")

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(s.T(), terraformOptions)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(s.T(), terraformOptions)

	_, alarmId := getTfOutputs(s, terraformOptions)

	svc := getCloudwatchService(s)

	resp, err := svc.DescribeAlarms(s.ctx, &cloudwatch.DescribeAlarmsInput{AlarmNames: []string{alarmId}})
	assert.NoError(s.T(), err, "Expected no error for DescribeAlarms")
	assert.Equal(s.T(), 1, len(resp.MetricAlarms), "Expected 1 alarm")

	alarm := getAlarm(s, svc, alarmId)

	assertCommon(s, alarm, alarmId)

	// Check fields specific to standard metrics alarms
	assert.Equal(s.T(), 1, len(alarm.Dimensions), "Expected 1 dimension")
	assert.Equal(s.T(), "FakeDimension", *alarm.Dimensions[0].Name, "Expected the dimension name to match")
	assert.Equal(s.T(), "SomeValue", *alarm.Dimensions[0].Value, "Expected the dimension value to match")
	assert.Equal(s.T(), s.namespace, *alarm.Namespace, "Expected the namespace to match")
	assert.Equal(s.T(), s.metricName, *alarm.MetricName, "Expected the metric name to match")
	assert.Equal(s.T(), "GreaterThanThreshold", string(alarm.ComparisonOperator), "Expected ComparisonOperator to be GreaterThanThreshold")

	// check tags
	tagsResp, err := svc.ListTagsForResource(s.ctx, &cloudwatch.ListTagsForResourceInput{ResourceARN: alarm.AlarmArn})
	assert.NoError(s.T(), err, "Expected no error for ListTagsForResource")
	tags := make([]awstagging.TagItem, 0)
	for _, tag := range tagsResp.Tags {
		tags = append(tags, awstagging.TagItem{Key: tag.Key, Value: tag.Value})
	}

	valid, missing := awstagging.VerifyTagsExist(tags)
	assert.True(s.T(), valid, "Expected all tags to be valid, missing: %v", missing)

	valid, bad := awstagging.VerifyTagsValueFormat(tags)
	assert.True(s.T(), valid, fmt.Sprintf("Tags have invalid values: %v", bad))

	// some extra tags we care about for this module
	t := getTag(tags, "runbook")
	assert.Equal(s.T(), s.runbookUrl, t, "Expected the runbook tag to exist and match")
	t = getTag(tags, "severity")
	assert.Equal(s.T(), s.severity, t, "Expected the severity tag to exist and match")
	t = getTag(tags, "source")
	assert.Equal(s.T(), "apres_cloudwatch_alarm_module", t, "Expected the source tag to exist and match")

	// Check StateValue, should be ALARM
	waitForAlarm(s, alarmId, svc)
}

func getTag(tags []awstagging.TagItem, key string) string {
	for _, tag := range tags {
		if *tag.Key == key {
			return *tag.Value
		}
	}
	return ""
}
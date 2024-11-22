package test

import (
	"context"
	"fmt"
	"testing"
	"time"

	"apres.dev/awstagging"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/eventbridge"
	"github.com/aws/aws-sdk-go-v2/service/eventbridge/types"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestLambdaSchedulerModule(t *testing.T) {
	awsRegion := "us-east-2"
	environment := "UnitTest"

	now := time.Now().Unix()
	name := fmt.Sprintf("test-%d", now)
	expression := "cron(* * * * ? *)"

	terraformOptions := &terraform.Options{
		TerraformDir: "./fixtures",
		Vars: map[string]any{
			"name": name,
			"environment": environment,
			"schedule_expression": expression,
		},
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	lambdaArn := terraform.Output(t, terraformOptions, "lambda_arn")
	assert.NotEmpty(t, lambdaArn)

	eventRuleArn := terraform.Output(t, terraformOptions, "event_rule_arn")
	assert.NotEmpty(t, eventRuleArn)

	eventRuleName := terraform.Output(t, terraformOptions, "event_rule_name")
	assert.NotEmpty(t, eventRuleName)

	ctx := context.Background()
	cfg, err := config.LoadDefaultConfig(ctx, config.WithRegion(awsRegion))
	assert.NoError(t, err, "expected no error for LoadDefaultConfig creating AWS session")
	ebClient := eventbridge.NewFromConfig(cfg)
	resp, err := ebClient.DescribeRule(ctx, &eventbridge.DescribeRuleInput{
		Name: aws.String(eventRuleName),
		EventBusName: aws.String("default"),
	})
	assert.NoError(t, err, "expected no error for DescribeRule")
	expectedName := fmt.Sprintf("%s-%s", environment, name)
	assert.Equal(t, expectedName, *resp.Name, "expected rule name to match")
	assert.Equal(t, expression, *resp.ScheduleExpression, "expected schedule expression to match")
	assert.Nil(t, resp.EventPattern, "expected no event pattern")
	assert.Equal(t, types.RuleStateEnabled, resp.State, "expected rule state to be enabled")

	// check tags
	tagsResp, err := ebClient.ListTagsForResource(ctx, &eventbridge.ListTagsForResourceInput{
		ResourceARN: aws.String(eventRuleArn),
	})
	assert.NoError(t, err, "expected no error for ListTagsForResource")
	tags := make([]awstagging.TagItem, 0)
	for _, tag := range tagsResp.Tags {
		tags = append(tags, awstagging.TagItem{Key: tag.Key, Value: tag.Value})
	}
	valid, missing := awstagging.VerifyTagsExist(tags)
	assert.True(t, valid, fmt.Sprintf("Expected tags not found: %v", missing))

	valid, bad := awstagging.VerifyTagsValueFormat(tags)
	assert.True(t, valid, fmt.Sprintf("Tags have invalid values: %v", bad))

	// now check the target
	targetsResp, err := ebClient.ListTargetsByRule(ctx, &eventbridge.ListTargetsByRuleInput{
		Rule: aws.String(eventRuleName),
		EventBusName: aws.String("default"),
	})
	assert.NoError(t, err, "expected no error for ListTargetsByRule")
	assert.Len(t, targetsResp.Targets, 1, "expected one target")

	assert.Equal(t, lambdaArn, *targetsResp.Targets[0].Arn, "expected target ARN to match")

}
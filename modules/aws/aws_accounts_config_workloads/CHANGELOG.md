# Changelog

This change log is automatically generated.

## 0.12.0 - 2024-12-02

Add signing variables to work around a terraform race condition.

## 0.11.0 - 2024-11-29

Enable and enforce EBS encryption by default.

## 0.10.0 - 2024-11-07

Remove alerting module due to unforeseen issues with Chatbot.

## 0.9.2 - 2024-11-04

Shorten names to fix the 38 character limit on IAM artifacts created in the alerting module.

## 0.9.1 - 2024-11-04

Pick up bug fixes in alerting module.

## 0.9.0 - 2024-11-04

Bump alerting module version to pick up regional deployments, and ecs_events version to pickup naming changes.

## 0.8.0 - 2024-10-23

Add AWS ChatBot to the workloads account, in one specified region, for CloudWatch Alarms support.

## 0.7.0 - 2024-10-18

Add the ECS Events module, to monitor for ECS tasks in crash loops.

## 0.6.3 - 2024-10-02

Fix typos in NLB region lookup.

## 0.6.2 - 2024-10-02

NLBs use a different policy than ALBs, so add that and set encryption to AES256.

## 0.6.1 - 2024-10-02

Fix path in bucket policy.

## 0.6.0 - 2024-10-02

Add a regional bucket for load balancer logs.

## 0.5.4 - 2024-08-15

Bumping lambda_regional version.

## 0.5.3 - 2024-08-15

Updating lambda_regional. Rename the original ssm parameter back to default.

## 0.5.2 - 2024-08-15

Include the signing profile name in SSM.

## 0.5.1 - 2024-08-14

Fixes a naming issue with the lambda regional config parameter name.

## 0.5.0 - 2024-08-14

Upgrading lambda_regional to store code signing arn in SSM.

## 0.4.0 - 2024-08-13

Adding lambda regional to workload accounts..

## 0.3.0 - 2024-08-12

Adding messaging_regional to the workload accounts.

## 0.2.0 - 2024-07-29

Update cloudwatchlogs_regional module version to pick up bug fix.

## 0.1.0 - 2024-07-15

Initial implementation of a workloads account module

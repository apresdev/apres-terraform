# Changelog

This change log is automatically generated.

## 2.1.4 - 2025-05-27

Add a secret for signing and encrypting cookies

## 2.1.3 - 2025-02-05

Fix volume bug for Fargate, updated docs, expose security group ID for consumption by other modules, remove redundant CloudWatch alarm and dashboard.

## 2.1.2 - 2024-12-13

Fix a bug in the target group protocol when SSL termination is required on the load balancer.

## 2.1.1 - 2024-12-13

Fix the missing SSL certificate ARN in the load balancer.

## 2.1.0 - 2024-12-03

Add an alarm for task crash loop detection.

## 2.0.1 - 2024-11-27

Fix bug with making load balancers public.

## 2.0.0 - 2024-10-30

Update names to match standards. This will cause a rebuild of most resources.

## 1.1.2 - 2024-10-18

Update providers, fix deprecation warning in the IAM role, add CloudWatch dashboard.

## 1.1.1 - 2024-10-02

Adds support for writing load balancer access logs to S3.

## 1.1.0 - 2024-09-26

Add support for securely delivering container secrets using Secrets Manager.

## 1.0.0 - 2024-09-25

Add support for public load balancers, and support both network/application load balancers.

## 0.2.0 - 2024-07-17

Enable use of NVMe drives in ECS on EC2 where supported.

## 0.1.0 - 2024-07-08

Initial commit of the ECS module

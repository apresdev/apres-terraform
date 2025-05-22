# Changelog

This change log is automatically generated.

## 0.6.1 - 2025-05-22

Minor fix to unit tests, fix to destroy terraform stack if the initial apply fails.

## 0.6.0 - 2025-05-20

Update module dependency version for Lambda and S3, and update the AWS provider version to latest.

## 0.5.2 - 2025-03-11

Fix missing attribute on provisioned dashboards.

## 0.5.1 - 2025-03-11

Fix bug for provisioned dashboard updates not propagating to Grafana, add consistent tagging to provisioned dashboards.

## 0.5.0 - 2025-03-11

Update Grafana Configurator and NAT Instance provisioned dashboards, add provisioned dashboards for ECS Clusters and Landlord.

## 0.4.0 - 2025-03-07

Add capability to add email subscriptions to the default SNS alert topic.

## 0.3.0 - 2025-03-07

Update lambda version to pick up fix for race condition in downloading the lambda configurator binary.

## 0.2.0 - 2025-03-05

Update Lambda version for the missing data alerts fix.

## 0.1.2 - 2025-02-10

Bump S3 module and AWS provider version to deal with bug in the provider.

## 0.1.1 - 2024-12-05

Add a standard Lambda dashboard.

## 0.1.0 - 2024-11-28

Initial creation of the Managed Grafana module.

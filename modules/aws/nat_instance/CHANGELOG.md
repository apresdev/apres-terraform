# Changelog

This change log is automatically generated.

## 1.3.3 - 2026-05-22

Update AWS provider lock file to 6.46.0

## 1.3.2 - 2026-05-22

Add git:: prefix to HTTPS module sources

## 1.3.1 - 2026-05-22

Switched source from SSH to HTTPS

## 1.3.0 - 2024-12-16

Switch interface security group attachment to facilitate replacement.

## 1.2.1 - 2024-12-16

Use name_prefix in IAM policy to support multi-instance deployments.

## 1.2.0 - 2024-12-13

Switch names to match Apres standards, and IAM artifacts to use name_prefix to support deploying to multiple regions in the same account, or even multiple instances in the same region.

## 1.1.0 - 2024-09-05

Add permissions for the NAT instances to view its own tags. Also remove the filter for the cloudwatch agent network metrics, since the interface names differ on various instance types.

## 1.0.2 - 2024-09-03

Add all dimensions to custom CloudWatch metrics.

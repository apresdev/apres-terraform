# Changelog

This change log is automatically generated.

## 1.2.0 - 2024-12-13

Switch names to match Apres standards, and IAM artifacts to use name_prefix to support deploying to multiple regions in the same account, or even multiple instances in the same region.

## 1.1.0 - 2024-09-05

Add permissions for the NAT instances to view its own tags. Also remove the filter for the cloudwatch agent network metrics, since the interface names differ on various instance types.

## 1.0.2 - 2024-09-03

Add all dimensions to custom CloudWatch metrics.

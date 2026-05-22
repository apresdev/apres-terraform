# Changelog

This change log is automatically generated.

## 2.4.2 - 2026-05-22

Add git:: prefix to HTTPS module sources

## 2.4.1 - 2026-05-22

Switched source from SSH to HTTPS

## 2.4.0 - 2025-02-11

The NAT image name was based on Amazon Linux 2, but should be using Amazon Linux 2023. The Amazon Linux 2 image is no longer available.

## 2.3.3 - 2024-12-16

Pick up fix from nat_instance module to handle replacement of security groups and ENI attachments.

## 2.3.2 - 2024-12-16

Bug fixes for IAM artifacts names when deploying to multiple regions.

## 2.3.1 - 2024-12-16

Update required permissions in README.md for the v2.3 change.

## 2.3.0 - 2024-12-13

Enable VPC module to be deployed in multiple regions in one AWS account.

## 2.2.0 - 2024-09-06

Bump NAT instance version to pick up CloudWatch Agent changes for more metrics.

## 2.1.0 - 2024-09-05

Update VPC module to use versioned NAT module, add a Grafana dashboard for the NAT instances.

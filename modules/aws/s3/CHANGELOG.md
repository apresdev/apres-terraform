# Changelog

This change log is automatically generated.

## 4.3.1 - 2026-05-22

Switched source from SSH to HTTPS

## 4.3.0 - 2025-07-29

Add mandatory account and region variables, to prevent recreating buckets when Terraform or OpenTofu defers the lookup.

## 4.2.0 - 2025-04-07

Switch the flag used to determine if the replication source bucket is in a different account to a boolean to deal with terraform race conditions.

## 4.1.0 - 2025-03-20

Fix the ARN for local bucket encryption when in replication scenarios, change argument to match actual usage.

## 4.0.0 - 2025-03-18

Add support for S3 replication, change encryption algorithm input to match the S3 documentation.

## 3.1.1 - 2025-02-10

Work around an AWS provider bug (https://github.com/hashicorp/terraform-provider-aws/issues/41268) by making the filter portion of the S3 lifecycle rule dynamic.

## 3.1.0 - 2024-12-19

Adding support for CORS rules in S3 module.

## 3.0.1 - 2024-10-02

Add validation for KMS and checkov skip when encryption is AES256

## 3.0.0 - 2024-10-01

Adds a default lifecycle rule, enabling intelligent tiering, deletes old version after 30 days, and aborts incomplete multipart uploads after seven days.

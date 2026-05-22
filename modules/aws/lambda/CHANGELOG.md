# Changelog

This change log is automatically generated.

## 1.2.2 - 2026-05-22

Switched source from SSH to HTTPS

## 1.2.1 - 2025-11-17

Fix bug in ordering when using a source_file instead of a zip_file.

## 1.2.0 - 2025-07-02

Upgrade the AWS provider to v6 and add support for Lambda@Edge.

## 1.1.2 - 2025-04-01

Bug fix to add source hash in test situations.

## 1.1.1 - 2025-04-01

Add the `invoke_arn` to the module outputs..

## 1.1.0 - 2025-03-27

Add ability to disable code signing for testing purposes, specifically for LocalStack where code signing is not supported.

## 1.0.0 - 2025-03-07

Change how source and zip files are managed to avoid race conditions.

## 0.7.0 - 2025-03-06

Switch to using source_hash on the binary upload to S3 to work around etag limitations. Upgrade providers.

## 0.6.0 - 2025-01-30

Update docs for Lambda's in VPCs and potentially long destruction times, plus some tests around it.

## 0.5.2 - 2025-01-23

Add outputs of ID and ARN's of the security group and dead letter queue resources.

## 0.5.1 - 2024-12-02

Minor fix to deal with the race condition on deploying a lambda to a new AWS account.

## 0.5.0 - 2024-11-29

Add possible overrides for code signing name and ARN to handle Terraform dependencies better.

## 0.4.0 - 2024-11-27

Remove source hash on binary files that was causing terraform plans to fail when the binary wasn't already on disk.

## 0.3.0 - 2024-10-29

Fix IAM artifacts to use name_prefix to support multi-region deployments.

## 0.2.1 - 2024-10-16

Fix bug where an updated local lambda package will not re-upload, fix timeout default, and update providers.

## 0.2.0 - 2024-08-23

Added feature `skip_zip` to allow users to skip the archive creation if they already have a zipped binary (defaults to off).

## 0.1.0 - 2024-08-16

Adding the initial version of the lambda module.

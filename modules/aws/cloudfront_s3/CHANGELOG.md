# Changelog

This change log is automatically generated.

## 1.6.1 - 2026-05-22

Switched source from SSH to HTTPS

## 1.6.0 - 2025-06-24

Add support for Lambda@Edge for Cloudfront.

## 1.5.2 - 2025-03-25

Fix the KMS policy on the KMS key used for logging bucket so CloudFront can write logs.

## 1.5.1 - 2025-03-21

Add missing KMS key policy on destination bucket in replication situations.

## 1.5.0 - 2025-03-21

Pick up S3 ARN fix, use distinct KMS keys for content and logging buckets.

## 1.4.2 - 2025-03-20

Fix bug for duplicate bucket policy for source replication.

## 1.4.1 - 2025-03-20

Fix internal reference to S3 when cloudfront_s3 is the source of replication.

## 1.4.0 - 2025-03-19

Add support for S3 bucket replication, and fix CloudFront logging.

## 1.3.0 - 2025-03-03

Only create Route53 entries if they can be created in the domain passed in, update docs on certificates and Route53.

## 1.2.0 - 2025-02-25

Add Route53 support, fix a bug in S3 lifecycles.

## 1.1.1 - 2025-02-10

Bump S3 module and AWS provider version to deal with bug in the provider.

## 1.1.0 - 2024-12-19

Adding support to enable browser based uploads to the S3 bucket (enabling CORS).

## 1.0.0 - 2024-11-01

Fix names and replace inline WAF module with the Apres WAF module.

## 0.2.2 - 2024-10-10

Bump s3::apres-terraform from 2.0.1 to 3.0.1 in /modules/aws/cloudfront_s3

## 0.2.1 - 2024-09-23

fix default SPA error responses in cloudfront_s3 module

## 0.2.0 - 2024-09-23

Add variable for custom error responses and default behaviour for SPA

## 0.1.1 - 2024-07-02

Update bug when the Name variable is upper case.

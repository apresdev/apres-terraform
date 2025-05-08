# Changelog

This change log is automatically generated.

## 0.13.1 - 2025-05-08

Update the Landlord image to latest that includes new diagnostics and logging.

## 0.13.0 - 2025-04-29

Add TenantUser in the response to the InviteToTenant API request

## 0.12.0 - 2025-04-28

Fix Terraform version in Landlord console container

## 0.11.9 - 2025-04-23

Add support for passing the version of the terraform module to the Landlord container.

## 0.11.8 - 2025-04-23

Update AWS permissions for Landlord

## 0.11.7 - 2025-04-23

Fix Landlord version.

## 0.11.6 - 2025-04-23

Landlord image was missing its embedded version leading it to display "N/A" for the version.

## 0.11.5 - 2025-04-22

Update Landlord to fix changing roles being properly reflected in AWS Cognito.

## 0.11.4 - 2025-04-17

Update to latest permissions based on `landlord iam`

## 0.11.3 - 2025-04-16

Update latest Landlord API -- fixes UserID result

## 0.11.2 - 2025-04-16

The custom:impersonate_user claim was added with the wrong length (32 not 36). And Cognito is so kind to make it impossible to change the length or even delete the claim once it has been configured.

## 0.11.1 - 2025-04-16

Fix the missing definition for the impersonate_user field

## 0.11.0 - 2025-04-16

Update to latest Landlord image. Includes the addition of impersonated tenant profile fields on RetrieveSubject

## 0.10.0 - 2025-04-14

Add `custom:user` claim for the Landlord user ID

## 0.9.2 - 2025-04-08

Update Landlord container to latest

## 0.9.1 - 2025-03-28

Upgrade to latest landlord image

## 0.9.0 - 2025-03-28

Add support for scaling the number of ECS tasks.

## 0.8.2 - 2025-03-26

Upgrade lambda dependency

## 0.8.1 - 2025-03-26

Upgrade Landlord image to latest

## 0.8.0 - 2025-03-25

Add ability to override user pool / client names

## 0.7.0 - 2025-03-24

Add support for defining profile fields at deployment time.

## 0.6.0 - 2025-03-06

TODO Add your changelog message, without any linebreaks, keep the *Changelog:* at the beginning of the line. The message will be automatically written to CHANGELOG.md in your module.

## 0.5.0 - 2025-03-05

Add support for Cognito email configuration.

## 0.4.1 - 2025-03-04

Bump API Gateway version for regional certificate fix.

## 0.4.0 - 2025-03-04

Setup custom domain on the API Gateway.

## 0.3.0 - 2025-02-28

Fix ECS deploy to use correct user pool name.

## 0.2.0 - 2025-02-27

Add Cognito ID and ARN outputs.

## 0.1.0 - 2025-02-26

Initial creation of the landlord module

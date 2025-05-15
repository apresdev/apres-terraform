# Getting Started with Apres Foundations

## Prerequisites

The following assumptions are made:

  1. You are using GitHub for source code management
  2. You are deploying to AWS

The documentation assumes the following knowledge:

  1. Basic knowledge of GitHub, including how to open Pull Requests and how
    to monitor GitHub Actions.
  2. Familiarity with the AWS Console, including how to navigate between
     accounts and regions.

To get access to the Apres resources, supply your GitHub username to Apres.
They will grant you access to several private repositories in the `apresdev`
GitHub Organization:

  * `apresdev/apres-terraform` - this is where the Apres Terraform Modules
   required for Foundations are stored.
  * `apresdev/cftc-template` - the template for the Custom Control Tower
   Configuration. Also known as Customizations for AWS Control Tower (CfCT).
  * `apresdev/foundations-template` - the template for deploying the core
   configuration and service across your AWS accounts

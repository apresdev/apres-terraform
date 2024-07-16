# Getting Started with Apres - Part 1 - Apres Foundations

## Table of Contents
1. [Setup Control Tower Customizations (CfCT)](#1-setup-control-tower-customizations-cfct)
2. [Create a GitHub repository to manage CfCT](#2-create-a-github-repository-to-manage-cfct)
3. [Create a GitHub repository to manage core infrastructure](#3-create-a-github-repository-to-manage-core-infrastructure)
4. [Begin deploying your services](#4-begin-deploying-your-services)


## Background

Apres primarily uses Terraform to configure and deploy services. Terraform requires both some form
of state management and credentials to AWS, which in turn requires some bootstrapping.

Service Control Policies are a very strong way of putting guardrails around your AWS organization,
which also needs to be managed.

To accomplish both the Terraform bootstrapping and Service Control Policies management,
Apres recommends using the
[Customizations for AWS Control Tower](https://docs.aws.amazon.com/controltower/latest/userguide/cfct-overview.html) (CfCT)
to manage and customize your AWS accounts.

## High Level Setup

The high level steps are:
1. Install Customizations for AWS Control Tower (CfCT) into your root account.
1. Create and configure a new GitHub repository in your org based on an Apres template repository, link it to CfCT
1. Use that repo to deploy Terraform state and AWS IAM artifacts that grant permissions to your repositories
1. Create a second GitHub repository based on the Apres Foundations template repository to deploy Terraform resources to your AWS accounts
1. Begin deploying your services

## 1. Setup Control Tower Customizations (CfCT)

Login to your AWS root account as a user with administrator privileges. Follow the AWS instructions
at [Step 1. Launch the stack](https://docs.aws.amazon.com/controltower/latest/userguide/step1.html), with two key modifications:
1. Step 2 references regions - use the region selector pick the home region you selected earlier.
2. Under *Parameters* change *AWS CodePipeline Source* to *AWS CodeCommit*.

The rest of the options can be left as defaults.

## 2. Create a GitHub repository to manage core infrastructure

In this step you will be creating a repository which will contain Terraform code to manage core infrastructure including:
* Security tooling - GuardDuty and SecurityHub
* FinOps tools - tagging, Cost Anomaly Detection, Budgets
* Per-AWS account configuration

For this step we'll only be creating the repository from a template, so we can use that name in step 3. In Step 4 we
will come back and finish configuring the repository.

Navigate to [https://github.com/apresdev/foundations-template](https://github.com/apresdev/foundations-template). Follow the instructions
at GitHub's [Creating a repository from a template](https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-repository-from-a-template)
instructions to create a repository in _your_ GitHub organization based on the template.

The name for this repository is your choice, Apres recommends using the repository name `foundations` or `core-infrastructure`.

## 3. Create a GitHub repository to manage CfCT

Navigate to [https://github.com/apresdev/cfct-template](https://github.com/apresdev/cfct-template). Follow the instructions
at GitHub's [Creating a repository from a template](https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-repository-from-a-template)
instructions to create a repository in _your_ GitHub organization based on the template. Apres recommends using the repository name
`custom-control-tower-configuration` to match what is in AWS CodeCommit.

Follow the setup instructions in the README of your new repository before continuing.

## 4. Deploy the core infrastructure

Let's review what you've setup so far:
* an AWS Organization with OU's and accounts
* integration with your IDP (Google or Microsoft 365)
* setup a repository based on the Apres Foundations template
* setup a repository for CfCT, and deployed to your AWS accounts:
  * A GitHub OIDC connecter
  * Terraform state resources
  * AWS IAM Roles and permissions to allow the Apres Foundations repository to deploy

You are ready to start deploying the Apres Foundations. Follow the instructions in the README.md file in
the GitHub repository you created in [Step 2](#2-create-a-github-repository-to-manage-core-infrastructure), also
available [here](https://github.com/apresdev/foundations-template/blob/main/README.md).

## Next Steps

Follow the directions in [Part 3 - Deploying your services](./getting-started-part-3-deploy-your-services.md)
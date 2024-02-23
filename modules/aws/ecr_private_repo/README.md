# Apres ECR Private Repository Terraform module

## Overview

Creates an ECR Private Repository, and IAM artifacts for the GitHub Repo to use to push/pull images.
The role created has the pattern `GitHubActionsECRServiceRole${name}`, and is provided at an output. For example
if the repo name provided is `acme` then the role name becomes `GitHubActionsECRServiceRoleAcme` with the capital A.

For example, let's create an image called `acme` and grant the `apresdev/acme` repo permission to push to it.
In the deploy tf (hint: [./aws-core/artifacts/us-east-2/variables.tf](./aws-core/artifacts/us-east-2/variables)) set the variable:
```hcl
variable "managed_repos" {
  # ...
  default = [
    {
      ecr_repo_name                    = "etl"
      github_repo_subject_claim_filter = "repo:apresdev/acme:*"
      shared_aws_org_for_pull          = ["o-abc1234/r-a012/*"]
    }
  ]
}
```

And then the sample workflow to push to ECR from a remote repo:
```yaml
jobs:
  build-and-push:
    name: Build and Push Docker Image
    runs-on: ubuntu-latest

    steps:
      - name: Check out code
        uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          # This role is created by the ecr_private_repo module, and only has permissions
          # to push a container to the "acme" ECR repo.
          role-to-assume: arn:aws:iam::123456789012:role/GitHubActionsECRServiceRoleEtl
          # append workflow name to session name, max 64 characters. Repo name is already in the IAM event.
          role-session-name: GitHubActionsAcmeBuildAndPush
          aws-region: us-east-2

      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v2

      - name: Build and tag Docker image
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          ECR_REPOSITORY: etl # name of this repo
          IMAGE_TAG: ${{ github.sha }}
        run: docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .

      - name: Push Docker image to ECR
        # Only do this on push to main.
        if: github.ref == 'refs/heads/main'
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          ECR_REPOSITORY: etl # name of this repo
          IMAGE_TAG: ${{ github.sha }}
        run: docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
dd
```

## Security Scanning

Scanning is enabled at the account level, not at the repo level.


<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.6.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.35.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_ecr_repository_policy.allow_pull](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository_policy) | resource |
| [aws_iam_policy.github_actions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy_attachment.github_actions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy_attachment) | resource |
| [aws_iam_role.github_actions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.allow_pull](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.github_actions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.github_actions_trust](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_default_tags"></a> [default\_tags](#input\_default\_tags) | Default set of tags to be applied to all resources | `map(string)` | <pre>{<br>  "application": "ECR",<br>  "managed-by": "terraform",<br>  "owner": "Engineering"<br>}</pre> | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment Name, used for tagging AWS resources. | `string` | `"Dev"` | no |
| <a name="input_github_repo_subject_claim_filter"></a> [github\_repo\_subject\_claim\_filter](#input\_github\_repo\_subject\_claim\_filter) | The GitHub repo to trust for GitHub Actions. Also known as the Subject claim filter for<br>  valid tokens. Must be in the format of<br>  repo:apresdev/repo-name:ref:refs/heads/branch-or-tag, can be a comma delimited<br>  list if there is more than one. Example:<br>  * repo:apresdev/iac:ref:refs/heads/main means only the main branch of the apresdev/iac repo can assume the role.<br>  * repo:apresdev/iac:* means any branch or tag of the apresdev/iac repo can assume the role.<br>  See https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect#example-subject-claims<br>  for examples of filtering by branch or deployment environment. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Name of the ECR repo | `string` | n/a | yes |
| <a name="input_shared_aws_org_for_pull"></a> [shared\_aws\_org\_for\_pull](#input\_shared\_aws\_org\_for\_pull) | Path to an AWS Organizations OU to share the repo to. This is translated to a condition using the<br>  aws:PrincipalOrgPaths condition key. See https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_condition-keys.html#condition-keys-principalorgpaths for more information.<br>  A valid example might "org-id/root-ou-id/*" (Remember to use the Org ID as the root!) | `list(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_github_iam_role_arn"></a> [github\_iam\_role\_arn](#output\_github\_iam\_role\_arn) | GitHub OIDC IAM Role ARN |
| <a name="output_github_iam_role_name"></a> [github\_iam\_role\_name](#output\_github\_iam\_role\_name) | GitHub OIDC IAM Role Name |
| <a name="output_repository_arn"></a> [repository\_arn](#output\_repository\_arn) | Repository ARN |
| <a name="output_repository_url"></a> [repository\_url](#output\_repository\_url) | Repository URL |
<!-- END_TF_DOCS -->
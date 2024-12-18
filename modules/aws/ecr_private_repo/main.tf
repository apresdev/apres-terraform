locals {
  tags = merge(
    var.extra_tags,
    tomap({
      "application" = var.application
      "component"   = var.component
      "environment" = var.environment
      "owner"       = var.owner
      "managed-by"  = "Terraform"
    })
  )

  # whether or not to create iam artifacts
  create_iam_artifacts = var.primary_region == "" || data.aws_region.current.name == var.primary_region ? true : false

  github_oidc_iam_role_name   = "GitHubActionsECRServiceRole${title(var.name)}"
  github_oidc_iam_policy_name = "GitHubActionsECRServicePolicy${title(var.name)}"

  # GitHub OIDC ARN - name is static so we can calculate it.
  github_oidc_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
}

resource "aws_ecr_repository" "repo" {
  #checkov:skip=CKV_AWS_136:AES-256 encryption is sufficient.
  #checkov:skip=CKV_AWS_163:Scanning will be enabled at the account level with Inspector integration.
  name                 = var.name
  image_tag_mutability = "IMMUTABLE"

  # Scanning is enabled at the account level with Inspector integration, not here.
  tags = merge(
    local.tags,
    {
      Name = var.name
    },
  )

  encryption_configuration {
    encryption_type = "AES256"
  }
}

# This policy is attached to the ECR repo, and allows the shared AWS org to pull images.
data "aws_iam_policy_document" "allow_pull" {
  statement {
    sid    = "PullAccess"
    effect = "Allow"

    # see note at this link as to why these are both "*"
    # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document#principals
    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]
    condition {
      test     = "ForAnyValue:StringLike"
      variable = "aws:PrincipalOrgPaths"
      values   = var.shared_aws_org_for_pull
    }
  }
}

resource "aws_ecr_repository_policy" "allow_pull" {
  repository = aws_ecr_repository.repo.name
  policy     = data.aws_iam_policy_document.allow_pull.json
}


# This is the policy the remote GitHub repos will use.
data "aws_iam_policy_document" "github_actions" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:CompleteLayerUpload",
      "ecr:GetAuthorizationToken",
      "ecr:UploadLayerPart",
      "ecr:InitiateLayerUpload",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:DescribeImageScanFindings"
    ]
    # can't use the ARN directly from the resource, since we need to allow all regions, not just
    # the current one.
    resources = ["arn:aws:ecr:*:${data.aws_caller_identity.current.account_id}:repository/${var.name}"]
  }

  # Add separate statement for ecr:GetAuthorizationToken because resource is necessarily "*"
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "github_actions" {
  count       = local.create_iam_artifacts ? 1 : 0
  name        = local.github_oidc_iam_policy_name
  path        = "/"
  description = "IAM policy for GitHub Actions for ECR - ${var.name}"
  policy      = data.aws_iam_policy_document.github_actions.json
  tags = merge(
    local.tags,
    {
      Name = local.github_oidc_iam_policy_name
    },
  )
}

data "aws_iam_policy_document" "github_actions_trust" {
  #checkov:skip=CKV_AWS_358:False positive
  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [local.github_oidc_arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [var.github_repo_subject_claim_filter]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
  }

}

# This is the role used by GitHub Actions via the OIDC provider.
resource "aws_iam_role" "github_actions" {
  count              = local.create_iam_artifacts ? 1 : 0
  name               = local.github_oidc_iam_role_name
  description        = "IAM Role for GitHub Actions for ECR"
  assume_role_policy = data.aws_iam_policy_document.github_actions_trust.json
  tags = merge(
    local.tags,
    {
      Name = local.github_oidc_iam_role_name
    },
  )
}

resource "aws_iam_policy_attachment" "github_actions" {
  count      = local.create_iam_artifacts ? 1 : 0
  name       = "GitHubActionsOIDCPolicyAttachment"
  roles      = [aws_iam_role.github_actions[0].name]
  policy_arn = aws_iam_policy.github_actions[0].arn
}

# moved role and policy after v1.1.0
moved {
  from = aws_iam_role.github_actions
  to   = aws_iam_role.github_actions[0]
}
moved {
  from = aws_iam_policy.github_actions
  to   = aws_iam_policy.github_actions[0]
}
moved {
  from = aws_iam_policy_attachment.github_actions
  to   = aws_iam_policy_attachment.github_actions[0]
}
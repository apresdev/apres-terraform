locals {
  # Need to remove the current region or else the deploy will throw an error.
  security_hub_regions = setsubtract(var.security_hub_regions, [data.aws_region.current.name])
  configuration_type   = length(local.security_hub_regions) > 0 ? "CENTRAL" : "LOCAL"
}

# Only create this if the list of regions, excluding the current one, is > 0, else it'll fail because there's nothing to aggregate.
resource "aws_securityhub_finding_aggregator" "default" {
  count             = length(local.security_hub_regions) > 0 ? 1 : 0
  linking_mode      = var.security_hub_linking_mode
  specified_regions = local.security_hub_regions
}

# From the docs: This is an advanced Terraform resource. Terraform will automatically assume management
# of the Security Hub Organization Configuration without import and perform no actions
# on removal from the Terraform configuration.
resource "aws_securityhub_organization_configuration" "default" {
  # Aggregator needs to be created first.
  depends_on = [aws_securityhub_finding_aggregator.default]
  # Central configuration requires this to be false.
  auto_enable = false
  organization_configuration {
    configuration_type = local.configuration_type
  }
}

resource "aws_securityhub_configuration_policy" "default" {
  name        = "Default"
  description = "This is the default configuration policy"

  configuration_policy {
    service_enabled = true
    enabled_standard_arns = [
      "arn:aws:securityhub:${data.aws_region.current.name}::standards/aws-foundational-security-best-practices/v/1.0.0",
      "arn:aws:securityhub:::ruleset/cis-aws-foundations-benchmark/v/1.2.0",
    ]
    security_controls_configuration {
      disabled_control_identifiers = [
        # KMS.3: AWS KMS Keys should not be deleted unintentionally - this occurs regularly in automated test environments.
        "KMS.3",
        # IAM.6: Hardware MFA should be enabled for the root user - we disable root logins by not having a password
        # AWS recommends disabling in https://docs.aws.amazon.com/securityhub/latest/userguide/controls-to-disable.html
        "IAM.6",
        # IAM.9: MFA should be enabled for the root user - we disable root logins by not having a password
        # AWS recommends disabling in https://docs.aws.amazon.com/securityhub/latest/userguide/controls-to-disable.html
        "IAM.9",
        # IAM.7,11-15: Password policy controls - we manage this in the aws_accounts_config_global module.
        # AWS recommends disabling in https://docs.aws.amazon.com/securityhub/latest/userguide/controls-to-disable.html
        "IAM.7",
        "IAM.11",
        "IAM.12",
        "IAM.13",
        "IAM.14",
        "IAM.15",
        # EC2.25: EC2 Launch Templates should not assign public IPs - we do for NAT instances in the VPC templateabs(
        "EC2.25",
        # EC2.9: EC2 instances should not have a public IP address - we do for NAT instances in the VPC template
        "EC2.9",
        # CloudTrail.2: CloudTrail should have have encryption at-rest enabled - Managed by ControlTower and not enabled by CT.
        "CloudTrail.2",
        # Macie.1: Macie should be enabled - it's not enabled for now.
        # See https://github.com/apresdev/apres-terraform/issues/27
        "Macie.1",
        # S3.1: Account wide setting for blocking all public access - we're managing this in the S3 module.
        # See https://github.com/apresdev/apres-terraform/issues/145
        "S3.1",
        # KMS.1/2: Principals in roles should not have access to kms:Decrypt on all KMS keys - we need this
        # for the deployer roles which manage the KMS keys.
        # AWS recommends disabling in https://docs.aws.amazon.com/securityhub/latest/userguide/controls-to-disable.html
        "KMS.1",
        "KMS.2",
        # Inspector.1/2/4: Not enabled yet
        # See https://github.com/apresdev/apres-terraform/issues/18
        "Inspector.1",
        "Inspector.2",
        "Inspector.4",
        # ECR1,3: ECR should have scanning and lifecycle policies.
        # See https://github.com/apresdev/apres-terraform/issues/147
        "ECR.1",
        "ECR.3"
      ]
    }
  }

  depends_on = [aws_securityhub_organization_configuration.default]
}

# Associate the policy with the whole organization
resource "aws_securityhub_configuration_policy_association" "default" {
  target_id = var.organization_root_id
  policy_id = aws_securityhub_configuration_policy.default.id
}

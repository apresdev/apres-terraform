# Create the AWS GuardDuty detector and enable the features for the detector.
#
# NOTE: It's unclear how and when, but sometimes AWS Organizations creates the detector,
# in which case you will have to do an import of the detector, see the README for details.
resource "aws_guardduty_detector" "default" {
  enable = true
  tags = merge(
    local.tags,
    {
      Name = "SecurityHubCriticalHighFindings"
    },
  )
}

resource "aws_guardduty_organization_configuration" "default" {
  auto_enable_organization_members = "ALL"
  detector_id                      = aws_guardduty_detector.default.id
}

resource "aws_guardduty_organization_configuration_feature" "eks_runtime_monitoring" {
  count       = var.guardduty_enable_eks_protection ? 1 : 0
  detector_id = aws_guardduty_detector.default.id
  name        = "EKS_RUNTIME_MONITORING"
  auto_enable = "ALL"
  additional_configuration {
    name        = "EKS_ADDON_MANAGEMENT"
    auto_enable = "ALL"
  }
}

resource "aws_guardduty_organization_configuration_feature" "s3" {
  count       = var.guardduty_enable_s3_protection ? 1 : 0
  detector_id = aws_guardduty_detector.default.id
  name        = "S3_DATA_EVENTS"
  auto_enable = "ALL"
}

resource "aws_guardduty_organization_configuration_feature" "rds" {
  count       = var.guardduty_enable_rds_protection ? 1 : 0
  detector_id = aws_guardduty_detector.default.id
  name        = "RDS_LOGIN_EVENTS"
  auto_enable = "ALL"
}

resource "aws_guardduty_organization_configuration_feature" "lambda" {
  count       = var.guardduty_enable_lambda_protection ? 1 : 0
  detector_id = aws_guardduty_detector.default.id
  name        = "LAMBDA_NETWORK_LOGS"
  auto_enable = "ALL"
}

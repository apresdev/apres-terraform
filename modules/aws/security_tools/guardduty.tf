# Reference the detector created by AWS Organizations.
data "aws_guardduty_detector" "default" {}

resource "aws_guardduty_organization_configuration" "default" {
  auto_enable_organization_members = "ALL"
  detector_id                      = data.aws_guardduty_detector.default.id
}

resource "aws_guardduty_detector_feature" "eks_runtime_monitoring" {
  count       = var.guardduty_enable_eks_protection ? 1 : 0
  detector_id = data.aws_guardduty_detector.default.id
  name        = "EKS_RUNTIME_MONITORING"
  status      = "ENABLED"
  additional_configuration {
    name   = "EKS_ADDON_MANAGEMENT"
    status = "ENABLED"
  }
}

resource "aws_guardduty_detector_feature" "s3" {
  count       = var.guardduty_enable_s3_protection ? 1 : 0
  detector_id = data.aws_guardduty_detector.default.id
  name        = "S3_DATA_EVENTS"
  status      = "ENABLED"
}

resource "aws_guardduty_detector_feature" "rds" {
  count       = var.guardduty_enable_rds_protection ? 1 : 0
  detector_id = data.aws_guardduty_detector.default.id
  name        = "RDS_LOGIN_EVENTS"
  status      = "ENABLED"
}

resource "aws_guardduty_detector_feature" "lambda" {
  count       = var.guardduty_enable_lambda_protection ? 1 : 0
  detector_id = data.aws_guardduty_detector.default.id
  name        = "LAMBDA_NETWORK_LOGS"
  status      = "ENABLED"
}

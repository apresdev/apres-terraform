data "aws_iam_policy_document" "rds_monitoring" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "rds_monitoring" {
  name_prefix        = "${local.name}-rdsmonitor"
  assume_role_policy = data.aws_iam_policy_document.rds_monitoring.json
  tags = merge(
    local.tags,
    {
      "Name" = "${local.name}-monitoring"
    }
  )
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

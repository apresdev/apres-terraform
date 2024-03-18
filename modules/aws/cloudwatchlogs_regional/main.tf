locals {
  tags = merge(
    var.default_tags,
    tomap({ "environment" = var.environment })
  )
}

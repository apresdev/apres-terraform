locals {
  tags = merge(
    var.default_tags,
    tomap({
      environment = var.environment
      managed-by  = "Terraform"
      application = var.application
      component   = var.component
      owner       = var.owner
    })
  )
  table_name = "${data.aws_caller_identity.current.account_id}-${lower(var.environment)}-${data.aws_region.current.name}-${lower(var.name)}"

  # Auto-scaling defaults
  autoscaling_enabled = var.billing_mode == "PROVISIONED" && var.autoscaling_enabled
  write_capacity      = var.billing_mode == "PROVISIONED" ? var.write_capacity : null
  read_capacity       = var.billing_mode == "PROVISIONED" ? var.read_capacity : null
}

# The following best practices are applied to the table by default:
#
# CKV_AWS_28: Ensure DynamoDB point in time recovery (backup) is enabled
# CKV2_AWS_16: Ensure that Auto Scaling is enabled on your DynamoDB tables
#
# The following are applied if configured:
# CKV_AWS_119: Ensure DynamoDB Tables are encrypted using a KMS Customer Managed CMK
#
resource "aws_dynamodb_table" "default" {

  name                        = local.table_name
  billing_mode                = var.billing_mode
  table_class                 = var.table_class
  write_capacity              = local.write_capacity
  read_capacity               = local.read_capacity
  deletion_protection_enabled = var.deletion_protection_enabled

  ttl {
    enabled        = var.ttl_enabled
    attribute_name = var.ttl_attribute_name
  }

  #checkov:skip=CKV_AWS_28: Ensure DynamoDB point in time recovery (backup) is enabled
  point_in_time_recovery {
    enabled = var.point_in_time_recovery_enabled
  }

  #checkov:skip=CKV_AWS_119: Ensure DynamoDB Tables are encrypted using a KMS Customer Managed CMK
  server_side_encryption {
    enabled     = true
    kms_key_arn = var.encryption_kms_key_id
  }

  # Attribute settings
  hash_key  = var.hash_key
  range_key = var.range_key
  dynamic "attribute" {
    for_each = var.attributes

    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }

  dynamic "global_secondary_index" {
    for_each = var.global_secondary_indices
    content {
      name               = global_secondary_index.value.name
      hash_key           = global_secondary_index.value.hash_key
      range_key          = global_secondary_index.value.range_key
      write_capacity     = global_secondary_index.value.write_capacity
      read_capacity      = global_secondary_index.value.read_capacity
      projection_type    = global_secondary_index.value.projection_type
      non_key_attributes = global_secondary_index.value.non_key_attributes
    }
  }

  stream_enabled   = var.stream_enabled
  stream_view_type = var.stream_view_type

  tags = merge(
    local.tags,
    tomap({
      Name = local.table_name
    })
  )

  depends_on = [data.aws_caller_identity.current]

  #checkov:skip=CKV2_AWS_16: Ensure that Auto Scaling is enabled on your DynamoDB tables

}

#CKV2_AWS_16: Ensure that Auto Scaling is enabled on your DynamoDB tables
resource "aws_appautoscaling_target" "table_read" {
  count = local.autoscaling_enabled && length(var.autoscaling_read) > 0 ? 1 : 0

  max_capacity       = var.autoscaling_read["max_capacity"]
  min_capacity       = var.read_capacity
  resource_id        = "table/${aws_dynamodb_table.default.name}"
  scalable_dimension = "dynamodb:table:ReadCapacityUnits"
  service_namespace  = "dynamodb"

  depends_on = [aws_dynamodb_table.default]
}

#CKV2_AWS_16: Ensure that Auto Scaling is enabled on your DynamoDB tables
resource "aws_appautoscaling_policy" "table_read_policy" {
  count = local.autoscaling_enabled && length(var.autoscaling_read) > 0 ? 1 : 0

  name               = "DynamoDBReadCapacityUtilization:${aws_appautoscaling_target.table_read[0].resource_id}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.table_read[0].resource_id
  scalable_dimension = aws_appautoscaling_target.table_read[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.table_read[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBReadCapacityUtilization"
    }

    scale_in_cooldown  = lookup(var.autoscaling_read, "scale_in_cooldown", var.autoscaling_defaults["scale_in_cooldown"])
    scale_out_cooldown = lookup(var.autoscaling_read, "scale_out_cooldown", var.autoscaling_defaults["scale_out_cooldown"])
    target_value       = lookup(var.autoscaling_read, "target_value", var.autoscaling_defaults["target_value"])
  }

  depends_on = [aws_appautoscaling_target.table_read[0]]
}

#CKV2_AWS_16: Ensure that Auto Scaling is enabled on your DynamoDB tables
resource "aws_appautoscaling_target" "table_write" {
  count = local.autoscaling_enabled && length(var.autoscaling_write) > 0 ? 1 : 0

  max_capacity       = var.autoscaling_write["max_capacity"]
  min_capacity       = var.write_capacity
  resource_id        = "table/${aws_dynamodb_table.default.name}"
  scalable_dimension = "dynamodb:table:WriteCapacityUnits"
  service_namespace  = "dynamodb"

  depends_on = [aws_dynamodb_table.default]
}

#CKV2_AWS_16: Ensure that Auto Scaling is enabled on your DynamoDB tables
resource "aws_appautoscaling_policy" "table_write_policy" {
  count = local.autoscaling_enabled && length(var.autoscaling_write) > 0 ? 1 : 0

  name               = "DynamoDBWriteCapacityUtilization:${aws_appautoscaling_target.table_write[0].resource_id}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.table_write[0].resource_id
  scalable_dimension = aws_appautoscaling_target.table_write[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.table_write[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBWriteCapacityUtilization"
    }

    scale_in_cooldown  = lookup(var.autoscaling_write, "scale_in_cooldown", var.autoscaling_defaults["scale_in_cooldown"])
    scale_out_cooldown = lookup(var.autoscaling_write, "scale_out_cooldown", var.autoscaling_defaults["scale_out_cooldown"])
    target_value       = lookup(var.autoscaling_write, "target_value", var.autoscaling_defaults["target_value"])
  }

  depends_on = [aws_appautoscaling_target.table_write[0]]
}

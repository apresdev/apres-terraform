output "ecs_task_definition_arn" {
  value       = aws_ecs_task_definition.default.arn
  description = "ARN of the ECS Task Definition, includes the family and revision."
}

output "ecs_service_arn" {
  value       = aws_ecs_service.default.id
  description = "ARN of the ECS Service."
}

output "ecs_service_name" {
  value       = aws_ecs_service.default.name
  description = "Name of the ECS Service."
}

output "ecs_cluster_arn" {
  value       = aws_ecs_cluster.default.arn
  description = "ARN of the ECS Cluster."
}

output "ecs_cluster_name" {
  value       = aws_ecs_cluster.default.name
  description = "Name of the ECS Cluster."
}

output "ec2_asg_name" {
  value       = local.use_ec2 == 1 ? aws_autoscaling_group.ecs_asg[0].name : ""
  description = "Name of the ECS AutoScaling Group, or empty string if using Fargate."
}

output "ec2_asg_arn" {
  value       = local.use_ec2 == 1 ? aws_autoscaling_group.ecs_asg[0].arn : ""
  description = "ARN of the ECS AutoScaling Group, or empty string if using Fargate."
}

output "load_balancer_arn" {
  value       = var.create_load_balancer ? aws_lb.default[0].arn : ""
  description = "ARN of the Load Balancer if it was created, else an empty string."
}

output "load_balancer_dns_name" {
  value       = var.create_load_balancer ? aws_lb.default[0].dns_name : ""
  description = "FQDN of the Load Balancer if it was created, else an empty string."
}

output "load_balancer_target_group_arn" {
  value       = var.create_load_balancer ? aws_lb_target_group.default[0].arn : ""
  description = "ARN of the Load Balancer Target Group if it was created, else an empty string."
}

output "dashboard_url" {
  # Need to compute this, it's not available from the provider.
  value       = "https://${data.aws_region.current.name}.console.aws.amazon.com/cloudwatch/home#dashboards:name=${local.cw_dashboard_name}"
  description = "URL for the ECS Cluster Dashboard"
}
output "ecs_task_definition_arn" {
  value       = aws_ecs_task_definition.default.arn
  description = "ARN of the ECS Task Definition, includes the family and revision."
}

output "ecs_cluster_arn" {
  value       = aws_ecs_cluster.default.arn
  description = "ARN of the ECS Cluster."
}

output "ecs_cluster_name" {
  value       = aws_ecs_cluster.default.name
  description = "Name of the ECS Cluster."
}

output "ecs_service_security_group_id" {
  value       = aws_security_group.ecs.id
  description = "Security Group ID to be used for the task"
}

output "private_subnet_ids" {
  value       = data.aws_subnets.private.ids
  description = "List of private subnet IDs where the task will run"
}
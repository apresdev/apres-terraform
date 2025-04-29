output "ecs_task_definition_arn" {
  value       = module.ecs_standalone_task.ecs_task_definition_arn
  description = "ARN of the ECS Task Definition, includes the family and revision."
}

output "ecs_cluster_arn" {
  value       = module.ecs_standalone_task.ecs_cluster_arn
  description = "ARN of the ECS Cluster."
}

output "ecs_cluster_name" {
  value       = module.ecs_standalone_task.ecs_cluster_name
  description = "Name of the ECS Cluster."
}

output "private_subnet_ids" {
  value       = module.ecs_standalone_task.private_subnet_ids
  description = "List of private subnet IDs where the task will run"
}

output "ecs_service_security_group_id" {
  value       = module.ecs_standalone_task.ecs_service_security_group_id
  description = "Security Group ID to be used for the task"
}
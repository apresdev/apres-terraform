output "ecs_task_definition_arn" {
  value       = module.ecs.ecs_task_definition_arn
  description = "ARN of the ECS Task Definition, includes the family and revision."
}

output "ecs_service_arn" {
  value       = module.ecs.ecs_service_arn
  description = "ARN of the ECS Service."
}

output "ecs_service_name" {
  value       = module.ecs.ecs_service_name
  description = "Name of the ECS Service."
}

output "ecs_cluster_arn" {
  value       = module.ecs.ecs_cluster_arn
  description = "ARN of the ECS Cluster."
}

output "ecs_cluster_name" {
  value       = module.ecs.ecs_cluster_name
  description = "Name of the ECS Cluster."
}

output "ec2_asg_name" {
  value       = module.ecs.ec2_asg_name
  description = "Name of the ECS AutoScaling Group, or empty string if using Fargate."

}
output "ec2_asg_arn" {
  value       = module.ecs.ec2_asg_arn
  description = "ARN of the ECS AutoScaling Group, or empty string if using Fargate."
}

output "load_balancer_arn" {
  value       = module.ecs.load_balancer_arn
  description = "ARN of the Load Balancer if it was created, else an empty string."
}

output "load_balancer_dns_name" {
  value       = module.ecs.load_balancer_dns_name
  description = "FQDN of the Load Balancer if it was created, else an empty string."
}

output "load_balancer_target_group_arn" {
  value       = module.ecs.load_balancer_target_group_arn
  description = "ARN of the Load Balancer Target Group if it was created, else an empty string."
}
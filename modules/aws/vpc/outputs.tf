output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.vpc.id
}

output "nat_dashboard_url" {
  description = "URL for the NAT Instance Dashboard"
  value       = "https://${data.aws_region.current.name}.console.aws.amazon.com/cloudwatch/home#dashboards:name=${var.nat_instance_dashboard_name}"
}

output "private_subnet_ids" {
  description = "List of Private Subnet IDs"
  value       = aws_subnet.private_subnet[*].id
}

output "public_subnet_ids" {
  description = "List of Public Subnet IDs"
  value       = aws_subnet.public_subnet[*].id
}

output "persistence_subnet_ids" {
  description = "List of Persistence Subnet IDs"
  value       = aws_subnet.persistence_subnet[*].id
}
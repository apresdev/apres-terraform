output "master_password_secret_arn" {
  description = "ARN of the secret containing the master password for the RDS instance"
  value       = aws_secretsmanager_secret.rds_master_password.arn
}

output "master_password_kms_key_id" {
  description = "KMS Key ID used to encrypt the master password for the RDS instance"
  value       = aws_kms_key.default.key_id
}

output "master_password_kms_key_arn" {
  description = "KMS Key ARN used to encrypt the master password for the RDS instance"
  value       = aws_kms_key.default.arn
}

output "security_group_id" {
  description = "ID of the security group for the RDS instance"
  value       = aws_security_group.rds.id
}

output "security_group_arn" {
  description = "ARN of the security group for the RDS instance"
  value       = aws_security_group.rds.arn
}

output "endpoint" {
  description = "DNS address of the RDS cluster"
  value       = aws_rds_cluster.default.endpoint
}

output "cluster_members" {
  description = "List of RDS cluster members"
  value       = aws_rds_cluster.default.cluster_members
}

output "reader_endpoint" {
  description = "Read-only endpoint for the Aurora cluster, automatically load-balanced across replicas"
  value       = aws_rds_cluster.default.reader_endpoint
}

output "cluster_id" {
  description = "ID of the RDS cluster"
  value       = aws_rds_cluster.default.id
}

output "arn" {
  description = "ARN of the RDS cluster"
  value       = aws_rds_cluster.default.arn
}

output "port" {
  description = "Database Port"
  value       = aws_rds_cluster.default.port
}

output "ca_certificate_identifier" {
  description = "The identifier of the CA certificate for the RDS instance, required to create TLS connections"
  value       = aws_rds_cluster.default.ca_certificate_identifier
}
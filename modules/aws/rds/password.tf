resource "random_password" "master_password" {
  # The password will be constant until the DB instance identifier changes, which should be never.
  keepers = {
    db_instance_identifier = local.name
  }
  length = 16
  # RDS only allows only a very small subset of special characters, which cause seemingly random problems so
  # we're disabling them.
  special = false
}

# create the secret
resource "aws_secretsmanager_secret" "rds_master_password" {
  #checkov:skip=CKV2_AWS_57:Rotating the master password is not supported as it will break the deployment.
  # Need to use a prefix instead of a static name for dev/test environments, since when a secret is deleted, it
  # is only marked for deletion, causing future deploys to fail.
  name_prefix = local.name
  description = "Master password for RDS instance ${local.name}"
  kms_key_id  = aws_kms_key.default.key_id
  tags = merge(
    local.tags,
    {
      "Name" = local.name
    }
  )
}

# store the password in the secret
resource "aws_secretsmanager_secret_version" "rds_master_password" {
  secret_id     = aws_secretsmanager_secret.rds_master_password.id
  secret_string = random_password.master_password.result
}
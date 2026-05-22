module "rds" {
  source = "../../"

  name        = var.name
  application = "UnitTest"
  component   = "RDS"
  environment = var.environment

  vpc_environment_tag = var.vpc_environment_tag

  engine         = var.engine
  engine_version = var.engine_version

  database_name             = var.database_name
  master_username           = var.master_username
  db_parameter_group_family = var.db_parameter_group_family

  instance_class     = var.instance_class
  serverless         = var.serverless
  serverless_scaling = var.serverless_scaling
  is_production      = false # set this or we won't be able to delete the db

  backup_window      = var.backup_window
  maintenance_window = var.maintenance_window

  allow_ingress_from_all_private_subnets = var.allow_ingress_from_all_private_subnets
  allow_ingress_security_groups          = var.allow_ingress_security_groups

  db_cluster_parameters  = var.db_cluster_parameters
  db_instance_parameters = var.db_instance_parameters
}

module "lambda" {
  #checkov:skip=CKV_TF_1:False positive, we are not using a hash because we use the tagged version.
  source        = "git::https://github.com/apresdev/apres-terraform.git//modules/aws/lambda?ref=rel/lambda/1.2.3"
  name          = var.name
  runtime       = "provided.al2023"
  binary_path   = "rdslambda/rdslambda.zip"
  skip_zip      = true
  handler       = "bootstrap"
  architectures = ["arm64"]
  environment   = var.environment
  owner         = "Testing"
  application   = "UnitTests"
  component     = "UnitTests"
  timeout       = 30
  vpc = {
    enabled         = true
    environment_tag = var.vpc_environment_tag
  }
  environment_variables = {
    RDS_HOST                = module.rds.endpoint
    RDS_PORT                = module.rds.port
    RDS_ENGINE              = var.engine # pass in whether it's mysql or postgres
    RDS_DATABASE_NAME       = var.database_name
    RDS_MASTER_USER         = var.master_username
    RDS_MASTER_PASSWORD_ARN = module.rds.master_password_secret_arn
  }
}

# Let the lambda access the RDS instance
resource "aws_security_group_rule" "attach" {
  description              = "Allow Lambda to access RDS"
  type                     = "ingress"
  from_port                = module.rds.port
  to_port                  = module.rds.port
  protocol                 = "tcp"
  source_security_group_id = module.lambda.security_group_id
  security_group_id        = module.rds.security_group_id
}

# Add a policy to allow the lambda to access the secret and the DB
data "aws_iam_policy_document" "lambda" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
    ]
    resources = [
      module.rds.master_password_secret_arn,
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
    ]
    resources = [
      module.rds.master_password_kms_key_arn
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "rds-db:connect"
    ]
    resources = [
      "arn:aws:rds-db:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:dbuser:${module.rds.cluster_id}/*"
    ]
  }
}

resource "aws_iam_policy" "lambda" {
  name   = var.name
  policy = data.aws_iam_policy_document.lambda.json
}

resource "aws_iam_role_policy_attachment" "lambda" {
  role       = module.lambda.iam_role_name
  policy_arn = aws_iam_policy.lambda.arn
}
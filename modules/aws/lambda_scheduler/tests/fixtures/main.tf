module "lambda" {
  source      = "../../../lambda"
  name        = var.name
  environment = var.environment
  owner       = "Testing"
  application = "UnitTests"
  component   = "LambdaTest"

  runtime       = "python3.9"
  binary_path   = "lambda.py"
  handler       = "lambda.lambda_handler"
  architectures = ["x86_64"]
}

module "scheduler" {
  source               = "../../"
  name                 = var.name
  environment          = var.environment
  application          = "UnitTests"
  component            = "LambdaScheduler"
  lambda_arn           = module.lambda.lambda_function_arn
  lambda_function_name = module.lambda.lambda_function_name
  schedule_expression  = var.schedule_expression
}
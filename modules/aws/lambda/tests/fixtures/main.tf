module "lambda" {
  source = "../../"

  name          = var.name
  runtime       = "python3.9"
  binary_path   = "lambda.py"
  handler       = "lambda.lambda_handler"
  architectures = ["x86_64"]

  environment = var.environment
  owner       = "Testing"
  application = "UnitTests"
  component   = "LambdaTest"

  environment_variables = {
    "OTHER" : "true"
  }
}

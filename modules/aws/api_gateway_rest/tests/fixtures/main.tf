module "apigw" {
  source                 = "../../"
  name                   = var.name
  environment            = var.environment
  owner                  = "Testing"
  application            = "UnitTests"
  component              = "APIGateway"
  api_version            = "v1"
  openapi_spec_file_path = "openapi.yaml"
  openapi_spec_variables = {
    description = "This is the description",
    timestamp   = var.timestamp
  }
}

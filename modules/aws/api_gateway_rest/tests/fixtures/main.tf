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
  attach_vpc_load_balancer = var.attach_vpc_load_balancer
  load_balancer_arn        = var.attach_vpc_load_balancer ? aws_lb.default[0].arn : ""
}

# Create an empty load balancer without any target groups to attach to the API Gateway,
# if requested. This forces a VPC Link to be created.
resource "aws_lb" "default" {
  count              = var.attach_vpc_load_balancer ? 1 : 0
  name               = "${var.name}-${var.environment}"
  internal           = true
  load_balancer_type = "network"
  subnets            = data.aws_subnets.private.ids
  tags = {
    application = "UnitTests"
    component   = "APIGateway"
    owner       = "Testing"
    environment = var.environment
    managed-by  = "Terraform"
  }
}
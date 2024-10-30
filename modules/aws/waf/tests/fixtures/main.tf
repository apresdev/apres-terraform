# We can't have a standalone WAF so we create a very simple load balancer
locals {
  tags = {
    Name        = "${var.name}-${var.environment}"
    environment = var.environment
    owner       = "Testing"
    application = "UnitTests"
    component   = "WAF"
  }
}

# To deploy a WAF with this module we need something to associate it with. So we create a very
# simple load balancer with no target group, and a security group with no rules. Under no circumstances
# should this configuration be used anywhere else.

resource "aws_security_group" "default" {
  #checkov:skip=CKV_AWS_23: Ignore for testing
  name   = "${var.name}-${var.environment}-sg"
  vpc_id = data.aws_vpc.default.id
  tags   = local.tags
}

resource "aws_lb" "default" {
  #checkov:skip=CKV_AWS_91: Ignore for testing
  #checkov:skip=CKV_AWS_131: Ignore for testing
  #checkov:skip=CKV_AWS_150: Ignore for testing
  name               = "${var.name}-${var.environment}"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.default.id]
  subnets            = [for subnet in data.aws_subnet.private : subnet.id]

  enable_deletion_protection = false
  tags                       = local.tags
}

module "waf" {
  source                 = "../../"
  name                   = var.name
  environment            = var.environment
  owner                  = "Testing"
  application            = "UnitTests"
  component              = "WAF"
  scope                  = "REGIONAL"
  associate_resource_arn = aws_lb.default.arn
  depends_on             = [aws_lb.default]
}

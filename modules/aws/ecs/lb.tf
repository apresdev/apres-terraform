locals {
  name = "${var.name}-${var.environment}"
}
resource "aws_lb" "default" {
  # TODO: Add access logging for NLB
  #checkov:skip=CKV_AWS_150:Not using deletion protection for now.
  #checkov:skip=CKV_AWS_91:Not enabling access logs for now.
  #checkov:skip=CKV2_AWS_20:False positive, this is an NLB, not an ALB.
  count = var.create_load_balancer ? 1 : 0

  # To create this we need the port set, so have a pre-condition check here so we don't fail half way through the deploy.
  lifecycle {
    precondition {
      condition     = var.create_load_balancer && var.container_port >= 1
      error_message = "Cannot create a load balancer without a container port set."
    }
  }

  name                             = local.name
  load_balancer_type               = "network"
  enable_cross_zone_load_balancing = "true"

  # launch lbs in private subnets
  internal        = true
  subnets         = data.aws_subnets.private.ids
  security_groups = [aws_security_group.nlb[0].id]

  # This is required for NLB to accept connections from Private Link, which is what API Gateway uses.
  enforce_security_group_inbound_rules_on_private_link_traffic = "off"

  tags = merge(
    local.tags,
    {
      Name = local.name
    },
  )
}

# adds a tcp listener to the load balancer and allows ingress
resource "aws_lb_listener" "tcp" {
  count             = var.create_load_balancer ? 1 : 0
  load_balancer_arn = aws_lb.default[0].id
  port              = var.load_balancer_port
  protocol          = "TCP" # Only option for NLB

  default_action {
    target_group_arn = aws_lb_target_group.default[0].id
    type             = "forward"
  }
  tags = merge(
    local.tags,
    {
      Name = local.name
    }
  )
}

resource "aws_lb_target_group" "default" {
  count                = var.create_load_balancer ? 1 : 0
  name                 = local.name
  port                 = var.load_balancer_port
  protocol             = "TCP"
  vpc_id               = data.aws_vpc.default.id
  target_type          = "ip"
  deregistration_delay = 30

  health_check {
    protocol            = "HTTP"
    path                = var.load_balancer_health_check_path
    healthy_threshold   = var.load_balancer_health_check_healthy_threshold
    unhealthy_threshold = var.load_balancer_health_check_unhealthy_threshold
    interval            = var.load_balancer_health_check_interval
  }

  tags = merge(
    local.tags,
    {
      Name = local.name
    },
  )
}

resource "aws_security_group" "nlb" {
  count       = var.create_load_balancer ? 1 : 0
  name        = "${local.name}-NLB"
  description = "Security group for NLB ${local.name}"
  vpc_id      = data.aws_vpc.default.id

  egress {
    description = "Allow all traffic out"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow all traffic in from the Private subnets"
    from_port   = var.load_balancer_port
    to_port     = var.load_balancer_port
    protocol    = "tcp"
    # TODO: This is what we want to use when we add the API Gateway. For now we just limit traffic
    # to the private subnets.
    #security_groups = [aws_security_group.api.id]
    cidr_blocks = [for s in data.aws_subnet.private : s.cidr_block]
  }

  tags = merge(
    local.tags,
    {
      Name = local.name
    },
  )
}
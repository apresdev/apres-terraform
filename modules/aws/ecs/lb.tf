locals {
  lb_access_logs_bucket_name = "${data.aws_caller_identity.current.account_id}-workloadconfig-${data.aws_region.current.name}-load-balancer-logs"
}
resource "aws_lb" "default" {
  # TODO: Add access logging for NLB
  #checkov:skip=CKV_AWS_150:Not using deletion protection for now.
  #checkov:skip=CKV_AWS_91:Not enabling access logs for now.
  #checkov:skip=CKV2_AWS_20:False positive when this is an LB
  count = var.create_load_balancer ? 1 : 0

  # To create this we need the port set, so have a pre-condition check here so we don't fail half way through the deploy.
  lifecycle {
    precondition {
      condition     = var.create_load_balancer && var.container_port >= 1
      error_message = "Cannot create a load balancer without a container port set."
    }
  }

  name                             = local.name
  load_balancer_type               = var.load_balancer_type
  enable_cross_zone_load_balancing = "true"

  # Access logs
  access_logs {
    # Leave prefix as the default.
    bucket  = local.lb_access_logs_bucket_name
    enabled = true
  }

  # launch lbs in public or private depending on the publicity
  internal = var.load_balancer_is_public ? false : true
  subnets  = var.load_balancer_is_public ? data.aws_subnets.public.ids : data.aws_subnets.private.ids
  # Use the security group given if it exists, else the one created in this module.
  security_groups = var.load_balancer_security_group != "" ? [var.load_balancer_security_group] : [aws_security_group.load_balancer[0].id]

  # This is required for NLB to accept connections from Private Link, which is what API Gateway uses.
  # Only applicable for NLB so we set it to null.
  enforce_security_group_inbound_rules_on_private_link_traffic = var.load_balancer_type == "network" ? "off" : null

  tags = merge(
    local.tags,
    {
      Name = local.name
    },
  )
}

locals {
  # Convoluted way to figure out the protocol, based on if there's an SSL cert and if it's
  # an ALB or NLB.
  lb_protocols = {
    "application" : {
      "ssl" : "HTTPS"
      "nossl" : "HTTP"
    }
    "network" : {
      "ssl" : "TLS"
      "nossl" : "TCP"
    }
  }
  lb_protocol = var.load_balancer_ssl_cert_arn == "" ? local.lb_protocols[var.load_balancer_type]["nossl"] : local.lb_protocols[var.load_balancer_type]["ssl"]
}

# adds a listener to the load balancer and allows ingress
resource "aws_lb_listener" "default" {
  count             = var.create_load_balancer ? 1 : 0
  load_balancer_arn = aws_lb.default[0].id
  port              = var.load_balancer_port
  protocol          = local.lb_protocol
  certificate_arn   = var.load_balancer_ssl_cert_arn != "" ? var.load_balancer_ssl_cert_arn : null
  ssl_policy        = var.load_balancer_ssl_cert_arn != "" ? "ELBSecurityPolicy-2016-08" : null

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
  protocol             = local.lb_protocol
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

locals {
  # If we are creating a load balancer and no security groups are given, create a security group.
  create_lb_security_group = var.create_load_balancer && var.load_balancer_security_group == ""
  # Set CIDR range for security group based on where load balancer is.
  sg_cidrs = var.load_balancer_is_public ? ["0.0.0.0/0"] : [for s in data.aws_subnet.private : s.cidr_block]
}

# Create a security group based on the variables set above.
resource "aws_security_group" "load_balancer" {
  #checkov:skip=CKV_AWS_382: False positive, Load Balancers need full egress.
  count       = local.create_lb_security_group ? 1 : 0
  name        = "${local.name}-LB"
  description = "LB for ${local.name}"
  vpc_id      = data.aws_vpc.default.id

  egress {
    description = "Allow all traffic out"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow traffic in on port ${var.load_balancer_port}"
    from_port   = var.load_balancer_port
    to_port     = var.load_balancer_port
    protocol    = "tcp"
    cidr_blocks = local.sg_cidrs
  }

  tags = merge(
    local.tags,
    {
      Name = local.name
    },
  )
}
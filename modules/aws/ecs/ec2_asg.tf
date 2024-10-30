locals {
  # the resources in this file are only created if the deployment target is EC2.
  use_ec2 = var.deployment_target == "EC2" ? 1 : 0

  # The user_data.sh script needs two variables to be set. If we do it as a templatefile() the
  # existing bash variables need to be escaped which makes editting the script difficult. So we
  # load it here with nested replace() functions. The strings can be whatever you want, but using
  # the format of %THING% format to be obvious.
  user_data = replace(
    replace(
      file("${path.module}/templates/user_data.sh"),
      "%ECS_CLUSTER_NAME%",
      aws_ecs_cluster.default.name
    ),
    "%USE_NVME_STORAGE%",
    var.ec2_use_instance_nvme_storage ? "true" : "false"
  )

  # We need the ASG name here and for the CloudWatch dashboard, even if we don't create
  # the ASG.
  ecs_asg_name = "${local.name}-ECSASG"
}

resource "aws_launch_template" "ecs_launch_template" {
  count         = local.use_ec2
  name          = local.name
  image_id      = data.aws_ami.ecs_ami.id
  instance_type = var.ec2_instance_type
  user_data     = base64encode(local.user_data)

  iam_instance_profile {
    arn = aws_iam_instance_profile.ec2_instance_role_profile[0].arn
  }

  monitoring {
    enabled = true
  }

  vpc_security_group_ids = [aws_security_group.ecs_asg[0].id]

  tags = merge(
    local.tags,
    {
      Name = var.name
    },
  )

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

}

resource "aws_iam_role" "ec2_instance_role" {
  count              = local.use_ec2
  name_prefix        = "${local.name}-EC2InstanceRole"
  assume_role_policy = data.aws_iam_policy_document.ec2_instance_role_policy.json
  tags = merge(
    local.tags,
    {
      Name = "${local.name}-EC2InstanceRole"
    },
  )
}

resource "aws_iam_role_policy_attachment" "ec2_ecs" {
  count      = local.use_ec2
  role       = aws_iam_role.ec2_instance_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  count      = local.use_ec2
  role       = aws_iam_role.ec2_instance_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

resource "aws_iam_instance_profile" "ec2_instance_role_profile" {
  count       = local.use_ec2
  name_prefix = "${local.name}-EC2InstanceRoleProfile"
  role        = aws_iam_role.ec2_instance_role[0].id
  tags = merge(
    local.tags,
    {
      Name = "${local.name}-EC2InstanceRoleProfile"
    },
  )
}

data "aws_iam_policy_document" "ec2_instance_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type = "Service"
      identifiers = [
        "ec2.amazonaws.com",
        "ecs.amazonaws.com"
      ]
    }
  }
}

resource "aws_autoscaling_group" "ecs_asg" {
  count                 = local.use_ec2
  name                  = local.ecs_asg_name
  max_size              = var.ec2_autoscale_max
  min_size              = var.ec2_autoscale_min
  vpc_zone_identifier   = data.aws_subnets.private.ids
  health_check_type     = "EC2"
  protect_from_scale_in = false # if set to true the ASG can never be deleted

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances"
  ]

  launch_template {
    id = aws_launch_template.ecs_launch_template[0].id
    # Do not set this to "$Latest" or the ASG will never refresh instances.
    version = aws_launch_template.ecs_launch_template[0].latest_version
  }

  instance_refresh {
    strategy = "Rolling"
  }

  lifecycle {
    create_before_destroy = true
  }

  # ASG tags are a bit different
  dynamic "tag" {
    for_each = local.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
  tag {
    key                 = "Name"
    value               = local.ecs_asg_name
    propagate_at_launch = true
  }
  # This tag is needed for the capacity provider.
  tag {
    key                 = "AmazonECSManaged"
    value               = true
    propagate_at_launch = true
  }
}

resource "aws_security_group" "ecs_asg" {
  #checkov:skip=CKV2_AWS_5:False positive, this security group is attached to the launch template.
  count       = local.use_ec2
  name        = local.ecs_asg_name
  description = "ECS ASG for ${local.name}"
  vpc_id      = data.aws_vpc.default.id

  egress {
    description = "Allow all traffic out"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.tags,
    {
      Name = local.ecs_asg_name
    },
  )
}

# If the load balancer is created and the deployment is EC2, allow traffic from the NLB to the instances,
# on all high numbered ports, one rule per security group id.
resource "aws_security_group_rule" "ecs_asg_ingress" {
  count             = var.create_load_balancer && local.use_ec2 == 1 ? 1 : 0
  type              = "ingress"
  description       = "Allow traffic from the load balancer to the ECS instances"
  from_port         = 1024
  to_port           = 65535
  protocol          = "tcp"
  security_group_id = aws_security_group.ecs_asg[0].id
  # if we're given a security group id use that, else use the one we created for the load balancer
  source_security_group_id = var.load_balancer_security_group != "" ? var.load_balancer_security_group : aws_security_group.load_balancer[0].id
}
locals {
  is_arm             = can(regex("[a-zA-Z]+\\d+g[a-z]*\\..+", var.instance_type))
  ami_id             = var.ami_id != null ? var.ami_id : data.aws_ami.main[0].id
  cwagent_param_arn  = var.use_cloudwatch_agent ? var.cloudwatch_agent_configuration_param_arn != null ? var.cloudwatch_agent_configuration_param_arn : aws_ssm_parameter.cloudwatch_agent_config[0].arn : null
  cwagent_param_name = var.use_cloudwatch_agent ? var.cloudwatch_agent_configuration_param_arn != null ? split("/", data.aws_arn.ssm_param[0].resource)[1] : aws_ssm_parameter.cloudwatch_agent_config[0].name : null
  security_groups    = concat(var.use_default_security_group ? [aws_security_group.main.id] : [], var.additional_security_group_ids)

  name = module.apres_names.local_name
}

module "apres_names" {
  #checkov:skip=CKV_TF_1:False positive, we are not using a hash because we use the tagged version.
  source      = "git@github.com:apresdev/apres-terraform.git//modules/aws/apres_names?ref=rel/apres_names/1.0.0"
  name        = var.name
  environment = var.environment
}

resource "aws_security_group" "main" {
  #checkov:skip=CKV_AWS_382: NAT Intances need egress to 0/0
  name        = local.name
  description = "Used in ${local.name} instance in subnet ${var.subnet_id}"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    description = "Unrestricted ingress from within VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${data.aws_vpc.main.cidr_block}"]
  }

  egress {
    description      = "Unrestricted egress"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(var.tags, {
    Name = local.name
  })
}

resource "aws_network_interface" "main" {
  description       = "${local.name} static private ENI"
  subnet_id         = var.subnet_id
  source_dest_check = false

  tags = merge(var.tags, {
    Name = local.name
  })
}

resource "aws_network_interface_sg_attachment" "main" {
  security_group_id    = aws_security_group.main.id
  network_interface_id = aws_network_interface.main.id
}

resource "aws_route" "main" {
  route_table_id         = var.route_table_id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_network_interface.main.id
}

resource "aws_ssm_parameter" "cloudwatch_agent_config" {
  count = var.use_cloudwatch_agent && var.cloudwatch_agent_configuration_param_arn == null ? 1 : 0

  name   = "${local.name}-cloudwatch-agent-config"
  key_id = var.kms_key_id
  type   = "SecureString"
  value = templatefile("${path.module}/templates/cwagent.json", {
    METRICS_COLLECTION_INTERVAL = var.cloudwatch_agent_configuration.collection_interval,
    METRICS_NAMESPACE           = var.cloudwatch_agent_configuration.namespace
    METRICS_ENDPOINT_OVERRIDE   = var.cloudwatch_agent_configuration.endpoint_override
  })
}
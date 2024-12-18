data "aws_ami" "default" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-20*"]
  }

  filter {
    name   = "architecture"
    values = ["arm64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "default" {
  name        = local.name
  description = "Security group for ${local.name}"
  vpc_id      = data.aws_vpc.default.id
  tags = merge(
    local.tags,
    {
      Name = local.name
    }
  )
}

# Allow all outbound traffic on all protocols
resource "aws_vpc_security_group_egress_rule" "default_ipv4" {
  description       = "Allow all egress traffic for ipv4"
  security_group_id = aws_security_group.default.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # allow all
}

resource "aws_vpc_security_group_egress_rule" "default_ipv6" {
  description       = "Allow all egress traffic for ipv6"
  security_group_id = aws_security_group.default.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1" # allow all
}

# Create number of instances spread across subnets
resource "aws_instance" "default" {
  count                  = var.number_hosts
  ami                    = data.aws_ami.default.id
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnets.private.ids[count.index]
  vpc_security_group_ids = [aws_security_group.default.id]
  iam_instance_profile   = aws_iam_instance_profile.default.id
  monitoring             = true
  ebs_optimized          = true
  root_block_device {
    encrypted = true
  }
  # Enforce IMDSv2
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh", {
    INSTALL_PACKAGES = join(" ", var.install_packages)
  }))
  user_data_replace_on_change = true

  tags = merge(
    local.tags,
    {
      Name = local.name
    }
  )
}

resource "aws_db_subnet_group" "default" {
  name        = local.name
  description = local.name
  subnet_ids  = data.aws_subnets.persistence.ids
  tags = merge(
    local.tags,
    {
      "Name" = local.name
    }
  )
}

resource "aws_security_group" "rds" {
  name        = "${local.name}-rds"
  description = "Security group for RDS instance ${local.name}"
  vpc_id      = data.aws_vpc.default.id

  # TODO: I don't think we want this.
  # egress {
  #   description = "Allow traffic out to peristence and private subnets"
  #   from_port   = 0
  #   to_port     = 0
  #   protocol    = -1
  #   # only allow egress to the private and persistence subnets
  #   cidr_blocks = local.private_and_persistence_cidrs
  # }

  tags = merge(
    local.tags,
    {
      Name = local.name
    },
  )
}

# Conditionally create two ingress rules, depending on the variables. See README.
resource "aws_security_group_rule" "ingress_private_subnets" {
  count             = var.allow_ingress_from_all_private_subnets ? 1 : 0
  type              = "ingress"
  description       = "Allow traffic from the persistence and private subnets to RDS"
  from_port         = local.port
  to_port           = local.port
  protocol          = "tcp"
  security_group_id = aws_security_group.rds.id
  cidr_blocks       = local.private_and_persistence_cidrs
}

resource "aws_security_group_rule" "ingress_security_groups" {
  count             = length(var.allow_ingress_security_groups) > 0 ? 1 : 0
  type              = "ingress"
  description       = "Allow traffic from specific security groups to RDS"
  from_port         = local.port
  to_port           = local.port
  protocol          = "tcp"
  security_group_id = aws_security_group.rds.id
  cidr_blocks       = var.allow_ingress_security_groups
}

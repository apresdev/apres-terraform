locals {
  tags = merge(
    var.extra_tags,
    tomap({
      "application" = var.application
      "component"   = "VPC"
      "owner"       = var.owner
      "environment" = var.environment
      "managed-by"  = "Terraform"
    })
  )
}

resource "aws_vpc" "vpc" {
  #checkov:skip=CKV2_AWS_12:False positive, default security group is managed and has no ingress/egress allowed.
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = merge(
    local.tags,
    {
      Name = "Workload VPC ${var.environment}",
    },
  )
}

# Manage the default security group and deny all traffic. Resources deployed in the VPC
# must include their own security group.
resource "aws_default_security_group" "default" {
  vpc_id = resource.aws_vpc.vpc.id
}

resource "aws_subnet" "public_subnet" {
  count             = 3
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.vpc_public_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = merge(
    local.tags,
    {
      Name        = "Public Subnet (AZ${count.index + 1})",
      subnet-tier = "public",
    },
  )

}

resource "aws_subnet" "private_subnet" {
  count                   = 3
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.vpc_private_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false
  tags = merge(
    local.tags,
    {
      Name        = "Private Subnet (AZ${count.index + 1})"
      subnet-tier = "private",
    },
  )
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id
  tags = merge(
    local.tags,
    {
      Name = "Workloads Internet Gateway"
    },
  )
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }
  tags = merge(
    local.tags,
    {
      Name = "Public Route Table"
    },
  )
}

resource "aws_route_table_association" "public_route_table_association" {
  count          = 3
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table" "private_route_table" {
  count  = 3
  vpc_id = aws_vpc.vpc.id
  tags = merge(
    local.tags,
    {
      Name = "Private Route Table ${count.index + 1}",
    },
  )
}
resource "aws_route_table_association" "private_route_table_association" {
  count          = 3
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_route_table[count.index].id
}

module "nat_instance" {
  #checkov:skip=CKV_TF_1: Explicitly using versions, not a hash.
  source               = "git@github.com:apresdev/apres-terraform.git//modules/aws/nat_instance?ref=rel/nat_instance/1.3.0"
  count                = 3
  name                 = "vpc-nat-az${count.index + 1}"
  environment          = var.environment
  vpc_id               = aws_vpc.vpc.id
  subnet_id            = aws_subnet.public_subnet[count.index].id
  use_cloudwatch_agent = true
  route_table_id       = aws_route_table.private_route_table[count.index].id
  instance_type        = var.vpc_nat_instance_type
  tags = merge(
    local.tags,
    {
      component = "NAT",
    },
  )
}

# Create persistence subnets with no routes to the internet at all
resource "aws_subnet" "persistence_subnet" {
  count                   = 3
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.vpc_persistence_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false
  tags = merge(
    local.tags,
    {
      Name        = "Persistence Subnet (AZ${count.index + 1})"
      subnet-tier = "persistence",
    },
  )
}

resource "aws_route_table_association" "persistence_route_table_association" {
  count          = 3
  subnet_id      = aws_subnet.persistence_subnet[count.index].id
  route_table_id = aws_route_table.persistence_route_table[count.index].id
}

resource "aws_route_table" "persistence_route_table" {
  count  = 3
  vpc_id = aws_vpc.vpc.id
  tags = merge(
    local.tags,
    {
      Name = "Persistence Route Table ${count.index + 1}",
    },
  )
}

# There should be no route from the subnet to the 0/0 (just 10/16) but we'll create the NACL anyway
# - route to private subnet allowed, all else denied.
resource "aws_network_acl" "persistence_network_acl" {
  #checkov:skip=CKV2_AWS_1:False positive, ACL is attached to the subnets via the association stanza.
  count  = 3
  vpc_id = aws_vpc.vpc.id
  tags = merge(
    local.tags,
    {
      Name = "Persistence Network ACL ${count.index + 1}",
    },
  )
}

# Allow traffic only to the private subnet. Because there's three and we want each persistence subnet
# to have access to each of the three private subnets, we'll create three rules, each with three instances.
resource "aws_network_acl_rule" "allow_private_subnet_traffic_out_0" {
  count          = 3
  egress         = true
  protocol       = "-1"
  rule_number    = 100
  rule_action    = "allow"
  cidr_block     = var.vpc_private_subnet_cidrs[0]
  network_acl_id = resource.aws_network_acl.persistence_network_acl[count.index].id
}
resource "aws_network_acl_rule" "allow_private_subnet_traffic_out_1" {
  count          = 3
  egress         = true
  protocol       = "-1"
  rule_number    = 101
  rule_action    = "allow"
  cidr_block     = var.vpc_private_subnet_cidrs[1]
  network_acl_id = resource.aws_network_acl.persistence_network_acl[count.index].id
}
resource "aws_network_acl_rule" "allow_private_subnet_traffic_out_2" {
  count          = 3
  egress         = true
  protocol       = "-1"
  rule_number    = 102
  rule_action    = "allow"
  cidr_block     = var.vpc_private_subnet_cidrs[2]
  network_acl_id = resource.aws_network_acl.persistence_network_acl[count.index].id
}

# Now allow traffic from each of the private subnets.
resource "aws_network_acl_rule" "allow_private_subnet_traffic_in_0" {
  #checkov:skip=CKV_AWS_352:All ports allowed to from private to persistence subnet
  count          = 3
  egress         = false
  protocol       = "-1"
  rule_number    = 110
  rule_action    = "allow"
  cidr_block     = var.vpc_private_subnet_cidrs[0]
  network_acl_id = resource.aws_network_acl.persistence_network_acl[count.index].id
}
resource "aws_network_acl_rule" "allow_private_subnet_traffic_in_1" {
  #checkov:skip=CKV_AWS_352:All ports allowed to from private to persistence subnet
  count          = 3
  egress         = false
  protocol       = "-1"
  rule_number    = 112
  rule_action    = "allow"
  cidr_block     = var.vpc_private_subnet_cidrs[1]
  network_acl_id = resource.aws_network_acl.persistence_network_acl[count.index].id
}
resource "aws_network_acl_rule" "allow_private_subnet_traffic_in_2" {
  #checkov:skip=CKV_AWS_352:All ports allowed to from private to persistence subnet
  count          = 3
  egress         = false
  protocol       = "-1"
  rule_number    = 113
  rule_action    = "allow"
  cidr_block     = var.vpc_private_subnet_cidrs[2]
  network_acl_id = resource.aws_network_acl.persistence_network_acl[count.index].id
}

# Block all traffic to 0/0. Rule 100-102 are evaluated first and will allow traffic to the private subnets.
resource "aws_network_acl_rule" "block_internet_traffic_out" {
  count          = 3
  egress         = true
  protocol       = "-1"
  rule_number    = 200
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  network_acl_id = resource.aws_network_acl.persistence_network_acl[count.index].id
}

# Block all traffic from 0/0
resource "aws_network_acl_rule" "block_internet_traffic_in" {
  #checkov:skip=CKV_AWS_352:All ports are blocked, check is a false positive.
  count          = 3
  egress         = false
  protocol       = "-1"
  rule_number    = 200
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  network_acl_id = resource.aws_network_acl.persistence_network_acl[count.index].id
}

resource "aws_network_acl_association" "persistence" {
  count          = 3
  subnet_id      = aws_subnet.persistence_subnet[count.index].id
  network_acl_id = aws_network_acl.persistence_network_acl[count.index].id
}

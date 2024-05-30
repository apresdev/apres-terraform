resource "aws_security_group" "vpc_service_endpoint" {
  count = length(var.vpc_service_endpoints)
  # TODO: we don't need this if it's an s3 or dynamodb endpoint
  name   = "vpc-endpoint-${var.vpc_service_endpoints[count.index]}"
  vpc_id = resource.aws_vpc.vpc.id

  ingress {
    description = "Unrestricted ingress from within VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  tags = merge(
    local.tags, {
      Name = "VPC Endpoint ${var.vpc_service_endpoints[count.index]}"
  })
}

resource "aws_vpc_endpoint" "service_endpoints" {
  count = length(var.vpc_service_endpoints)
  # There is a special case for S3 and private DNS entries, where the gateway needs to exist first before
  # the DNS setting can be enabled. So we set the depends_on here even though those resources may not be created.
  depends_on        = [aws_vpc_endpoint.s3, aws_vpc_endpoint.dynamodb]
  vpc_id            = resource.aws_vpc.vpc.id
  vpc_endpoint_type = "Interface"
  # We want Private DNS for almost all services, but there are two cases where we can't used it.
  # 1. DynamoDB does not support private DNS
  # 2. S3 does not support private DNS if the S3 Gateway endpoint is disabled
  private_dns_enabled = var.vpc_service_endpoints[count.index] == "dynamodb" || (var.vpc_service_endpoints[count.index] == "s3" && var.enable_s3_gateway_endpoint == false) ? false : true
  subnet_ids          = [for id in aws_subnet.private_subnet : id.id]
  security_group_ids  = [aws_security_group.vpc_service_endpoint[count.index].id]
  service_name        = "com.amazonaws.${data.aws_region.current.name}.${var.vpc_service_endpoints[count.index]}"
  tags = merge(
    local.tags,
    {
      Name = "VPC Service Endpoint ${var.vpc_service_endpoints[count.index]}",
    },
  )
}

resource "aws_vpc_endpoint" "s3" {
  count             = var.enable_s3_gateway_endpoint ? 1 : 0
  vpc_id            = aws_vpc.vpc.id
  vpc_endpoint_type = "Gateway"
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  route_table_ids   = flatten([[for id in aws_route_table.private_route_table : id.id], aws_route_table.public_route_table.id])
  tags = merge(
    local.tags,
    {
      Name = "VPC Gateway Endpoint S3",
    },
  )
}

resource "aws_vpc_endpoint" "dynamodb" {
  count             = var.enable_dynamodb_gateway_endpoint ? 1 : 0
  vpc_id            = aws_vpc.vpc.id
  vpc_endpoint_type = "Gateway"
  service_name      = "com.amazonaws.${data.aws_region.current.name}.dynamodb"
  route_table_ids   = flatten([[for id in aws_route_table.private_route_table : id.id], aws_route_table.public_route_table.id])
  tags = merge(
    local.tags,
    {
      Name = "VPC Gateway Endpoint DynamoDB",
    },
  )
}
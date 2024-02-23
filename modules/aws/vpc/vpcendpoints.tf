resource "aws_security_group" "vpc_service_endpoint" {
  count  = length(var.vpc_service_endpoints)
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
  # TODO: S3 and DynamoDB are of type Gateway!
  count               = length(var.vpc_service_endpoints)
  vpc_id              = resource.aws_vpc.vpc.id
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [for id in aws_subnet.private_subnet : id.id]
  security_group_ids  = [aws_security_group.vpc_service_endpoint[count.index].id]
  service_name        = "com.amazonaws.${data.aws_region.current.name}.${var.vpc_service_endpoints[count.index]}"
  tags = merge(
    local.tags,
    {
      Name = "VPC Endpoint ${var.vpc_service_endpoints[count.index]}",
    },
  )
}
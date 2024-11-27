resource "aws_security_group" "default" {
  count = local.use_vpc ? 1 : 0

  # This is a false positive.  This resource is attached in the lambda resource if and only if local.use_vpc is true, which is the same
  # condition for whether or not to create this resource.  (see the dynamidynamic "vpc_config" section in resource "aws_lambda_function" "default" in main.tf )
  #checkov:skip=CKV2_AWS_5:"Ensure that Security Groups are attached to another resource"
  #checkov:skip=CKV_AWS_382: "False postive, Lambda needs full egress."
  name        = "${local.name}-Lambda-Function"
  description = "Security group for ECS Task ${local.name}"
  vpc_id      = data.aws_vpc.default[0].id

  egress {
    description = "Allow all traffic out"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.name}-Lambda-Function"
    },
  )

}

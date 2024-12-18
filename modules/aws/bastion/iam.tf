resource "aws_iam_instance_profile" "default" {
  name_prefix = local.name
  role        = aws_iam_role.default.name

  tags = merge(local.tags, {
    Name = local.name
  })
}

resource "aws_iam_role" "default" {
  name_prefix = local.name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.tags, {
    Name = local.name
  })
}

resource "aws_iam_role_policy_attachment" "default" {
  role       = aws_iam_role.default.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
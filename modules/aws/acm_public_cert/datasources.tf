# Fetch the hosted zone that will serve the ACM certificate records used for DNS validation.
data "aws_route53_zone" "default" {
  name         = var.hosted_zone
  private_zone = false
}

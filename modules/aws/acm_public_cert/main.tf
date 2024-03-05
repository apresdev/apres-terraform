locals {
  tags = merge(
    var.default_tags,
    tomap({
      environment = var.environment
      managed-by  = "terraform"
    })
  )
}

# ######################################################################################################################
# Create the ACM certificate.  We shall use DNS validation, as such we will need to create Route53 records to prove
# ownership of the domains included in the certificate.
# ######################################################################################################################
resource "aws_acm_certificate" "default" {

  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names

  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  options {
    certificate_transparency_logging_preference = "ENABLED"
  }

  tags = merge(
    local.tags,
    tomap({
      Name = var.domain_name
    })
  )
}

# ######################################################################################################################
# Create the Route53 records that will prove ownership of the given domain name
# ######################################################################################################################
resource "aws_route53_record" "acm_certificate_validation_records" {

  for_each = {
    for dvo in aws_acm_certificate.default.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 300
  type            = each.value.type
  zone_id         = data.aws_route53_zone.default.zone_id

  depends_on = [
    aws_acm_certificate.default,
    data.aws_route53_zone.default
  ]

}

# ######################################################################################################################
# Attach the Route53 validation records to the ACM certificate.
# ######################################################################################################################
resource "aws_acm_certificate_validation" "cert_validation" {

  certificate_arn         = aws_acm_certificate.default.arn
  validation_record_fqdns = [for record in aws_route53_record.acm_certificate_validation_records : record.fqdn]

  # Dependency to guarantee that certificate and DNS records are created before this resource
  depends_on = [
    aws_acm_certificate.default,
    aws_route53_record.acm_certificate_validation_records,
  ]

}

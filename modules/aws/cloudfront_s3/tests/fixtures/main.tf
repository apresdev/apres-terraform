module "cloudfront_s3" {
  source                                = "../../"
  name                                  = var.name
  environment                           = var.environment
  application                           = var.application
  component                             = var.component
  cloudfront_geo_restrictions_locations = ["US", "CA"] # US is where GHA runs, CA is where Apres works
  cloudfront_geo_restrictions_type      = "whitelist"
  is_spa                                = true
}

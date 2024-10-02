# Create an S3 bucket where the signed and unsigned lambda source will be placed.
# The lambda module will automatically upload lambda artifacts to this bucket to be signed and will automatically configure the lamda 
# resource to pull signed artifacts from the same S3 bucket.
module "s3_artifacts" {
  #checkov:skip=CKV_TF_1: No hash specified, that's ok because we are using the version.
  source = "git@github.com:apresdev/apres-terraform.git//modules/aws/s3?ref=rel/s3/3.0.0"

  name = "lambda-artifacts"

  environment = var.environment
  component   = var.component
  application = var.application
  owner       = var.owner
}

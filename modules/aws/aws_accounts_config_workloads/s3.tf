# The bucket policy differs depending if a region was available before 2022 or not.
# See https://docs.aws.amazon.com/elasticloadbalancing/latest/application/enable-access-logging.html#attach-bucket-policy
# for the discussion. For regions prior to 2022, the bucket policy includes an account ID.
locals {
  pre2022_regions = {
    "us-east-1" : "127311923021",
    "us-east-2" : "033677994240",
    "us-west-1" : "027434742980",
    "us-east-2" : "797873946194",
    "af-south-1" : "098369216593",
    "ap-east-1" : "754344448648",
    "ap-southeast-3" : "589379963580",
    "ap-south=1" : "718504428378",
    "ap-northeast-3" : "383597477331",
    "ap-northeast-2" : "600734575887",
    "ap-southeast-1" : "114774131450",
    "ap-southeast-2" : "783225319266",
    "ap-northeast-1" : "582318560864",
    "ca-central-1" : "985666609251",
    "eu-central-1" : "054676820928",
    "eu-west-1" : "156460612806",
    "eu-west-2" : "652711504416",
    "eu-south-1" : "635631232127",
    "eu-west-3" : "009996457667",
    "eu-north-1" : "897822967062",
    "me-south-1" : "076674570225",
    "sa-east-1" : "507241528517",
  }
  is_pre2022_region = contains(keys(local.pre2022_regions), data.aws_region.current.name)
}

data "aws_iam_policy_document" "pre2022_lb_bucket_policy" {
  # S3 Bucket policy for regions created before 2022
  count = local.is_pre2022_region ? 1 : 0
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.pre2022_regions[data.aws_region.current.name]}:root"]
    }
    actions = [
      "s3:PutObject"
    ]
    resources = [
      module.load_balancer_logs_bucket.bucket_arn
    ]
  }
}

data "aws_iam_policy_document" "post2022_lb_bucket_policy" {
  # S3 Bucket policy for regions created after 2022
  count = local.is_pre2022_region ? 0 : 1
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["logdelivery.elasticloadbalancing.amazonaws.com"]
    }
    actions = [
      "s3:PutObject"
    ]
    resources = [
      module.load_balancer_logs_bucket.bucket_arn
    ]
  }
}

resource "aws_s3_bucket_policy" "default" {
  # Set the bucket policy based on the region, if it's pre 2022 or not.
  bucket = module.load_balancer_logs_bucket.bucket_name
  policy = local.is_pre2022_region ? data.aws_iam_policy_document.pre2022_lb_bucket_policy[0].json : data.aws_iam_policy_document.post2022_lb_bucket_policy[0].json
}

module "load_balancer_logs_bucket" {
  #checkov:skip=CKV_TF_1: No hash specified, that's ok because we are using the version.
  source      = "git@github.com:apresdev/apres-terraform.git//modules/aws/s3?ref=rel/s3/3.0.0"
  name        = "load-balancer-logs"
  environment = "WorkloadConfig"
  application = "LoadBalancerAccessLogs"
  component   = "S3"
  owner       = "Engineering"
  # Disable default bucket policy, setting our own here.
  set_default_bucket_policy = false
  # Use the default lifecycle rule to delete all logs after 365 days.
  lifecycle_rule = {
    enabled                                = true
    abort_incomplete_multipart_upload_days = 7
    transition_to_intelligent_tier_days    = 1
    object_delete_days                     = var.retain_load_balancer_logs_days
    prefix                                 = ""
    old_versions_delete_days               = 30
  }
}
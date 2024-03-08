variable "domain_name" {
  description = "The FDQN for the certificate to create."
  type        = string
}

variable "subject_alternative_names" {
  description = <<EOM
(Optional) Set of domains that should be SANs in the issued certificate. To remove all elements of a previously configured list, set this value equal to an empty list ([]) or use the terraform taint command to trigger recreation.
EOM
  type        = list(string)
  default     = []
}

variable "hosted_zone" {
  description = "The hosted zone domain name that will managed the Route53 DNS records used for certificate validation."
  type        = string
}

variable "environment" {
  description = "Environment name, used for tagging AWS resources."
  type        = string
  default     = "dev"
}

variable "default_tags" {
  description = "Default set of tags to be applied to all resources"
  type        = map(string)
  default     = {}
}

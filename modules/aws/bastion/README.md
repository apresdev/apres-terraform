# Bastion

This module sets up a bastion host in the private subnet, based on Amazon Linux 2023, using AWS SSM as
an access method instead of opening up a public SSH port.

WARNING: The bastion hosts are meant to be ephemeral, and they _will_ be replaced when a new version
is released, and all data stored on the host will be lost. You should NOT store data on them, ever.

Only ARM instances are supported, since they are more far more cost effective.

## Accessing the Bastion Hosts

The bastion hosts are created in the private subnets, and do not have the SSH port open. Instead,
use AWS SSM to access the hosts. This can be done via the AWS Console following the
[Start a session](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-sessions-start.html) instructions.

Native SSH (from your laptop etc) is not supported. It is complex to setup and difficult to secure,
and more than one administator will require sharing the private SSH key, which is very bad practice.

## Adding packages

Installing software can be done automatically by adding the yum package names to the variable
`install_packages`. [This page](https://docs.aws.amazon.com/linux/al2023/release-notes/all-packages.html)
lists all the available packages.

Common packages are:
* PostgreSQL, required for connecting to a PostgreSQL database like Aurora: `postgresql16`
* MariaDB, required for connecting to an Aurora DB running MariaDB or Mysql: `mariadb105`

## Adding IAM Permissions

If you need to access other AWS resources from the bastion hosts, such as accessing an S3 bucket,
you will need to grant IAM permissions to the hosts. To do so, use the
output variable `iam_role_arn` and attach your own policy.

In the following example we give the bastion host access to list objects from an S3 bucket:
```hcl
# Create the bastion host(s)
module "bastion" {
    # ...
}

# Create the policy document
data "aws_iam_policy_document" "default" {
  statement {
    sid    = "ListObjectsInBucket
    effect = "Allow"
    actions = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::mybucket"]
  }
}

# Create the policy in IAM
resource "aws_iam_policy" "default" {
  name_prefix = "bastionpolicy"
  policy      = data.aws_iam_policy_document.default.json
}

# Attach the policy to the Bastion host role
resource "aws_iam_role_policy_attachment" "default" {
  role       = module.bastion.iam_role_arn
  policy_arn = aws_iam_policy.default.arn
}

```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.0, <2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.59.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_apres_names"></a> [apres\_names](#module\_apres\_names) | git@github.com:apresdev/apres-terraform.git//modules/aws/apres_names | rel/apres_names/1.0.0 |

## Resources

| Name | Type |
|------|------|
| [aws_iam_instance_profile.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_instance.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_security_group.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_vpc_security_group_egress_rule.default_ipv4](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_egress_rule.default_ipv6](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_ami.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_subnets.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets) | data source |
| [aws_vpc.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_application"></a> [application](#input\_application) | Application name, used for tagging AWS resources. | `string` | n/a | yes |
| <a name="input_component"></a> [component](#input\_component) | Component name, used for tagging AWS resources. | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment Name, used for naming and tagging AWS resources. | `string` | n/a | yes |
| <a name="input_extra_tags"></a> [extra\_tags](#input\_extra\_tags) | Extra tags to be applied to all resources | `map(string)` | `{}` | no |
| <a name="input_install_packages"></a> [install\_packages](#input\_install\_packages) | A list of packages to install on the bastion host. The packages must be available in the<br/>    Amazon Linux 2023 repositories, available<br/>    [here](https://docs.aws.amazon.com/linux/al2023/release-notes/all-packages.html). | `list(string)` | `[]` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | The instance type to use for the bastion host | `string` | `"t4g.nano"` | no |
| <a name="input_name"></a> [name](#input\_name) | Name used to create resources | `string` | n/a | yes |
| <a name="input_number_hosts"></a> [number\_hosts](#input\_number\_hosts) | The number of bastion hosts to create, must be 1, 2, or 3. If greater than 1<br/>    the hosts will be spread across availability zones. | `number` | `1` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | Owner of the resources, used for tagging AWS resources. | `string` | `"Engineering"` | no |
| <a name="input_vpc_environment_tag"></a> [vpc\_environment\_tag](#input\_vpc\_environment\_tag) | The `environment` tag used to look up the VPC and resources in it. Typically there's one VPC<br/>    per account, with an environment like 'Dev', 'Test', or 'Prod' but there is a possibility of more<br/>    if it was configured that way. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_iam_role_arn"></a> [iam\_role\_arn](#output\_iam\_role\_arn) | The ARN of the IAM role for the bastion host(s). |
| <a name="output_instance_ids"></a> [instance\_ids](#output\_instance\_ids) | A list of the IDs of the bastion host(s). |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | The ID of the security group for the bastion host(s). |
<!-- END_TF_DOCS -->
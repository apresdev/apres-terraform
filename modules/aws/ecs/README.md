# ECS

Creates an ECS cluster, service and task using the specified container image.

Supports:
* ephemeral volumes
* Fargate and EC2 Deployment
* Creation of an NLB to front the service.

The goal of this module is to setup an ECS cluster that has API Gateway in front of it.
The private connection from API Gateway to the ECS cluster is via VPC Links, and only
NLB's support that at time of writing.

Because API Gateway VPC Links do not have a security group attached, the NLB allows traffic in from
the private subnets.

Not supported at this time:
* Public-facing Load Balancers
* Classic Load Balancers
* Application Load Balancers
* HTTPS termination on the Load Balancer - while relatively simple to do this immediately gets into
  the question of which domain to use for private resources for which we don't have a good answer yet
* Only HTTP health checks are supported, TCP based health checks are not supported

If the deployment target is EC2, the instances are setup in an Autoscale group, deployed to the
Private subnets that were created using the Apres VPC module.

The network mode is always `awsvpc`. Windows is not supported.

## TODO Items

* Determine why NVMe drives (instance storage) can't be mounted consistently before docker starts.
  [Issue 107](https://github.com/apresdev/apres-terraform/issues/107)
* Support certs and HTTPS on the Load Balancers
  [Issue 108](https://github.com/apresdev/apres-terraform/issues/108)
* Support inbound security groups on the Load Balancer
  [Issue 109](https://github.com/apresdev/apres-terraform/issues/109)
* Add access logging to the Load Balancer
  [Issue 110](https://github.com/apresdev/apres-terraform/issues/110)
* Add ability to scale up/down by more than 1 EC2 instance
  [Issue 111](https://github.com/apresdev/apres-terraform/issues/111)


## Environment Variables
The following environment variables are passed to the container by default:

| Name | Description |
| -----| ----------- |
| AWS_REGION | AWS Region, like us-east-2, where the container is running |
| AWS_ACCOUNT_ID | Account ID where the container is running |
| ENVIRONMENT | Environment passed into the stack, used to tag all resources |
| APPLICATION | Application passed into the stack, used to tag all resources |
| COMPONENT | Component passed into the stack, used to tag all resources |

# AWS IAM Permissions

The following permissions are required to use this module, shown as a Policy snippet in JSON.
Substitute `${AWS::AccountId}` with the Account ID where this is deployed, and `${name}` with
the name passed in.

```json
{
  "Effect": "Allow",
  "Action": [
      "application-autoscaling:*",
      "autoscaling:*",
      "ec2:*",
      "ecs:*",
      "elasticloadbalancing:*",
      "logs:*",
  ]
  "Resource": "*"
},
{
  "Effect": "Allow",
  "Action": "iam:*",
  "Resource": [
    "arn:aws:iam::${AWS::AccountId}:policy/${name}-*",
    "arn:aws:iam::${AWS::AccountId}:role/${name}-*"
  ]
}
```
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6.0, <2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.56.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cloudwatchlogs"></a> [cloudwatchlogs](#module\_cloudwatchlogs) | git@github.com:apresdev/apres-terraform.git//modules/aws/cloudwatchlogs | rel/cloudwatchlogs/1.0.0 |

## Resources

| Name | Type |
|------|------|
| [aws_appautoscaling_policy.app_down](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_policy) | resource |
| [aws_appautoscaling_policy.app_up](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_policy) | resource |
| [aws_appautoscaling_target.app_scale_target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_target) | resource |
| [aws_autoscaling_group.ecs_asg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group) | resource |
| [aws_cloudwatch_metric_alarm.cpu_utilization_high](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.cpu_utilization_low](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_ecs_capacity_provider.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_capacity_provider) | resource |
| [aws_ecs_cluster.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster) | resource |
| [aws_ecs_cluster_capacity_providers.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster_capacity_providers) | resource |
| [aws_ecs_service.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_task_definition.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_iam_instance_profile.ec2_instance_role_profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.ec2_instance_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.task_execution_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.task_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.ec2_ecs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ec2_ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_launch_template.ecs_launch_template](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [aws_lb.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb_listener.tcp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_target_group.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_security_group.ecs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.ecs_asg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.nlb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.ecs_asg_ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.ecs_ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_ami.ecs_ami](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.ec2_instance_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.task_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_subnet.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |
| [aws_subnets.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets) | data source |
| [aws_vpc.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_application"></a> [application](#input\_application) | Application name, used for tagging AWS resources. | `string` | n/a | yes |
| <a name="input_cloudwatch_logs_group_name"></a> [cloudwatch\_logs\_group\_name](#input\_cloudwatch\_logs\_group\_name) | Name of the CloudWatch Logs group to send logs to, should be a path like /acme/blah.<br>  If not specified, the path will be created using the variables `/application/name-environment` | `string` | `""` | no |
| <a name="input_cloudwatch_logs_retention_days"></a> [cloudwatch\_logs\_retention\_days](#input\_cloudwatch\_logs\_retention\_days) | Number of days to retain logs in CloudWatch Logs | `number` | `365` | no |
| <a name="input_component"></a> [component](#input\_component) | Component name, used for tagging AWS resources. | `string` | n/a | yes |
| <a name="input_container_cpu_architecture"></a> [container\_cpu\_architecture](#input\_container\_cpu\_architecture) | The CPU architecture to use for the container, one of X86\_64 or ARM64. If using EC2, it must match the<br>  architecture of the instance type, but is not enforced here.<br><br>  See https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#runtime-platform<br><br>  There are special considerations when using ECS on ARM64,<br>  see https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-arm64.html | `string` | `"ARM64"` | no |
| <a name="input_container_environment_variables"></a> [container\_environment\_variables](#input\_container\_environment\_variables) | A map of environment variables to set in the container. The keys are the environment variable names, and the values are the<br>  environment variable values. For example:<pre>{<br>    "DATABASE_URL" = "postgres://host:5432/dbname"<br>    "DEBUG" = "true"<br>  }</pre>See the README.md for environment variables that are passed in by default. Any environment variables set<br>  here will be added. | `map(string)` | `{}` | no |
| <a name="input_container_health_check_command"></a> [container\_health\_check\_command](#input\_container\_health\_check\_command) | The command ECS should run to check the health of the container. This must be a command that returns 0<br>  if the container is healthy, and non-zero if it is not.<br><br>  If left blank there will be no health check, and the other health check variables will be ignored.<br><br>  This health check is different from the Load Balancer's health check and is run by the ECS service. It can be used even<br>  if the service has no network interface, and is run directly in the container by ECS.<br><br>  For example:<pre>["CMD-SHELL", "curl -f http://localhost:5000/metrics || exit 1"]</pre>See https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_HealthCheck.html<br>  for further details. | `list(string)` | `[]` | no |
| <a name="input_container_health_check_interval"></a> [container\_health\_check\_interval](#input\_container\_health\_check\_interval) | The time between health checks in seconds, ignored if `container_health_check_command` is not set.<br><br>  See https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_HealthCheck.html for details. | `number` | `30` | no |
| <a name="input_container_health_check_retries"></a> [container\_health\_check\_retries](#input\_container\_health\_check\_retries) | The number of retries to attempt before marking the container unhealthy, ignored if `container_health_check_command`<br>  is not set.<br><br>  See https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_HealthCheck.html for details. | `number` | `3` | no |
| <a name="input_container_health_check_start_period"></a> [container\_health\_check\_start\_period](#input\_container\_health\_check\_start\_period) | The time to wait before starting the health check in seconds, ignored if `container_health_check_command` is not set.<br><br>  See https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_HealthCheck.html for details. | `number` | `30` | no |
| <a name="input_container_health_check_timeout"></a> [container\_health\_check\_timeout](#input\_container\_health\_check\_timeout) | The time to wait for a health check to return a result in seconds, ignored if `container_health_check_command`<br>  is not set.<br><br>  See https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_HealthCheck.html for details. | `number` | `5` | no |
| <a name="input_container_image_uri"></a> [container\_image\_uri](#input\_container\_image\_uri) | URI of the container, should include the tag!<br>    An example using ECR:: 012345668901.dkr.ecr.us-east-2.amazonaws.com/backend:46c2c244158828aa06c90655f58f1cc55b641234 | `string` | n/a | yes |
| <a name="input_container_port"></a> [container\_port](#input\_container\_port) | TCP port number on which the application in the Docker container listens to, typically defined with<br>  the EXPOSE line in the Dockerfile.<br><br>  The default is -1, which means no port is exposed. You must set a value if using a Load Balancer. | `number` | `-1` | no |
| <a name="input_container_tmpfs"></a> [container\_tmpfs](#input\_container\_tmpfs) | Sometimes containers need to write temporary files, like Java does to /tmp and nginx in a /var/cache.<br>    To accommodate that, this parameter allows one more tmpfs filessystems to be added to the container.<br><br>    This is not supported on Fargate!<br><br>    Size is in Mb, see the link below for a full list of mount options. "rw" is likely the one you will need.<br>    For example:<pre>hcl<br>    {<br>       containerPath = "/tmp"<br>       mountOptions = ["rw"]<br>       size = 50<br>    }</pre>This will mount a 50Mb tmpfs filesystem at /tmp in the container.<br><br>    See "tmpfs" at this link for details:<br>    https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#container_definition_linuxparameters | <pre>list(object({<br>    containerPath = string,<br>    mountOptions  = list(string),<br>    size          = number,<br>  }))</pre> | `[]` | no |
| <a name="input_cpu"></a> [cpu](#input\_cpu) | The number of cpu units to reserve for the container. Default is the smallest possible Fargate size.<br><br>  If using Fargate, CPU and Memory settings must be paired correctly. They are not enforced here,<br>  see the description at<br>  https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html | `number` | `256` | no |
| <a name="input_create_load_balancer"></a> [create\_load\_balancer](#input\_create\_load\_balancer) | Create a load balancer for the service. If false, all variables starting with<br>    `load_balancer_` will be ignored." | `bool` | n/a | yes |
| <a name="input_deployment_target"></a> [deployment\_target](#input\_deployment\_target) | The deployment target for the ECS service, can be either "FARGATE" or "EC2". | `string` | n/a | yes |
| <a name="input_ec2_autoscale_max"></a> [ec2\_autoscale\_max](#input\_ec2\_autoscale\_max) | Maximum number of EC2 instances to scale to. Ignored if deployment\_target is FARGATE. | `number` | `3` | no |
| <a name="input_ec2_autoscale_min"></a> [ec2\_autoscale\_min](#input\_ec2\_autoscale\_min) | Minimum number of EC2 instances to scale to. Ignored if deployment\_target is FARGATE. | `number` | `1` | no |
| <a name="input_ec2_instance_type"></a> [ec2\_instance\_type](#input\_ec2\_instance\_type) | The EC2 instance type to use for the ECS service. The architecture of the instance type must match what you set in<br>  the variable container\_cpu\_architecture. Ignored if deployment\_target is FARGATE. | `string` | `"t3.micro"` | no |
| <a name="input_ec2_use_instance_nvme_storage"></a> [ec2\_use\_instance\_nvme\_storage](#input\_ec2\_use\_instance\_nvme\_storage) | NOTE this is not supported at this time, setting this to true will be ignored! See<br>  https://github.com/apresdev/apres-terraform/issues/107<br><br>  If true and deployment\_target is EC2, the instance will use NVMe storage for ephemeral storage. This is to<br>  be used together with the `ephemeral_volumes` variable.<br><br>  For example, an m7gd.medium has an NVMe SSD of 59GB, and using that as ephemeral storage has significant<br>  performance benefits over using EBS.<br><br>  The volume is transient and will be destroyed when the container is terminated.<br><br>  Capacity planning is critical - the NVMe volume must be large enough to support the ephemeral volume size,<br>  of _all_ the container instances that can run on the instance. For example:<br>  * An m7gd.large has 118GB of NVMe storage, and 2 vCPUs (or 2048 CPU units)<br>  * If your container has cpu=768, two containers may run on the instance, and if the ephemeral volume is more than 1/2<br>    of the 118GB NVMe volume, the ephemeral volume will not fit on the instance.<br><br>  NVMe storage is only supported on certain instance types, it is up to the user to verify the instance type<br>  has an NVME drive. If more than one are present, the first one according to `lsblk` will be used. | `bool` | `false` | no |
| <a name="input_ecs_autoscale_max_instances"></a> [ecs\_autoscale\_max\_instances](#input\_ecs\_autoscale\_max\_instances) | Maximum number of container instances to scale to | `number` | `10` | no |
| <a name="input_ecs_autoscale_min_instances"></a> [ecs\_autoscale\_min\_instances](#input\_ecs\_autoscale\_min\_instances) | Minimum number of container instances to scale down to | `number` | `1` | no |
| <a name="input_ecs_cpu_high_threshold_percent"></a> [ecs\_cpu\_high\_threshold\_percent](#input\_ecs\_cpu\_high\_threshold\_percent) | If the average CPU utilization over two minutes rises to this threshold,<br>  the number of containers will be increased (but not above ecs\_autoscale\_max\_instances). | `number` | `80` | no |
| <a name="input_ecs_cpu_low_threshold_percent"></a> [ecs\_cpu\_low\_threshold\_percent](#input\_ecs\_cpu\_low\_threshold\_percent) | If the average CPU utilization over a two minutes drops to this threshold,<br>  the number of container instances will be reduced (but not below ecs\_autoscale\_min\_instances). | `number` | `20` | no |
| <a name="input_ecs_task_iam_policy_document"></a> [ecs\_task\_iam\_policy\_document](#input\_ecs\_task\_iam\_policy\_document) | The IAM Policy document to attach to the ECS task. This is a JSON document, and should be a valid IAM policy. Example:<br>  {<br>    "Version": "2012-10-17",<br>    "Statement": [<br>      {<br>        "Effect": "Allow",<br>        "Action": "s3:ListBucket",<br>        "Resource": "arn:aws:s3:::mybucket"<br>      }<br>    ]<br>  }<br>  We recommend storing this in a separate file and using the file() or templatefile() function to load it. The default is an<br>  innocuous policy that allows the task to get its own identity with sts:GetCallerIdentity.<br><br>  An example of using a file, with the file `ecs-task-iam-policy.json` in the same directory as the module:<pre>hcl<br>      module "ecs" {<br>        # ...<br>        ecs_task_iam_policy_document = file("\$\{path.module\}/../../ecs-task-iam-policy.json")<br>      }</pre> | `string` | `"{\"Version\": \"2012-10-17\", \"Statement\": [ { \"Effect\": \"Allow\", \"Action\": \"sts:GetCallerIdentity\", \"Resource\": \"*\" } ] }"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment Name, used for naming and tagging AWS resources. | `string` | n/a | yes |
| <a name="input_ephemeral_volumes"></a> [ephemeral\_volumes](#input\_ephemeral\_volumes) | A list of maps, each map represents an ephemeral volume to mount in the container. The map should have the<br>    following keys:<br>    - name: The name of the volume, for example "data"<br>    - size\_in\_gb: The size of the volume in GB, for example 20. Must be between 21 and 200GB.<br>    - mount\_point: The mount point for the volume, for example "/data"<br>    This is a list but only one volume is supported at this time.<br>    Example:<br>    [<br>      {<br>        name = "data"<br>        size\_in\_gb = 21<br>        mount\_point = "/data"<br>      }<br>    ] | <pre>list(object({<br>    name       = string,<br>    mountpoint = string,<br>    size_in_gb = number,<br>  }))</pre> | `[]` | no |
| <a name="input_extra_tags"></a> [extra\_tags](#input\_extra\_tags) | Extra tags to be applied to all resources | `map(string)` | `{}` | no |
| <a name="input_load_balancer_health_check_healthy_threshold"></a> [load\_balancer\_health\_check\_healthy\_threshold](#input\_load\_balancer\_health\_check\_healthy\_threshold) | The number of consecutive successful health checks required before considering an unhealthy target healthy. See<br>  https://docs.aws.amazon.com/elasticloadbalancing/latest/network/target-group-health-checks.html#health-check-settings<br>  for details. | `number` | `5` | no |
| <a name="input_load_balancer_health_check_interval"></a> [load\_balancer\_health\_check\_interval](#input\_load\_balancer\_health\_check\_interval) | The time in seconds between health checks. See<br>  https://docs.aws.amazon.com/elasticloadbalancing/latest/network/target-group-health-checks.html#health-check-settings<br>  for details. | `number` | `30` | no |
| <a name="input_load_balancer_health_check_path"></a> [load\_balancer\_health\_check\_path](#input\_load\_balancer\_health\_check\_path) | The path to check for the load balancer health check.<br>  https://docs.aws.amazon.com/elasticloadbalancing/latest/network/target-group-health-checks.html#health-check-settings<br>  for details. | `string` | `"/"` | no |
| <a name="input_load_balancer_health_check_unhealthy_threshold"></a> [load\_balancer\_health\_check\_unhealthy\_threshold](#input\_load\_balancer\_health\_check\_unhealthy\_threshold) | The number of consecutive failed health checks required before considering the target unhealthy. See<br>  https://docs.aws.amazon.com/elasticloadbalancing/latest/network/target-group-health-checks.html#health-check-settings<br>  for details. | `number` | `2` | no |
| <a name="input_load_balancer_port"></a> [load\_balancer\_port](#input\_load\_balancer\_port) | Port the load balancer should listen on | `number` | `80` | no |
| <a name="input_memory"></a> [memory](#input\_memory) | The amount of memory to reserve for the container. Default is the smallest possible Fargate size.<br><br>  If using Fargate, CPU and Memory settings must be paired correctly. They are not enforced here,<br>  see the description at<br>  https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html | `number` | `512` | no |
| <a name="input_name"></a> [name](#input\_name) | Name used to create resources | `string` | n/a | yes |
| <a name="input_owner"></a> [owner](#input\_owner) | Owner of the resources, used for tagging AWS resources. | `string` | `"Engineering"` | no |
| <a name="input_vpc_environment_tag"></a> [vpc\_environment\_tag](#input\_vpc\_environment\_tag) | The `environment` tag used to look up the VPC and resources in it. Typically there's one VPC<br>    per account, with an environment like 'Dev', 'Test', or 'Prod' but there is a possibility of more<br>    if it was configured that way. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ec2_asg_arn"></a> [ec2\_asg\_arn](#output\_ec2\_asg\_arn) | ARN of the ECS AutoScaling Group, or empty string if using Fargate. |
| <a name="output_ec2_asg_name"></a> [ec2\_asg\_name](#output\_ec2\_asg\_name) | Name of the ECS AutoScaling Group, or empty string if using Fargate. |
| <a name="output_ecs_cluster_arn"></a> [ecs\_cluster\_arn](#output\_ecs\_cluster\_arn) | ARN of the ECS Cluster. |
| <a name="output_ecs_cluster_name"></a> [ecs\_cluster\_name](#output\_ecs\_cluster\_name) | Name of the ECS Cluster. |
| <a name="output_ecs_service_arn"></a> [ecs\_service\_arn](#output\_ecs\_service\_arn) | ARN of the ECS Service. |
| <a name="output_ecs_service_name"></a> [ecs\_service\_name](#output\_ecs\_service\_name) | Name of the ECS Service. |
| <a name="output_ecs_task_definition_arn"></a> [ecs\_task\_definition\_arn](#output\_ecs\_task\_definition\_arn) | ARN of the ECS Task Definition, includes the family and revision. |
| <a name="output_load_balancer_arn"></a> [load\_balancer\_arn](#output\_load\_balancer\_arn) | ARN of the Load Balancer if it was created, else an empty string. |
| <a name="output_load_balancer_dns_name"></a> [load\_balancer\_dns\_name](#output\_load\_balancer\_dns\_name) | FQDN of the Load Balancer if it was created, else an empty string. |
| <a name="output_load_balancer_target_group_arn"></a> [load\_balancer\_target\_group\_arn](#output\_load\_balancer\_target\_group\_arn) | ARN of the Load Balancer Target Group if it was created, else an empty string. |
<!-- END_TF_DOCS -->
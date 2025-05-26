variable "name" {
  description = "Name used to create resources"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9-_ ]+$", var.name))
    error_message = "Name must be alphanumeric and can contain hyphens and underscores."
  }
}

variable "extra_tags" {
  description = "Extra tags to be applied to all resources"
  type        = map(string)
  default     = {}
  validation {
    condition     = alltrue([for x in var.extra_tags : can(regex("^[A-Z][a-zA-Z0-9]+$", x))])
    error_message = "Tag values must be alphanumeric and capitalized."
  }
}

variable "application" {
  description = "Application name, used for tagging AWS resources."
  type        = string
  validation {
    condition     = can(regex("^[A-Z][a-zA-Z0-9]*$", var.application))
    error_message = "Application name must be alphanumeric and capitalized."
  }
}

variable "component" {
  description = "Component name, used for tagging AWS resources."
  type        = string
  validation {
    condition     = can(regex("^[A-Z][a-zA-Z0-9]*$", var.component))
    error_message = "Component name must be alphanumeric and capitalized."
  }
}

variable "owner" {
  description = "Owner of the resources, used for tagging AWS resources."
  type        = string
  default     = "Engineering"
  validation {
    condition     = can(regex("^[A-Z][a-zA-Z0-9]*$", var.owner))
    error_message = "Owner must be alphanumeric and capitalized."
  }
}

variable "environment" {
  description = "Environment Name, used for naming and tagging AWS resources."
  type        = string
  validation {
    condition     = can(regex("^[A-Z][a-zA-Z0-9]*$", var.environment))
    error_message = "Environment name must be alphanumeric and capitalized."
  }
}

variable "vpc_environment_tag" {
  description = <<EOF
    The `environment` tag used to look up the VPC and resources in it. Typically there's one VPC
    per account, with an environment like 'Dev', 'Test', or 'Prod' but there is a possibility of more
    if it was configured that way.
  EOF
  type        = string
  validation {
    condition     = can(regex("^[A-Z][a-zA-Z0-9]*$", var.vpc_environment_tag))
    error_message = "VPC Environment Tag must be alphanumeric and capitalized."
  }
}

variable "container_image_uri" {
  description = <<EOF
    URI of the container, should include the tag!
    An example using ECR:
    `012345668901.dkr.ecr.us-east-2.amazonaws.com/backend:46c2c244158828aa06c90655f58f1cc55b641234`
    EOF
  type        = string
}

variable "cpu" {
  description = <<EOF
  The number of cpu units to reserve for the container. Default is the smallest possible Fargate size.

  If using Fargate, CPU and Memory settings must be paired correctly. They are not enforced here,
  see the description at
  https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html
  EOF
  type        = number
  default     = 256
}

variable "memory" {
  description = <<EOF
  The amount of memory to reserve for the container. Default is the smallest possible Fargate size.

  If using Fargate, CPU and Memory settings must be paired correctly. They are not enforced here,
  see the description at
  https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html
  EOF
  type        = number
  default     = 512
}

variable "ecs_task_iam_policy_document" {
  description = <<EOF
  The IAM Policy document to attach to the ECS task. This is a JSON document, and should be a valid IAM policy. Example:
  ```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::mybucket"
    }
  ]
}
  ```
  We recommend storing this in a separate file and using the file() or templatefile() function to load it,
  or use the
  [aws_iam_policy_document data source](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document).
  The default is an innocuous policy that allows the task to get its own identity with sts:GetCallerIdentity.

  An example of using a file, with the file `ecs-task-iam-policy.json` in the same directory as the module:
  ```
module "ecs" {
  # ...
  ecs_task_iam_policy_document = file("\$\{path.module\}/../../ecs-task-iam-policy.json")
}
  ```
  EOF
  type        = string
  default     = "{\"Version\": \"2012-10-17\", \"Statement\": [ { \"Effect\": \"Allow\", \"Action\": \"sts:GetCallerIdentity\", \"Resource\": \"*\" } ] }"
}

variable "cloudwatch_logs_group_name" {
  description = <<EOF
  Name of the CloudWatch Logs group to send logs to, should be a path like /acme/blah.
  If not specified, the path will be created using the variables `/application/name-environment`
  EOF
  type        = string
  default     = ""
}

variable "cloudwatch_logs_retention_days" {
  description = "Number of days to retain logs in CloudWatch Logs"
  type        = number
  default     = 365
  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.cloudwatch_logs_retention_days)
    error_message = "Cloudwatch Logs retention days must be one of 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653."
  }
}

variable "ephemeral_volumes" {
  default = []
  type = list(object({
    name       = string,
    mountpoint = string,
    size_in_gb = number,
  }))
  validation {
    condition     = length(var.ephemeral_volumes) == 1 || length(var.ephemeral_volumes) == 0
    error_message = "Only zero or one ephemeral volume is supported at this time"
  }
  description = <<EOF
    A list of maps, each map represents an ephemeral volume to mount in the container. The map should have the
    following keys:
    - name: The name of the volume, for example "data"
    - size_in_gb: The size of the volume in GB, for example 20. Must be between 21 and 200GB.
    - mount_point: The mount point for the volume, for example "/data"
    This is a list but only one volume is supported at this time.
    Example:
    ```
[
  {
    name        = "data"
    size_in_gb  = 21
    mount_point = "/data"
  }
]
    ```
  EOF
}

variable "container_health_check_command" {
  description = <<EOF
  The command ECS should run to check the health of the container. This must be a command that returns 0
  if the container is healthy, and non-zero if it is not.

  If left blank there will be no health check, and the other health check variables will be ignored.

  This health check is different from the Load Balancer's health check and is run by the ECS service. It can be used even
  if the service has no network interface, and is run directly in the container by ECS.

  For example:
  ```
  ["CMD-SHELL", "curl -f http://localhost:5000/metrics \|\| exit 1"]
  ```

  See https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_HealthCheck.html
  for further details.
  EOF
  type        = list(string)
  default     = []
}

variable "container_health_check_interval" {
  description = <<EOF
  The time between health checks in seconds, ignored if `container_health_check_command` is not set.

  See https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_HealthCheck.html for details.
  EOF
  type        = number
  default     = 30
}

variable "container_health_check_timeout" {
  description = <<EOF
  The time to wait for a health check to return a result in seconds, ignored if `container_health_check_command`
  is not set.

  See https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_HealthCheck.html for details.
  EOF
  type        = number
  default     = 5
}

variable "container_health_check_retries" {
  description = <<EOF
  The number of retries to attempt before marking the container unhealthy, ignored if `container_health_check_command`
  is not set.

  See https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_HealthCheck.html for details.
  EOF
  type        = number
  default     = 3
}

variable "container_health_check_start_period" {
  description = <<EOF
  The time to wait before starting the health check in seconds, ignored if `container_health_check_command` is not set.

  See https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_HealthCheck.html for details.
  EOF
  type        = number
  default     = 30
}

variable "container_cpu_architecture" {
  description = <<EOF
  The CPU architecture to use for the container, one of X86_64 or ARM64. If using EC2, it must match the
  architecture of the instance type, but is not enforced here.

  See https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#runtime-platform

  There are special considerations when using ECS on ARM64,
  see https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-arm64.html
  EOF
  type        = string
  default     = "ARM64"
  validation {
    condition     = var.container_cpu_architecture == "X86_64" || var.container_cpu_architecture == "ARM64"
    error_message = "The only valid values for container_cpu_architecture is X86_64 or ARM64"
  }
}

variable "container_port" {
  description = <<EOF
  TCP port number on which the application in the Docker container listens to, typically defined with
  the EXPOSE line in the Dockerfile.

  The default is -1, which means no port is exposed. You must set a value if using a Load Balancer.

  EOF
  type        = number
  default     = -1
  validation {
    condition     = var.container_port == -1 || (var.container_port >= 1 && var.container_port <= 65535)
    error_message = "Container port must be -1, or between 1 and 65535"
  }
}

variable "container_secrets" {
  description = <<EOF
    To avoid passing in secrets in clear text, provide a list of ARNs of secrets in Secrets Manager to be securely
    injected as environment variables into the container.

    ARN's may include the secret ARN, or have the key name or a specific version appended. See the docs at
    https://docs.aws.amazon.com/AmazonECS/latest/developerguide/secrets-envvar-secrets-manager.html for
    details, with two examples following.

    The kms_key_alias it the KMS key alias that was used to encrypt the secret.

    Secrets are stored with key/value pairs in Secret Manager. If you want the full JSON object as the
    environment variable, the ARN should not include a key, for example:
    ```
{
  name          = "DATABASE_CONFIG"
  secret_arn    = "arn:aws:secretsmanager:us-east-2:123456789012:secret:mydbconfig"
  kms_key_alias = "aws/secretsmanager"
}
    ```
    and the resulting environment variable, stored as a string, might be:
    ```
DATABASE_CONFIG={"username":"mydbuser","password":"asdf","engine":"mariadb","host":"127.0.0.1","port":"12345","dbname":"asdf"}
    ```
    If you want just the password, which in this example is in Secrets Manager with the key `password`, the ARN should
    look like:
    ```
{
  name          = "DATABASE_PASSWORD"
  secret_arn    = "arn:aws:secretsmanager:us-east-2:123456789012:secret:mydbconfig:password"
  kms_key_alias = "aws/secretsmanager"
}
    ```
    and the resulting environment variable, stored as a string, might be:
    ```
DATABASE_PASSWORD=asdf
    ```

    The IAM permissions to read the secret ARN will be automatically added to the task execution role, including
    a statement to allow decryption using the KMS key(s) identified by their aliases.
  EOF
  type = list(object({
    name          = string
    secret_arn    = string
    kms_key_alias = string
  }))
  default = []
  validation {
    condition     = alltrue([for x in var.container_secrets : can(regex("^[a-zA-Z0-9_]+$", x.name))])
    error_message = "Secret names must be alphanumeric and can contain underscores."
  }
  validation {
    condition     = alltrue([for x in var.container_secrets : can(regex("^arn:aws:secretsmanager:[a-z0-9-]+:[0-9]{12}:secret:[a-zA-Z0-9-].+$", x.secret_arn))])
    error_message = "Secret ARNs must be in the format arn:aws:secretsmanager:region:account:secret:secret-name"
  }
}

variable "ecs_cpu_low_threshold_percent" {
  description = <<EOF
  If the average CPU utilization over a two minutes drops to this threshold,
  the number of container instances will be reduced (but not below ecs_autoscale_min_instances).
  EOF
  type        = number
  default     = 20
}

variable "ecs_cpu_high_threshold_percent" {
  description = <<EOF
  If the average CPU utilization over two minutes rises to this threshold,
  the number of containers will be increased (but not above ecs_autoscale_max_instances).
  EOF
  type        = number
  default     = 80
}

variable "ecs_autoscale_max_instances" {
  description = "Maximum number of container instances to scale to"
  type        = number
  default     = 10
  validation {
    condition     = var.ecs_autoscale_max_instances >= 1
    error_message = "Maximum number of instances must be at least 1"
  }
}

variable "ecs_autoscale_min_instances" {
  description = "Minimum number of container instances to scale down to"
  type        = number
  validation {
    condition     = var.ecs_autoscale_min_instances >= 1
    error_message = "Minimum number of instances must be at least 1"
  }
  default = 1
}

variable "container_environment_variables" {
  description = <<EOF
  A map of environment variables to set in the container. The keys are the environment variable names, and the values are the
  environment variable values. For example:
  ```
{
  "DATABASE_URL" = "postgres://host:5432/dbname"
  "DEBUG"        = "true"
}
  ```

  See the README.md for environment variables that are passed in by default. Any environment variables set
  here will be added.
  EOF
  type        = map(string)
  default     = {}
}

variable "deployment_target" {
  description = <<EOF
  The deployment target for the ECS service, can be either "FARGATE" or "EC2".
  EOF
  type        = string
  validation {
    condition     = var.deployment_target == "FARGATE" || var.deployment_target == "EC2"
    error_message = "deployment_target must be either FARGATE or EC2"
  }
}

variable "ec2_instance_type" {
  description = <<EOF
  The EC2 instance type to use for the ECS service. The architecture of the instance type must match what you set in
  the variable container_cpu_architecture. Ignored if deployment_target is FARGATE.
  EOF
  type        = string
  default     = "t3.micro"
}

variable "ec2_autoscale_min" {
  description = "Minimum number of EC2 instances to scale to. Ignored if deployment_target is FARGATE."
  type        = number
  default     = 1
}

variable "ec2_autoscale_max" {
  description = "Maximum number of EC2 instances to scale to. Ignored if deployment_target is FARGATE."
  type        = number
  default     = 3
}

variable "ec2_use_instance_nvme_storage" {
  description = <<EOF
  If true and deployment_target is EC2, the instance will use NVMe storage for ephemeral storage, mounting
  it as /var/lib/docker on the host.

  This is to be used together with the `ephemeral_volumes` variable.

  For example, an m7gd.medium has an NVMe SSD of 59GB, and using that as ephemeral storage has significant
  performance benefits over using EBS.

  The volume is transient and will be destroyed when the container is terminated.

  Capacity planning is critical - the NVMe volume must be large enough to support the ephemeral volume size,
  of _all_ the container instances that can run on the instance. For example:
  - An m7gd.large has 118GB of NVMe storage, and 2 vCPUs (or 2048 CPU units)
  - If your container has cpu=768, two containers may run on the instance, and if the ephemeral volume is more than 1/2
    of the 118GB NVMe volume, the ephemeral volume will not fit on the instance.

  NVMe storage is only supported on certain instance types, it is up to the user to verify the instance type
  has an NVME drive. If more than one are present, the first one according to `lsblk` will be used.
  EOF
  type        = bool
  default     = false
}

variable "container_tmpfs" {
  description = <<EOF
    Sometimes containers need to write temporary files, like Java does to /tmp and nginx in a /var/cache.
    To accommodate that, this parameter allows one more tmpfs filessystems to be added to the container.

    This is not supported on Fargate!

    Size is in Mb, see the link below for a full list of mount options. "rw" is likely the one you will need.
    For example:
    ```
{
   containerPath = "/tmp"
   mountOptions  = ["rw"]
   size          = 50
}
    ```

    This will mount a 50Mb tmpfs filesystem at /tmp in the container.

    See "tmpfs" at this link for details:
    https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#container_definition_linuxparameters

  EOF
  type = list(object({
    containerPath = string,
    mountOptions  = list(string),
    size          = number,
  }))
  default = []
}

variable "create_load_balancer" {
  description = <<EOF
    Create a load balancer for the service. If false, all variables starting with
    `load_balancer_` will be ignored.
  EOF
  type        = bool
}

variable "load_balancer_type" {
  description = <<EOF
    Load balancer type, can be either 'application' or 'network',
    for Application Load Balancer or Network Load Balancer. This is ignored if create_load_balancer is false.
    Default is 'network' for backwards compatibility.
  EOF
  type        = string
  default     = "network"
  validation {
    condition     = var.load_balancer_type == "application" || var.load_balancer_type == "network"
    error_message = "Load balancer type must be either 'application' or 'network'"
  }
}

variable "load_balancer_is_public" {
  description = <<EOF
  If true, the load balancer will be public, if false, it will be private. If public and no security groups
  are passed in through the `load_balancer_security_groups` variable, then a security group will be created
  allowing traffic through on 0.0.0.0/0!
  EOF
  type        = bool
  default     = false
}

variable "load_balancer_security_group" {
  description = <<EOF
    A security group ID to attach to the load balancer. If not specified, the following
    choices are made:
    - If the load balancer is public, 0.0.0.0/0 on the load balancer will be allowed.
    - If the load balancer is private, the private subnets CIDR's will be allowed.

    For network load balancers, adding or removing a security group will force a recreation of
    the load balancer.
  EOF
  type        = string
  default     = ""
}

variable "load_balancer_ssl_cert_arn" {
  description = <<EOF
    ARN of the SSL certificate to use for the load balancer.
    If specified, the protocol on the listener will be set to:
    - HTTPS for application load balancers
    - TLS for network load balancers
    If not specified, the load balancer will not use SSL, and protocol will be set to:
    - HTTP for application load balancers
    - TCP for network load balancers
  EOF
  type        = string
  default     = ""
}

variable "load_balancer_port" {
  description = "Port the load balancer should listen on"
  type        = number
  default     = 80
  validation {
    condition     = var.load_balancer_port >= 1 && var.load_balancer_port <= 65535
    error_message = "Container port must be between 1 and 65535"
  }
}

variable "load_balancer_health_check_path" {
  description = <<EOF
  The path to check for the load balancer health check.
  https://docs.aws.amazon.com/elasticloadbalancing/latest/network/target-group-health-checks.html#health-check-settings
  for details.
  EOF
  type        = string
  default     = "/"
}

variable "load_balancer_health_check_healthy_threshold" {
  description = <<EOF
  The number of consecutive successful health checks required before considering an unhealthy target healthy. See
  https://docs.aws.amazon.com/elasticloadbalancing/latest/network/target-group-health-checks.html#health-check-settings
  for details.
  EOF
  type        = number
  default     = 5
}

variable "load_balancer_health_check_unhealthy_threshold" {
  description = <<EOF
  The number of consecutive failed health checks required before considering the target unhealthy. See
  https://docs.aws.amazon.com/elasticloadbalancing/latest/network/target-group-health-checks.html#health-check-settings
  for details.
  EOF
  type        = number
  default     = 2
}

variable "load_balancer_health_check_interval" {
  description = <<EOF
  The time in seconds between health checks. See
  https://docs.aws.amazon.com/elasticloadbalancing/latest/network/target-group-health-checks.html#health-check-settings
  for details.
  EOF
  type        = number
  default     = 30
}

variable "crash_loop_threshold" {
  description = <<EOF
    Total number of times a task can crash, exit with a non-zero code, in a 300 second time period, before
    an alarm is triggered.
    EOF
  type        = number
  default     = 10
}

# ECS Standalone Task

Creates the resources required to run a standalone ECS task. This is useful for running
tasks on demand that are not part of a service that needs to run all the time, like an ETL job.

For any ECS service that should always be running, use the `ecs` module instead!

**Table of Contents**
- [ECS Standalone Task](#ecs-standalone-task)
  - [Dependencies](#dependencies)
  - [Environment Variables](#environment-variables)
  - [Secrets](#secrets)
  - [Running the task](#running-the-task)
    - [Shell Script Example](#shell-script-example)
  - [AWS IAM Permissions](#aws-iam-permissions)
  - [Requirements](#requirements)
  - [Providers](#providers)
  - [Modules](#modules)
  - [Resources](#resources)
  - [Inputs](#inputs)
  - [Outputs](#outputs)


This module supports:
* Ephemeral volumes
* Fargate deployment
* Health checks on the tasks - this may be useful for long-running tasks

The network mode is always `awsvpc`. Windows is not supported.

## Dependencies

This depends on the aws_accounts_config_workloads module to be deployed in the account/region,
at least version 0.6.

## Environment Variables
The following environment variables are passed to the container by default:

| Name | Description |
| -----| ----------- |
| AWS_REGION | AWS Region, like us-east-2, where the container is running |
| AWS_ACCOUNT_ID | Account ID where the container is running |
| ENVIRONMENT | Environment passed into the stack, used to tag all resources |
| APPLICATION | Application passed into the stack, used to tag all resources |
| COMPONENT | Component passed into the stack, used to tag all resources |

## Secrets

Secrets like passwords should _never_ be passed along in Environment variables. This module
supports using Secrets Manager, and then the secret values will never be visible. See
the comments on the `container_secrets` variable for examples.

## Running the task

To run the task from the CLI, use the `aws ecs run-task` command, using the outputs from this module. This
is a minimal example, where the variables like `${cluster}` are meant to represent
the output values from this module (e.g. the output `ecs_cluster_arn` is represented here as `${ecs_cluster_arn}`):

```bash
aws ecs run-task \
  --cluster ${ecs_cluster_arn} \
  --count 1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[${private_subnet_ids}],securityGroups=[${ecs_security_group_id}],assignPublicIp=DISABLED}" \
  --task-definition ${ecs_task_definition_arn} \
```

For example:
```bash
aws ecs run-task \
  --cluster arn:aws:ecs:us-east-2:111111111111:cluster/Myenv-myname \
  --count 1 \
  --launch-type FARGATE \
   --task-definition arn:aws:ecs:us-east-2:111111111111:task-definition/Myenv-myname-mike:1 \
   --network-configuration "awsvpcConfiguration={subnets=[subnet-0ef3,subnet-0ba6,subnet-0255],securityGroups=[sg-02c77decc0b937310],assignPublicIp=DISABLED}"
```

To pass in parameters, use the `--overrides` flag. For example, to pass in the environment variable
`MY_CUSTOM_NAME` with the value `test`, add the following line to the command above

```bash
  --overrides '{"containerOverrides":[{"name":"${container_name}","environment":[{"name":"MY_CUSTOM_NAME","value":"test"}]}]}'
```

The taskArn in the output will be the ARN of the task that was run, you can retrieve it with this
`jq` command:

```bash
aws ecs run-task ... | jq -r '.tasks[0].containers[0].taskArn'
```

To view the status of the task, use the following command, using the `ecs_cluster_arn` from the module output
and the task ARN from the previous command:

```bash
aws ecs describe-tasks \
  --cluster ${ecs_cluster_arn} \
  --tasks ${task_arn} | jq '.tasks[0].containers[0] | [.exitCode,.lastStatus]'
```

In the previous example the `jq` command will show the last status and exit code:
```json
[
  0,
  "STOPPED"
]
```
For a list of status values, see the
[ECS task lifecycle](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-lifecycle-explanation.html) documentation.

See  also the
[AWS ECS run-task](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/ecs/run-task.html)
or `aws ecs run-task help` for more details.

### Shell Script Example

The following shell script example runs the task, waits for the task to exit, and exits with the same exit
code as the task. Replace the first four variables with the outputs from the stack.

```bash
#!/usr/bin/env bash
CLUSTER_ARN="arn:aws:ecs:us-east-2:111111111111:cluster/Myenv-myname"
TASK_DEFINITION_ARN="arn:aws:ecs:us-east-2:111111111111:task-definition/Myenv-myname:1"
SUBNETS="subnet-0ef3e,subnet-0ba6,subnet-0255"
SECURITY_GROUP_ID="sg-02c7"

ARN=`AWS_PROFILE=apres-sandbox aws ecs run-task \
--cluster $CLUSTER_ARN \
--count 1 \
--launch-type FARGATE \
--task-definition $TASK_DEFINITION_ARN \
--network-configuration "awsvpcConfiguration={subnets=[$SUBNETS],securityGroups=[$SECURITY_GROUP_ID],assignPublicIp=DISABLED}" | jq -r '.tasks[0].containers[0].taskArn'`

echo "Running task ARN: $ARN"
while [ 1 ]
do
    STATUS=`AWS_PROFILE=apres-sandbox aws ecs describe-tasks --cluster ${CLUSTER_ARN} --tasks $ARN | jq -r '.tasks[0].containers[0].lastStatus'`
    if [ "$STATUS" == "STOPPED" ]; then
        EXIT_CODE=`AWS_PROFILE=apres-sandbox aws ecs describe-tasks --cluster ${CLUSTER_ARN} --tasks $ARN | jq -r '.tasks[0].containers[0].exitCode'`
        echo "Task stopped with exit code: $EXIT_CODE"
        if [ "$EXIT_CODE" == "0" ]; then
            exit 0
        else
            exit 1
        fi
    fi
    sleep 1
done
```

## AWS IAM Permissions

The following permissions are required to use this module, shown as a Policy snippet in JSON.
Substitute `${AWS::AccountId}` with the Account ID where this is deployed, and `${name}` with
the name passed in.

```json
{
  "Effect": "Allow",
  "Action": [
      "ec2:*",
      "ecs:*",
      "logs:*",
  ]
  "Resource": "*"
},
{
  "Effect": "Allow",
  "Action": "iam:*",
  "Resource": [
    "arn:aws:iam::${AWS::AccountId}:policy/${environment}-${name}-*",
    "arn:aws:iam::${AWS::AccountId}:role/${environment}-${name}-*"
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
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.72.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_apres_names"></a> [apres\_names](#module\_apres\_names) | git@github.com:apresdev/apres-terraform.git//modules/aws/apres_names | rel/apres_names/1.0.0 |
| <a name="module_cloudwatchlogs"></a> [cloudwatchlogs](#module\_cloudwatchlogs) | git@github.com:apresdev/apres-terraform.git//modules/aws/cloudwatchlogs | rel/cloudwatchlogs/1.1.0 |

## Resources

| Name | Type |
|------|------|
| [aws_ecs_cluster.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster) | resource |
| [aws_ecs_task_definition.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_iam_role.task_execution_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.task_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.task_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.task_execution_role_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_security_group.ecs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.task_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.task_execution_secrets_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_subnet.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |
| [aws_subnets.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets) | data source |
| [aws_vpc.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_application"></a> [application](#input\_application) | Application name, used for tagging AWS resources. | `string` | n/a | yes |
| <a name="input_cloudwatch_logs_group_name"></a> [cloudwatch\_logs\_group\_name](#input\_cloudwatch\_logs\_group\_name) | Name of the CloudWatch Logs group to send logs to, should be a path like /acme/blah.<br/>  If not specified, the path will be created using the variables `/application/name-environment` | `string` | `""` | no |
| <a name="input_cloudwatch_logs_retention_days"></a> [cloudwatch\_logs\_retention\_days](#input\_cloudwatch\_logs\_retention\_days) | Number of days to retain logs in CloudWatch Logs | `number` | `365` | no |
| <a name="input_component"></a> [component](#input\_component) | Component name, used for tagging AWS resources. | `string` | n/a | yes |
| <a name="input_container_cpu_architecture"></a> [container\_cpu\_architecture](#input\_container\_cpu\_architecture) | The CPU architecture to use for the container, one of X86\_64 or ARM64. If using EC2, it must match the<br/>  architecture of the instance type, but is not enforced here.<br/><br/>  See https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#runtime-platform<br/><br/>  There are special considerations when using ECS on ARM64,<br/>  see https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-arm64.html | `string` | `"ARM64"` | no |
| <a name="input_container_environment_variables"></a> [container\_environment\_variables](#input\_container\_environment\_variables) | A map of environment variables to set in the container. The keys are the environment variable names, and the values are the<br/>  environment variable values. For example:<pre>{<br/>  "DATABASE_URL" = "postgres://host:5432/dbname"<br/>  "DEBUG"        = "true"<br/>}</pre>See the README.md for environment variables that are passed in by default. Any environment variables set<br/>  here will be added. | `map(string)` | `{}` | no |
| <a name="input_container_health_check_command"></a> [container\_health\_check\_command](#input\_container\_health\_check\_command) | The command ECS should run to check the health of the container. This must be a command that returns 0<br/>  if the container is healthy, and non-zero if it is not.<br/><br/>  If left blank there will be no health check, and the other health check variables will be ignored.<br/><br/>  This health check is different from the Load Balancer's health check and is run by the ECS service. It can be used even<br/>  if the service has no network interface, and is run directly in the container by ECS.<br/><br/>  For example:<pre>["CMD-SHELL", "curl -f http://localhost:5000/metrics \|\| exit 1"]</pre>See https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_HealthCheck.html<br/>  for further details. | `list(string)` | `[]` | no |
| <a name="input_container_health_check_interval"></a> [container\_health\_check\_interval](#input\_container\_health\_check\_interval) | The time between health checks in seconds, ignored if `container_health_check_command` is not set.<br/><br/>  See https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_HealthCheck.html for details. | `number` | `30` | no |
| <a name="input_container_health_check_retries"></a> [container\_health\_check\_retries](#input\_container\_health\_check\_retries) | The number of retries to attempt before marking the container unhealthy, ignored if `container_health_check_command`<br/>  is not set.<br/><br/>  See https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_HealthCheck.html for details. | `number` | `3` | no |
| <a name="input_container_health_check_start_period"></a> [container\_health\_check\_start\_period](#input\_container\_health\_check\_start\_period) | The time to wait before starting the health check in seconds, ignored if `container_health_check_command` is not set.<br/><br/>  See https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_HealthCheck.html for details. | `number` | `30` | no |
| <a name="input_container_health_check_timeout"></a> [container\_health\_check\_timeout](#input\_container\_health\_check\_timeout) | The time to wait for a health check to return a result in seconds, ignored if `container_health_check_command`<br/>  is not set.<br/><br/>  See https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_HealthCheck.html for details. | `number` | `5` | no |
| <a name="input_container_image_uri"></a> [container\_image\_uri](#input\_container\_image\_uri) | URI of the container, should include the tag!<br/>    An example using ECR:<br/>    `012345668901.dkr.ecr.us-east-2.amazonaws.com/backend:46c2c244158828aa06c90655f58f1cc55b641234` | `string` | n/a | yes |
| <a name="input_container_secrets"></a> [container\_secrets](#input\_container\_secrets) | To avoid passing in secrets in clear text, provide a list of ARNs of secrets in Secrets Manager to be securely<br/>    injected as environment variables into the container.<br/><br/>    ARN's may include the secret ARN, or have the key name or a specific version appended. See the docs at<br/>    https://docs.aws.amazon.com/AmazonECS/latest/developerguide/secrets-envvar-secrets-manager.html for<br/>    details, with two examples following.<br/><br/>    The kms\_key\_alias it the KMS key alias that was used to encrypt the secret.<br/><br/>    Secrets are stored with key/value pairs in Secret Manager. If you want the full JSON object as the<br/>    environment variable, the ARN should not incluce a key, for example:<pre>{<br/>  name          = "DATABASE_CONFIG"<br/>  secret_arn    = "arn:aws:secretsmanager:us-east-2:123456789012:secret:mydbconfig"<br/>  kms_key_alias = "aws/secretsmanager"<br/>}</pre>and the resulting environment variable, stored as a string, might be:<pre>DATABASE_CONFIG={"username":"mydbuser","password":"asdf","engine":"mariadb","host":"127.0.0.1","port":"12345","dbname":"asdf"}</pre>If you want just the password, which in this example is in Secrets Manager with the key `password`, the ARN should<br/>    look like:<pre>{<br/>  name          = "DATABASE_PASSWORD"<br/>  secret_arn    = "arn:aws:secretsmanager:us-east-2:123456789012:secret:mydbconfig:password"<br/>  kms_key_alias = "aws/secretsmanager"<br/>}</pre>and the resulting environment variable, stored as a string, might be:<pre>DATABASE_PASSWORD=asdf</pre>The IAM permissions to read the secret ARN will be automatically added to the task execution role, including<br/>    a statement to allow decryption using the KMS key(s) identified by their aliases. | <pre>list(object({<br/>    name          = string<br/>    secret_arn    = string<br/>    kms_key_alias = string<br/>  }))</pre> | `[]` | no |
| <a name="input_container_tmpfs"></a> [container\_tmpfs](#input\_container\_tmpfs) | Sometimes containers need to write temporary files, like Java does to /tmp and nginx in a /var/cache.<br/>    To accommodate that, this parameter allows one more tmpfs filessystems to be added to the container.<br/><br/>    This is not supported on Fargate!<br/><br/>    Size is in Mb, see the link below for a full list of mount options. "rw" is likely the one you will need.<br/>    For example:<pre>{<br/>   containerPath = "/tmp"<br/>   mountOptions  = ["rw"]<br/>   size          = 50<br/>}</pre>This will mount a 50Mb tmpfs filesystem at /tmp in the container.<br/><br/>    See "tmpfs" at this link for details:<br/>    https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#container_definition_linuxparameters | <pre>list(object({<br/>    containerPath = string,<br/>    mountOptions  = list(string),<br/>    size          = number,<br/>  }))</pre> | `[]` | no |
| <a name="input_cpu"></a> [cpu](#input\_cpu) | The number of cpu units to reserve for the container. Default is the smallest possible Fargate size.<br/><br/>  If using Fargate, CPU and Memory settings must be paired correctly. They are not enforced here,<br/>  see the description at<br/>  https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html | `number` | `256` | no |
| <a name="input_ecs_task_iam_policy_document"></a> [ecs\_task\_iam\_policy\_document](#input\_ecs\_task\_iam\_policy\_document) | The IAM Policy document to attach to the ECS task. This is a JSON document, and should be a valid IAM policy. Example:<pre>{<br/>  "Version": "2012-10-17",<br/>  "Statement": [<br/>    {<br/>      "Effect": "Allow",<br/>      "Action": "s3:ListBucket",<br/>      "Resource": "arn:aws:s3:::mybucket"<br/>    }<br/>  ]<br/>}</pre>We recommend storing this in a separate file and using the file() or templatefile() function to load it,<br/>  or use the<br/>  [aws\_iam\_policy\_document data source](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document).<br/>  The default is an innocuous policy that allows the task to get its own identity with sts:GetCallerIdentity.<br/><br/>  An example of using a file, with the file `ecs-task-iam-policy.json` in the same directory as the module:<pre>module "ecs" {<br/>  # ...<br/>  ecs_task_iam_policy_document = file("\$\{path.module\}/../../ecs-task-iam-policy.json")<br/>}</pre> | `string` | `"{\"Version\": \"2012-10-17\", \"Statement\": [ { \"Effect\": \"Allow\", \"Action\": \"sts:GetCallerIdentity\", \"Resource\": \"*\" } ] }"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment Name, used for naming and tagging AWS resources. | `string` | n/a | yes |
| <a name="input_ephemeral_volumes"></a> [ephemeral\_volumes](#input\_ephemeral\_volumes) | A list of maps, each map represents an ephemeral volume to mount in the container. The map should have the<br/>    following keys:<br/>    - name: The name of the volume, for example "data"<br/>    - size\_in\_gb: The size of the volume in GB, for example 20. Must be between 21 and 200GB.<br/>    - mount\_point: The mount point for the volume, for example "/data"<br/>    This is a list but only one volume is supported at this time.<br/>    Example:<pre>[<br/>  {<br/>    name        = "data"<br/>    size_in_gb  = 21<br/>    mount_point = "/data"<br/>  }<br/>]</pre> | <pre>list(object({<br/>    name       = string,<br/>    mountpoint = string,<br/>    size_in_gb = number,<br/>  }))</pre> | `[]` | no |
| <a name="input_extra_tags"></a> [extra\_tags](#input\_extra\_tags) | Extra tags to be applied to all resources | `map(string)` | `{}` | no |
| <a name="input_memory"></a> [memory](#input\_memory) | The amount of memory to reserve for the container. Default is the smallest possible Fargate size.<br/><br/>  If using Fargate, CPU and Memory settings must be paired correctly. They are not enforced here,<br/>  see the description at<br/>  https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html | `number` | `512` | no |
| <a name="input_name"></a> [name](#input\_name) | Name used to create resources | `string` | n/a | yes |
| <a name="input_owner"></a> [owner](#input\_owner) | Owner of the resources, used for tagging AWS resources. | `string` | `"Engineering"` | no |
| <a name="input_vpc_environment_tag"></a> [vpc\_environment\_tag](#input\_vpc\_environment\_tag) | The `environment` tag used to look up the VPC and resources in it. Typically there's one VPC<br/>    per account, with an environment like 'Dev', 'Test', or 'Prod' but there is a possibility of more<br/>    if it was configured that way. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ecs_cluster_arn"></a> [ecs\_cluster\_arn](#output\_ecs\_cluster\_arn) | ARN of the ECS Cluster. |
| <a name="output_ecs_cluster_name"></a> [ecs\_cluster\_name](#output\_ecs\_cluster\_name) | Name of the ECS Cluster. |
| <a name="output_ecs_service_security_group_id"></a> [ecs\_service\_security\_group\_id](#output\_ecs\_service\_security\_group\_id) | Security Group ID to be used for the task |
| <a name="output_ecs_task_definition_arn"></a> [ecs\_task\_definition\_arn](#output\_ecs\_task\_definition\_arn) | ARN of the ECS Task Definition, includes the family and revision. |
| <a name="output_private_subnet_ids"></a> [private\_subnet\_ids](#output\_private\_subnet\_ids) | List of private subnet IDs where the task will run |
<!-- END_TF_DOCS -->
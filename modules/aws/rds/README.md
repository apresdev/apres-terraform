# RDS

This module provides a secure, simple way to create an Aurora RDS cluster. RDS is a very complex service,
this module trims down the choices to use Aurora MySQL or PostgreSQL.

**Table of Contents**
- [RDS](#rds)
  - [Decisions](#decisions)
  - [Future Plans](#future-plans)
  - [Database Engine Versions](#database-engine-versions)
  - [Deployment Notes](#deployment-notes)
  - [Managing the Master Password](#managing-the-master-password)
  - [IAM Authentication](#iam-authentication)
  - [Instance Class](#instance-class)
  - [Network Security](#network-security)
  - [Upgrades and Maintenance Windows](#upgrades-and-maintenance-windows)
  - [Alarms and Actions](#alarms-and-actions)
  - [AWS IAM Permissions](#aws-iam-permissions)
- [Auto-generated Module Details](#auto-generated-module-details)
  - [Requirements](#requirements)
  - [Providers](#providers)
  - [Modules](#modules)
  - [Resources](#resources)
  - [Inputs](#inputs)
  - [Outputs](#outputs)

## Decisions

This module contains the following decisions:
* The module only support Aurora PostgreSQL and Aurora MySQL. Aurora is extremely performant and
  scalable, and removes enough of the administration overhead, like managing disk space, that the extra cost is worth it.
* For Aurora MySQL, only Aurora MySQL 2.x (MySQL 5.7) and greater are supported. Aurora MySQL 1.x (MySQL v5.6) is
  not supported, as it lacks some functionality.
* DB instances will automatically be created in the persistence subnets, which has no internet access, inbound or outbound.
  That is, your DB instances will _never_ be available to the internet.
* When using Aurora Servless, only Serverless v2 is supported, as Serverless v1 is near end of life at time of writing.
* This module does not support direct integration between Amazon Aurora and AWS Secrets Manager due to limitations,
  see the [Managing the Master Password](#managing-the-master-password) section for further details.

## Future Plans

This module will incorporate AWS Backup to manage continuous and cross-region backups for Aurora.
See [Issue 340](https://github.com/apresdev/apres-terraform/issues/340).

## Database Engine Versions

The matrix of database engines, versions, and parameter groups names is complex and inconsistent. As of January 2025,
these are the latest recommended versions:

| Engine | Version | Paramater Group Name | Database Version |
| ------ | ------- | -------------------- | ---------------- |
| aurora-mysql | 8.0.mysql_aurora.3.08.0 | aurora-mysql8.0 | [Aurora MySQL 3.08.0](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraMySQLReleaseNotes/AuroraMySQL.Updates.3080.html) |
| aurora-postgresql | 16.6 | aurora-postgresql16 | [PostgreSQL 16 versions](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraPostgreSQLReleaseNotes/AuroraPostgreSQL.Updates.html#aurorapostgresql-versions-version16) |

To translate that, a code snippet using this module to deploy the latest version of Aurora MySQL:

```hcl
module "db" {
    # ...
    engine                    = "aurora-mysql"
    engine_version            = "8.0.mysql_aurora.3.08.0"
    db_parameter_group_family = "aurora-mysql8.0"
    # ...
}
```

and the equivalent Aurora PostgreSQL:

```hcl
module "db" {
    # ...
    engine                    = "aurora-postgresql"
    engine_version            = "16.6"
    db_parameter_group_family = "aurora-postgresql16"
    # ...
}
```

## Deployment Notes

* It can take upwards of 30 minutes to create or destroy a cluster.

## Managing the Master Password

AWS recommends directly integrating AWS Secrets Manager and Aurora, to seemlessly manage the master user's password.
However there are several service features - Aurora read replicas, Aurora RDS Blue/Green deployments,
and Aurora Global Database - that cannot be used when following that pattern, so this module
does not support the integration.

Instead, the module does the following:
* Create a random password, stores it in Secrets Manager for later consumption by other services.
* Creates the database using that password.
* Passes the Secrets ARN as an output.

A sample golang snippet using the AWS SDK to get the password follows, without error checking for brevity.
See [rdslambda/main.go](./tests/fixtures/rdslambda/main.go) in
this module's unit tests for the full example.

```golang
  ctx := context.Background()
  awsConfig, _ := config.LoadDefaultConfig(ctx)
  secretsClient := secretsmanager.NewFromConfig(awsConfig)
  secretData, err := secretsClient.GetSecretValue(ctx, &secretsmanager.GetSecretValueInput{
	  	SecretId: "Secrete ARN here, use the output `master_password_secret_arn`"
  })
  password := aws.ToString(secretData.SecretString)
```
To retrieve the password, your service's IAM identity will need access to both the secret and the KMS key.
A sample IAM policy document is as follows, using the outputs of this module. See this module's
unit test [main.tf](./tests/fixtures/main.tf) for a full example, where it grants a Lambda access
to retrieve the password.

```hcl
module "rds" {
  # removed for brevity...
}

data "aws_iam_policy_document" "lambda" {
  statement {
    effect = "Allow"
    actions = [ "secretsmanager:GetSecretValue" ]
    resources = [ module.rds.master_password_secret_arn ]
  }
  statement {
    effect = "Allow"
    actions = [ "kms:Decrypt" ]
    resources = [ module.rds.master_password_kms_key_arn ]
  }
}
```

## IAM Authentication

IAM Authentication to the DB is enabled by default. The PostgreSQL and MySQL native authentication remains
functional, but is not recommended for use.

See the
[IAM database authentication](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/UsingWithRDS.IAMDBAuth.html)
doc on how to connect to the Aurora DB cluster natively, using common languages.

## Instance Class

See [DB instance class types](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.DBInstanceClass.Types.html) for a list of instance families.

The list of supported instance types differs between regions and engine types, so much so that an entire
document exists to show how to find instances. See
[Determining DB instance class support in AWS regions](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.DBInstanceClass.RegionSupport.html) for the details.

## Network Security

By default, the Aurora cluster is created in the persistence subnets, which has no internet access inbound
or outbound. The Security Group used for the RDS cluster has no rules attached. There are three ways to
add access, the first two are effectively the same, due to possible race conditions both are supported. The
third is not recommended at all, but occasionally required.

1. Add your security group ID's to the `allow_ingress_security_groups` variable. Those security groups
   will be granted network access to the RDS cluster. For example:
   ```hcl
   module "rds" {
    # ...
    allow_ingress_security_groups = ["sg-06473c203d1659a12"]
   }
   ```
1. Use the output `security_group_id` and add your own security groups. See this module's
   unit test [main.tf](./tests/fixtures/main.tf) for an example of this, where it grants the Lambda's security
   group to the RDS security group. For example:
   ```hcl
     module "rds" {
       # removed for brevity
     }
     # Let the lambda access the RDS instance
     resource "aws_security_group_rule" "attach" {
       description              = "Allow Lambda to access RDS"
       type                     = "ingress"
       from_port                = module.rds.port
       to_port                  = module.rds.port
       protocol                 = "tcp"
       source_security_group_id = module.lambda.security_group_id
       security_group_id        = module.rds.security_group_id
     }
   ```
1. NOT RECOMMENDED! Set the `allow_ingress_from_all_private_subnets` to true. This grants inbound access
   to the RDS cluster from all private and persistence subnets. This is not recommended, but occasionally required
   by services that don't participate well in security groups.

## Upgrades and Maintenance Windows

By default, all changes that may cause an outage, typically those incurring a database restart,
occur during the specified maintenance window.

This module uses the `is_production` flag to manage that. In a production environment, this variable
_must_ be set to true, and breaking changes will take effect in the next maintenance window. In a development
environment, the `is_production` variable can be set to `false`, and changes will take effect immediately,
even if a restart is needed.

If the database in question is a production database, `is_production` is true, and a change needs to be
implemented immediately, we do NOT recommend changing the `is_production` flag. Instead, use the steps
at [Maintaining an Amazon Aurora DB cluster](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/USER_UpgradeDBInstance.Maintenance.html)
to force the changes to take effect.

## Alarms and Actions

The module, by default, creates a set of CloudWatch alarms that covers the basics.
The creation of the alarms and thresholds
are configured with the `create_cloudwatch_alarms` and `alarm_thresholds`. The alarm details
and runbooks are documented separately in [ALARMS_RUNBOOK.md](./ALARMS_RUNBOOK.md).

## AWS IAM Permissions

The following permissions are required to use this module, shown as a Policy snippet in JSON.
Substitute:
*  `${AWS::AccountId}` with the Account ID where this is deployed
*  `${AWS::Region}` with the region where this is deployed, like `us-east-2`
*  `${Name}` with the name passed in as the `name` variable
the name passed in.

```json
"Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sts:GetCallerIdentity",
                "ec2:Describe*",
                "iam:PassRole",
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "rds:*"
            ],
            "Resource": [
                "arn:aws:rds::${AWS::AccountId}:global-cluster:*",
                "arn:aws:rds:${AWS::Region}:${AWS::AccountId}:cluster:${Name}",
                "arn:aws:rds:${AWS::Region}:${AWS::AccountId}:cluster-pg:${Name}*",
                "arn:aws:rds:${AWS::Region}:${AWS::AccountId}:cluster-snapshot:*",
                "arn:aws:rds:${AWS::Region}:${AWS::AccountId}:og:*",
                "arn:aws:rds:${AWS::Region}:${AWS::AccountId}:pg:${Name}*",
                "arn:aws:rds:${AWS::Region}:${AWS::AccountId}:subgrp:${Name}",
                "arn:aws:rds:${AWS::Region}:${AWS::AccountId}:db:${Name}*",
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:*SecurityGroup*"
            ],
            "Resource": [
                "arn:aws:ec2:${AWS::Region}:${AWS::AccountId}:security-group/*",
                "arn:aws:ec2:${AWS::Region}:${AWS::AccountId}:vpc/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "iam:*",
            ],
            "Resource": "arn:aws:iam::${AWS::AccountId}:role/${Name}*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "kms:EnableKeyRotation",
                "kms:GetKeyRotationStatus",
                "kms:ListResourceTags",
                "kms:DescribeKey",
                "kms:GetKeyPolicy",
                "kms:PutKeyPolicy",
                "kms:ScheduleKeyDeletion"
            ],
            "Resource": "arn:aws:kms:${AWS::Region}:${AWS::AccountId}:key/*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:*"
            ],
            "Resource": "arn:aws:logs:${AWS::Region}:${AWS::AccountId}:log-group:/aws/rds/cluster/${Name}/*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "secretsmanager:CreateSecret",
                "secretsmanager:DescribeSecret",
                "secretsmanager:GetResourcePolicy",
                "secretsmanager:PutSecretValue",
                "secretsmanager:GetSecretValue",
                "secretsmanager:DeleteSecret"
            ],
            "Resource": "arn:aws:secretsmanager:${AWS::Region}:${AWS::AccountId}:secret:${Name}*"
        }
]
```

# Auto-generated Module Details
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.0, <2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.84.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.84.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.6.3 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_apres_names"></a> [apres\_names](#module\_apres\_names) | git@github.com:apresdev/apres-terraform.git//modules/aws/apres_names | rel/apres_names/1.0.0 |
| <a name="module_cloudwatchlogs"></a> [cloudwatchlogs](#module\_cloudwatchlogs) | git@github.com:apresdev/apres-terraform.git//modules/aws/cloudwatchlogs | rel/cloudwatchlogs/1.1.0 |
| <a name="module_cwa_acu_utilization"></a> [cwa\_acu\_utilization](#module\_cwa\_acu\_utilization) | git@github.com:apresdev/apres-terraform.git//modules/aws/cloudwatch_alarm | rel/cloudwatch_alarm/0.1.0 |
| <a name="module_cwa_buffer_cache_hit_ratio"></a> [cwa\_buffer\_cache\_hit\_ratio](#module\_cwa\_buffer\_cache\_hit\_ratio) | git@github.com:apresdev/apres-terraform.git//modules/aws/cloudwatch_alarm | rel/cloudwatch_alarm/0.1.0 |
| <a name="module_cwa_cpu_utilization"></a> [cwa\_cpu\_utilization](#module\_cwa\_cpu\_utilization) | git@github.com:apresdev/apres-terraform.git//modules/aws/cloudwatch_alarm | rel/cloudwatch_alarm/0.1.0 |
| <a name="module_cwa_freeable_memory"></a> [cwa\_freeable\_memory](#module\_cwa\_freeable\_memory) | git@github.com:apresdev/apres-terraform.git//modules/aws/cloudwatch_alarm | rel/cloudwatch_alarm/0.1.0 |
| <a name="module_cwa_read_latency"></a> [cwa\_read\_latency](#module\_cwa\_read\_latency) | git@github.com:apresdev/apres-terraform.git//modules/aws/cloudwatch_alarm | rel/cloudwatch_alarm/0.1.0 |
| <a name="module_cwa_write_latency"></a> [cwa\_write\_latency](#module\_cwa\_write\_latency) | git@github.com:apresdev/apres-terraform.git//modules/aws/cloudwatch_alarm | rel/cloudwatch_alarm/0.1.0 |

## Resources

| Name | Type |
|------|------|
| [aws_db_parameter_group.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_parameter_group) | resource |
| [aws_db_subnet_group.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group) | resource |
| [aws_iam_role.rds_monitoring](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.rds_monitoring](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_kms_key.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_kms_key_policy.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key_policy) | resource |
| [aws_rds_cluster.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_cluster) | resource |
| [aws_rds_cluster_instance.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_cluster_instance) | resource |
| [aws_rds_cluster_parameter_group.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_cluster_parameter_group) | resource |
| [aws_secretsmanager_secret.rds_master_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.rds_master_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_security_group.rds](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.ingress_private_subnets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.ingress_security_groups](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [random_password.master_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.rds_monitoring](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_subnet.persistence](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |
| [aws_subnet.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |
| [aws_subnets.persistence](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets) | data source |
| [aws_subnets.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets) | data source |
| [aws_vpc.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alarm_thresholds"></a> [alarm\_thresholds](#input\_alarm\_thresholds) | Thresholds for the cloudwatch alarms. This is ignored if `create_cloudwatch_alarms` is false."<br/><br/>  The thresholds are:<br/>  * cpu\_utilization: The CPU utilization percentage that, if the average over five minutes is greater than this threshold,<br/>    will trigger an alarm. Default is 85%.<br/>  * acu\_utilization: Only available in serverless configuration. The ACU utilization percentage that, if the average over<br/>    five minutes is greater than this threshold, will trigger an alarm. After Aurora hits 100% it cannot scale more.<br/>    Default is 85%.<br/>  * free\_memory: The amount of free memory in GB that, if the average over five minutes is less than this threshold,<br/>    will trigger an alarm. Default is 0.5GB, which is sufficient for small workloads.<br/>  * read\_latency: the average amount of time taken to read data from the database, in seconds. If the average over five<br/>    minutes is greater than this threshold, an alarm will be triggered. Default value is 100ms.<br/>  * write\_latency: the average amount of time taken to write data to the database, in seconds. If the average over five<br/>    minutes is greater than this threshold, an alarm will be triggered. Default value is 100ms.<br/>  * buffer\_cache\_hit\_ratio: The percentage of requests that are served by the buffer cache, if the average over five minutes is less<br/>    than this threshold, an alarm will be triggered. Default value is 85%.<br/><br/>  See the [Alarms and Actions](#alarms-and-actions) section of the README for more information. | <pre>object({<br/>    cpu_utilization        = number<br/>    acu_utilization        = number<br/>    free_memory            = number<br/>    read_latency           = number<br/>    write_latency          = number<br/>    buffer_cache_hit_ratio = number<br/>  })</pre> | <pre>{<br/>  "acu_utilization": 85,<br/>  "buffer_cache_hit_ratio": 85,<br/>  "cpu_utilization": 85,<br/>  "free_memory": 0.5,<br/>  "read_latency": 0.1,<br/>  "write_latency": 0.1<br/>}</pre> | no |
| <a name="input_allow_ingress_from_all_private_subnets"></a> [allow\_ingress\_from\_all\_private\_subnets](#input\_allow\_ingress\_from\_all\_private\_subnets) | If set to true, the security group will allow incoming connections from all private subnets<br/>    in the VPC. This is NOT recommended, as it opens up the database to all services running in the VPC.<br/><br/>    Apres recommends setting this to false, and either use the output `rds_security_group_id` to<br/>    add an ingress rule to allow your service to connect to the database, or add the security group<br/>    of your service to the "allow\_ingress\_security\_groups" variable. There _may_ be occasions where this<br/>    parameter is needed. | `bool` | `false` | no |
| <a name="input_allow_ingress_security_groups"></a> [allow\_ingress\_security\_groups](#input\_allow\_ingress\_security\_groups) | List of security group IDs to allow connections from. If `allow_ingress_from_all_private_subnets`<br/>    is set to false, this list can be populated with the security group IDs of the services that need to<br/>    connect to the database. | `list(string)` | `[]` | no |
| <a name="input_allow_major_version_upgrades"></a> [allow\_major\_version\_upgrades](#input\_allow\_major\_version\_upgrades) | Determines if major version upgrades are allowed. If set to true, the database<br/>    will be upgraded to the latest major version when it is available, in the next maintenance<br/>    window. If set to false, which is what you typically want in a production environment,<br/>    the database will not be upgraded.<br/><br/>    See the README for further discussion. | `bool` | `false` | no |
| <a name="input_application"></a> [application](#input\_application) | Application name, used for tagging AWS resources. | `string` | n/a | yes |
| <a name="input_backtrack_window"></a> [backtrack\_window](#input\_backtrack\_window) | The number of seconds to retain a backtrack window. The value represents the number<br/>    of seconds you can roll back the database in a point-in-time recovery.<br/><br/>    This feature is only available for aurora-mysql, and only in select regions. See<br/>    [Region and version availability](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraMySQL.Managing.Backtrack.html#AuroraMySQL.Managing.Backtrack.Availability)<br/>    for details. Use of this setting is ignored for aurora-postgresql.<br/><br/>    The default is 8 hours (21,600 seconds), the maximum possible is 72 hours (259,200 seconds).<br/><br/>    Setting to 0 seconds disables it, but note that it cannot be enabled later, turning it on<br/>    later requires a new cluster.<br/><br/>    There is a cost to Backtrack, although neglible. | `number` | `21600` | no |
| <a name="input_backup_retention_period"></a> [backup\_retention\_period](#input\_backup\_retention\_period) | Number of days to retain backups for. | `number` | `7` | no |
| <a name="input_backup_window"></a> [backup\_window](#input\_backup\_window) | Time range in UTC during which automated backups are created. For example,<br/>    04:00-04:30. Must not overlap with maintenance window. The default 06:00-06:30 UTC<br/>    is 01:00-01:30 EST. | `string` | `"06:00-06:30"` | no |
| <a name="input_component"></a> [component](#input\_component) | Component name, used for tagging AWS resources. | `string` | n/a | yes |
| <a name="input_create_cloudwatch_alarms"></a> [create\_cloudwatch\_alarms](#input\_create\_cloudwatch\_alarms) | If set to true, cloudwatch alarms will be created for the database. | `bool` | `true` | no |
| <a name="input_database_name"></a> [database\_name](#input\_database\_name) | Name of the database to create inside the DB cluster. This will be used by your<br/>    application. Database names must be lower case, and can contain numbers or underscores, with a maximum<br/>    of 63 letters. | `string` | n/a | yes |
| <a name="input_database_port"></a> [database\_port](#input\_database\_port) | Port the database listens on. If left as default, the default port for aurora-postgresql is 5432 and<br/>    aurora-mysql is 3306. The port is also given as an output `database_port`. | `number` | `0` | no |
| <a name="input_db_cluster_parameters"></a> [db\_cluster\_parameters](#input\_db\_cluster\_parameters) | A list of parameters you can customize on a DB cluster. If left empty, the default<br/>    parameters will be used, any values set here override the default.<br/><br/>    See the following docs for the parameters and the defaults:<br/>    * [Aurora PosgreSQL](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Reference.ParameterGroups.html)<br/>    * [Aurora MySQL](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraMySQL.Reference.ParameterGroups.html) | <pre>list(object({<br/>    name  = string<br/>    value = string<br/>  }))</pre> | `[]` | no |
| <a name="input_db_instance_parameters"></a> [db\_instance\_parameters](#input\_db\_instance\_parameters) | A list of parameters you can customize on a DB instance. If left empty, the default<br/>    parameters will be used, any values set here overridex the default.<br/><br/>    See the following docs for the parameters and the defaults:<br/>    * [Aurora PosgreSQL](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Reference.ParameterGroups.html#AuroraPostgreSQL.Reference.Parameters.Instance)<br/>    * [Aurora MySQL](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraMySQL.Reference.ParameterGroups.html#AuroraMySQL.Reference.Parameters.Instance) | <pre>list(object({<br/>    name  = string<br/>    value = string<br/>  }))</pre> | `[]` | no |
| <a name="input_db_parameter_group_family"></a> [db\_parameter\_group\_family](#input\_db\_parameter\_group\_family) | The name of the DB parameter group family to use. This is specific to the engine and version<br/>    of the database, and can't be calculated.<br/><br/>    Typical family groups are:<br/>    * aurora-postgresql16<br/>    * aurora-mysql8.0<br/><br/>    The definitive way to find a list of parameter group families is to use the AWS CLI:<br/>    `aws rds describe-db-engine-versions --engine aurora-postgresql --query 'DBEngineVersions[].DBParameterGroupFamily'`<br/>    or<br/>    `aws rds describe-db-engine-versions --engine aurora-mysql --query 'DBEngineVersions[].DBParameterGroupFamily'`<br/><br/>    See the README for more discussion on version and examples. | `string` | n/a | yes |
| <a name="input_engine"></a> [engine](#input\_engine) | One of the supported database engines, 'aurora-postgresql' or 'aurora-mysql' | `string` | n/a | yes |
| <a name="input_engine_version"></a> [engine\_version](#input\_engine\_version) | Version of the database engine to use. There is no default, since it depends on the `engine` variable,<br/>    which is one of 'aurora-postgresql' or 'aurora-mysql'.<br/><br/>    The definitive way to find a list of version is to use the AWS CLI:<br/>    `aws rds describe-db-engine-versions --engine aurora-postgresql --query 'DBEngineVersions[].EngineVersion'`<br/>    or<br/>    `aws rds describe-db-engine-versions --engine aurora-mysql --query 'DBEngineVersions[].EngineVersion'`<br/><br/>    Apres recommends using the latest version available, to extend the amount of time before you need<br/>    to upgrade. At January 2025 that is:<br/>    * aurora-postgresql: 16.6<br/>    * aurora-mysql: 3.08.0 | `string` | n/a | yes |
| <a name="input_enhanced_os_monitoring"></a> [enhanced\_os\_monitoring](#input\_enhanced\_os\_monitoring) | Granularity, in seconds, of how frequently operating system metrics are collected and sent to CloudWatch. Valid values<br/>    are 0 (disabled), 1, 5, 10, 15, 30, and 60 seconds. The default is 0, which disables enhanced monitoring. Enabling<br/>    this will increase CloudWatch costs. See<br/>    [OS metrics in Enhanced Monitoring](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/USER_Monitoring-Available-OS-Metrics.html)<br/>    for the list of metrics that will be collected. | `number` | `0` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name, used for naming and tagging AWS resources. | `string` | n/a | yes |
| <a name="input_extra_tags"></a> [extra\_tags](#input\_extra\_tags) | Extra tags to be applied to all resources | `map(string)` | `{}` | no |
| <a name="input_instance_class"></a> [instance\_class](#input\_instance\_class) | Instance class to use for the database. See the README for details.<br/><br/>    If the `serverless` variable is set, this variable is ignored. | `string` | n/a | yes |
| <a name="input_is_production"></a> [is\_production](#input\_is\_production) | Indicates if the database is a production database. This will be used to determine<br/>    two parameters - deletion protection of the instance, and deleting automated backups.<br/><br/>    If set to false:<br/>    * Deletion protection will be disabled<br/>    * Automated backups will be deleted when the instance is deleted<br/>    * No final snapshot will be taken when the instance is deleted<br/>    * Disruptive changes will be applied immediately instead of in the next maintenance window<br/><br/>    If set to true:<br/>    * Deletion protection will be enabled, the instance won't be able to be deleted without<br/>      a manual step to disable it<br/>    * Automated backups will be retained should the instance be deleted.<br/>    * A final snapshot of the DB will be taken on deletion, named the same as the instance name with<br/>      "-final" appended.<br/>    * Any disruptive changes will be applied in the next maintenance window.<br/>    * Plan and Apply will fail if `number_cluster_instances` < 2 | `bool` | `true` | no |
| <a name="input_maintenance_window"></a> [maintenance\_window](#input\_maintenance\_window) | Day and time range in UTC during which maintenance is performed. For example, Sun:05:00-Sun:05:30.<br/>    Must not overlap with `backup_window`. The default of Sun:07:00-Sun:07:30 UTC is 02:00-02:30 EST on<br/>    Sunday. | `string` | `"Sun:07:00-Sun:07:30"` | no |
| <a name="input_master_username"></a> [master\_username](#input\_master\_username) | Master username for the database | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Name used to create resources | `string` | n/a | yes |
| <a name="input_number_cluster_instances"></a> [number\_cluster\_instances](#input\_number\_cluster\_instances) | Number of instances in the cluster. Must be >= 2 if `is_production` is true.<br/><br/>    The first instance created will be the writer instance, and it can be accessed using the cluster endpoint. The<br/>    remainder of the instances will be read replicas, and can be accessed using the instance-specific endpoints. | `number` | `2` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | Owner of the resources, used for tagging AWS resources. | `string` | `"Engineering"` | no |
| <a name="input_performance_insights_retention"></a> [performance\_insights\_retention](#input\_performance\_insights\_retention) | Number of days for which to retain Performance Insights data. Must be 0, 7, 731, or a multiple of 31.<br/>    A value of 0 means performance insights are disabled. See<br/>    [Pricing and data retention for Performance Insights](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_PerfInsights.Overview.cost.html)<br/>    for all values. (Note that page talks about months, this value is in days, thus the 31 day multiple).<br/><br/>    Default is 7 days, which is in the free tier. | `number` | `7` | no |
| <a name="input_serverless"></a> [serverless](#input\_serverless) | If set to true, the database will be a serverless (v2) database. The `instance_class`<br/>    variable will be ignored. | `bool` | `false` | no |
| <a name="input_serverless_scaling"></a> [serverless\_scaling](#input\_serverless\_scaling) | Serverless scaling configuration, ignored if `serverless` is false.<br/><br/>    Auto-pause is only enabled if `min_capacity` is set to zero.<br/><br/>    See [Aurora Serverless v2 scaling](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-serverless-v2.how-it-works.html#aurora-serverless-v2.how-it-works.capacity)<br/>    for details on the capacity parameters. | <pre>object({<br/>    max_capacity             = number<br/>    min_capacity             = number<br/>    seconds_until_auto_pause = number<br/>  })</pre> | <pre>{<br/>  "max_capacity": 2,<br/>  "min_capacity": 0,<br/>  "seconds_until_auto_pause": 300<br/>}</pre> | no |
| <a name="input_storage_type"></a> [storage\_type](#input\_storage\_type) | One of "standard" or "io-optimized". Standard is the default, and is suitable for most workloads. See<br/>    [Storage configurations for Amazon Aurora DB clusters](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Overview.StorageReliability.html#aurora-storage-type)<br/>    for discussion on the two types. | `string` | `"standard"` | no |
| <a name="input_vpc_environment_tag"></a> [vpc\_environment\_tag](#input\_vpc\_environment\_tag) | The `environment` tag used to look up the VPC and resources in it. Typically there's one VPC<br/>    per account, with an environment like 'Dev', 'Test', or 'Prod' but there is a possibility of more<br/>    if it was configured that way. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output\_arn) | ARN of the RDS cluster |
| <a name="output_ca_certificate_identifier"></a> [ca\_certificate\_identifier](#output\_ca\_certificate\_identifier) | The identifier of the CA certificate for the RDS instance, required to create TLS connections |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | ID of the RDS cluster |
| <a name="output_cluster_members"></a> [cluster\_members](#output\_cluster\_members) | List of RDS cluster members |
| <a name="output_endpoint"></a> [endpoint](#output\_endpoint) | DNS address of the RDS cluster |
| <a name="output_master_password_kms_key_arn"></a> [master\_password\_kms\_key\_arn](#output\_master\_password\_kms\_key\_arn) | KMS Key ARN used to encrypt the master password for the RDS instance |
| <a name="output_master_password_kms_key_id"></a> [master\_password\_kms\_key\_id](#output\_master\_password\_kms\_key\_id) | KMS Key ID used to encrypt the master password for the RDS instance |
| <a name="output_master_password_secret_arn"></a> [master\_password\_secret\_arn](#output\_master\_password\_secret\_arn) | ARN of the secret containing the master password for the RDS instance |
| <a name="output_port"></a> [port](#output\_port) | Database Port |
| <a name="output_reader_endpoint"></a> [reader\_endpoint](#output\_reader\_endpoint) | Read-only endpoint for the Aurora cluster, automatically load-balanced across replicas |
| <a name="output_security_group_arn"></a> [security\_group\_arn](#output\_security\_group\_arn) | ARN of the security group for the RDS instance |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | ID of the security group for the RDS instance |
<!-- END_TF_DOCS -->
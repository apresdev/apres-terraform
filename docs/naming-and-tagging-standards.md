# Apres AWS Naming and Tagging Standards

## Naming

AWS resource names, displayed in the AWS console and returned in the CLI and API's, are not straightforward.
Some services like IAM are global and require globally unique names within the AWS account. S3
requires globally unique names among all customers and all regions. Most developers will at some point need
to deploy multiple instances of a service in a single AWS account and region, requiring unique names.

To accomplish all that, the default naming scheme used in Apres terraform modules will
be `${environment}-${name}` (See the [Apres Tags](#apres-tags)
section below for details on what `name` and `environment` represent) using the variables passed into the
the terraform modules. For example, if using the `ecs` module and the name is `backend` and environment is `Dev`, the
resulting name used for ECS resources will be `Dev-backend`. Services with special cases are outlined below.

Some resources, because of the complexity, may have an identifier appended. The ECS module in particular uses
this when creating IAM artifacts, since each ECS task uses at least two IAM roles. In those cases, the name
will be `${environment}-${name}-SomeIdentifier`.

The [apres-names](../modules/aws/apres_names/) module is the implementation of this standard.

### IAM Artifacts Naming

IAM resources are deployed globally, and there is a use case for needing to deploy the same stack and environment
in two regions in the same account. If the name of the IAM artifact is the same, the second deploy will fail. To
avoid this, wherever supporeted modules will use the
[name_prefix](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role#name_prefix)
argument, and the resulting name will be `${environment}-${name}-<unique_id>` where the unique_id is created by AWS.
Using the same example as above, the name could be `Dev-backend-20240409161750033900000001`.

An exception is made for IAM artifact names that need to be computed by outside resources, such as the roles used by GitHub
OIDC providers. Those roles must have static predictable names.

### S3 Bucket Naming

S3 buckets must be globally unique among all customers and regions. Names must also be in lower case.
To accomplish this the bucket name consist of four parts:
* Current 12 digit AWS Account ID.
* Environment in lower case.
* Current region, like `us-east-2`
* Name in lower case.

With a bucket name of `testbucket` and environment of `MyEnv` the bucket name would be
`123456789012-myenv-us-east-2-testbucket`.

## Tagging

Apres Terraform Modules will tag all AWS resources with a specific set of tags, see below for detailed explanation of the tags.

AWS has a great whitepaper (Best Practices for Tagging AWS Resources)[https://docs.aws.amazon.com/whitepapers/latest/tagging-best-practices/tagging-best-practices.html] which Apres modules follow.

These tags are used for:
* Identifying what a resource is used for.
* Tags are occasionally used for service discovery
* Tags are used in Cost Explorer and other FinOps tools to determine the cost of parts of the service.

## Apres Tags Conventions

By convention:
* Tag Keys are in Kebab case - all lower case with dashes between words.
* Tag Values are in Pascal case - each word is upper case, no spaces between words. Acronyms like `VPC` are kept in upper case, numbers are allowed.

Exceptions:
* The `Name` tag is a special case, the Key is Pascal case and the value can have spaces. The `Name` tag is what is usually displayed in the AWS Console. The value in most cases should match the resource name, and since it is case sensitive we do not
enforce it starting with a capital letter.

Apres internal testing enforces the tag values are as follows, using golang regular expressions:
* `Name` tag: `^[a-zA-Z0-9-_ ]+$`
* All others: `^[A-Z][a-zA-Z0-9]+$`

## Apres Tags

These are the tags set by Apres Terraform Modules.

| Tag Key |
| ------------- |
| [Name](#Name) |
| [application](#application) |
| [component](#component) |
| [environment](#environment) |
| [owner](#owner) |
| [managed-by](#managed-by) |

Best practice is to keep the values of `Name` and `environment` short, otherwise you could hit AWS name lenght limits in
unexpected places.

### Name

The Name of the resource, used by the AWS Console for display purposes.

Examples:
* DevVPC
* ProdDashboard

### application

The `application` is the high level bucket to organize your services into. Applications should not be granular, and
can be further divided into categories using the `component` tag.

Examples used by Apres:
* `Network` - core networking including VPC, Gateways, and NAT instances
* `FinOps` - Resources used to manage Cost Anomaly detection and Budgets
* `GitHub` - Resources used to interact with GitHub

### component

A `component` is a sub-category of an `application`.

Examples:
* `CostAnomalyDetection`, a component of the application `FinOps`
* `VPC`, a component of the application `Network`

### environment

Environment tags are meant to be used to allow multiple instances of an Apres module to be deployed in the same
AWS Account or region, and still differentiate between the instances. In some cases the `environment` tag value
is included in the computed resource `Name` where resources require unique names.

Examples:
* `Dev` - Development environment
* `DevForLoadTest` - Deployed in the same AWS account as a stack with the value `Dev`
* `Prod` - Production environment

### owner

Specifies the owner of the resource. This becomes increasingly important as infrastructure grows and AWS is used by
different departments of the organization.

Examples:
* `Engineering`
* `Finance`
* `Marketing`

### managed-by

The name of the tool managing the Infrastructure. Some tools like AWS CloudFormation add their own tags, but as
infrastructure grows it can be difficult to determine which Infrastructure-as-Code tool manages infrastructure, and
Apres recommends adopting this tag for that purpose.

Examples:
* `Terraform` - used by all Apres Terraform modules
* `CloudFormation` - used by all Apres CloudFormation templates



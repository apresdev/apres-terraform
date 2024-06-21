# Apres AWS Tagging

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



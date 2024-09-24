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

variable "api_version" {
  description = "The version of the API, for example v1, used for the stage name and will be the first part of the API path, but is not passed along to the container."
  type        = string
  default     = "v1"
}

variable "openapi_spec_file_path" {
  description = <<EOF
  The path to the OpenAPI spec file to use for the API Gateway.
  EOF
  type        = string
}

variable "openapi_spec_variables" {
  description = <<EOF
    Values to be substituted into the OpenAPI spec, that are only known at deploy time. This module
    uses the [templatefile](https://developer.hashicorp.com/terraform/language/functions/templatefile) function
    to substitute variables.

    For example, to include an Amazon integration, your OpenAPI spec might look like:
    ```
      x-amazon-apigateway-integration:
        connectionId: "$${vpc_link_connection_id}"
        connectionType: "VPC_LINK"
        httpMethod: "$${http_method}"
        type: "http_proxy"
        uri: "$${nlb_uri}"
        payloadFormatVersion: "1.0"
    ```
    and then the variables passed in here would include:
    ```
    module "api_gateway_rest" {
      ...
      openapi_spec_variables = {
        http_method = "ANY"
        nlb_uri = "https://$${aws_lb_listener.my_loadbalancer.dns_name}/"
      }
    }
    ```
    See the `load_balancer_arn` variable for details on the `vpc_link_connection_id` substitution.
  EOF
  type        = map(string)
}

variable "load_balancer_arn" {
  description = <<EOF
    The ARN of a target load balancer to which the API Gateway should be forwarding requests, as defined
    in the API spec. If this is set, a VPC Link will be created.

    Because the VPC Link ID is not known until after it is built, when the OpenAPI spec is processed, the
    variable `vpc_link_connection_id` will be substituted in with the actual VPC Link ID. An example of how
    to configure this in your OpenAPI Spec is:
    ```
     "x-amazon-apigateway-integration": {
          "connectionId": "$${vpc_link_connection_id}",
          "connectionType": "VPC_LINK",
          "httpMethod": "any",
          "type": "http_proxy",
          "uri": "https://$${nlb_uri}/blah",
    ```
    In this example the `nlb_uri` is set to DNS name of the load balancer handling the requests,
    not created in this module, and must be passed into the
    `openapi_spec_variables` variable. For example:
    ```
    resource "aws_lb" "my_loadbalancer" {
      ...
    }
    module "api_gateway_rest" {
      ...
      load_balancer_arn = aws_lb.my_loadbalancer.arn        # causes VPC Link to be created
      openapi_spec_variables = {
        nlb_uri = aws_lb_listener.my_loadbalancer.dns_name  # Used in the OpenAPI spec
      }
    }
    ```
  EOF
  type        = string
  default     = ""
}
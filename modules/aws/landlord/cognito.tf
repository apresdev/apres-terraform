locals {
  sms_region            = var.sms_aws_region == "" ? data.aws_region.current.name : var.sms_aws_region
  user_pool_name        = var.override_user_pool_name == "" ? "${local.name}-default-user-pool" : var.override_user_pool_name
  user_pool_client_name = var.override_user_pool_client_name == "" ? "${local.name}-default-user-pool-client" : var.override_user_pool_client_name
  default_email_message = format("{username} login here: %s with temporary password: {####}", var.app_url)
}

# Create a static UUID that will not change
resource "random_uuid" "sms_external_id" {
}

resource "aws_cognito_user_pool" "default" {
  name = local.user_pool_name

  email_verification_subject = "Your Verification Code"
  email_verification_message = "Please use the following code: {####}"

  admin_create_user_config {
    allow_admin_create_user_only = true
    invite_message_template {
      email_subject = format("Invitation for %s", var.app_url)
      email_message = var.invite_email_template_filename != "" ? file(var.invite_email_template_filename) : local.default_email_message
      sms_message   = format("{username} login here: %s with temporary password: {####}", var.app_url)
    }
  }

  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  # We keep the password policy constraints to a minimum, and use the advice
  # from NIST to inform the user of their password strength. Requiring specific
  # character sets doesn't necessarily make a strong password.
  password_policy {
    minimum_length                   = 8
    require_lowercase                = false
    require_numbers                  = false
    require_symbols                  = false
    require_uppercase                = false
    temporary_password_validity_days = 7
  }

  # Landlord allows for the additional / removal of MFA. With Cognito, if you require
  # MFA, it makes it awkward to temporarily disable in troubleshooting scenarios.
  mfa_configuration = "OPTIONAL"

  software_token_mfa_configuration {
    enabled = true
  }

  sms_configuration {
    external_id    = random_uuid.sms_external_id.result
    sns_caller_arn = aws_iam_role.landlord_sms_cognito_role.arn
    sns_region     = local.sms_region
  }

  email_configuration {
    email_sending_account  = var.cognito_email_sending_account
    from_email_address     = var.cognito_from_email_address
    reply_to_email_address = var.cognito_reply_to_email_address
    source_arn             = var.cognito_ses_source_arn
  }

  username_configuration {
    case_sensitive = false
  }

  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "email"
    required                 = true

    string_attribute_constraints {
      min_length = 5
      max_length = 128
    }
  }

  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "tenant"
    required                 = false

    string_attribute_constraints {
      # String representation of a UUID in the form
      # "123e4567-e89b-12d3-a456-426614174000"
      max_length = 36
    }
  }

  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "user"
    required                 = false

    string_attribute_constraints {
      # String representation of a UUID in the form
      # "123e4567-e89b-12d3-a456-426614174000"
      max_length = 36
    }
  }

  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "impersonate_tenant"
    required                 = false

    string_attribute_constraints {
      # String representation of a UUID in the form
      # "123e4567-e89b-12d3-a456-426614174000"
      max_length = 36
    }
  }

  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "impersonate_group"
    required                 = false

    string_attribute_constraints {
      # String of the form:
      # tenant-<tenant-uuid>-<role-name>
      max_length = 128
    }
  }

  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "impersonate_email"
    required                 = false

    string_attribute_constraints {
      min_length = 5
      max_length = 128
    }
  }

  # The Cognito ID of the impersonated user
  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "impersonate_sub"
    required                 = false

    string_attribute_constraints {
      # String representation of a UUID in the form
      # "123e4567-e89b-12d3-a456-426614174000"
      max_length = 36
    }
  }

  # The UserID of the impersonated user
  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "impersonate_user_id"
    required                 = false

    string_attribute_constraints {
      # String representation of a UUID in the form
      # "123e4567-e89b-12d3-a456-426614174000"
      max_length = 36
    }
  }

  # DEPRECATED
  # This impersonation claim was added with the wrong length (32 not 36).
  # And Cognito is so kind to make it impossible to change the length or
  # even delete the claim once it has been configured.
  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "impersonate_user"
    required                 = false

    string_attribute_constraints {
      max_length = 32
    }
  }

  user_pool_add_ons {
    advanced_security_mode = "AUDIT"
  }

  lambda_config {
    pre_token_generation_config {
      lambda_arn     = module.landlord_pre_token_generation_lambda.lambda_function_arn
      lambda_version = "V2_0"
    }
  }

  tags = merge(
    local.tags,
    {
      Name = local.user_pool_name
    },
  )
}

resource "aws_cognito_user_pool_client" "default" {
  name                 = local.user_pool_client_name
  explicit_auth_flows  = ["ALLOW_USER_PASSWORD_AUTH", "ALLOW_REFRESH_TOKEN_AUTH", "ALLOW_USER_SRP_AUTH"]
  user_pool_id         = aws_cognito_user_pool.default.id
  default_redirect_uri = "${var.app_url}/"
  callback_urls        = concat(["${var.app_url}/"], var.cognito_callback_urls)
  logout_urls          = ["${var.app_url}/logout"]
  generate_secret      = true
  allowed_oauth_flows  = ["code"]
  allowed_oauth_scopes = ["email", "openid", "aws.cognito.signin.user.admin"]
  # This enables the Cognito Hosted UI
  supported_identity_providers         = ["COGNITO"]
  allowed_oauth_flows_user_pool_client = true
}

resource "aws_cognito_user_pool_domain" "default" {
  domain       = var.custom_domain_prefix
  user_pool_id = aws_cognito_user_pool.default.id
}

resource "aws_cognito_user_pool_ui_customization" "example" {
  css        = var.hosted_ui_css_filename != "" ? file(var.hosted_ui_css_filename) : ""
  image_file = var.hosted_ui_logo_filename != "" ? filebase64(var.hosted_ui_logo_filename) : ""

  # Refer to the aws_cognito_user_pool_domain resource's
  # user_pool_id attribute to ensure it is in an 'Active' state
  user_pool_id = aws_cognito_user_pool_domain.default.user_pool_id
}

resource "aws_iam_role" "landlord_sms_cognito_role" {
  # Use prefix so this can be deployed in more than one region
  name_prefix = "${local.name}-SMSCognito"

  force_detach_policies = true

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "cognito-idp.amazonaws.com"
        },
        "Action" : "sts:AssumeRole",
        "Condition" : {
          "StringEquals" : {
            "sts:ExternalId" : random_uuid.sms_external_id.result
            "aws:SourceAccount" : data.aws_caller_identity.current.account_id
          },
          "ArnLike" : {
            "aws:SourceArn" : format(
              "arn:aws:cognito-idp:%s:%s:userpool/*",
              local.sms_region,
            data.aws_caller_identity.current.account_id)
          }
        }
      },
    ]
  })

  tags = merge(
    local.tags,
    {
      Name = "${local.name}-SMSCognito"
    },
  )
}

resource "aws_iam_role_policy" "landlord_sms_cognito_role_policy" {
  #checkov:skip=CKV_AWS_355:Need a wildcard on the SNS publish
  #checkov:skip=CKV_AWS_290:Need a wildcard on the SNS publish
  # Use prefix so this can be deployed in more than one region
  name_prefix = "${local.name}-SMSCognito"
  role        = aws_iam_role.landlord_sms_cognito_role.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "sns:publish"
        ],
        "Resource" : [
          "*"
        ]
      }
    ]
  })
}

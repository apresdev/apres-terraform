
// used for both the webapp and landlord ECS module.
data "aws_iam_policy_document" "ecs_task" {
  #checkov:skip=CKV_AWS_356:Need a wildcard for the IAM statements
  #checkov:skip=CKV_AWS_111:Need a wildcard for the IAM statements
  statement {
    effect = "Allow"
    actions = [
      "ses:SendEmail",
      "cognito-idp:AdminAddUserToGroup",
      "cognito-idp:AdminConfirmSignUp",
      "cognito-idp:AdminCreateUser",
      "cognito-idp:AdminDeleteUser",
      "cognito-idp:AdminGetUser",
      "cognito-idp:AdminAddUserToGroup",
      "cognito-idp:AdminConfirmSignUp",
      "cognito-idp:AdminCreateUser",
      "cognito-idp:AdminDeleteUser",
      "cognito-idp:AdminDisableUser",
      "cognito-idp:AdminEnableUser",
      "cognito-idp:AdminGetUser",
      "cognito-idp:AdminListUserAuthEvents",
      "cognito-idp:AdminRemoveUserFromGroup",
      "cognito-idp:AdminResetUserPassword",
      "cognito-idp:AdminSetUserMFAPreference",
      "cognito-idp:AdminSetUserPassword",
      "cognito-idp:AdminUpdateUserAttributes",
      "cognito-idp:AssociateSoftwareToken",
      "cognito-idp:ConfirmForgotPassword",
      "cognito-idp:ConfirmSignUp",
      "cognito-idp:CreateGroup",
      "cognito-idp:DeleteGroup",
      "cognito-idp:DescribeUserPool",
      "cognito-idp:DescribeUserPoolClient",
      "cognito-idp:DescribeUserPoolDomain",
      "cognito-idp:ForgotPassword",
      "cognito-idp:GetGroup",
      "cognito-idp:InitiateAuth",
      "cognito-idp:ListUserPoolClients",
      "cognito-idp:ListUserPools",
      "cognito-idp:ListUsers",
      "cognito-idp:RespondToAuthChallenge",
      "cognito-idp:SignUp",
      "cognito-idp:VerifySoftwareToken"
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:DeleteItem",
      "dynamodb:DescribeTable",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:Query",
      "dynamodb:Scan"
    ]
    resources = [
      module.landlord_dynamo.table_arn
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:Query"
    ]
    resources = [
      "${module.landlord_dynamo.table_arn}/index*"
    ]
  }
}

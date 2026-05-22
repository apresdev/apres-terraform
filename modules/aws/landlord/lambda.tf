# This lambda runs prior to token generation and is responsible for adding
# our custom Landlord claims to the access token. This includes the tenant
# claim, and any impersonation claims.
module "landlord_pre_token_generation_lambda" {
  #checkov:skip=CKV_TF_1:False positive, we are not using a hash because we use the tagged version.
  source      = "git::https://github.com/apresdev/apres-terraform.git//modules/aws/lambda?ref=rel/lambda/1.2.3"
  name        = "${var.name}-token"
  environment = var.environment
  source_file = "${path.module}/lambda/landlord_pre_token_generation_lambda.mjs"
  runtime     = "nodejs20.x"
  handler     = "landlord_pre_token_generation_lambda.handler"
}

resource "aws_lambda_permission" "with_sns" {
  statement_id  = "AllowExecuteFromCognito"
  action        = "lambda:InvokeFunction"
  function_name = module.landlord_pre_token_generation_lambda.lambda_function_arn
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.default.arn
}

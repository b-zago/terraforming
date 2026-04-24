#check permissions on lambda_core it actually needs a role for s3 + cloudwatch
module "lambda_authorizer" {
  source = "../modules/lambda"
  lambda_func = {
    function_name = "netpipe-authorizer"
    handler       = "lambda_auth.lambda_handler"
    runtime       = "python3.14"
    source_file   = "./lambda/lambda_auth.py"
    role_arn      = aws_iam_role.lambda_authorizer_iam_role.arn
    role_name     = aws_iam_role.lambda_authorizer_iam_role.name
    timeout       = 5
    memory_size   = 128
    logging       = true
  }
}

module "lambda_core" {
  source = "../modules/lambda"
  lambda_func = {
    function_name = "netpipe-core"
    handler       = "lambda_core.lambda_handler"
    runtime       = "python3.14"
    source_file   = "./lambda/lambda_core.py"
    role_arn      = aws_iam_role.lambda_core_iam_role.arn
    role_name     = aws_iam_role.lambda_core_iam_role.name
    timeout       = 20
    memory_size   = 128
    logging       = true
  }
}

module "lambda_monthly" {
  source = "../modules/lambda"
  lambda_func = {
    function_name = "netpipe-monthly"
    handler       = "lambda_monthly.lambda_handler"
    runtime       = "python3.14"
    source_file   = "./lambda/lambda_monthly.py"
    role_arn      = aws_iam_role.lambda_monthly_iam_role.arn
    role_name     = aws_iam_role.lambda_monthly_iam_role.name
    timeout       = 10
    memory_size   = 128
    logging       = true
  }
}

resource "aws_lambda_permission" "lambda_auth_permission" {
  statement_id  = "AllowGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_authorizer.lambda_data.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.gateway_http_api.execution_arn}/*"
}

resource "aws_lambda_permission" "lambda_core_permission" {
  statement_id  = "AllowGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_core.lambda_data.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.gateway_http_api.execution_arn}/*"
}

resource "aws_lambda_permission" "lambda_monthly_permission" {
  statement_id  = "AllowSchedulerInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_monthly.lambda_data.arn
  principal     = "scheduler.amazonaws.com"
  source_arn    = aws_scheduler_schedule.monthly_scheduler.arn
}


output "api_endpoint" {
  value = "http://${aws_apigatewayv2_api.gateway_http_api.id}.execute-api.localhost.localstack.cloud:4566/${aws_apigatewayv2_stage.api_stage.name}/"
}

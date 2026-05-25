module "ecr" {
  source                             = "../modules/ecr/"
  repository_name                    = local.name
  oidc_provider_arn                  = var.oidc_provider_arn
  repository_lambda_pull_access_arns = [module.lambda.arn]
  gh_lambda_arn                      = module.lambda.arn
}

module "lambda" {
  source        = "../modules/lambdav2"
  role_name     = "${local.name}-lambda-role"
  function_name = "${local.name}-${local.env}"
  image_uri     = module.ecr.repository_url
  allowed_permissions = {
    dynamodb = {
      actions   = ["dynamodb:Scan", "dynamodb:PutItem", "dynamodb:DeleteItem", "dynamodb:BatchWriteItem"]
      resources = [aws_dynamodb_table.dynamodb_table.arn]
    }
    ssm = {
      actions   = ["ssm:GetParameter"]
      resources = [aws_ssm_parameter.app_parameters.arn]
    }
  }
  environemt = {
    NYANWATCH_TABLE = local.dynamodb_table
    TIMEOUT         = "1"
    HMAC_KEY        = var.HMAC_KEY
    RECEIVER_ID     = var.RECEIVER_ID
  }
}

module "scheduler" {
  source              = "../modules/scheduler/"
  schedule_expression = "rate(1 minute)"
  scheduler_name      = "${local.name}-${local.env}"
  target_arn          = module.lambda.arn
  role_name           = "${local.name}-scheduler-role"
  allowed_permissions = {
    lambda = {
      actions   = ["lambda:InvokeFunction"]
      resources = [module.lambda.arn]
    }
  }
}

resource "aws_dynamodb_table" "dynamodb_table" {
  name         = local.dynamodb_table
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "service"

  attribute {
    name = "service"
    type = "S"
  }
}

resource "aws_ssm_parameter" "app_parameters" {
  name  = "/nyanwatch/endpoints"
  type  = "String"
  value = file("${path.module}/endpoints.json")
}

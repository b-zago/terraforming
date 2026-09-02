data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "lambda_authorizer_permissions" {
  statement {
    effect = "Allow"

    actions   = ["dynamodb:GetItem", "dynamodb:UpdateItem"]
    resources = [aws_dynamodb_table.dynamodb_table.arn]
  }
}

resource "aws_iam_role" "lambda_authorizer_iam_role" {
  name               = "netpipe-lambda-authorizer-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  description        = "Grants read access to NetpipeUsers dynamodb table"
}

resource "aws_iam_policy" "lambda_authorizer_policy" {
  name   = "netpipe-lambda-authorizer-policy"
  policy = data.aws_iam_policy_document.lambda_authorizer_permissions.json
}

resource "aws_iam_role_policy_attachment" "lambda_authorizer_policy_attachment" {
  role       = aws_iam_role.lambda_authorizer_iam_role.name
  policy_arn = aws_iam_policy.lambda_authorizer_policy.arn
}

###---LAMBDA-CORE---###

data "aws_iam_policy_document" "lambda_core_permissions" {
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:HeadObject"]
    resources = ["${aws_s3_bucket.s3_bucket.arn}/*"]
  }
  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.s3_bucket.arn]
  }
  statement {
    effect = "Allow"

    actions   = ["dynamodb:UpdateItem"]
    resources = [aws_dynamodb_table.dynamodb_table.arn]
  }
}

resource "aws_iam_role" "lambda_core_iam_role" {
  name               = "netpipe-lambda-core-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  description        = "Grants update permission to NetpipeUsers dynamodb table + read/write to netpipe-bucket"
}

resource "aws_iam_policy" "lambda_core_policy" {
  name   = "netpipe-lambda-core-policy"
  policy = data.aws_iam_policy_document.lambda_core_permissions.json
}

resource "aws_iam_role_policy_attachment" "lambda_core_policy_attachment" {
  role       = aws_iam_role.lambda_core_iam_role.name
  policy_arn = aws_iam_policy.lambda_core_policy.arn
}

###---LAMBDA MONTHLY---###

data "aws_iam_policy_document" "lambda_monthly_permissions" {
  statement {
    sid    = "AllowDynamodbScanUpdate"
    effect = "Allow"

    actions = ["dynamodb:Scan", "dynamodb:UpdateItem"]

    resources = [aws_dynamodb_table.dynamodb_table.arn]
  }
}

resource "aws_iam_role" "lambda_monthly_iam_role" {
  name               = "netpipe-lambda-monthly-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_policy" "lambda_monthly_policy" {
  name   = "netpipe-lambda-monthly-policy"
  policy = data.aws_iam_policy_document.lambda_monthly_permissions.json
}

resource "aws_iam_role_policy_attachment" "lambda_monthly_policy_attachment" {
  role       = aws_iam_role.lambda_monthly_iam_role.name
  policy_arn = aws_iam_policy.lambda_monthly_policy.arn
}

###---SCHEDULER---###

data "aws_iam_policy_document" "scheduler_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "scheduler_permissions" {
  statement {
    effect = "Allow"

    actions = ["lambda:InvokeFunction"]

    resources = [module.lambda_monthly.lambda_data.arn]
  }
}

resource "aws_iam_role" "scheduler_iam_role" {
  name               = "netpipe-scheduler-role"
  assume_role_policy = data.aws_iam_policy_document.scheduler_assume_role.json
}

resource "aws_iam_policy" "scheduler_policy" {
  name   = "netpipe-scheduler-policy"
  policy = data.aws_iam_policy_document.scheduler_permissions.json
}

resource "aws_iam_role_policy_attachment" "scheduler_policy_attachment" {
  role       = aws_iam_role.scheduler_iam_role.name
  policy_arn = aws_iam_policy.scheduler_policy.arn
}

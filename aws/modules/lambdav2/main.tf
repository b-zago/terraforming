resource "aws_lambda_function" "this" {
  function_name = var.function_name
  role          = aws_iam_role.this.arn
  memory_size   = var.memory_size
  timeout       = var.timeout
  package_type  = var.create_image_lambda ? "Image" : "Zip"
  architectures = tolist(var.architectures)

  environment {
    variables = var.environemt
  }

  tags = var.tags

  #image specific
  image_uri = var.create_image_lambda ? "${var.image_uri}:${var.latest_tag}" : null

  dynamic "image_config" {
    for_each = var.image_config != null ? [1] : []

    content {
      entry_point       = image_config.value.entry_point
      command           = image_config.value.command
      working_directory = image_config.value.working_directory
    }
  }

  #zip specific
  filename    = var.create_image_lambda ? null : data.archive_file.this[0].output_path
  handler     = var.create_image_lambda ? null : var.zip_config.handler
  code_sha256 = var.create_image_lambda ? null : data.archive_file.this[0].output_base64sha256
  runtime     = var.create_image_lambda ? null : var.zip_config.runtime

  #cloudwatch log group depends on

  depends_on = var.enable_logging ? [aws_cloudwatch_log_group.this] : null

}

#image specific
data "archive_file" "this" {
  count = var.create_image_lambda ? 0 : 1

  type        = "zip"
  source_file = var.zip_config.path_is_file ? var.zip_config.source_path : null
  source_dir  = var.zip_config.path_is_file ? null : var.zip_config.source_path
  output_path = var.zip_config.output_path
}

###---IAM---###

data "aws_iam_policy_document" "lambda_ar" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "lambda" {
  dynamic "statement" {
    for_each = var.allowed_permissions != null ? var.allowed_permissions : []

    content {
      effect    = "Allow"
      actions   = statement.value.actions
      resources = statement.value.resources
    }

  }
}

resource "aws_iam_policy" "this" {
  count = var.allowed_permissions != null ? 1 : 0

  name   = "${var.role_name}-policy"
  policy = data.aws_iam_policy_document.lambda.json
}

resource "aws_iam_role" "this" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.lambda_ar.json
}

resource "aws_iam_role_policy_attachment" "ar" {
  count = var.enable_logging ? 1 : 0

  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "this" {
  count = var.allowed_permissions != null ? 1 : 0

  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this[0].arn
}

###---LOGGING---###

resource "aws_cloudwatch_log_group" "this" {
  count = var.enable_logging ? 1 : 0

  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.logging_retention

  tags = var.tags
}


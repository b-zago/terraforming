data "archive_file" "this" {
  type        = "zip"
  source_file = var.lambda_func.source_file
  output_path = "${trimsuffix(var.lambda_func.source_file, ".py")}.zip"
}

resource "aws_lambda_function" "this" {
  filename      = data.archive_file.this.output_path
  function_name = var.lambda_func.function_name
  role          = var.lambda_func.role_arn
  handler       = var.lambda_func.handler
  code_sha256   = data.archive_file.this.output_base64sha256
  runtime       = var.lambda_func.runtime
  timeout       = var.lambda_func.timeout
  memory_size   = var.lambda_func.memory_size

  depends_on = [aws_cloudwatch_log_group.this]
}

resource "aws_iam_role_policy_attachment" "this" {
  count      = var.lambda_func.logging ? 1 : 0
  role       = var.lambda_func.role_name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_cloudwatch_log_group" "this" {
  count             = var.lambda_func.logging ? 1 : 0
  name              = "/aws/lambda/${var.lambda_func.function_name}"
  retention_in_days = 7
}

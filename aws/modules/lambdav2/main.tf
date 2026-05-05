resource "aws_lambda_function" "example" {
  function_name = var.function_name
  role          = var.role_arn
  package_type  = "Image"
  image_uri     = "${var.image_uri}:latest"

  memory_size = var.memory_size
  timeout     = var.timeout

  architectures = ["arm64"] # Graviton support for better price/performance
}

###---IAM---###

resource "aws_iam_role_policy_attachment" "this" {
  count      = var.lambda_func.logging ? 1 : 0
  role       = var.lambda_func.role_name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

###---LOGGING---###

resource "aws_cloudwatch_log_group" "this" {
  count             = var.lambda_func.logging ? 1 : 0
  name              = "/aws/lambda/${var.lambda_func.function_name}"
  retention_in_days = 7
}

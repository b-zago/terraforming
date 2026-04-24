output "lambda_data" {
  value = {
    invoke_arn = aws_lambda_function.this.invoke_arn
    arn        = aws_lambda_function.this.arn
    id         = aws_lambda_function.this.id
  }
}

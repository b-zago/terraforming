variable "lambda_func" {
  type = object({
    source_file   = string
    role_arn      = string
    role_name     = string
    function_name = string
    handler       = string
    runtime       = string
    timeout       = number
    memory_size   = number
    logging       = bool
  })
}

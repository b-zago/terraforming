variable "function_name" {
  description = "Lambda function name"
  type        = string
}

variable "role_arn" {
  description = "IAM role for Lambda to assume"
  type        = string
}

variable "image_uri" {
  description = "ECR repository url"
  type        = string
}

variable "memory_size" {
  description = "Memory size in MB for Lambda to use. Defaults to 128"
  type        = number
  default     = 128
}

variable "timeout" {
  description = "Defines hard time limit in seconds after which the Lambda should end it's existence. Default to 10"
  type        = number
  default     = 10
}


###---LOGGING---###

variable "enable_logging" {
  description = "Should CloudWatch logging be enabled for this Lamda. Default to true"
  type        = bool
  default     = true
}

variable "role_name" {
  description = "IAM role name that Lambda assumes. Needed for policy attachment. Required if logging enabled"
  type        = string
  default     = null

  validation {
    condition     = !var.enable_logging || (var.enable_logging && var.role_name != null)
    error_message = "Must specify role_name if enable_logging is set to true"
  }
}

###---LAMBDA COMMON---###
variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "function_name" {
  description = "Lambda function name"
  type        = string
}

variable "role_name" {
  description = "IAM role name for your Lambda"
  type        = string
}


variable "memory_size" {
  description = "Memory size in MB for your Lambda to use. Defaults to 128"
  type        = number
  default     = 128
}

variable "timeout" {
  description = "Defines hard time limit in seconds after which the Lambda should end it's existence. Default to 10"
  type        = number
  default     = 10
}

variable "create_image_lambda" {
  description = "Whether this lambda should run docker image or packaged code. Defaults to true"
  type        = bool
  default     = true
}

variable "architectures" {
  description = "Instruction set architecture for your Lambda function. Defaults to `arm64`. Can only be also set to `x86_64`."
  type        = string
  default     = "arm64"
}

variable "environemt" {
  description = "Map of environment variables available to your Lambda function during execution"
  type        = map(string)
  default     = {}
}

###---LAMBDA IMAGE---###

variable "image_uri" {
  description = "ECR repository url. Tag `latest` is appended by default - can be changed in latest_tag"
  type        = string
  default     = null

  validation {
    condition     = !var.create_image_lambda || var.image_uri != null
    error_message = "If you want to create an image function you need to specify the image_uri variable"
  }
}

variable "latest_tag" {
  description = "Default tag to be appended to ECR repo URL. Defaults to `prod-latest`"
  type        = string
  default     = "prod-latest"
}

variable "image_config" {
  description = "Optional configuration block for the image"
  type = object({
    command           = optional(list(string))
    entry_point       = optional(list(string))
    working_directory = optional(string)
  })
  default = null

}
###---LAMBDA ZIPPED---###

variable "zip_config" {
  description = "Configuration for your zip package type Lambda. `source_path` must be either a path to directory or a file, set `path_is_file` accordingly. `path_is_file` defaults to true"
  type = object({
    handler      = string
    runtime      = string
    path_is_file = optional(bool, true)
    source_path  = string
    output_path  = string
  })
  default = null

  validation {
    condition     = var.create_image_lambda || (!var.create_image_lambda && var.zip_config != null)
    error_message = "If you want to create a zip package type function you need to specify the zip_config variable"
  }
}

###---LOGGING---###

variable "enable_logging" {
  description = "Whether CloudWatch logging is enabled for this Lambda. Defaults to true"
  type        = bool
  default     = true
}

variable "logging_retention" {
  description = "CloudWatch log group retention in days. Defaults to 7"
  type        = number
  default     = 7
}

# zip package switch, echeduler switch


###---IAM---###

variable "allowed_permissions" {
  description = "List of objects allowed permissions that Lambda can use"
  type = map(object({
    actions   = list(string)
    resources = list(string)
  }))
  default = null
}

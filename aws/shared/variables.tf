variable "alert_email" {
  description = "E-mail adress that is used for alerts"
  type        = string
}

variable "private_bucket_name" {
  description = "Name of the private shared bucket to function as a terraform backend"
  type        = string
}

variable "adm_role_arn" {
  description = "IAM role arn with admin access"
  type        = string
}

variable "github_iam_role_arn" {
  description = "IAM role arn with GitHub OICD configured"
  type        = string
}

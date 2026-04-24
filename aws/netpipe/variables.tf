variable "alert_email" {
  type      = string
  sensitive = true
}

variable "dynamodb_table_name" {
  type = string
}

variable "s3_bucket_name" {
  type = string
}

variable "app_tag" {
  type = map(string)
}

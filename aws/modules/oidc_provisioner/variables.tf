variable "resources_bucket" {
  type        = string
  description = "S3 bucket where OIDC files are stored"
}

variable "region" {
  type = string
}

variable "bucket_path" {
  type        = string
  description = "Root path for OIDC files"
}

variable "role_name" {
  type = string
}

variable "subjects" {
  type        = map(string)
  description = "Key should be the desired IAM role name with value of k8s SA sub"
}

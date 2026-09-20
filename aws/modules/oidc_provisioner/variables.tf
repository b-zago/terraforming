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


variable "subjects" {
  type = map(object({
    sub       = string
    ssm_paths = list(string)
  }))
  description = "Key should be the desired IAM role name. Paths should begin with `/`"
}

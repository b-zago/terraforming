variable "oidc_provider_arn" {
  type = string
}

variable "app_tag" {
  description = "AWS App tag"
  type        = string
}

variable "HMAC_KEY" {
  description = "For env to use for docker image"
  type        = string
  sensitive   = true
}

variable "RECEIVER_ID" {
  description = "For env to use for docker image"
  type        = string
  sensitive   = true
}

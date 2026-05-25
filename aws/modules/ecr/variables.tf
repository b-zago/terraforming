###---REPO---###

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "repository_name" {
  description = "The name of the repository. Required"
  type        = string
}

variable "repository_image_tag_mutability" {
  description = "The tag mutability setting for the repository. For this module specifically must be one of: `MUTABLE` or `IMMUTABLE`. Defaults to `MUTABLE`"
  type        = string
  default     = "MUTABLE"
}

variable "repository_image_scan_on_push" {
  description = "Indicates whether images are scanned after being pushed to the repository (`true`) or not scanned (`false`). Defaults to true"
  type        = bool
  default     = true
}

variable "repository_force_delete" {
  description = "If `true`, will delete the repository even if it contains images. Defaults to `false`"
  type        = bool
  default     = false
}

###---REPO POLICY---###

variable "repository_pull_access_arns" {
  description = "The ARNs of the IAM users/roles that have pull access to the repository"
  type        = list(string)
  default     = []
}

variable "repository_lambda_pull_access_arns" {
  description = "The ARNs of the Lambda service roles that have pull access to the repository"
  type        = list(string)
  default     = []
}

variable "repository_push_access_arns" {
  description = "The ARNs of the IAM users/roles that have push access to the repository"
  type        = list(string)
  default     = []
}

variable "repository_admin_access_arns" {
  description = "The ARNs of the IAM users/roles that have all access to the repository"
  type        = list(string)
  default     = []
}


variable "repository_policy_statements" {
  description = "A map of IAM policy [statements](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document#statement) for custom permission usage"
  type = map(object({
    sid           = optional(string)
    actions       = optional(list(string))
    not_actions   = optional(list(string))
    effect        = optional(string)
    resources     = optional(list(string))
    not_resources = optional(list(string))
    principals = optional(list(object({
      type        = string
      identifiers = list(string)
    })))
    not_principals = optional(list(object({
      type        = string
      identifiers = list(string)
    })))
    conditions = optional(list(object({
      test     = string
      values   = list(string)
      variable = string
    })))
  }))
  default = null
}

###--LIFECYCLE POLICY---###

variable "create_lifecycle_policy" {
  description = "Configure if this module should create a lifecycle policy for this repo. Defaults to true (check repository_lifecycle_policy)"
  type        = bool
  default     = true
}

variable "repository_lifecycle_policy" {
  description = "The policy document. This is a JSON formatted string (use jsonencode() when passing custom policy). See more details about [Policy Parameters](http://docs.aws.amazon.com/AmazonECR/latest/userguide/LifecyclePolicies.html#lifecycle_policy_parameters) in the official AWS docs. Defaults to a strict cleanup policy"
  type        = string
  default     = null
}

###---CI GH ROLE---###

variable "create_gh_role" {
  description = "Determines if OIDC github role should be created to allow GH Actions to push to this repo. GH repo name should match ECR repo name. Defaults to true"
  type        = bool
  default     = true
}

variable "oidc_provider_arn" {
  description = "Arn for GH OIDC provider"
  type        = string
  default     = null

  validation {
    condition     = !var.create_gh_role || var.oidc_provider_arn != null
    error_message = "You need to specify oidc_provider_arn if you're going to create gh role"
  }
}

variable "gh_org" {
  description = "Organization/User name of github repo. Default to b-zago for my ease of use"
  type        = string
  default     = "b-zago"
}

variable "gh_branches" {
  description = "List of branches with workflow permission to push the image. Defaults to ['main', 'staging']"
  type        = list(string)
  default     = ["main", "staging"]

}

variable "gh_update_lambda_permission" {
  description = "Should github role have access to update lambda permission. Defaults to true"
  type        = bool
  default     = true
}

variable "gh_lambda_arn" {
  type    = string
  default = null
}

variable "gh_role_name" {
  description = "Github role name suffix that uses OIDC provider. It gets appended tight after repository_name. Defaults to `-github-ci`"
  type        = string
  default     = "-github-ci"
}

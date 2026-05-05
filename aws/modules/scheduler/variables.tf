variable "scheduler_name" {
  description = "Scheduler function name"
  type        = string
}

variable "scheduler_group_name" {
  description = "Scheduler group name. Defaults to `default`"
  type        = string
  default     = "default"
}

variable "schedule_expression" {
  description = "Defines how often Scheduler should run"
  type        = string
}

variable "schedule_expression_timezone" {
  description = "Timezone in which scheduler operates. Defaults to `Europe/Warsaw`"
  type        = string
  default     = "Europe/Warsaw"
}

variable "flexible_time_window" {
  description = "Determines whether the schedule is invoked within a flexible time window. One of: `OFF`, `FLEXIBLE`. Defaults to `OFF`. Optionally you can also specify maximum time window during which a schedule can be invoked. Ranges <1-1440>"
  type = object({
    mode                      = string
    maximum_window_in_minutes = number
  })
  default = {
    mode                      = "OFF"
    maximum_window_in_minutes = null
  }
}

variable "target_arn" {
  description = "Scheduler target arn"
  type        = string
}

variable "maximum_retry_attempts" {
  description = "Maximum number of retry attempts to make before the request fails. Ranges <0-185>. Defaults to 2"
  type        = number
  default     = 2
}

variable "maximum_event_age_in_seconds" {
  description = "Maximum amount of time, in seconds, to continue to make retry attempts. Ranges <60-86400>. Defaults to 60"
  type        = number
  default     = 60
}

###---IAM---###

variable "role_name" {
  description = "IAM role name for your Scheduler"
  type        = string
}

variable "allowed_permissions" {
  description = "List of objects allowed permissions that Scheduler can use"
  type = map(object({
    actions   = list(string)
    resources = list(string)
  }))
  default = null
}

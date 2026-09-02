variable "additional_tags" {
  type    = map(string)
  default = {}
}

variable "vpc_name" {
  type        = string
  description = "Used for tagging VPC and subnets"
}

variable "cidr" {
  type        = string
  description = "VPC CIDR"
}

variable "public_subnets" {
  type = map(object({
    cidr = string
    az   = string
  }))
  description = "Provide at least one public subnet"
}


variable "private_subnets" {
  type = map(object({
    cidr = string
    az   = string
  }))

  default     = {}
  description = "With at least one provided, a single NGW will be created on the specified public subnet key with `nat_subnet_key` variable"
}

variable "nat_subnet_key" {
  type    = string
  default = ""

  validation {
    condition     = length(var.private_subnets) == 0 || var.nat_subnet_key != ""
    error_message = "Need to specify nat_subnet_key when at least one private subnet defined"
  }
}

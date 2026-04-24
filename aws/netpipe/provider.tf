terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"

  default_tags {
    tags = merge(var.app_tag, {
      ManagedBy   = "terraform"
      Environment = "prod"
    })
  }
}

locals {
  region = "eu-central-1"
  tags = {
    ManagedBy      = "terraform"
    Environment    = local.env
    App            = local.name
    awsApplication = var.app_tag
  }
  name           = "nyanwatch"
  dynamodb_table = "NyanwatchFailures"
  env            = "prod"
}

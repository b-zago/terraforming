locals {
  region = "eu-central-1"
  tags = {
    ManagedBy   = "terraform"
    Environment = "prod"
    App         = local.name
  }
  name = "shared"
}

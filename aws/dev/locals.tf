locals {
  region = "eu-central-1"
  tags = {
    ManagedBy   = "terraform"
    Environment = local.env
    App         = local.name
  }
  name = "dev"
  env  = "dev"
}

###---BUDGET---###

resource "aws_budgets_budget" "monthly" {
  name         = "${local.name}-monthly-budget"
  budget_type  = "COST"
  limit_amount = "5"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.alert_email]
  }
}

###---PIRVATE S3---###

resource "aws_s3_bucket" "private_bucket" {
  bucket = var.private_bucket_name
}

resource "aws_s3_bucket_public_access_block" "private_bucket_pab" {
  bucket = aws_s3_bucket.private_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "private_bucket_policy" {
  bucket = aws_s3_bucket.private_bucket.id
  policy = data.aws_iam_policy_document.private_bucket_permissions.json
}

resource "aws_s3_bucket_versioning" "private_bucket_versioning" {
  bucket = aws_s3_bucket.private_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "private_bucket_config" {
  # Must have bucket versioning enabled first
  depends_on = [aws_s3_bucket_versioning.private_bucket_versioning]

  bucket = aws_s3_bucket.private_bucket.bucket

  rule {
    id = "${local.name}-private-bucket-config"

    noncurrent_version_expiration {
      noncurrent_days           = 90
      newer_noncurrent_versions = 5
    }

    status = "Enabled"
  }
}

###---RESOURCES S3---###

resource "aws_s3_bucket" "resources_bucket" {
  bucket = local.resources_bucket
}

resource "aws_s3_bucket_ownership_controls" "resources_bucket_ownership" {
  bucket = aws_s3_bucket.resources_bucket.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "resources_bucket_pab" {
  bucket = aws_s3_bucket.resources_bucket.id

  block_public_acls       = true
  block_public_policy     = false
  ignore_public_acls      = true
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "resources_bucket_policy" {
  bucket = aws_s3_bucket.resources_bucket.id
  policy = data.aws_iam_policy_document.resources_bucket_permissions.json

  depends_on = [aws_s3_bucket_public_access_block.resources_bucket_pab]
}


###--REGISTRY SCAN CONFIG---###

resource "aws_ecr_registry_scanning_configuration" "ecr_registry_scan_config" {

  scan_type = "BASIC"
}


###--- DEFAULT EBS ENCRYPTION ---###


resource "aws_ebs_encryption_by_default" "ebs_default_encryption" {
  enabled = true

}

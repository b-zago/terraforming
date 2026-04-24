resource "aws_s3_bucket" "aws_static_website_bucket" {
  bucket = "${local.project_name}-bucket"
}

resource "aws_s3_bucket_public_access_block" "bucket_pab" {
  bucket = aws_s3_bucket.aws_static_website_bucket.id
  #only via bucket policy
  block_public_acls       = true
  block_public_policy     = false
  ignore_public_acls      = true
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "allow_read_get_access" {
  bucket = aws_s3_bucket.aws_static_website_bucket.id
  policy = data.aws_iam_policy_document.allow_read_get_access.json
}

data "aws_iam_policy_document" "allow_read_get_access" {
  statement {
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    effect = "Allow"

    actions = ["s3:GetObject"]

    resources = ["${aws_s3_bucket.aws_static_website_bucket.arn}/*"]
  }
}

resource "aws_s3_bucket_website_configuration" "website_config" {
  bucket = aws_s3_bucket.aws_static_website_bucket.id

  index_document {
    suffix = local.suffix
  }
}

resource "aws_s3_object" "website" {
  for_each     = toset(["index.html", "app.js", "styles.css"])
  bucket       = aws_s3_bucket.aws_static_website_bucket.id
  key          = each.key
  source       = "./website/${each.key}"
  content_type = local.content_types[each.key]

  etag = filemd5("./website/${each.key}")
}


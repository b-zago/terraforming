data "aws_iam_policy_document" "private_bucket_permissions" {
  statement {
    effect = "Deny"

    actions = ["s3:*"]

    resources = [aws_s3_bucket.private_bucket.arn, "${aws_s3_bucket.private_bucket.arn}/*"]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }

  statement {
    effect = "Deny"

    actions = ["s3:*"]

    resources = [aws_s3_bucket.private_bucket.arn, "${aws_s3_bucket.private_bucket.arn}/*"]

    condition {
      test     = "ArnNotEquals"
      variable = "aws:PrincipalArn"
      values   = [var.adm_role_arn]
    }

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

###---OIDC PROVIDERS---###

resource "aws_iam_openid_connect_provider" "github_oidc" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]
}

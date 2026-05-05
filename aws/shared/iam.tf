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

###---CI ROLES---###

data "aws_iam_policy_document" "github_ci_permissions" {
  statement {
    effect = "Allow"

    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_oidc.arn]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo: b-zago/*"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_openid_connect_provider" "github_oidc" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]
}

resource "aws_iam_role" "github_ci_role" {
  name               = "${local.name}-github-ci"
  assume_role_policy = data.aws_iam_policy_document.github_ci_permissions.json
}

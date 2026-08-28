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

data "aws_iam_policy_document" "resources_bucket_permissions" {
  statement {
    effect = "Deny"

    actions = ["s3:*"]

    resources = [aws_s3_bucket.resources_bucket.arn, "${aws_s3_bucket.resources_bucket.arn}/*"]

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
    effect  = "Allow"
    actions = ["s3:GetObject"]

    resources = ["${aws_s3_bucket.resources_bucket.arn}/oidc/*"]

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

resource "aws_iam_openid_connect_provider" "bare_metal_staging_oidc" {
  url = "https://${local.resources_bucket}.s3.${local.region}.amazonaws.com/oidc/staging"

  client_id_list = [
    "sts.amazonaws.com",
  ]
}

data "aws_kms_key" "kms_ssm_key" {
  key_id = "alias/aws/ssm"
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "metal_sa_ar" {
  statement {
    sid    = "AllowBareMetalOIDC"
    effect = "Allow"

    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.bare_metal_staging_oidc.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${aws_iam_openid_connect_provider.bare_metal_staging_oidc.url}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${aws_iam_openid_connect_provider.bare_metal_staging_oidc.url}:sub"
      values   = ["system:serviceaccount:external-secrets:external-secrets"]
    }
  }
}

data "aws_iam_policy_document" "metal_sa_permissions" {

  statement {
    sid       = "KMSAccess"
    effect    = "Allow"
    actions   = ["kms:Encrypt", "kms:Decrypt"]
    resources = [data.aws_kms_key.kms_ssm_key.arn]
  }

  statement {
    sid       = "SSMAccess"
    effect    = "Allow"
    actions   = ["ssm:GetParameter"]
    resources = ["arn:aws:ssm:${local.region}:${data.aws_caller_identity.current.account_id}:parameter/clusters/*"]
  }
}

resource "aws_iam_role" "metal_sa_role" {
  name               = "metal-sa-role"
  assume_role_policy = data.aws_iam_policy_document.metal_sa_ar.json
}

resource "aws_iam_role_policy" "metal_sa_role_policy" {
  name   = "metal-sa-role-policy"
  role   = aws_iam_role.metal_sa_role.id
  policy = data.aws_iam_policy_document.metal_sa_permissions.json
}

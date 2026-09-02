terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

}

resource "aws_iam_openid_connect_provider" "this" {
  url = "https://${var.resources_bucket}.s3.${var.region}.amazonaws.com/${var.bucket_path}"

  client_id_list = [
    "sts.amazonaws.com",
  ]
}

data "aws_kms_key" "this" {
  key_id = "alias/aws/ssm"
}

data "aws_caller_identity" "this" {}

data "aws_iam_policy_document" "metal_sa_ar" {
  statement {
    sid    = "AllowBareMetalOIDC"
    effect = "Allow"

    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.this.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${aws_iam_openid_connect_provider.this.url}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${aws_iam_openid_connect_provider.this.url}:sub"
      values   = ["system:serviceaccount:external-secrets:external-secrets"]
    }
  }
}

data "aws_iam_policy_document" "metal_sa_permissions" {

  statement {
    sid       = "KMSAccess"
    effect    = "Allow"
    actions   = ["kms:Encrypt", "kms:Decrypt"]
    resources = [data.aws_kms_key.this.arn]
  }

  statement {
    sid       = "SSMAccess"
    effect    = "Allow"
    actions   = ["ssm:GetParameter"]
    resources = ["arn:aws:ssm:${var.region}:${data.aws_caller_identity.this.account_id}:parameter/clusters/*"]
  }
}

resource "aws_iam_role" "this" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.metal_sa_ar.json
}

resource "aws_iam_role_policy" "this" {
  name   = "${var.role_name}-policy"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.metal_sa_permissions.json
}

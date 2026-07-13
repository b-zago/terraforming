data "aws_iam_openid_connect_provider" "github_oidc" {
  url = "https://token.actions.githubusercontent.com"
}

data "aws_kms_key" "kms_ssm_key" {
  key_id = "alias/aws/ssm"
}

data "aws_caller_identity" "current" {}


data "aws_iam_policy_document" "github_ar" {

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github_oidc.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values = flatten([
        for repo in var.gh_repos : [
          "repo:${var.gh_org}/${repo}:ref:refs/heads/main",
          "repo:${var.gh_org}/${repo}:ref:refs/heads/staging",
        ]
      ])
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
  }

}

data "aws_iam_policy_document" "github_permissions" {
  statement {
    sid     = "SSMAccess"
    effect  = "Allow"
    actions = ["ssm:GetParameter", "ssm:PutParameter"]
    resources = [
      for repo in var.gh_repos :
      "arn:aws:ssm:${local.region}:${data.aws_caller_identity.current.account_id}:parameter/${repo}/*"
    ]
  }

  statement {
    sid       = "KMSAccess"
    effect    = "Allow"
    actions   = ["kms:Encrypt", "kms:Decrypt"]
    resources = [data.aws_kms_key.kms_ssm_key.arn]
  }
}


resource "aws_iam_role" "github" {
  name               = "${local.name}-github-oidc-role"
  assume_role_policy = data.aws_iam_policy_document.github_ar.json
}

resource "aws_iam_role_policy" "github" {
  name   = "${local.name}-github-permissions"
  role   = aws_iam_role.github.id
  policy = data.aws_iam_policy_document.github_permissions.json
}

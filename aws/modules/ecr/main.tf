terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

}

locals {
  repository_policy_has_statements = (
    length(var.repository_pull_access_arns) > 0 ||
    length(var.repository_lambda_pull_access_arns) > 0 ||
    length(var.repository_push_access_arns) > 0 ||
    length(var.repository_admin_access_arns) > 0 ||
    length(coalesce(var.repository_policy_statements, {})) > 0
  )
}
# Policy used by both private and public repositories
data "aws_iam_policy_document" "repository" {

  dynamic "statement" {
    for_each = length(var.repository_pull_access_arns) > 0 ? var.repository_pull_access_arns : []

    content {
      sid    = "PrivatePullOnly"
      effect = "Allow"

      principals {
        type        = "AWS"
        identifiers = var.repository_pull_access_arns
      }

      actions = [
        "ecr:GetAuthorizationToken",
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer",
      ]
    }

  }

  dynamic "statement" {
    for_each = length(var.repository_lambda_pull_access_arns) > 0 ? var.repository_lambda_pull_access_arns : []

    content {
      sid    = "PrivateLambdaPullOnly"
      effect = "Allow"

      principals {
        type        = "Service"
        identifiers = ["lambda.amazonaws.com"]
      }

      actions = [
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer",
      ]

      condition {
        test     = "StringLike"
        variable = "aws:sourceArn"

        values = var.repository_lambda_pull_access_arns
      }
    }
  }

  dynamic "statement" {
    for_each = length(var.repository_push_access_arns) > 0 ? var.repository_push_access_arns : []

    content {
      sid    = "AllowPushPullOnly"
      effect = "Allow"

      principals {
        type        = "AWS"
        identifiers = statement.value
      }

      actions = [
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability",
        "ecr:CompleteLayerUpload",
        "ecr:GetDownloadUrlForLayer",
        "ecr:InitiateLayerUpload",
        "ecr:PutImage",
        "ecr:UploadLayerPart",
        "ecr:GetAuthorizationToken"
      ]

    }
  }

  dynamic "statement" {
    for_each = length(var.repository_admin_access_arns) > 0 ? var.repository_admin_access_arns : []

    content {
      sid    = "AllowAll"
      effect = "Allow"

      principals {
        type        = "AWS"
        identifiers = statement.value
      }

      actions = [
        "ecr:*"
      ]

    }
  }


  dynamic "statement" {
    for_each = var.repository_policy_statements != null ? var.repository_policy_statements : {}

    content {
      sid           = statement.value.sid
      actions       = statement.value.actions
      not_actions   = statement.value.not_actions
      effect        = statement.value.effect
      resources     = statement.value.resources
      not_resources = statement.value.not_resources

      dynamic "principals" {
        for_each = statement.value.principals != null ? statement.value.principals : []

        content {
          type        = principals.value.type
          identifiers = principals.value.identifiers
        }
      }

      dynamic "not_principals" {
        for_each = statement.value.not_principals != null ? statement.value.not_principals : []

        content {
          type        = not_principals.value.type
          identifiers = not_principals.value.identifiers
        }
      }

      dynamic "condition" {
        for_each = statement.value.conditions != null ? statement.value.conditions : []

        content {
          test     = condition.value.test
          values   = condition.value.values
          variable = condition.value.variable
        }
      }
    }
  }
}

###---REPO---###

resource "aws_ecr_repository" "this" {

  name                 = var.repository_name
  image_tag_mutability = var.repository_image_tag_mutability

  force_delete = var.repository_force_delete

  image_scanning_configuration {
    scan_on_push = var.repository_image_scan_on_push
  }

  tags = var.tags
}

###---REPO POLICY---###

resource "aws_ecr_repository_policy" "this" {
  count = local.repository_policy_has_statements ? 1 : 0

  repository = aws_ecr_repository.this.name
  policy     = data.aws_iam_policy_document.repository.json
}


###---LIFECYCLE POLICY---###

resource "aws_ecr_lifecycle_policy" "this" {
  count = var.create_lifecycle_policy ? 1 : 0

  repository = aws_ecr_repository.this.name
  policy = var.repository_lifecycle_policy == null ? jsonencode({

    "rules" : [
      {
        "rulePriority" : 1,
        "description" : "Limit image count for prod images.",
        "selection" : {
          "tagStatus" : "tagged",
          "tagPatternList" : ["prod-*"],
          "countType" : "imageCountMoreThan",
          "countNumber" : 3
        },
        "action" : {
          "type" : "expire"
        }
      },
      {
        "rulePriority" : 2,
        "description" : "Limit image count for staging images.",
        "selection" : {
          "tagStatus" : "tagged",
          "tagPatternList" : ["staging-*"],
          "countType" : "imageCountMoreThan",
          "countNumber" : 3
        },
        "action" : {
          "type" : "expire"
        }
      },
      {
        "rulePriority" : 3,
        "description" : "Catch-all to expire every other tagged images after 14 days",
        "selection" : {
          "tagStatus" : "tagged",
          "tagPatternList" : ["*"],
          "countType" : "sinceImagePushed",
          "countUnit" : "days",
          "countNumber" : 14
        },
        "action" : {
          "type" : "expire"
        }
      },
      {
        "rulePriority" : 4,
        "description" : "Don't keep any untagged images for 7 days",
        "selection" : {
          "tagStatus" : "untagged",
          "countType" : "sinceImagePushed",
          "countUnit" : "days",
          "countNumber" : 7
        },
        "action" : {
          "type" : "expire"
        }
      },

    ]

  }) : var.repository_lifecycle_policy
}



###---CI GH ROLE---###
data "aws_iam_policy_document" "github_ar" {

  dynamic "statement" {
    for_each = var.create_gh_role ? [1] : []

    content {

      effect  = "Allow"
      actions = ["sts:AssumeRoleWithWebIdentity"]

      principals {
        type        = "Federated"
        identifiers = [var.oidc_provider_arn]
      }

      condition {
        test     = "StringEquals"
        variable = "token.actions.githubusercontent.com:sub"
        values = [
          for b in var.gh_branches :
          "repo:${var.gh_org}/${var.repository_name}:ref:refs/heads/${b}"
        ]
      }

      condition {
        test     = "StringEquals"
        variable = "token.actions.githubusercontent.com:aud"
        values   = ["sts.amazonaws.com"]
      }
    }
  }

}

data "aws_iam_policy_document" "github_permissions" {
  dynamic "statement" {
    for_each = var.create_gh_role ? [1] : []

    content {
      sid       = "GetAuthorizationToken"
      effect    = "Allow"
      actions   = ["ecr:GetAuthorizationToken"]
      resources = ["*"]
    }
  }
  dynamic "statement" {
    for_each = var.create_gh_role ? [1] : []

    content {
      sid    = "GrantPushPullPermissions"
      effect = "Allow"
      actions = [
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability",
        "ecr:CompleteLayerUpload",
        "ecr:GetDownloadUrlForLayer",
        "ecr:InitiateLayerUpload",
        "ecr:PutImage",
        "ecr:UploadLayerPart"
      ]

      resources = [aws_ecr_repository.this.arn]
    }
  }
  dynamic "statement" {
    for_each = var.gh_update_lambda_permission ? [1] : []

    content {
      sid    = "LambdaUpdateFunctionPermissions"
      effect = "Allow"
      actions = [
        "lambda:UpdateFunctionCode",
        "lambda:GetFunction",
        "lambda:GetFunctionConfiguration"
      ]
      resources = [var.gh_lambda_arn]
    }

  }
}

resource "aws_iam_role_policy" "this" {
  count = var.create_gh_role ? 1 : 0

  name   = "${aws_iam_role.this[0].name}-policy"
  role   = aws_iam_role.this[0].id
  policy = data.aws_iam_policy_document.github_permissions.json
}

resource "aws_iam_role" "this" {
  count = var.create_gh_role ? 1 : 0

  name               = "${var.repository_name}${var.gh_role_name}"
  assume_role_policy = data.aws_iam_policy_document.github_ar.json
}


# Policy used by both private and public repositories
data "aws_iam_policy_document" "repository" {

  dynamic "statement" {
    for_each = length(var.repository_pull_access_arns) > 0 ? [1] : []

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
    for_each = length(var.repository_lambda_pull_access_arns) > 0 ? [1] : []

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
    for_each = length(var.repository_push_access_arns) > 0 ? [var.repository_push_access_arns] : []

    content {
      sid    = "AllowPushOnly"
      effect = "Allow"

      principals {
        type        = "AWS"
        identifiers = statement.value
      }

      actions = [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:CompleteLayerUpload",
        "ecr:InitiateLayerUpload",
        "ecr:PutImage",
        "ecr:UploadLayerPart"
      ]

    }
  }

  dynamic "statement" {
    for_each = length(var.repository_admin_access_arns) > 0 ? [var.repository_admin_access_arns] : []

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
        "description" : "Limit image count.",
        "selection" : {
          "tagStatus" : "tagged",
          "tagPatternList" : ["prod-*", "staging-*"],
          "countType" : "imageCountMoreThan",
          "countNumber" : 5
        },
        "action" : {
          "type" : "expire"
        }
      },
      {
        "rulePriority" : 2,
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
        "rulePriority" : 3,
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

###--REGISTRY SCAN CONFIG---###

resource "aws_ecr_registry_scanning_configuration" "this" {

  scan_type = "BASIC"
}

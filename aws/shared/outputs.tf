output "github_iam_role_arn" {
  description = "IAM role arn with github OIDC"
  value       = aws_iam_role.github_ci_role.arn
}

output "ecr_shared_arn" {
  description = "ECR private repository arn"
  value       = module.ecr_shared.repository_arn
}

output "ecr_shared_url" {
  description = "ECR private repository URL"
  value       = module.ecr_shared.repository_url
}

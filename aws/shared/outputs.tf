output "oidc_gh_provider_arn" {
  description = "OIDC GH provider arn"
  value       = aws_iam_openid_connect_provider.github_oidc.arn
}

output "metal_oidc_arns" {
  value = { for k, v in module.metal_oidc_providers : k => v.role_arn }
}

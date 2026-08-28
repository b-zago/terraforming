output "oidc_gh_provider_arn" {
  description = "OIDC GH provider arn"
  value       = aws_iam_openid_connect_provider.github_oidc.arn
}

output "oidc_metal_staging_provider_arn" {
  description = "OIDC metal staging provider arn"
  value       = aws_iam_openid_connect_provider.bare_metal_staging_oidc.arn
}

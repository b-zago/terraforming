output "oidc_gh_provider_arn" {
  description = "OIDC GH provider arn"
  value       = aws_iam_openid_connect_provider.github_oidc.arn
}

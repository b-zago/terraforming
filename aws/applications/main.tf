resource "aws_servicecatalogappregistry_application" "netpipe_app" {
  name = "netpipe-app"
}

output "netpipe_app_tag" {
  value = aws_servicecatalogappregistry_application.netpipe_app.application_tag
}

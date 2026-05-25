resource "aws_servicecatalogappregistry_application" "netpipe_app" {
  name = "netpipe-app"
}

resource "aws_servicecatalogappregistry_application" "nyanwatch-app" {
  name = "nyanwatch-app"
}

output "netpipe_app_tag" {
  value = aws_servicecatalogappregistry_application.netpipe_app.application_tag
}

output "nyanwatch_app_tag" {
  value = aws_servicecatalogappregistry_application.nyanwatch-app.application_tag
}

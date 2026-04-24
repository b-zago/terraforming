locals {
  content_types = {
    "index.html" = "text/html"
    "app.js"     = "application/javascript"
    "styles.css" = "text/css"
  }
}

locals {
  project_name = "static-website"
  suffix       = "index.html"
}

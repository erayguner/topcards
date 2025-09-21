# Enable required APIs using a single managed resource set
locals {
  default_project_services = [
    "bigquery.googleapis.com",
    "compute.googleapis.com",
    "iam.googleapis.com",
    "secretmanager.googleapis.com",
    "servicenetworking.googleapis.com",
    "sqladmin.googleapis.com",
    "storage.googleapis.com"
  ]

  combined_project_services = distinct(
    concat(local.default_project_services, tolist(var.additional_project_services))
  )
}

resource "google_project_service" "required" {
  for_each = var.enable_apis ? { for service in local.combined_project_services : service => service } : {}

  service                    = each.value
  disable_dependent_services = true
  disable_on_destroy         = false
}

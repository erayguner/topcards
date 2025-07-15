# Enable required APIs
resource "google_project_service" "compute_api" {
  count   = var.enable_apis ? 1 : 0
  service = "compute.googleapis.com"

  disable_dependent_services = true
  disable_on_destroy         = false
}

resource "google_project_service" "storage_api" {
  count   = var.enable_apis ? 1 : 0
  service = "storage.googleapis.com"

  disable_dependent_services = true
  disable_on_destroy         = false
}

resource "google_project_service" "iam_api" {
  count   = var.enable_apis ? 1 : 0
  service = "iam.googleapis.com"

  disable_dependent_services = true
  disable_on_destroy         = false
}

resource "google_project_service" "sql_api" {
  count   = var.enable_apis ? 1 : 0
  service = "sqladmin.googleapis.com"

  disable_dependent_services = true
  disable_on_destroy         = false
}

resource "google_project_service" "networking_api" {
  count   = var.enable_apis ? 1 : 0
  service = "servicenetworking.googleapis.com"

  disable_dependent_services = true
  disable_on_destroy         = false
}

resource "google_project_service" "bigquery_api" {
  count   = var.enable_apis ? 1 : 0
  service = "bigquery.googleapis.com"

  disable_dependent_services = true
  disable_on_destroy         = false
}

resource "google_project_service" "secretmanager_api" {
  count   = var.enable_apis ? 1 : 0
  service = "secretmanager.googleapis.com"

  disable_dependent_services = true
  disable_on_destroy         = false
}
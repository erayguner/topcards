# Enable required APIs
resource "google_project_service" "compute_api" {
  service = "compute.googleapis.com"

  disable_dependent_services = true
  disable_on_destroy         = false
}

resource "google_project_service" "storage_api" {
  service = "storage.googleapis.com"

  disable_dependent_services = true
  disable_on_destroy         = false
}

resource "google_project_service" "iam_api" {
  service = "iam.googleapis.com"

  disable_dependent_services = true
  disable_on_destroy         = false
}

resource "google_project_service" "sql_api" {
  service = "sqladmin.googleapis.com"

  disable_dependent_services = true
  disable_on_destroy         = false
}

resource "google_project_service" "networking_api" {
  service = "servicenetworking.googleapis.com"

  disable_dependent_services = true
  disable_on_destroy         = false
}

resource "google_project_service" "bigquery_api" {
  service = "bigquery.googleapis.com"

  disable_dependent_services = true
  disable_on_destroy         = false
}

resource "google_project_service" "secretmanager_api" {
  service = "secretmanager.googleapis.com"

  disable_dependent_services = true
  disable_on_destroy         = false
}
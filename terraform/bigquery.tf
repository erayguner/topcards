# BigQuery dataset for CSV data analysis
resource "google_bigquery_dataset" "csv_dataset" {
  dataset_id    = "${var.project_id}_${var.environment}_csv_data"
  friendly_name = "CSV Data Analysis Dataset"
  description   = "Dataset for analyzing CSV files from the simple storage bucket"
  location      = var.region

  # Access control
  access {
    role          = "OWNER"
    user_by_email = google_service_account.app_service_account.email
  }

  access {
    role          = "READER"
    special_group = "projectReaders"
  }

  access {
    role          = "WRITER"
    special_group = "projectWriters"
  }

  # Labels for organization
  labels = {
    environment = var.environment
    purpose     = "csv-analysis"
    managed_by  = "terraform"
  }

  depends_on = [google_project_service.bigquery_api]
}

# BigQuery external table for CSV files in simple bucket
resource "google_bigquery_table" "csv_external_table" {
  dataset_id = google_bigquery_dataset.csv_dataset.dataset_id
  table_id   = "csv_files_external"

  description = "External table reading CSV files from simple storage bucket"

  external_data_configuration {
    autodetect    = true
    source_format = "CSV"

    csv_options {
      quote                 = "\""
      skip_leading_rows     = 1
      allow_jagged_rows     = false
      allow_quoted_newlines = false
    }

    source_uris = [
      "gs://${google_storage_bucket.simple_bucket.name}/*.csv"
    ]
  }

  # Labels for organization
  labels = {
    environment = var.environment
    purpose     = "csv-external-table"
    managed_by  = "terraform"
  }

  depends_on = [
    google_bigquery_dataset.csv_dataset,
    google_storage_bucket.simple_bucket
  ]
}
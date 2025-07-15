# KMS key for bucket encryption
resource "google_kms_key_ring" "app_keyring" {
  name     = "${var.project_id}-${var.environment}-keyring"
  location = var.region
}

resource "google_kms_crypto_key" "bucket_key" {
  name     = "bucket-encryption-key"
  key_ring = google_kms_key_ring.app_keyring.id

  purpose         = "ENCRYPT_DECRYPT"
  rotation_period = "7776000s" # 90 days

  lifecycle {
    prevent_destroy = true
  }
}

# Service Account for compute instances
resource "google_service_account" "app_service_account" {
  account_id   = "${var.project_id}-${var.environment}-app-sa"
  display_name = "Application Service Account"
  description  = "Service account for application compute instances"

  depends_on = [google_project_service.iam_api]
}

# IAM binding for service account - Storage Admin
resource "google_project_iam_member" "app_sa_storage_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.app_service_account.email}"
}

# IAM binding for service account - Monitoring Writer
resource "google_project_iam_member" "app_sa_monitoring_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.app_service_account.email}"
}

# IAM binding for service account - Secret Accessor
resource "google_project_iam_member" "app_sa_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.app_service_account.email}"
}

# IAM binding for Cloud SQL client
resource "google_project_iam_member" "app_sa_sql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.app_service_account.email}"
}

# IAM binding for BigQuery data viewer
resource "google_project_iam_member" "app_sa_bigquery_data_viewer" {
  project = var.project_id
  role    = "roles/bigquery.dataViewer"
  member  = "serviceAccount:${google_service_account.app_service_account.email}"
}

# IAM binding for BigQuery job user
resource "google_project_iam_member" "app_sa_bigquery_job_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.app_service_account.email}"
}

# Random password for database
resource "random_password" "db_password" {
  length  = 32
  special = true
}

# Store database password in Secret Manager
resource "google_secret_manager_secret" "db_password" {
  secret_id = "${var.project_id}-${var.environment}-db-password"

  replication {
    auto {}
  }

  depends_on = [google_project_service.secretmanager_api]
}

resource "google_secret_manager_secret_version" "db_password_version" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = random_password.db_password.result
}
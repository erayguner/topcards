# Storage bucket for access logs
# Note: CKV_GCP_62 fails here by design - log buckets cannot log to themselves
# This is a false positive in Checkov for dedicated log storage buckets
#checkov:skip=CKV_GCP_62:Log bucket cannot log to itself - this is by design
resource "google_storage_bucket" "access_logs" {
  name     = "${var.project_id}-${var.environment}-access-logs"
  location = var.region

  # Security settings
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  # Versioning for compliance
  versioning {
    enabled = true
  }

  # Lifecycle management for logs
  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type = "Delete"
    }
  }

  depends_on = var.enable_apis ? [google_project_service.required["storage.googleapis.com"]] : []
}

# Storage bucket for application data
resource "google_storage_bucket" "app_bucket" {
  name     = "${var.project_id}-${var.environment}-app-storage"
  location = var.region

  # Prevent accidental deletion
  lifecycle {
    prevent_destroy = true
  }

  # Security settings
  uniform_bucket_level_access = true

  # Public access prevention
  public_access_prevention = "enforced"

  # Versioning
  versioning {
    enabled = true
  }

  # Encryption
  encryption {
    default_kms_key_name = google_kms_crypto_key.bucket_key.id
  }

  # Access logging
  logging {
    log_bucket        = google_storage_bucket.access_logs.name
    log_object_prefix = "access-logs/"
  }

  depends_on = concat(
    var.enable_apis ? [google_project_service.required["storage.googleapis.com"]] : [],
    [google_storage_bucket.access_logs]
  )
}

# Simple GCP storage bucket for general use
resource "google_storage_bucket" "simple_bucket" {
  name     = "${var.project_id}-${var.environment}-simple-storage"
  location = var.region

  # Basic security settings
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  # Simple lifecycle rule
  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type = "Delete"
    }
  }

  # Simple versioning
  versioning {
    enabled = false
  }

  # Labels for organization
  labels = {
    environment = var.environment
    purpose     = "simple-storage"
    managed_by  = "terraform"
  }

  depends_on = var.enable_apis ? [google_project_service.required["storage.googleapis.com"]] : []
}

terraform {
  required_version = ">= 1.5"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

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

  # Versioning
  versioning {
    enabled = true
  }

  # Encryption
  encryption {
    default_kms_key_name = google_kms_crypto_key.bucket_key.id
  }

  depends_on = [google_project_service.storage_api]
}

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

# VPC Network
resource "google_compute_network" "vpc_network" {
  name                    = "${var.project_id}-${var.environment}-network"
  auto_create_subnetworks = false
  mtu                     = 1460

  depends_on = [google_project_service.compute_api]
}

# Subnet
resource "google_compute_subnetwork" "subnet" {
  name          = "${var.project_id}-${var.environment}-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.vpc_network.id

  # Enable private Google access
  private_ip_google_access = true

  # Secondary ranges for GKE (if needed)
  secondary_ip_range {
    range_name    = "services-range"
    ip_cidr_range = "192.168.1.0/24"
  }

  secondary_ip_range {
    range_name    = "pod-ranges"
    ip_cidr_range = "192.168.64.0/22"
  }
}

# Firewall rule - Allow HTTP and HTTPS
resource "google_compute_firewall" "allow_http_https" {
  name    = "${var.project_id}-${var.environment}-allow-http-https"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-server"]
}

# Firewall rule - Allow SSH
resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.project_id}-${var.environment}-allow-ssh"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh-access"]
}

# Compute Instance Template
resource "google_compute_instance_template" "app_template" {
  name_prefix  = "${var.project_id}-${var.environment}-template-"
  machine_type = var.machine_type
  region       = var.region

  # Boot disk
  disk {
    source_image = "ubuntu-os-cloud/ubuntu-2204-lts"
    auto_delete  = true
    boot         = true
    disk_size_gb = 20
    disk_type    = "pd-standard"

    # Encryption
    disk_encryption_key {
      kms_key_self_link = google_kms_crypto_key.bucket_key.id
    }
  }

  # Network interface
  network_interface {
    network    = google_compute_network.vpc_network.self_link
    subnetwork = google_compute_subnetwork.subnet.self_link

    # External IP for internet access
    access_config {
      network_tier = "PREMIUM"
    }
  }

  # Service account
  service_account {
    email  = google_service_account.app_service_account.email
    scopes = ["cloud-platform"]
  }

  # Security and startup
  tags = ["web-server", "ssh-access"]

  metadata = {
    startup-script = file("${path.module}/startup-script.sh")
  }

  # Lifecycle
  lifecycle {
    create_before_destroy = true
  }
}

# Service Account for compute instances
resource "google_service_account" "app_service_account" {
  account_id   = "${var.project_id}-${var.environment}-app-sa"
  display_name = "Application Service Account"
  description  = "Service account for application compute instances"

  depends_on = [google_project_service.iam_api]
}

# IAM binding for service account
resource "google_project_iam_member" "app_sa_storage_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.app_service_account.email}"
}

resource "google_project_iam_member" "app_sa_monitoring_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.app_service_account.email}"
}

# Compute Instance (single instance for demo)
resource "google_compute_instance" "app_instance" {
  count        = var.instance_count
  name         = "${var.project_id}-${var.environment}-instance-${count.index + 1}"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 20
      type  = "pd-standard"
    }
  }

  network_interface {
    network    = google_compute_network.vpc_network.self_link
    subnetwork = google_compute_subnetwork.subnet.self_link

    access_config {
      network_tier = "PREMIUM"
    }
  }

  service_account {
    email  = google_service_account.app_service_account.email
    scopes = ["cloud-platform"]
  }

  tags = ["web-server", "ssh-access"]

  metadata = {
    startup-script = file("${path.module}/startup-script.sh")
  }

  depends_on = [
    google_project_service.compute_api,
    google_service_account.app_service_account
  ]
}

# Private IP allocation for Cloud SQL
resource "google_compute_global_address" "private_ip_address" {
  name          = "${var.project_id}-${var.environment}-private-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc_network.id

  depends_on = [google_project_service.networking_api]
}

# Private connection for Cloud SQL
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]

  depends_on = [google_project_service.networking_api]
}

# Random password for database
resource "random_password" "db_password" {
  length  = 32
  special = true
}

# Cloud SQL PostgreSQL instance
resource "google_sql_database_instance" "postgres_instance" {
  name             = "${var.project_id}-${var.environment}-postgres"
  database_version = var.db_version
  region           = var.region

  # Prevent accidental deletion
  deletion_protection = var.environment == "prod" ? true : false

  settings {
    tier              = var.db_tier
    availability_type = var.environment == "prod" ? "REGIONAL" : "ZONAL"
    disk_type         = "PD_SSD"
    disk_size         = var.db_disk_size
    disk_autoresize   = true

    # Backup configuration
    backup_configuration {
      enabled                        = true
      start_time                     = "03:00"
      location                       = var.region
      point_in_time_recovery_enabled = true
      transaction_log_retention_days = 7

      backup_retention_settings {
        retained_backups = 30
        retention_unit   = "COUNT"
      }
    }

    # IP configuration for private access
    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = google_compute_network.vpc_network.id
      enable_private_path_for_google_cloud_services = true
      require_ssl                                   = true

      authorized_networks {
        name  = "internal-subnet"
        value = google_compute_subnetwork.subnet.ip_cidr_range
      }
    }

    # Database flags for security and performance
    database_flags {
      name  = "log_checkpoints"
      value = "on"
    }

    database_flags {
      name  = "log_connections"
      value = "on"
    }

    database_flags {
      name  = "log_disconnections"
      value = "on"
    }

    database_flags {
      name  = "log_lock_waits"
      value = "on"
    }

    database_flags {
      name  = "shared_preload_libraries"
      value = "pg_stat_statements"
    }

    # Maintenance window
    maintenance_window {
      day          = 7
      hour         = 4
      update_track = "stable"
    }

    # Insights configuration
    insights_config {
      query_insights_enabled  = true
      query_string_length     = 1024
      record_application_tags = true
      record_client_address   = true
    }
  }

  depends_on = [
    google_service_networking_connection.private_vpc_connection,
    google_project_service.sql_api
  ]
}

# Database user
resource "google_sql_user" "app_user" {
  name     = var.db_user
  instance = google_sql_database_instance.postgres_instance.name
  password = random_password.db_password.result
}

# Application database
resource "google_sql_database" "app_database" {
  name     = var.db_name
  instance = google_sql_database_instance.postgres_instance.name
}

# SSL certificate for database connection
resource "google_sql_ssl_cert" "client_cert" {
  common_name = "${var.project_id}-${var.environment}-client-cert"
  instance    = google_sql_database_instance.postgres_instance.name
}

# Store database password in Secret Manager
resource "google_project_service" "secretmanager_api" {
  service = "secretmanager.googleapis.com"

  disable_dependent_services = true
  disable_on_destroy         = false
}

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

# IAM binding for service account to access secrets
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
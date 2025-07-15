# Cloud SQL PostgreSQL instance
resource "google_sql_database_instance" "postgres_instance" {
  count            = var.enable_database ? 1 : 0
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

    # Enhanced database flags for security and compliance
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
      name  = "log_hostname"
      value = "on"
    }

    database_flags {
      name  = "log_min_messages"
      value = "ERROR"
    }

    database_flags {
      name  = "log_statement"
      value = "all"
    }

    database_flags {
      name  = "shared_preload_libraries"
      value = "pgaudit,pg_stat_statements"
    }

    database_flags {
      name  = "pgaudit.log"
      value = "ddl,dml,role,function,misc"
    }

    database_flags {
      name  = "pgaudit.log_catalog"
      value = "on"
    }

    database_flags {
      name  = "pgaudit.log_client"
      value = "on"
    }

    database_flags {
      name  = "pgaudit.log_level"
      value = "ERROR"
    }

    database_flags {
      name  = "pgaudit.log_parameter"
      value = "on"
    }

    database_flags {
      name  = "pgaudit.log_relation"
      value = "on"
    }

    database_flags {
      name  = "pgaudit.log_statement_once"
      value = "off"
    }

    database_flags {
      name  = "log_duration"
      value = "on"
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

    # User-defined labels for the instance
    user_labels = var.labels
  }

  depends_on = [
    google_service_networking_connection.private_vpc_connection
  ]
}

# Database user
resource "google_sql_user" "app_user" {
  count    = var.enable_database ? 1 : 0
  name     = var.db_user
  instance = google_sql_database_instance.postgres_instance[0].name
  password = random_password.db_password.result
}

# Application database
resource "google_sql_database" "app_database" {
  count    = var.enable_database ? 1 : 0
  name     = var.db_name
  instance = google_sql_database_instance.postgres_instance[0].name
}

# SSL certificate for database connection
resource "google_sql_ssl_cert" "client_cert" {
  count       = var.enable_database ? 1 : 0
  common_name = "${var.project_id}-${var.environment}-client-cert"
  instance    = google_sql_database_instance.postgres_instance[0].name
}
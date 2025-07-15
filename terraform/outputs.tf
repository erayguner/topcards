output "project_id" {
  description = "The GCP project ID"
  value       = var.project_id
}

output "region" {
  description = "The GCP region"
  value       = var.region
}

output "vpc_network_name" {
  description = "The name of the VPC network"
  value       = google_compute_network.vpc_network.name
}

output "vpc_network_id" {
  description = "The ID of the VPC network"
  value       = google_compute_network.vpc_network.id
}

output "subnet_name" {
  description = "The name of the subnet"
  value       = google_compute_subnetwork.subnet.name
}

output "subnet_cidr" {
  description = "The CIDR range of the subnet"
  value       = google_compute_subnetwork.subnet.ip_cidr_range
}

output "storage_bucket_name" {
  description = "The name of the storage bucket"
  value       = google_storage_bucket.app_bucket.name
}

output "storage_bucket_url" {
  description = "The URL of the storage bucket"
  value       = google_storage_bucket.app_bucket.url
}

output "simple_bucket_name" {
  description = "The name of the simple storage bucket"
  value       = google_storage_bucket.simple_bucket.name
}

output "simple_bucket_url" {
  description = "The URL of the simple storage bucket"
  value       = google_storage_bucket.simple_bucket.url
}

output "simple_bucket_location" {
  description = "The location of the simple storage bucket"
  value       = google_storage_bucket.simple_bucket.location
}

output "kms_key_ring_name" {
  description = "The name of the KMS key ring"
  value       = google_kms_key_ring.app_keyring.name
}

output "kms_crypto_key_name" {
  description = "The name of the KMS crypto key"
  value       = google_kms_crypto_key.bucket_key.name
}

output "service_account_email" {
  description = "The email of the service account"
  value       = google_service_account.app_service_account.email
}

output "instance_names" {
  description = "The names of the compute instances"
  value       = google_compute_instance.app_instance[*].name
}

output "instance_external_ips" {
  description = "The external IP addresses of the compute instances (none - private only)"
  value       = []
}

output "instance_internal_ips" {
  description = "The internal IP addresses of the compute instances"
  value       = google_compute_instance.app_instance[*].network_interface[0].network_ip
}

output "instance_zones" {
  description = "The zones of the compute instances"
  value       = google_compute_instance.app_instance[*].zone
}

output "firewall_rules" {
  description = "The names of the firewall rules"
  value = [
    google_compute_firewall.allow_https.name,
    google_compute_firewall.allow_http_lb.name,
    google_compute_firewall.allow_ssh.name
  ]
}

output "enabled_apis" {
  description = "List of enabled GCP APIs"
  value = var.enable_apis ? [
    google_project_service.compute_api[0].service,
    google_project_service.storage_api[0].service,
    google_project_service.iam_api[0].service,
    google_project_service.sql_api[0].service,
    google_project_service.networking_api[0].service,
    google_project_service.secretmanager_api[0].service,
    google_project_service.bigquery_api[0].service
  ] : []
}

# Database outputs
output "database_instance_name" {
  description = "The name of the Cloud SQL instance"
  value       = var.enable_database ? google_sql_database_instance.postgres_instance[0].name : null
}

output "database_instance_connection_name" {
  description = "The connection name of the Cloud SQL instance"
  value       = var.enable_database ? google_sql_database_instance.postgres_instance[0].connection_name : null
}

output "database_instance_private_ip" {
  description = "The private IP address of the Cloud SQL instance"
  value       = var.enable_database ? google_sql_database_instance.postgres_instance[0].private_ip_address : null
}

output "database_name" {
  description = "The name of the application database"
  value       = var.enable_database ? google_sql_database.app_database[0].name : null
}

output "database_user" {
  description = "The username of the application database user"
  value       = var.enable_database ? google_sql_user.app_user[0].name : null
  sensitive   = true
}

output "database_password_secret_name" {
  description = "The name of the Secret Manager secret containing the database password"
  value       = google_secret_manager_secret.db_password.secret_id
}

output "database_ssl_cert" {
  description = "SSL certificate information for database connection"
  value = var.enable_database ? {
    cert             = google_sql_ssl_cert.client_cert[0].cert
    common_name      = google_sql_ssl_cert.client_cert[0].common_name
    create_time      = google_sql_ssl_cert.client_cert[0].create_time
    expiration_time  = google_sql_ssl_cert.client_cert[0].expiration_time
    sha1_fingerprint = google_sql_ssl_cert.client_cert[0].sha1_fingerprint
  } : null
  sensitive = true
}

output "private_vpc_connection" {
  description = "The private VPC connection for Cloud SQL"
  value       = google_service_networking_connection.private_vpc_connection.network
}

# BigQuery outputs
output "bigquery_dataset_id" {
  description = "The ID of the BigQuery dataset for CSV data"
  value       = google_bigquery_dataset.csv_dataset.dataset_id
}

output "bigquery_dataset_location" {
  description = "The location of the BigQuery dataset"
  value       = google_bigquery_dataset.csv_dataset.location
}

output "bigquery_external_table_id" {
  description = "The ID of the BigQuery external table for CSV files"
  value       = google_bigquery_table.csv_external_table.table_id
}

output "bigquery_external_table_self_link" {
  description = "The self link of the BigQuery external table"
  value       = google_bigquery_table.csv_external_table.self_link
}

output "bigquery_csv_source_uri" {
  description = "The source URI pattern for CSV files in BigQuery"
  value       = "gs://${google_storage_bucket.simple_bucket.name}/*.csv"
}
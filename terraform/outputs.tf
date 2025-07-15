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
  description = "The external IP addresses of the compute instances"
  value       = google_compute_instance.app_instance[*].network_interface.0.access_config.0.nat_ip
}

output "instance_internal_ips" {
  description = "The internal IP addresses of the compute instances"
  value       = google_compute_instance.app_instance[*].network_interface.0.network_ip
}

output "instance_zones" {
  description = "The zones of the compute instances"
  value       = google_compute_instance.app_instance[*].zone
}

output "firewall_rules" {
  description = "The names of the firewall rules"
  value = [
    google_compute_firewall.allow_http_https.name,
    google_compute_firewall.allow_ssh.name
  ]
}

output "enabled_apis" {
  description = "List of enabled GCP APIs"
  value = [
    google_project_service.compute_api.service,
    google_project_service.storage_api.service,
    google_project_service.iam_api.service
  ]
}
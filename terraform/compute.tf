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

  # Network interface - Private only for security
  network_interface {
    network    = google_compute_network.vpc_network.self_link
    subnetwork = google_compute_subnetwork.subnet.self_link
    # Removed external IP access for security - use Cloud NAT or VPN for outbound access
  }

  # Service account
  service_account {
    email  = google_service_account.app_service_account.email
    scopes = ["cloud-platform"]
  }

  # Enable Shielded VM features for security
  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  # Security and startup
  tags = ["web-server", "ssh-access"]

  metadata = {
    startup-script         = file("${path.module}/startup-script.sh")
    block-project-ssh-keys = "true"
  }

  # Lifecycle
  lifecycle {
    create_before_destroy = true
  }
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
    # Encrypt boot disk with KMS key
    kms_key_self_link = google_kms_crypto_key.bucket_key.id
  }

  network_interface {
    network    = google_compute_network.vpc_network.self_link
    subnetwork = google_compute_subnetwork.subnet.self_link
    # Removed external IP access for security - use Cloud NAT or VPN for outbound access
  }

  service_account {
    email  = google_service_account.app_service_account.email
    scopes = ["cloud-platform"]
  }

  # Enable Shielded VM features for security
  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  tags = ["web-server", "ssh-access"]

  metadata = {
    startup-script         = file("${path.module}/startup-script.sh")
    block-project-ssh-keys = "true"
  }

  depends_on = [
    google_project_service.compute_api,
    google_service_account.app_service_account
  ]
}
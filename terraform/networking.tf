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

  # Enable VPC Flow Logs for security monitoring
  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }

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

# Firewall rule - Allow HTTPS only (secure web traffic)
resource "google_compute_firewall" "allow_https" {
  name    = "${var.project_id}-${var.environment}-allow-https"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-server"]
}

# Firewall rule - Allow HTTP from load balancer only
resource "google_compute_firewall" "allow_http_lb" {
  name    = "${var.project_id}-${var.environment}-allow-http-lb"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  # Restrict HTTP to Google Load Balancer IP ranges
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["web-server"]
}

# Firewall rule - Allow SSH from specific IP ranges only
resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.project_id}-${var.environment}-allow-ssh"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # Restrict SSH access to specified CIDR blocks for security
  source_ranges = var.allowed_cidr_blocks
  target_tags   = ["ssh-access"]
}

# Cloud Router for NAT
resource "google_compute_router" "router" {
  name    = "${var.project_id}-${var.environment}-router"
  region  = var.region
  network = google_compute_network.vpc_network.id
}

# Cloud NAT for outbound internet access
resource "google_compute_router_nat" "nat" {
  name                               = "${var.project_id}-${var.environment}-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
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
# GCP-INFRA - SECURITY.TF

resource "google_compute_firewall" "allow_mgmt" {
  name    = "a10-allow-mgmt"
  network = google_compute_network.vpc_a10_management.name

  allow {
    protocol = "tcp"
    ports    = ["22", "443"]
  }

  source_ranges = var.source_ip_ranges
}

resource "google_compute_firewall" "allow_vip_http_https" {
  name    = "a10-allow-vip-http-https"
  network = google_compute_network.vpc_a10_external.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "allow_internal" {
  name    = "allow-internal"
  network = google_compute_network.vpc_a10_internal.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = ["10.0.0.0/8"]
}

resource "google_compute_firewall" "internal_backend_http" {
  name    = "a10-internal-backend-http"
  network = google_compute_network.vpc_a10_internal.name

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443"]
  }
  
  source_ranges = var.source_ip_ranges
  //source_ranges = [google_compute_subnetwork.subnet_ip_internal.ip_cidr_range]
}

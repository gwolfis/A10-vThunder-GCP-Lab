# GCP-INFRA - NETWORKS.TF

resource "google_compute_network" "vpc_a10_management" {
  name                    = var.vpc_a10_management_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet_ip_management" {
  name          = var.subnet_management_name
  ip_cidr_range = var.subnet_ip_management
  region        = var.region
  network       = google_compute_network.vpc_a10_management.self_link
}

resource "google_compute_network" "vpc_a10_external" {
  name                    = var.vpc_a10_external_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet_ip_external" {
  name          = var.subnet_external_name
  ip_cidr_range = var.subnet_ip_external
  region        = var.region
  network       = google_compute_network.vpc_a10_external.self_link
}

resource "google_compute_network" "vpc_a10_internal" {
  name                    = var.vpc_a10_internal_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet_ip_internal" {
  name          = var.subnet_internal_name
  ip_cidr_range = var.subnet_ip_internal
  region        = var.region
  network       = google_compute_network.vpc_a10_internal.self_link
}

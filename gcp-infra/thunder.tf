# GCP-INFRA - THUNDER.TF

locals {
  adc_instances = {
    for i in range(var.adc_count) :
    "${var.adc_hostname_prefix}-${i + 1}" => {
      hostname  = "${var.adc_hostname_prefix}-${i + 1}"
      mgmt_host = var.adc_mgmt_host_start + i
      ext_host  = var.adc_ext_host_start + i
      int_host  = var.adc_int_host_start + i
    }
  }

  adc_ips = {
    for k, v in local.adc_instances : k => {
      eth0_ip = cidrhost(var.subnet_ip_management, v.mgmt_host)
      eth1_ip = cidrhost(var.subnet_ip_external, v.ext_host)
      eth2_ip = cidrhost(var.subnet_ip_internal, v.int_host)
    }
  }

  # Only the first ADC gets an external public IP on eth1
  external_public_keys = toset(["${var.adc_hostname_prefix}-1"])

  a10_cloudinit = {
    for k, v in local.adc_instances : k => templatefile("${path.module}/cloud-init-a10.tmpl", {
      hostname      = v.hostname
      user_name     = var.a10_username
      user_password = var.a10_password
      dns_primary   = var.dns_primary
      time_zone     = var.time_zone
      ntp_server    = var.ntp_server

      eth0_ip = local.adc_ips[k].eth0_ip
      eth1_ip = local.adc_ips[k].eth1_ip
      eth2_ip = local.adc_ips[k].eth2_ip
      eth0_gw = google_compute_subnetwork.subnet_ip_management.gateway_address
      eth1_gw = google_compute_subnetwork.subnet_ip_external.gateway_address
    })
  }
}

resource "google_compute_address" "a10_management_pip" {
  for_each = local.adc_instances
  name     = "${each.key}-management-pip"
  region   = var.region
}

# Only create external PIPs for the keys in external_public_keys
resource "google_compute_address" "a10_external_pip" {
  for_each = {
    for k, v in local.adc_instances : k => v
    if contains(local.external_public_keys, k)
  }

  name   = "${each.key}-external-pip"
  region = var.region
}

resource "google_compute_instance" "a10_vthunder" {
  for_each                  = local.adc_instances
  name                      = each.value.hostname
  machine_type              = var.a10_machine_type
  zone                      = var.zone
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = var.a10_image
      size  = 30
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet_ip_management.self_link
    network_ip = local.adc_ips[each.key].eth0_ip
    access_config {
      nat_ip = google_compute_address.a10_management_pip[each.key].address
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet_ip_external.self_link
    network_ip = local.adc_ips[each.key].eth1_ip

    dynamic "access_config" {
      for_each = contains(local.external_public_keys, each.key) ? [1] : []
      content {
        nat_ip = google_compute_address.a10_external_pip[each.key].address
      }
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet_ip_internal.self_link
    network_ip = local.adc_ips[each.key].eth2_ip
  }

  labels = {
    environment = var.environment
    deployment  = var.deployment
    adc         = each.key
  }

  metadata = {
    owner       = var.owner
    "user-data" = local.a10_cloudinit[each.key]
  }
}

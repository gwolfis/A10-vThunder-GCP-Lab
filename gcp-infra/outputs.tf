# GCP-INFRA OUTPUTS

########################################
# Raw outputs to support other modules
########################################

output "project_id" {
  value = var.project_id
}

output "region" {
  value = var.region
}

output "zone" {
  value = var.zone
}

locals {
  adc_keys        = sort(keys(google_compute_instance.a10_vthunder))
  primary_adc_key = local.adc_keys[0]
}

output "a10_instance_self_link_map" {
  description = "Self links of all vThunder instances"
  value = {
    for k, inst in google_compute_instance.a10_vthunder :
    k => inst.self_link
  }
}

output "network_self_link" {
  value = google_compute_network.vpc_a10_management.self_link
}

output "mgmt_subnetwork_self_link" {
  value = google_compute_subnetwork.subnet_ip_management.self_link
}

output "a10_mgmt_private_ip_map" {
  description = "Private management IPs of all A10 ADCs"
  value = {
    for k, inst in google_compute_instance.a10_vthunder :
    k => inst.network_interface[0].network_ip
  }
}

output "a10_mgmt_ip_map" {
  description = "Public management IPs of all A10 ADCs"
  value = {
    for k, ip in google_compute_address.a10_management_pip :
    k => ip.address
  }
}

output "a10_external_private_ip_map" {
  description = "Private external IPs of all A10 ADCs"
  value = {
    for k, inst in google_compute_instance.a10_vthunder :
    k => inst.network_interface[1].network_ip
  }
}

output "a10_external_ip_map" {
  description = "Public external IPs of all A10 ADCs, null if not assigned"
  value = {
    for k, inst in google_compute_instance.a10_vthunder :
    k => try(google_compute_address.a10_external_pip[k].address, null)
  }
}

output "external_subnetwork_self_link" {
  value = google_compute_subnetwork.subnet_ip_external.self_link
}

output "a10_internal_ip_map" {
  description = "Internal IPs of all A10 ADCs"
  value = {
    for k, inst in google_compute_instance.a10_vthunder :
    k => inst.network_interface[2].network_ip
  }
}

########################################
# Backwards compatible outputs for primary ADC
########################################

output "a10_instance_self_link" {
  description = "Self link of the primary vThunder instance"
  value       = google_compute_instance.a10_vthunder[local.primary_adc_key].self_link
}

output "a10_mgmt_private_ip" {
  description = "Private management IP of the primary A10 ADC"
  value       = google_compute_instance.a10_vthunder[local.primary_adc_key].network_interface[0].network_ip
}

output "a10_mgmt_ip" {
  description = "Public management IP of the primary A10 ADC"
  value       = google_compute_address.a10_management_pip[local.primary_adc_key].address
}

output "a10_external_private_ip" {
  description = "Private external IP of the primary A10 ADC"
  value       = google_compute_instance.a10_vthunder[local.primary_adc_key].network_interface[1].network_ip
}

output "a10_external_ip" {
  description = "Public external IP of the primary A10 ADC, null if not assigned"
  value       = try(google_compute_address.a10_external_pip[local.primary_adc_key].address, null)
}

output "a10_internal_ip" {
  description = "Internal IP of the primary A10 ADC"
  value       = google_compute_instance.a10_vthunder[local.primary_adc_key].network_interface[2].network_ip
}

########################################
# Network and backend outputs
########################################

output "a10_external_network" {
  value = google_compute_network.vpc_a10_external.self_link
}

output "backend_ip" {
  description = "Private IP of the backend webserver"
  value       = google_compute_instance.backend_web.network_interface[0].network_ip
}

output "backend_external_ip" {
  description = "Public IP of the backend webserver if present"
  value       = try(google_compute_instance.backend_web.network_interface[0].access_config[0].nat_ip, null)
}

output "a10_cert_name" {
  description = "SSL certificate and key name on the A10"
  value       = "a10demo"
}

output "source_ip_ranges" {
  description = "Source IP ranges allowed"
  value       = var.source_ip_ranges
}

########################################
# Human readable overview
########################################

output "thunder_adc_lab_info" {
  description = "Overview of key IP addresses and shortcuts"
  value = <<EOF

Thunder ADC Lab Info

Primary ADC key
  ${local.primary_adc_key}

Thunder ADCs
${join("\n", [
  for k in local.adc_keys : format(
    "  %s\n    mgmt private    : %s\n    mgmt public     : %s\n    external private: %s\n    external public : %s\n    internal private: %s\n    shortcuts\n      ssh mgmt       : ssh admin@%s\n      https mgmt gui : https://%s\n      https external : %s\n",
    k,
    google_compute_instance.a10_vthunder[k].network_interface[0].network_ip,
    google_compute_address.a10_management_pip[k].address,
    google_compute_instance.a10_vthunder[k].network_interface[1].network_ip,
    try(google_compute_address.a10_external_pip[k].address, "n/a"),
    google_compute_instance.a10_vthunder[k].network_interface[2].network_ip,
    google_compute_address.a10_management_pip[k].address,
    google_compute_address.a10_management_pip[k].address,
    try(format("https://%s", google_compute_address.a10_external_pip[k].address), "n/a")
  )
])}

Backend
  backend-1 private: ${google_compute_instance.backend_web.network_interface[0].network_ip}
  backend-1 public : ${try(google_compute_instance.backend_web.network_interface[0].access_config[0].nat_ip, "n/a")}

EOF
}

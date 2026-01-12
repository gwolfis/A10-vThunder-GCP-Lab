# GCP-EDGE - OUTPUTS.TF

output "vips_to_check" {
  value = [
    "https://${google_compute_address.vip_web_ext.address}"
  ]
}

locals {
  configured_adcs = sort(tolist(var.configure_adcs))
  adc2_configured = contains(var.configure_adcs, "vthunder-2")
}

output "edge_forwarding_info" {
  description = "Summary of the GCP edge forwarding configuration"
  value = <<EOT
GCP Edge Forwarding
-------------------
Configured ADC keys : ${join(", ", local.configured_adcs)}
ADC2 configured     : ${local.adc2_configured}

Active ADC key      : ${var.edge_active_adc_key}
Forwarding rule     : ${google_compute_forwarding_rule.vip_web_fr.name}
Target instance     : ${jsonencode(local.target_instance_name_map)}
VIP (TCP/443)       : ${google_compute_address.vip_web_ext.address}:443
HTTPS shortcut      : https://${google_compute_address.vip_web_ext.address}

ADC Management access
${join("\n", [
  for k in local.configured_adcs : format(
    "  %s\n    mgmt public  : %s\n    ssh shortcut : ssh %s@%s\n    https gui    : https://%s\n",
    k,
    lookup(local.mgmt_ip_map, k, "n/a"),
    var.a10_username,
    lookup(local.mgmt_ip_map, k, "n/a"),
    lookup(local.mgmt_ip_map, k, "n/a")
  )
])}
EOT
}

output "edge_slb_status" {
  description = "Whether SLB config has been applied per ADC key"
  value = {
    "vthunder-1" = contains(var.configure_adcs, "vthunder-1")
    "vthunder-2" = contains(var.configure_adcs, "vthunder-2")
  }
}

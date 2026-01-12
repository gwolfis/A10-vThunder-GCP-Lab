# GCP-EDGE - OUTPUTS.TF

output "vips_to_check" {
  value = [
    "https://${google_compute_address.vip_web_ext.address}"
  ]
}

output "edge_forwarding_info" {
  description = "Summary of the GCP edge forwarding configuration"
  value       = <<EOT
GCP Edge Forwarding

Configured ADC keys : ${join(", ", local.adc_keys)}
Active ADC key      : ${local.edge_active_adc_key_effective}
Forwarding rule     : ${google_compute_forwarding_rule.vip_web_fr.name}
Target instance map : ${jsonencode(local.target_instance_name_map)}
VIP (TCP/443)       : ${google_compute_address.vip_web_ext.address}:443
HTTPS shortcut      : https://${google_compute_address.vip_web_ext.address}

Management access
${join("\n", [
  for k in local.adc_keys : format(
    "%s\n  Management public IP  : %s\n  Management private IP : %s\n  SSH shortcut          : ssh %s@%s\n",
    k,
    lookup(local.mgmt_ip_map, k, "n/a"),
    lookup(
      try(
        data.terraform_remote_state.infra.outputs.a10_mgmt_private_ip_map,
        data.terraform_remote_state.infra.outputs.a10_private_ip_map,
        {}
      ),
      k,
      "n/a"
    ),
    var.a10_username,
    lookup(local.mgmt_ip_map, k, "n/a")
  )
])}

EOT
}

output "edge_slb_status" {
  description = "Whether SLB config has been applied per ADC key"
  value = {
    "vthunder-1" = contains(local.adc_keys, "vthunder-1")
    "vthunder-2" = contains(local.adc_keys, "vthunder-2")
  }
}

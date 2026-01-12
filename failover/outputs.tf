# FAILOVER - OUTPUTS.TF

output "failover_vm_internal_ip" {
  value = google_compute_instance.failover.network_interface[0].network_ip
}

output "failover_vm_public_ip" {
  value = try(google_compute_instance.failover.network_interface[0].access_config[0].nat_ip, null)
  depends_on  = [null_resource.wait_for_failover_service]
}

output "primary_ti_name" {
  value = "a10-ti-vthunder-1"
}

output "secondary_ti_name" {
  value = "a10-ti-vthunder-2"
}

output "primary_ti_zone" {
  value = data.terraform_remote_state.infra.outputs.zone
}

output "secondary_ti_zone" {
  value = data.terraform_remote_state.infra.outputs.zone
}

output "forwarding_rule_filter" {
  value = "labels.a10-ha=true"
}

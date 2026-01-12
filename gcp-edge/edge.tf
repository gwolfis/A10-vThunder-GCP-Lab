resource "google_compute_address" "vip_web_ext" {
  name   = "vip-web-ext-ip"
  region = data.terraform_remote_state.infra.outputs.region
}

locals {
  mgmt_ip_map = data.terraform_remote_state.infra.outputs.a10_mgmt_public_ip_map
  adc_keys    = sort(keys(local.mgmt_ip_map))

  adc1_key = local.adc_keys[0]
  adc2_key = length(local.adc_keys) > 1 ? local.adc_keys[1] : local.adc_keys[0]

  adc1_mgmt_ip = local.mgmt_ip_map[local.adc1_key]
  adc2_mgmt_ip = local.mgmt_ip_map[local.adc2_key]

  target_instance_name_map = {
    for k in local.adc_keys :
    k => "a10-ti-${replace(k, "_", "-")}"
  }

  target_instance_self_link_map = {
    for k, name in local.target_instance_name_map :
    k => "https://www.googleapis.com/compute/v1/projects/${data.terraform_remote_state.infra.outputs.project_id}/zones/${data.terraform_remote_state.infra.outputs.zone}/targetInstances/${name}"
  }

  edge_active_adc_key_normalized = length(trimspace(var.edge_active_adc_key)) > 0 ? replace(var.edge_active_adc_key, "_", "-") : local.adc1_key
  edge_active_adc_key_effective  = contains(local.adc_keys, local.edge_active_adc_key_normalized) ? local.edge_active_adc_key_normalized : local.adc1_key

  active_target_instance_self_link = local.target_instance_self_link_map[local.edge_active_adc_key_effective]
}



resource "null_resource" "a10_target_instance" {
  for_each = local.target_instance_name_map

  triggers = {
    project_id       = data.terraform_remote_state.infra.outputs.project_id
    zone             = data.terraform_remote_state.infra.outputs.zone
    external_net_url = data.terraform_remote_state.infra.outputs.a10_external_network
    a10_instance_url = data.terraform_remote_state.infra.outputs.a10_instance_self_link_map[each.key]
    ti_name          = each.value
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]

    command = <<-EOT
      set -e

      PROJECT_ID="${self.triggers.project_id}"
      ZONE="${self.triggers.zone}"

      EXTERNAL_NET_URL="${self.triggers.external_net_url}"
      EXTERNAL_NETWORK_NAME="$(basename "$EXTERNAL_NET_URL")"

      A10_INSTANCE_URL="${self.triggers.a10_instance_url}"
      A10_INSTANCE_NAME="$(basename "$A10_INSTANCE_URL")"

      TI_NAME="${self.triggers.ti_name}"

      echo "Checking if target instance $TI_NAME already exists in $PROJECT_ID/$ZONE..."
      if gcloud compute target-instances describe "$TI_NAME" \
          --project="$PROJECT_ID" \
          --zone="$ZONE" >/dev/null 2>&1; then
        echo "Target instance $TI_NAME already exists, skipping create"
        exit 0
      fi

      echo "Creating target instance $TI_NAME on network $EXTERNAL_NETWORK_NAME..."
      gcloud compute target-instances create "$TI_NAME" \
        --project="$PROJECT_ID" \
        --zone="$ZONE" \
        --instance="$A10_INSTANCE_NAME" \
        --network="$EXTERNAL_NETWORK_NAME"
    EOT
  }
}

resource "google_compute_forwarding_rule" "vip_web_fr" {
  name                  = "vip-web-fr"
  region                = data.terraform_remote_state.infra.outputs.region
  load_balancing_scheme = "EXTERNAL"

  ip_protocol = "TCP"
  port_range  = "443"

  ip_address = google_compute_address.vip_web_ext.address
  target     = local.active_target_instance_self_link

  labels = {
    "a10-ha" = "true"
  }

  depends_on = [null_resource.a10_target_instance]
}

resource "google_compute_firewall" "allow_https_to_a10" {
  name    = "a10-fw-allow-https"
  network = data.terraform_remote_state.infra.outputs.a10_external_network

  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = data.terraform_remote_state.infra.outputs.source_ip_ranges
  target_tags   = ["a10-adc-external"]
}
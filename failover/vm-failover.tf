# FAILOVER - VM-FAILOVER.TF

locals {
  infra = data.terraform_remote_state.infra.outputs
  edge  = data.terraform_remote_state.edge.outputs

  project_id = coalesce(try(local.edge.project_id, null), try(local.infra.project_id, null), "__MISSING__")
  region     = coalesce(try(local.edge.region, null), try(local.infra.region, null), "__MISSING__")
  
  vips_to_check = try(local.edge.vips_to_check, try(local.infra.vips_to_check, []))

  forwarding_rule_filter = coalesce(
    try(local.edge.forwarding_rule_filter, null),
    try(local.infra.forwarding_rule_filter, null),
    "labels.a10-ha=true"
  )

  edge_slb_status = try(local.edge.edge_slb_status, {})
  adc_keys        = sort(keys(local.edge_slb_status))

  primary_adc_key   = length(local.adc_keys) > 0 ? local.adc_keys[0] : null
  secondary_adc_key = length(local.adc_keys) > 1 ? local.adc_keys[1] : null

  primary_ti_name = coalesce(
    try(local.edge.primary_ti_name, null),
    try(local.infra.primary_ti_name, null),
    local.primary_adc_key != null ? "a10-ti-${local.primary_adc_key}" : "__MISSING__"
  )

  primary_ti_zone = coalesce(
    try(local.edge.primary_ti_zone, null),
    try(local.infra.primary_ti_zone, null),
    try(local.infra.zone, null),
    "__MISSING__"
  )

  secondary_ti_name = coalesce(
    try(local.edge.secondary_ti_name, null),
    try(local.infra.secondary_ti_name, null),
    local.secondary_adc_key != null ? "a10-ti-${local.secondary_adc_key}" : "__MISSING__"
  )

  secondary_ti_zone = coalesce(
    try(local.edge.secondary_ti_zone, null),
    try(local.infra.secondary_ti_zone, null),
    try(local.infra.zone, null),
    "__MISSING__"
  )

  mgmt_subnetwork_self_link = coalesce(
    try(local.infra.mgmt_subnetwork_self_link, null),
    try(local.infra.management_subnetwork_self_link, null),
    try(local.infra.mgmt_subnet_self_link, null),
    try(local.infra.management_subnet_self_link, null),
    "__MISSING__"
  )

  network_self_link = coalesce(
    try(local.infra.network_self_link, null),
    try(local.infra.vpc_self_link, null),
    try(local.infra.network, null),
    try(local.infra.vpc, null),
    "__MISSING__"
  )
}


locals {
  failover_sh      = file("${path.module}/a10-failover.sh")
  failover_service = file("${path.module}/a10-failover.service")

  startup_script = <<-EOT
#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y ca-certificates curl gnupg openssl coreutils

if ! command -v gcloud >/dev/null 2>&1; then
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /etc/apt/keyrings/cloud.google.gpg
  echo "deb [signed-by=/etc/apt/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" > /etc/apt/sources.list.d/google-cloud-sdk.list
  apt-get update -y
  apt-get install -y google-cloud-cli
fi

mkdir -p /etc/a10-failover

cat >/etc/a10-failover/env <<EOF
REGION=${local.region}
PRIMARY_TI=${local.primary_ti_name}
PRIMARY_ZONE=${local.primary_ti_zone}
SECONDARY_TI=${local.secondary_ti_name}
SECONDARY_ZONE=${local.secondary_ti_zone}
HEALTH_POLICY=ANY
VIPS_TO_CHECK="${join(" ", local.vips_to_check)}"
FW_FILTER="${local.forwarding_rule_filter}"
HEALTHCHECK_TOOL=OPENSSL
OPENSSL_TIMEOUT_SECONDS=6
EOF

cat >/usr/local/bin/a10-failover.sh <<'EOF'
${local.failover_sh}
EOF
chmod 0755 /usr/local/bin/a10-failover.sh

cat >/etc/systemd/system/a10-failover.service <<'EOF'
${local.failover_service}
EOF
chmod 0644 /etc/systemd/system/a10-failover.service

systemctl daemon-reload
systemctl enable --now a10-failover.service
  EOT
}


resource "google_compute_instance" "failover" {
  project      = data.terraform_remote_state.infra.outputs.project_id
  zone         = data.terraform_remote_state.infra.outputs.zone
  name         = "failover-vm"
  machine_type = "e2-micro"

  tags = ["a10-failover", "a10-failover-ssh"]

  boot_disk {
    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/family/ubuntu-minimal-2404-lts-amd64"
    }
  }

  network_interface {
    subnetwork = local.mgmt_subnetwork_self_link

    access_config {
    }
  }

  network_interface {
    subnetwork = local.infra.external_subnetwork_self_link
  }

  service_account {
    email  = google_service_account.failover.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  lifecycle {
  precondition {
    condition = local.project_id != "__MISSING__" && local.region != "__MISSING__" && local.primary_ti_name != "__MISSING__" && local.primary_ti_zone != "__MISSING__" && local.secondary_ti_name != "__MISSING__" && local.secondary_ti_zone != "__MISSING__" && local.mgmt_subnetwork_self_link != "__MISSING__" && local.network_self_link != "__MISSING__"
    error_message = "Target instance namen of zones ontbreken of management subnet of network outputs ontbreken in gcp-infra. Voeg outputs toe voor mgmt_subnetwork_self_link en network_self_link."
    }
  }


  metadata_startup_script = local.startup_script
}

resource "google_compute_firewall" "allow_ssh_failover" {
  name    = "allow-ssh-failover-vm"
  network = local.network_self_link

  direction = "INGRESS"
  priority  = 1000

  target_tags   = ["a10-failover-ssh"]
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

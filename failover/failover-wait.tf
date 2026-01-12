resource "null_resource" "wait_for_failover_service" {
  triggers = {
    instance_id = google_compute_instance.failover.id
    script_hash = sha256(local.startup_script)
  }

  depends_on = [
    google_compute_firewall.allow_ssh_failover
  ]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-lc"]
    command = <<EOT
set -euo pipefail

NAME="${google_compute_instance.failover.name}"
PROJECT="${google_compute_instance.failover.project}"
ZONE="${google_compute_instance.failover.zone}"

for i in $(seq 1 60); do
  if gcloud compute ssh "$NAME" \
    --project "$PROJECT" \
    --zone "$ZONE" \
    --quiet \
    --command "systemctl is-active --quiet a10-failover.service"
  then
    echo "a10-failover.service is active"
    exit 0
  fi

  echo "Waiting for a10-failover.service to become active, attempt $i"
  sleep 5
done

echo "Timeout waiting for a10-failover.service"
exit 1
EOT
  }
}

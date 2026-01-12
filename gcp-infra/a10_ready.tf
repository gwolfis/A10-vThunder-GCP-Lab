resource "null_resource" "a10_ready" {
  for_each = local.adc_instances

  depends_on = [
    google_compute_instance.a10_vthunder
  ]

  triggers = {
    mgmt_ip = google_compute_address.a10_management_pip[each.key].address
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<-EOT
      set -e

      A10="${self.triggers.mgmt_ip}"
      USER="${var.a10_username}"
      PASS="${var.a10_password}"

      echo "Waiting for AXAPI on $${A10}"

      for i in $(seq 1 24); do
        RESP=$(curl -s -k -X POST "https://$${A10}/axapi/v3/auth" \
          -H "Content-Type: application/json" \
          -d "{\"credentials\":{\"username\":\"$${USER}\",\"password\":\"$${PASS}\"}}" || true)

        if echo "$RESP" | grep -q '"authresponse"'; then
          echo "AXAPI is up"
          exit 0
        fi

        echo "No valid AXAPI response yet, sleeping 10 seconds"
        sleep 10
      done

      echo "AXAPI not reachable after 24 attempts"
      exit 1
    EOT
  }
}

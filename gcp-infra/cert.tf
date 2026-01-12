# CERTS.terraform

# !!! The generated private key will be in Terrafrom state. 
# No problem for a lab, but not a security best practise in production!

########################################
# CERT GENERATION AND UPLOAD TO A10
########################################

locals {
  cert_dir      = "${path.module}/.generated"
  cert_name     = "a10demo"
  cert_path     = "${local.cert_dir}/${local.cert_name}.crt"
  key_path      = "${local.cert_dir}/${local.cert_name}.key"
  cert_subject  = "/C=NL/O=A10 Demo/CN=www.a10demo.com"
}

# Generate self-signed cert and key locally
resource "null_resource" "generate_a10demo_cert_key" {
  triggers = {
    cert_name    = local.cert_name
    cert_subject = local.cert_subject
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<-EOT
      set -euo pipefail

      mkdir -p "${local.cert_dir}"

      if [ ! -f "${local.cert_path}" ] || [ ! -f "${local.key_path}" ]; then
        echo "Generating self-signed cert and key in ${local.cert_dir}"
        openssl req -x509 -nodes -newkey rsa:2048 \
          -keyout "${local.key_path}" \
          -out "${local.cert_path}" \
          -days 365 \
          -subj "${local.cert_subject}"
      else
        echo "Cert and key already exist, skipping generation"
      fi
    EOT
  }
}

# Upload cert and key to every A10 instance via AXAPI
resource "null_resource" "upload_a10demo_cert_key" {
  for_each = local.adc_instances

  depends_on = [
    null_resource.a10_ready,
    null_resource.generate_a10demo_cert_key
  ]

  triggers = {
    mgmt_ip   = google_compute_address.a10_management_pip[each.key].address
    cert_name = local.cert_name
    cert_path = local.cert_path
    key_path  = local.key_path
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<-EOT
      set -euo pipefail

      A10="${self.triggers.mgmt_ip}"
      USER="${var.a10_username}"
      PASS="${var.a10_password}"
      CERT_PATH="${self.triggers.cert_path}"
      KEY_PATH="${self.triggers.key_path}"
      CERT_NAME="${self.triggers.cert_name}"

      echo "AXAPI login on $${A10}"
      RESP=$(curl -s -k -X POST "https://$${A10}/axapi/v3/auth" \
         -H "Content-Type: application/json" \
         -d "{\"credentials\":{\"username\":\"$${USER}\",\"password\":\"$${PASS}\"}}")

      TOKEN=$(echo "$${RESP}" | python3 -c 'import sys, json; print(json.load(sys.stdin)["authresponse"]["signature"])')

      echo "Upload SSL cert $${CERT_NAME} to $${A10}"
      curl -s -k -X POST "https://$${A10}/axapi/v3/file/ssl-cert" \
        -H "Authorization: A10 $${TOKEN}" \
        -F "json={\"ssl-cert\":{\"certificate-type\":\"pem\",\"file\":\"$${CERT_NAME}\",\"file-handle\":\"$${CERT_NAME}.crt\",\"action\":\"import\"}};type=application/json" \
        -F "file=@$${CERT_PATH};type=application/octet-stream" \
        >/dev/null

      echo "Upload SSL key $${CERT_NAME} to $${A10}"
      curl -s -k -X POST "https://$${A10}/axapi/v3/file/ssl-key" \
        -H "Authorization: A10 $${TOKEN}" \
        -F "json={\"ssl-key\":{\"file\":\"$${CERT_NAME}\",\"file-handle\":\"$${CERT_NAME}.key\",\"action\":\"import\"}};type=application/json" \
        -F "file=@$${KEY_PATH};type=application/octet-stream" \
        >/dev/null

      echo "Logoff $${A10}"
      curl -s -k -X POST "https://$${A10}/axapi/v3/logoff" \
        -H "Authorization: A10 $${TOKEN}" \
        -H "Content-Type: application/json" \
        -d '{}' \
        >/dev/null

      echo "Done uploading cert and key to $${A10}"
    EOT
  }
}

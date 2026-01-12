# GCP-INFRA - BACKEND.TF


locals {
  backend_ip = cidrhost(var.subnet_ip_internal, 20)
}

resource "google_compute_address" "a10_backend_pip" {
  name   = "a10-backend-pip"
  region = var.region
}

resource "google_compute_instance" "backend_web" {
  name                      = "a10-backend-1"
  machine_type              = var.backend_machine_type
  zone                      = var.zone
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/family/ubuntu-minimal-2404-lts-amd64"
      size  = 20
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet_ip_internal.self_link
    network_ip = local.backend_ip

    access_config {
      nat_ip = google_compute_address.a10_backend_pip.address
    }
  }

  tags = ["a10-backend", "http-backend"]

  metadata_startup_script = <<-EOT
    #!/bin/bash
    set -euxo pipefail

    echo "Startup script begin" | sudo tee /var/log/startup-script.log

    sudo apt-get update -y
    sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
    sudo apt-get install -y docker.io

    sudo systemctl enable docker
    sudo systemctl start docker

    # Oude container opruimen als hij bestaat
    if sudo docker ps -a --format '{{.Names}}' | grep -q '^a10-aadc-demo$'; then
      sudo docker rm -f a10-aadc-demo || true
    fi

    # Pull image from Docker hub
    sudo docker pull gwolfis/a10-aadc-demo:latest

    # Start container with ports 80, 443 and BG_COLOR
    sudo docker run -d \
      --restart unless-stopped \
      -p 80:80 \
      -p 443:443 \
      -e BG_COLOR="#004A9F" \
      --name a10-aadc-demo \
      gwolfis/a10-aadc-demo:latest

    echo "Startup script ready" | sudo tee -a /var/log/startup-script.log
  EOT
}
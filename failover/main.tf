terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.20.0"
    }
  }
}

data "terraform_remote_state" "infra" {
  backend = "local"

  config = {
    path = "${path.module}/../gcp-infra/terraform.tfstate"
  }
}

# data "terraform_remote_state" "infra" {
#   backend = "gcs"
#   config = {
#     bucket = var.state_bucket
#     prefix = var.infra_state_prefix
#   }
# }

data "terraform_remote_state" "edge" {
  backend = "local"

  config = {
    path = "${path.module}/../gcp-edge/terraform.tfstate"
  }
}

provider "google" {
  project     = data.terraform_remote_state.infra.outputs.project_id
  region      = data.terraform_remote_state.infra.outputs.region
  zone        = data.terraform_remote_state.infra.outputs.zone
  credentials = file(pathexpand("~/secrets/terraform-sa.json"))
}

resource "google_service_account" "failover" {
  account_id   = "a10-failover-sa"
  display_name = "A10 failover watcher"
}

resource "google_project_iam_member" "failover_lb_admin" {
  project = data.terraform_remote_state.infra.outputs.project_id
  role    = "roles/compute.loadBalancerAdmin"
  member  = "serviceAccount:${google_service_account.failover.email}"
}

resource "google_project_iam_member" "failover_viewer" {
  project = data.terraform_remote_state.infra.outputs.project_id
  role    = "roles/compute.viewer"
  member  = "serviceAccount:${google_service_account.failover.email}"
}

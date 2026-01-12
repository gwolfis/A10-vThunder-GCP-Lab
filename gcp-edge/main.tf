# GCP-EDGE - MAIN.TF

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
    thunder = {
      source  = "a10networks/thunder"
      version = "~> 1.4.2"
    }
  }

  backend "local" {}
}

data "terraform_remote_state" "infra" {
  backend = "local"

  config = {
    path = "${path.module}/../gcp-infra/terraform.tfstate"
  }
}

provider "google" {
  project     = data.terraform_remote_state.infra.outputs.project_id
  region      = data.terraform_remote_state.infra.outputs.region
  zone        = data.terraform_remote_state.infra.outputs.zone
  credentials = file(pathexpand("~/secrets/terraform-sa.json"))
}

locals {
  mgmt_ip_map = data.terraform_remote_state.infra.outputs.a10_mgmt_ip_map
}

provider "thunder" {
  alias    = "th1"
  address  = lookup(local.mgmt_ip_map, "vthunder-1", "127.0.0.1")
  username = var.a10_username
  password = var.a10_password
}

provider "thunder" {
  alias    = "th2"
  address  = lookup(local.mgmt_ip_map, "vthunder-2", "127.0.0.1")
  username = var.a10_username
  password = var.a10_password
}

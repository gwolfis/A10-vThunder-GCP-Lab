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

provider "thunder" {
  alias    = "th1"
  address  = local.adc1_mgmt_ip
  username = var.a10_username
  password = var.a10_password
}

provider "thunder" {
  alias    = "th2"
  address  = local.adc2_mgmt_ip
  username = var.a10_username
  password = var.a10_password
}
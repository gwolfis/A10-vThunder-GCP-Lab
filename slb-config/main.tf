# SLB-CONFIG - MAIN.TF

terraform {
  required_providers {
    thunder = {
      source  = "a10networks/thunder"
      version = "~> 1.4.2"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
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

provider "thunder" {
  address  = data.terraform_remote_state.infra.outputs.a10_mgmt_ip
  username = var.a10_username
  password = var.a10_password
}

# GCP-INFRA - MAIN.TF

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  backend "local" {}
}

provider "google" {
  project     = var.project_id
  region      = var.region
  zone        = var.zone
  credentials = file(pathexpand("~/secrets/terraform-sa.json"))
}

# Terraform deployer can use this runtime account
resource "google_service_account_iam_binding" "a10_runtime_user" {
  service_account_id = google_service_account.a10_runtime.name
  role               = "roles/iam.serviceAccountUser"

  members = [
    "serviceAccount:terraform-deployer@${var.project_id}.iam.gserviceaccount.com"
  ]
}

# Runtime serviceaccount A10 VM
resource "google_service_account" "a10_runtime" {
  account_id   = "a10-runtime"
  display_name = "A10 runtime service account"
}

# Terraform deployer can use this runtime account
resource "google_service_account_iam_binding" "backend_runtime_user" {
  service_account_id = google_service_account.backend_runtime.name
  role               = "roles/iam.serviceAccountUser"

  members = [
    "serviceAccount:terraform-deployer@${var.project_id}.iam.gserviceaccount.com"
  ]
}

# Runtime serviceaccount backend VM
resource "google_service_account" "backend_runtime" {
  account_id   = "backend-runtime"
  display_name = "Backend runtime service account"
}


# GCP-EDGE - SLB.TF

module "slb_th1" {
  source    = "./modules/a10-slb"
  providers = { thunder = thunder.th1 }

  enabled     = contains(var.configure_adcs, "vthunder-1")
  backend_ip  = data.terraform_remote_state.infra.outputs.backend_ip
  vip_ip      = google_compute_address.vip_web_ext.address
  cert_name   = var.a10_cert_name
  name_suffix = "-TH1"
}

module "slb_th2" {
  source    = "./modules/a10-slb"
  providers = { thunder = thunder.th2 }

  enabled     = contains(var.configure_adcs, "vthunder-2")
  backend_ip  = data.terraform_remote_state.infra.outputs.backend_ip
  vip_ip      = google_compute_address.vip_web_ext.address
  cert_name   = var.a10_cert_name
  name_suffix = "-TH2"
}

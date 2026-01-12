# GCP-EDGE MODULEDS A10-SLB VARIABLES.TF

variable "enabled" {
  type = bool
}

variable "backend_ip" {
  type = string
}

variable "vip_ip" {
  type = string
}

variable "cert_name" {
  type = string
}

variable "name_suffix" {
  type = string
}
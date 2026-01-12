# GCP-EDGE VARIABLES.TF

variable "a10_username" {}
variable "a10_password" {}

variable "configure_adcs" {
  description = "Which ADC keys to configure in this run"
  type        = set(string)
  default     = ["vthunder-1"]
}

variable "edge_active_adc_key" {
  description = "ADC key used by the forwarding rule target instance"
  type        = string
  default     = "vthunder-1"
}

variable "a10_cert_name" {
  description = "Certificate and key name on the A10"
  type        = string
  default     = "a10demo"
}
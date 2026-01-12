# GCP-INFRA - VARIABLES.TF

#GCP Credentials
variable "project_id" { default = "" }
variable "region" { default = "" }
variable "zone" { default = "" }

# Tags
variable "environment" {}
variable "deployment" {}
variable "owner" {}

# VPCs and Networks
variable "vpc_a10_management_name" {}
variable "vpc_a10_external_name" {}
variable "vpc_a10_internal_name" {}
variable "subnet_management_name" {}
variable "subnet_external_name" {}
variable "subnet_internal_name" {}

variable "subnet_ip_management" {  default = "10.0.10.0/24" }
variable "subnet_ip_external" {  default = "10.0.11.0/24" }
variable "subnet_ip_internal" {  default = "10.0.12.0/24" }

variable "source_ip_ranges" { default = ["0.0.0.0/0"]}

# Thunder Deployment
variable "adc_count" { default = 1 }
variable "adc_hostname_prefix" { default = "vthunder"}

variable "adc_mgmt_host_start" { default = 10 }
variable "adc_ext_host_start" { default = 10 }
variable "adc_int_host_start" { default = 10 }

variable "primary_adc_key" { default = "thunder-1"}

variable "a10_machine_type" {}
variable "a10_image" {}

#Thunder Runtime-init
variable "thunder_hostname" {}
variable "a10_username" {}
variable "a10_password" {}
variable "dns_primary" {}
variable "time_zone" {}
variable "ntp_server" {}

# Backend
variable "backend_machine_type" {}
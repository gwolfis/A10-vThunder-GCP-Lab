# FAILOVER - VARIABLES.TF

variable "edge_state_prefix" {
  type    = string
  default = ""
}

variable "name" {
  type    = string
  default = "a10-failover-vm"
}

variable "assign_public_ip" {
  type    = bool
  default = true
}

variable "network_tags" {
  type    = list(string)
  default = ["a10-failover"]
}

variable "health_policy" {
  type    = string
  default = "ANY"
}

variable "fw_filter" {
  type        = string
  description = "gcloud forwarding rules filter, bijvoorbeeld name=vip-web-fr of name~'^vip-.*-fr$'"
  default     = "name=vip-web-fr"
}

variable "max_attempts" {
  type    = number
  default = 3
}

variable "sleep_seconds" {
  type    = number
  default = 2
}

variable "loop_interval_seconds" {
  type    = number
  default = 30
}

variable "cooldown_after_failover_seconds" {
  type    = number
  default = 180
}

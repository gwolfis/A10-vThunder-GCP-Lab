# GCP-EDGE MODULEDS A10-SLB SLB.TF

resource "thunder_slb_server" "backend_edge_1" {
  count = var.enabled ? 1 : 0

  name = "backend-edge-1${var.name_suffix}"
  host = var.backend_ip

  port_list {
    port_number = 80
    protocol    = "tcp"
  }

  port_list {
    port_number = 443
    protocol    = "tcp"
  }
}

resource "thunder_slb_service_group" "sg_http_edge" {
  count = var.enabled ? 1 : 0

  name     = "SG-HTTP-EDGE${var.name_suffix}"
  protocol = "tcp"

  member_list {
    name = thunder_slb_server.backend_edge_1[0].name
    port = 80
  }
}

resource "thunder_slb_service_group" "sg_https_edge" {
  count = var.enabled ? 1 : 0

  name     = "SG-HTTPS-EDGE${var.name_suffix}"
  protocol = "tcp"

  member_list {
    name = thunder_slb_server.backend_edge_1[0].name
    port = 443
  }
}

resource "thunder_slb_template_client_ssl" "tp_cssl" {
  count = var.enabled ? 1 : 0

  name = "TP-CSSL-A10DEMO-EDGE${var.name_suffix}"

  certificate_list {
    cert = var.cert_name
    key  = var.cert_name
  }
}

resource "thunder_slb_template_server_ssl" "tp_sssl" {
  count = var.enabled ? 1 : 0

  name = "TP-SSSL-A10DEMO-EDGE${var.name_suffix}"

  certificate {
    cert = var.cert_name
    key  = var.cert_name
  }
}

resource "thunder_slb_virtual_server" "vip_web_edge" {
  count = var.enabled ? 1 : 0

  name       = "VIP-WEB-EDGE${var.name_suffix}"
  ip_address = var.vip_ip

  port_list {
    port_number   = 80
    protocol      = "http"
    service_group = thunder_slb_service_group.sg_http_edge[0].name
    auto          = 1
  }

  port_list {
    port_number         = 443
    protocol            = "https"
    service_group       = thunder_slb_service_group.sg_https_edge[0].name
    template_client_ssl = thunder_slb_template_client_ssl.tp_cssl[0].name
    template_server_ssl = thunder_slb_template_server_ssl.tp_sssl[0].name
    auto                = 1
  }
}

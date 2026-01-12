# SLB-CONFIG - SLB.TF


resource "thunder_slb_server" "backend_1" {
  name = "backend-1"
  host = data.terraform_remote_state.infra.outputs.backend_ip

  port_list {
      port_number = 80
      protocol    = "tcp"
    }

  port_list {
      port_number = 443
      protocol    = "tcp"
    }
}

resource "thunder_slb_service_group" "sg_http" {
  name     = "SG-HTTP"
  protocol = "tcp"

  member_list {
    name = thunder_slb_server.backend_1.name
    port = 80
  }
}

resource "thunder_slb_service_group" "sg_https" {
  name     = "SG-HTTPS"
  protocol = "tcp"

  member_list {
    name = thunder_slb_server.backend_1.name
    port = 443
  }
}

resource "thunder_slb_template_client_ssl" "tp_cssl_a10demo" {
  name = "TP-CSSL-A10DEMO"

  certificate_list {
    cert = "a10demo"
    key  = "a10demo"
  }
}

resource "thunder_slb_template_server_ssl" "tp_sssl_a10demo" {
  name = "TP-SSSL-A10DEMO"

  certificate {
    cert = "a10demo"
    key  = "a10demo"
  }
}


resource "thunder_slb_virtual_server" "vip-web" {
  name       = "VIP-WEB"
  ip_address = data.terraform_remote_state.infra.outputs.a10_external_ip

  port_list {
    port_number    = 80
    protocol       = "http"
    service_group  = thunder_slb_service_group.sg_http.name
    auto           = 1
  }

  port_list {
    port_number          = 443
    protocol             = "https"
    service_group        = thunder_slb_service_group.sg_https.name
    template_client_ssl  = thunder_slb_template_client_ssl.tp_cssl_a10demo.name
    template_server_ssl  = thunder_slb_template_server_ssl.tp_sssl_a10demo.name
    auto                 = 1
  }
}
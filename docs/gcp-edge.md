# 5. gcp-edge: GCP forwarding rules

This module is intended for:

* Creating GCP forwarding rules that point directly to the A10 external IP / VIP
* Demonstrating how the A10 can act as an “edge” ADC for GCP load balancing scenarios

It also uses `terraform_remote_state` to consume outputs from `gcp-infra`.

> **Note:** By default, deploying gcp-edge will only configure GCP forwarding rules to one ADC. When you use two ADCs make sure to adjust terraform.tfvars accordingly.

1. Copy the example variables file `terraform.tfvars.example`.

```bash
cd gcp-edge or cd ../gcp-edge
cp terraform.tfvars.example terraform.tfvars
```

In `terraform.tfvars` adjust the following:

```
# GCP-EDGE - TERRAFROM.TFVARS

a10_username = "admin"
a10_password = "<set-vthunder-strong-password>"

# configure_adcs      = ["vthunder-1"]                  # Default setting when deploying 1 ADC.
configure_adcs      = ["vthunder-1", "vthunder-2"]      # Use this setting when deploying 2 ADCs. un-# this one and # the 1 ADC "configure_adcs = ["vthunder-1"]" setting
edge_active_adc_key = "vthunder-1"
a10_cert_name        = "a10demo"
```

To deploy `gcp-edge`:

```bash
cd gcp-edge or cd ../gcp-edge

terraform init
terraform plan
terraform apply
```

The following output will assist you in testing the deployment:

```
GCP Edge Forwarding
-------------------
Configured ADC keys : vthunder-1, vthunder-2
ADC2 configured     : true

Active ADC key      : vthunder-1
Forwarding rule     : vip-web-fr
Target instance     : {"vthunder-1":"a10-ti-vthunder-1","vthunder-2":"a10-ti-vthunder-2"}
VIP (TCP/443)       : 34.xx.xx.xx
HTTPS shortcut      : https://34.xx.xx.xx

ADC Management access
  vthunder-1
    mgmt public  : 34.xx.xx.xx
    ssh shortcut : ssh admin@34.xx.xx.xx
    https gui    : https://34.xx.xx.xx

  vthunder-2
    mgmt public  : 35.xx.xx.xx
    ssh shortcut : ssh admin@35.xx.xx.xx
    https gui    : https://35.xx.xx.xx
```

### Test

After apply, Terraform prints:

the forwarding rule public IP and an https shortcut

Open the https shortcut. You should see the demo web page.

If you do not see the page:

confirm gcp-infra and slb-config are deployed

---

---
**Next:** [failover](failover.md)
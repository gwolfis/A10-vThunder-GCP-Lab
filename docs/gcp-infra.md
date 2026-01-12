# 3. gcp-infra: Infrastructure deployment

This module:

* Configures three VPC networks with their own subnets (management, external and internal).
* Deploys one or two (based upon selection) A10 vThunder instance with three NICs.
* Deploys a backend Ubuntu VM running a Docker based A10 demo web app.
* Generates a self signed key and certificate with the `tls` provider.
* Uploads key and certificate to the A10 via AXAPI.
* Outputs all relevant IP addresses and handy shortcuts.

### 3.1 Configuration

This module lets you choose whether to deploy 1 or 2 vThunder ADCs, depending on what you want to test and learn. This is controlled with `adc_count`.

1. Copy the example variables file `terraform.tfvars.example`.

```bash
cd gcp-infra
cp terraform.tfvars.example terraform.tfvars
```

2. Inside `gcp-infra/terraform.tfvars` set at least:
```hcl
project_id   = "a10demo"               # your GCP project ID
region       = "europe-west4"
zone         = "europe-west4-a"

a10_username = "admin"
a10_password = "Thunder2025!"
```

You can adjust CIDRs machine types and other variables as needed: check `variables.tf` in `gcp-infra` for the full list.

### 3.2 Initialize and apply

From the `gcp-infra` folder:

```bash
cd gcp-infra

terraform init
terraform plan
terraform apply
```

After a successful apply you will see a human readable output like:

```text
Thunder ADC Lab Info
--------------------

Thunder ADC IPs
  mgmt     (priv) : 10.10.10.10
  mgmt     (pub)  : 34.xx.xx.xx
  external (priv) : 10.10.11.10
  external (pub)  : 35.xx.xx.xx
  internal (priv) : 10.10.12.10

Backend
  backend-1 (priv): 10.10.12.20
  backend-1 (pub) : n/a

Shortcuts
  ssh thunder1-mgmt : ssh admin@34.xx.xx.xx
  https mgmt gui    : https://34.xx.xx.xx
  https vip         : https://35.xx.xx.xx
```

You should now be able to:

* SSH to the A10 management IP
* Open the A10 Web GUI over HTTPS on the management IP
* SSH to the backend VM (if a public IP is configured or from a jump host)

The A10 already has a self signed certificate and key (`a10demo`) uploaded by Terraform.

---

---
**Next:** [slb-config](slb-config.md) => for a simple L4-L7 SLB configuration.
**Next:** [cgp-edge](gcp-edge.md)     => Deploying GCP forwarding rules.
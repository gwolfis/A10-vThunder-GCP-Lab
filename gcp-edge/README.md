# gcp-edge

This module is part of the **A10 vThunder GCP Lab** and focuses on deploying GCP forwarding rules.

It deploys:

* GCP forwarding rules that point to the A10 VIP on the external interface.
* An edge style setup to demonstrate how A10 can be used as an ADC at the GCP edge.

This module consumes outputs from `gcp-infra` via `terraform_remote_state`.

## Usage

1. Copy the example variables file and adjust it to your lab setup.

```bash
cd gcp-edge
cp terraform.tfvars.example terraform.tfvars
```

Deploy.

terraform init
terraform plan
terraform apply

## Test

After apply, Terraform prints the forwarding rule public IP and an HTTPS shortcut. Open the HTTPS shortcut and you should see the demo web page.
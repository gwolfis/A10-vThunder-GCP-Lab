# 4. slb-config: A10 SLB and SSL configuration

This module uses the **A10 Thunder Terraform provider** to configure:

* SLB server for the backend
* Service groups (HTTP/HTTPS)
* Client SSL template using the `a10demo` certificate
* Server SSL template (for end to end TLS)
* Virtual server (VIP) on the external interface/IP

### 4.1 Remote state input

`slb-config` reads the outputs of `gcp-infra` via `terraform_remote_state` to get:

* A10 management IP (for the Thunder provider)
* A10 external IP / interface
* Backend private IP

Make sure the backend for `terraform_remote_state` in `slb-config/main.tf` matches how you store state for `gcp-infra` (local or GCS).

Example (local backend):

```hcl
data "terraform_remote_state" "infra" {
  backend = "local"

  config = {
    path = "../gcp-infra/terraform.tfstate"
  }
}
```

### 4.2 Provider credentials

1. Copy the example variables file `terraform.tfvars.example`.

```bash
cd slb-config
cp terraform.tfvars.example terraform.tfvars
```

`slb-config` connects directly to the A10 management IP using the same username and password:

```hcl
provider "thunder" {
  address  = data.terraform_remote_state.infra.outputs.a10_mgmt_ip
  username = var.a10_username
  password = var.a10_password
}
```

Set these in `slb-config/terraform.tfvars`:

```hcl
a10_username = "admin"
a10_password = "<set-vthunder-strong-password>"
```

### 4.3 Apply SLB configuration

From the `slb-config` folder:

```bash
cd slb-config

terraform init
terraform plan
terraform apply
```

After this:

* The vThunder has SLB objects (server service-groups virtual server)
* The HTTPS VIP uses the self signed cert `a10demo` via a client SSL template
* Optionally the backend uses HTTPS with a server SSL template bound to the same cert

You can verify on the A10:

```text
show slb server
show slb service-group
show slb virtual-server
show slb template client-ssl
show slb template server-ssl
show pki cert
show pki key
```

---

# slb-config

This module is part of the **A10 vThunder GCP Lab**.

It uses the A10 Thunder Terraform provider to configure:
- SLB server for the backend.
- Service groups.
- SSL templates.
- Virtual server (VIP).

Make sure `gcp-infra` has been applied first so the vThunder is up and has the `a10demo` certificate.

```bash
terraform init
terraform apply
```
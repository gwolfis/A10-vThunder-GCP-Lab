# failover

This module is part of the **A10 vThunder GCP Lab** and it provides simple high availability for the VIP by switching GCP forwarding rules between two vThunder target instances. :contentReference[oaicite:0]{index=0}

## What it deploys

It deploys a small Ubuntu VM in GCP plus a firewall rule for SSH and a service account with IAM permissions to read and update forwarding rules. :contentReference[oaicite:1]{index=1}

On the VM it installs a systemd service and a script that performs VIP health checks and runs `gcloud compute forwarding-rules set-target` when failover is needed. :contentReference[oaicite:2]{index=2}

## When to use it

Use this module only when you deploy **two** ADCs. With one ADC there is no secondary target and failover is not applicable. :contentReference[oaicite:3]{index=3}

## Usage

```bash
cd failover
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

## Test

SSH to the failover VM and watch the service logs

sudo systemctl status a10-failover.service
sudo journalctl -u a10-failover.service -f


Trigger a failure on the active ADC, for example disable the VIP or reboot the ADC, then confirm the forwarding rule target switches to the other target instance.
# 6. Failover: ADC high availability

## Failover VM

This repository includes an optional failover component that deploys a small Linux VM in GCP which continuously monitors one or more VIPs and automatically switches GCP forwarding rules between two A10 vThunder ADC target instances.

This module is only relevant if you deploy **two** ADCs. If you deploy a single ADC, skip this module because there is no secondary target to fail over to.

## What gets deployed

The failover module deploys the following resources in GCP.

### Compute instance

A single Ubuntu VM named `failover-vm` with:

* Machine type `e2-micro`
* Ubuntu Minimal `ubuntu-minimal-2404-lts-amd64`
* Two NICs  
  * NIC 1 in the management subnet with a public IP, used for SSH access and for downloading packages during bootstrap  
  * NIC 2 in the external subnet, used to reach the public VIPs from inside the VPC

### Firewall rule

An ingress firewall rule that allows SSH (TCP 22) to the VM by using the VM network tag `a10-failover-ssh`.

### Service account and IAM bindings

A dedicated service account `a10-failover-sa` is created for the VM, and it is granted permissions needed to read forwarding rule state and update forwarding rule targets.

## Why this VM exists

GCP forwarding rules do not provide native “health based failover” between two target instances for this lab design. The purpose of the failover VM is therefore:

* Validate that the VIP(s) are reachable by performing a lightweight health check
* Detect when the currently active ADC side is not healthy anymore
* Switch one or more forwarding rules to the other A10 target instance by running `gcloud compute forwarding-rules set-target`

This is intentionally simple and transparent so you can learn how failover can be implemented with plain GCP primitives and automation.

## What gets installed on the VM

During first boot the VM runs a startup script that installs and configures everything needed for the watcher.

### Packages

The startup script installs these packages:

* `ca-certificates`
* `curl`
* `gnupg`
* `openssl`
* `coreutils`

It also installs the Google Cloud CLI (`google-cloud-cli`) if it is not present.

### Configuration file

The module creates a configuration file at:

* `/etc/a10-failover/env`

This file is used as an `EnvironmentFile` for the systemd service. It includes values such as:

* `REGION`
* `PRIMARY_TI` and `PRIMARY_ZONE`
* `SECONDARY_TI` and `SECONDARY_ZONE`
* `FW_FILTER` (forwarding rule filter)
* `VIPS_TO_CHECK` (optional explicit VIP list)
* `HEALTH_POLICY` (for example `ANY`)
* `HEALTHCHECK_TOOL` (`OPENSSL` or `TCP`)
* `OPENSSL_TIMEOUT_SECONDS`

### Failover script

The module writes the failover watcher script to:

* `/usr/local/bin/a10-failover.sh`

How it works at a high level:

* It reads `/etc/a10-failover/env` if available and exports the variables for the script runtime:contentReference[oaicite:0]{index=0}
* It discovers VIP IP addresses from forwarding rules if `VIPS_TO_CHECK` is not set:contentReference[oaicite:1]{index=1}
* It performs health checks using either:
  * OpenSSL TLS 1.2 handshake, default
  * A plain TCP connect to port 443
* When health checks fail according to the selected policy it switches forwarding rules to the other target instance using `gcloud compute forwarding-rules set-target`:contentReference[oaicite:2]{index=2}

The watcher runs in an infinite loop and logs each cycle and each action to the system journal:contentReference[oaicite:3]{index=3}.

### systemd service

The module installs a systemd unit at:

* `/etc/systemd/system/a10-failover.service`

This service:

* Loads `/etc/a10-failover/env`
* Starts `/usr/local/bin/a10-failover.sh`
* Restarts automatically on failure
* Logs to `journalctl` under the identifier `a10-failover`

The startup script enables and starts the service immediately.

## How to test failover

The most reliable way to test is to confirm the current forwarding rule targets, force the active ADC side to become unreachable, then watch the forwarding rule targets change.

### 1. Confirm the service is running

SSH to the failover VM and run:

```bash
sudo systemctl status a10-failover.service
sudo journalctl -u a10-failover.service -f
```
You should see periodic log lines like “Healthcheck cycle” and either “no failover” or a message that a failover is needed.

2. Inspect current forwarding rule targets and watch them switch when failing over.

From your workstation:

```
while true; do
  date
  gcloud compute forwarding-rules list \
    --regions=europe-west4 \
    --format="table(name,IPAddress,target)"
  sleep 1
done
```

Take note of which target instance is currently referenced in the target column.

1. Trigger a failure

Pick one of these options:
- Disable either the external or internal interface of the active ADC.
- Disable the VIP on the active ADC.
- Reboot the active ADC.


2. Watch the forwarding rules switch

Keep the failover VM logs open:

sudo journalctl -u a10-failover.service -f


You should see logs indicating the watcher detected failures and is switching forwarding rules to the other target instance, followed by “Failover done”.

The target field should now reference the other target instance.

## Notes and tuning

* Forwarding rule selection is controlled by FW_FILTER. If no rules match the filter the script will log that there is nothing to do and it will exit that cycle cleanly.

* VIP selection can be explicit via VIPS_TO_CHECK or automatic discovery via the forwarding rules that match FW_FILTER a10-failover

* Health check behaviour is controlled by HEALTH_POLICY (ANY or ALL) and HEALTHCHECK_TOOL (OPENSSL or TCP)

---
**Next:** [cleanup](cleanup.md)

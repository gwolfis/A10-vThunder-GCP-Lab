
## docs/troubleshooting.md

```markdown
# Troubleshooting

## I cannot reach the A10 management UI

1. confirm your current public IP is included in source_ip_ranges  
2. confirm the management public IP is correct  
3. confirm you use https not http  

## The demo page does not show on the A10 VIP

1. verify slb-config has been applied successfully  
2. verify the backend container is running on the backend VM  
3. verify you are testing https  

## The demo page does not show via gcp-edge

1. verify the A10 VIP works directly first  
2. verify gcp-edge apply completed successfully  
3. verify your source_ip_ranges allow your public IP

## 8. Troubleshooting

A few common issues:

* **`storage.NewClient() failed: could not find default credentials`**
  → Check that `credentials = file("~/secrets/terraform-sa.json")` points to a valid JSON key and that the path exists.

* **`Permission denied` / `iam.serviceAccounts.create` / `storage.buckets.create`**
  → The Terraform deployment service account is missing the required IAM roles, see section 1.2.

* **A10 AXAPI auth errors during TLS upload**
  → Verify you can log in to the A10 GUI using the same `a10_username` and `a10_password` used in `terraform.tfvars`.
  → Check network/firewall rules so your local machine can reach the management IP.

* **Backend returns HTTP 400 “You’re speaking plain HTTP to an SSL-enabled server port”**
  → This usually means the A10 is sending HTTP to backend port 443.
  Make sure your service-group member ports and SSL templates (client vs server side) match the intended topology (offload vs end-to-end TLS).

---

Enjoy the lab and feel free to adapt it for your own A10 + GCP scenarios.

````

Als je wilt kan ik in een volgende stap nog een korte “Quick start” sectie toevoegen met letterlijk de command sequence:

```bash
cd gcp-infra && terraform apply
cd slb-config && terraform apply
cd gcp-edge && terraform apply
```


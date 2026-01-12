# 7. Cleanup

To remove all resources:

1. In subfolder `failover` (if used):

   ```bash
   terraform destroy
   ```

2. In `gcp-edge` (if used):

   ```bash
   terraform destroy
   ```

3. In `slb-config` (if used):

   ```bash
   terraform destroy
   ```

4. In `gcp-infra`:

   ```bash
   terraform destroy
   ```

Note: destroying `gcp-infra` first will break the remote state dependency for the other modules. Objects in GCP might remain in your project and will cost.

---

---
**Next:** [troubleshooting](troubleshooting.md)

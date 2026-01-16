# 7. Cleanup

This section provides guidance in removing all the deployed resources via Terraform. Please remind that one deployment builds on top of the other and this means that you want ot remove in the reversed order to ensure removal of all the deployed attributes.

To remove all resources:

1. In subfolder `failover` (if used):

   ```
   terraform destroy
   ```

2. In `gcp-edge` (if used):

   ```
   terraform destroy
   ```

3. In `slb-config` (if used):

   ```
   terraform destroy
   ```

4. In `gcp-infra`:

   ```
   terraform destroy
   ```

Note: destroying `gcp-infra` first will break the remote state dependency for the other modules. Objects in GCP might remain in your project and will cost.

---


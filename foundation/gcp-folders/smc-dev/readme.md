# gcp-folders/smc-dev

Terraform for the **`smc-dev`** folder (`922883963214`): the folder itself.

| | |
| --- | --- |
| GCP node | the **`smc-dev`** folder (`922883963214`) |
| Terraform state | `gs://smc-ops-tf-state/terraform/state/foundation/gcp-folders/smc-dev/default.tfstate` |
| Imported | 2026-11-01/02 from the live Org, 1 resources, zero-diff plan |

## Resources

| Terraform type | Count |
| --- | --- |
| `google_folder` | 1 |

## Files

| File | What it holds |
| --- | --- |
| `gcp_folders_smc_dev.tf` | smc-dev (922883963214) |
| `gcp_folders_smc_dev_gcs_backend.tf` | this directory's state location (hardcoded) |
| `gcp_provider.tf` | symlink to the repo-root `gcp_provider.tf` (Terraform + provider versions) |

Each resource's `import {}` block sits right under it. After the first apply they are no-ops, kept as a record of where each resource came from.

## Run it

```bash
cd foundation/gcp-folders/smc-dev
export GOOGLE_IMPERSONATE_SERVICE_ACCOUNT=smc-tf-foundation-sa@smc-ops.iam.gserviceaccount.com
export GOOGLE_BACKEND_IMPERSONATE_SERVICE_ACCOUNT=$GOOGLE_IMPERSONATE_SERVICE_ACCOUNT
terraform init && terraform plan   # expected: No changes
```

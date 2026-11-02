# iam/smc-prod

Terraform for the **`smc-prod`** folder (`386439801809`): IAM: service accounts and IAM bindings.

| | |
| --- | --- |
| GCP node | the **`smc-prod`** folder (`386439801809`) |
| Terraform state | `gs://smc-ops-tf-state/terraform/state/foundation/iam/smc-prod/default.tfstate` |
| Imported | 2026-11-01/02 from the live Org, 2 resources, zero-diff plan |

## Resources

| Terraform type | Count |
| --- | --- |
| `google_folder_iam_member` | 2 |

## Files

| File | What it holds |
| --- | --- |
| `gcp_provider.tf` | symlink to the repo-root `gcp_provider.tf` (Terraform + provider versions) |
| `iam_smc_prod_folder.tf` | folder IAM bindings |
| `iam_smc_prod_gcs_backend.tf` | this directory's state location (hardcoded) |

Each resource's `import {}` block sits right under it. After the first apply they are no-ops, kept as a record of where each resource came from.

## Run it

```bash
cd foundation/iam/smc-prod
export GOOGLE_IMPERSONATE_SERVICE_ACCOUNT=smc-tf-foundation-sa@smc-ops.iam.gserviceaccount.com
export GOOGLE_BACKEND_IMPERSONATE_SERVICE_ACCOUNT=$GOOGLE_IMPERSONATE_SERVICE_ACCOUNT
terraform init && terraform plan   # expected: No changes
```

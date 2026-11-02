# logging/smc-ops

Terraform for the **`smc-ops`** folder (`714502724732`): log sinks and log buckets.

| | |
| --- | --- |
| GCP node | the **`smc-ops`** folder (`714502724732`) |
| Terraform state | `gs://smc-ops-tf-state/terraform/state/foundation/logging/smc-ops/default.tfstate` |
| Imported | 2026-11-01/02 from the live Org, 2 resources, zero-diff plan |

## Resources

| Terraform type | Count |
| --- | --- |
| `google_logging_folder_sink` | 2 |

## Files

| File | What it holds |
| --- | --- |
| `gcp_provider.tf` | symlink to the repo-root `gcp_provider.tf` (Terraform + provider versions) |
| `logging_smc_ops_gcs_backend.tf` | this directory's state location (hardcoded) |
| `logging_smc_ops_sinks.tf` | log sinks on smc-ops folder (714502724732) |

Each resource's `import {}` block sits right under it. After the first apply they are no-ops, kept as a record of where each resource came from.

## Run it

```bash
cd foundation/logging/smc-ops
export GOOGLE_IMPERSONATE_SERVICE_ACCOUNT=smc-tf-foundation-sa@smc-ops.iam.gserviceaccount.com
export GOOGLE_BACKEND_IMPERSONATE_SERVICE_ACCOUNT=$GOOGLE_IMPERSONATE_SERVICE_ACCOUNT
terraform init && terraform plan   # expected: No changes
```

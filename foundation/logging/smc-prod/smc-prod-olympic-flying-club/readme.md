# logging/smc-prod/smc-prod-olympic-flying-club

Terraform for project **`smc-prod-olympic-flying-club`** in folder `smc-prod` (`386439801809`): log sinks and log buckets.

| | |
| --- | --- |
| GCP node | project **`smc-prod-olympic-flying-club`** in folder `smc-prod` (`386439801809`) |
| Terraform state | `gs://smc-ops-tf-state/terraform/state/foundation/logging/smc-prod/smc-prod-olympic-flying-club/default.tfstate` |
| Imported | 2026-11-01/02 from the live Org, 3 resources, zero-diff plan |

## Resources

| Terraform type | Count |
| --- | --- |
| `google_logging_project_bucket_config` | 1 |
| `google_logging_project_sink` | 2 |

## Files

| File | What it holds |
| --- | --- |
| `gcp_provider.tf` | symlink to the repo-root `gcp_provider.tf` (Terraform + provider versions) |
| `logging_smc_prod_olympic_flying_club_gcs_backend.tf` | this directory's state location (hardcoded) |
| `logging_smc_prod_olympic_flying_club_log_buckets.tf` | log buckets |
| `logging_smc_prod_olympic_flying_club_log_sinks.tf` | log sinks |

Each resource's `import {}` block sits right under it. After the first apply they are no-ops, kept as a record of where each resource came from.

## Run it

```bash
cd foundation/logging/smc-prod/smc-prod-olympic-flying-club
export GOOGLE_IMPERSONATE_SERVICE_ACCOUNT=smc-tf-foundation-sa@smc-ops.iam.gserviceaccount.com
export GOOGLE_BACKEND_IMPERSONATE_SERVICE_ACCOUNT=$GOOGLE_IMPERSONATE_SERVICE_ACCOUNT
terraform init && terraform plan   # expected: No changes
```

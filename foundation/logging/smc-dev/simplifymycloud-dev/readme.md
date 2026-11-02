# logging/smc-dev/simplifymycloud-dev

Terraform for project **`simplifymycloud-dev`** in folder `smc-dev` (`922883963214`): log sinks and log buckets.

| | |
| --- | --- |
| GCP node | project **`simplifymycloud-dev`** in folder `smc-dev` (`922883963214`) |
| Terraform state | `gs://smc-ops-tf-state/terraform/state/foundation/logging/smc-dev/simplifymycloud-dev/default.tfstate` |
| Imported | 2026-11-01/02 from the live Org, 6 resources, zero-diff plan |

## Resources

| Terraform type | Count |
| --- | --- |
| `google_logging_metric` | 3 |
| `google_logging_project_bucket_config` | 1 |
| `google_logging_project_sink` | 2 |

## Files

| File | What it holds |
| --- | --- |
| `gcp_provider.tf` | symlink to the repo-root `gcp_provider.tf` (Terraform + provider versions) |
| `logging_simplifymycloud_dev_gcs_backend.tf` | this directory's state location (hardcoded) |
| `logging_simplifymycloud_dev_log_buckets.tf` | log buckets |
| `logging_simplifymycloud_dev_log_sinks.tf` | log sinks |
| `logging_simplifymycloud_dev_monitoring.tf` | monitoring: dashboards, alerts, channels, log metrics |

Each resource's `import {}` block sits right under it. After the first apply they are no-ops, kept as a record of where each resource came from.

## Run it

```bash
cd foundation/logging/smc-dev/simplifymycloud-dev
export GOOGLE_IMPERSONATE_SERVICE_ACCOUNT=smc-tf-foundation-sa@smc-ops.iam.gserviceaccount.com
export GOOGLE_BACKEND_IMPERSONATE_SERVICE_ACCOUNT=$GOOGLE_IMPERSONATE_SERVICE_ACCOUNT
terraform init && terraform plan   # expected: No changes
```

# logging/gcp-org

Terraform for the **simplifymy.cloud Org** (`933250405420`): log sinks and log buckets.

| | |
| --- | --- |
| GCP node | the **simplifymy.cloud Org** (`933250405420`) |
| Terraform state | `gs://smc-ops-tf-state/terraform/state/foundation/logging/gcp-org/default.tfstate` |
| Imported | 2026-11-01/02 from the live Org, 3 resources, zero-diff plan |

## Resources

| Terraform type | Count |
| --- | --- |
| `google_logging_organization_sink` | 3 |

## Files

| File | What it holds |
| --- | --- |
| `gcp_provider.tf` | symlink to the repo-root `gcp_provider.tf` (Terraform + provider versions) |
| `logging_gcp_org_archive_sink.tf` | org-wide cold archive sink |
| `logging_gcp_org_gcs_backend.tf` | this directory's state location (hardcoded) |
| `logging_gcp_org_sinks.tf` | log sinks on the Org (933250405420) |

Each resource's `import {}` block sits right under it. After the first apply they are no-ops, kept as a record of where each resource came from.

## Run it

```bash
cd foundation/logging/gcp-org
export GOOGLE_IMPERSONATE_SERVICE_ACCOUNT=smc-tf-foundation-sa@smc-ops.iam.gserviceaccount.com
export GOOGLE_BACKEND_IMPERSONATE_SERVICE_ACCOUNT=$GOOGLE_IMPERSONATE_SERVICE_ACCOUNT
terraform init && terraform plan   # expected: No changes
```

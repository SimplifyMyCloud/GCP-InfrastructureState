# gcp-org

Terraform for the **simplifymy.cloud Org** (`933250405420`): organization policies.

| | |
| --- | --- |
| GCP node | the **simplifymy.cloud Org** (`933250405420`) |
| Terraform state | `gs://smc-ops-tf-state/terraform/state/foundation/gcp-org/default.tfstate` |
| Imported | 2026-11-01/02 from the live Org, 5 resources, zero-diff plan |

## Resources

| Terraform type | Count |
| --- | --- |
| `google_org_policy_policy` | 5 |

## Files

| File | What it holds |
| --- | --- |
| `gcp_org_gcs_backend.tf` | this directory's state location (hardcoded) |
| `gcp_org_policies.tf` | organization policies (simplifymy.cloud, 933250405420) |
| `gcp_provider.tf` | symlink to the repo-root `gcp_provider.tf` (Terraform + provider versions) |

Each resource's `import {}` block sits right under it. After the first apply they are no-ops, kept as a record of where each resource came from.

## Run it

```bash
cd foundation/gcp-org
export GOOGLE_IMPERSONATE_SERVICE_ACCOUNT=smc-tf-foundation-sa@smc-ops.iam.gserviceaccount.com
export GOOGLE_BACKEND_IMPERSONATE_SERVICE_ACCOUNT=$GOOGLE_IMPERSONATE_SERVICE_ACCOUNT
terraform init && terraform plan   # expected: No changes
```

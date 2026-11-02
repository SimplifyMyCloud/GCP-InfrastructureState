# iam/smc-prod/smc-prod-bbmrc

Terraform for project **`smc-prod-bbmrc`** in folder `smc-prod` (`386439801809`): IAM: service accounts and IAM bindings.

| | |
| --- | --- |
| GCP node | project **`smc-prod-bbmrc`** in folder `smc-prod` (`386439801809`) |
| Terraform state | `gs://smc-ops-tf-state/terraform/state/foundation/iam/smc-prod/smc-prod-bbmrc/default.tfstate` |
| Imported | 2026-11-01/02 from the live Org, 2 resources, zero-diff plan |

## Resources

| Terraform type | Count |
| --- | --- |
| `google_project_iam_member` | 2 |

## Files

| File | What it holds |
| --- | --- |
| `gcp_provider.tf` | symlink to the repo-root `gcp_provider.tf` (Terraform + provider versions) |
| `iam_smc_prod_bbmrc_gcs_backend.tf` | this directory's state location (hardcoded) |
| `iam_smc_prod_bbmrc_project.tf` | project IAM bindings |

Each resource's `import {}` block sits right under it. After the first apply they are no-ops, kept as a record of where each resource came from.

## Run it

```bash
cd foundation/iam/smc-prod/smc-prod-bbmrc
export GOOGLE_IMPERSONATE_SERVICE_ACCOUNT=smc-tf-foundation-sa@smc-ops.iam.gserviceaccount.com
export GOOGLE_BACKEND_IMPERSONATE_SERVICE_ACCOUNT=$GOOGLE_IMPERSONATE_SERVICE_ACCOUNT
terraform init && terraform plan   # expected: No changes
```

## Findings (imported as-is, fix in a later PR)

- `user:chris@simplifymy.cloud` holds basic role `roles/owner` on this project

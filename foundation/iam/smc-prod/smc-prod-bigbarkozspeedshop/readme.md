# iam/smc-prod/smc-prod-bigbarkozspeedshop

Terraform for project **`smc-prod-bigbarkozspeedshop`** in folder `smc-prod` (`386439801809`): IAM: service accounts and IAM bindings.

| | |
| --- | --- |
| GCP node | project **`smc-prod-bigbarkozspeedshop`** in folder `smc-prod` (`386439801809`) |
| Terraform state | `gs://smc-ops-tf-state/terraform/state/foundation/iam/smc-prod/smc-prod-bigbarkozspeedshop/default.tfstate` |
| Imported | 2026-11-01/02 from the live Org, 19 resources, zero-diff plan |

## Resources

| Terraform type | Count |
| --- | --- |
| `google_project_iam_member` | 18 |
| `google_service_account` | 1 |

## Files

| File | What it holds |
| --- | --- |
| `gcp_provider.tf` | symlink to the repo-root `gcp_provider.tf` (Terraform + provider versions) |
| `iam_smc_prod_bigbarkozspeedshop_gcs_backend.tf` | this directory's state location (hardcoded) |
| `iam_smc_prod_bigbarkozspeedshop_project.tf` | project IAM bindings |
| `iam_smc_prod_bigbarkozspeedshop_service_accounts.tf` | service accounts |

Each resource's `import {}` block sits right under it. After the first apply they are no-ops, kept as a record of where each resource came from.

## Run it

```bash
cd foundation/iam/smc-prod/smc-prod-bigbarkozspeedshop
export GOOGLE_IMPERSONATE_SERVICE_ACCOUNT=smc-tf-foundation-sa@smc-ops.iam.gserviceaccount.com
export GOOGLE_BACKEND_IMPERSONATE_SERVICE_ACCOUNT=$GOOGLE_IMPERSONATE_SERVICE_ACCOUNT
terraform init && terraform plan   # expected: No changes
```

## Seen in GCP but not managed here

| Asset type | Count | Why |
| --- | --- | --- |
| ServiceAccount | 2 | Google-created default SA (Compute / App Engine); not ownable by google_service_account |

## Findings (imported as-is, fix in a later PR)

- `user:chris@simplifymy.cloud` holds basic role `roles/owner` on this project
- service-account keys: list user-managed ones with `gcloud iam service-accounts keys list --iam-account=<sa> --managed-by=user` (org policy already blocks NEW keys)

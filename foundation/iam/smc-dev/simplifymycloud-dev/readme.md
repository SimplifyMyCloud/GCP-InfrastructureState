# iam/smc-dev/simplifymycloud-dev

Terraform for project **`simplifymycloud-dev`** in folder `smc-dev` (`922883963214`): IAM: service accounts and IAM bindings.

| | |
| --- | --- |
| GCP node | project **`simplifymycloud-dev`** in folder `smc-dev` (`922883963214`) |
| Terraform state | `gs://smc-ops-tf-state/terraform/state/foundation/iam/smc-dev/simplifymycloud-dev/default.tfstate` |
| Imported | 2026-11-01/02 from the live Org, 81 resources, zero-diff plan |

## Resources

| Terraform type | Count |
| --- | --- |
| `google_project_iam_member` | 74 |
| `google_service_account` | 7 |

## Files

| File | What it holds |
| --- | --- |
| `gcp_provider.tf` | symlink to the repo-root `gcp_provider.tf` (Terraform + provider versions) |
| `iam_simplifymycloud_dev_gcs_backend.tf` | this directory's state location (hardcoded) |
| `iam_simplifymycloud_dev_project.tf` | project IAM bindings |
| `iam_simplifymycloud_dev_service_accounts.tf` | service accounts |

Each resource's `import {}` block sits right under it. After the first apply they are no-ops, kept as a record of where each resource came from.

## Run it

```bash
cd foundation/iam/smc-dev/simplifymycloud-dev
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

# iam/gcp-org

Terraform for the **simplifymy.cloud Org** (`933250405420`): IAM: service accounts and IAM bindings.

| | |
| --- | --- |
| GCP node | the **simplifymy.cloud Org** (`933250405420`) |
| Terraform state | `gs://smc-ops-tf-state/terraform/state/foundation/iam/gcp-org/default.tfstate` |
| Imported | 2026-11-01/02 from the live Org, 10 resources, zero-diff plan |

## Resources

| Terraform type | Count |
| --- | --- |
| `google_organization_iam_audit_config` | 1 |
| `google_organization_iam_custom_role` | 3 |
| `google_organization_iam_member` | 6 |

## Files

| File | What it holds |
| --- | --- |
| `gcp_provider.tf` | symlink to the repo-root `gcp_provider.tf` (Terraform + provider versions) |
| `iam_gcp_org_audit_config.tf` | org-wide audit logging config |
| `iam_gcp_org_custom_roles.tf` | org-level custom roles |
| `iam_gcp_org_gcs_backend.tf` | this directory's state location (hardcoded) |
| `iam_gcp_org_members.tf` | organization IAM bindings (simplifymy.cloud, 933250405420) |
| `iam_gcp_org_tf_foundation_sa.tf` | smc-tf-foundation-sa deployment grants |

Each resource's `import {}` block sits right under it. After the first apply they are no-ops, kept as a record of where each resource came from.

## Run it

```bash
cd foundation/iam/gcp-org
export GOOGLE_IMPERSONATE_SERVICE_ACCOUNT=smc-tf-foundation-sa@smc-ops.iam.gserviceaccount.com
export GOOGLE_BACKEND_IMPERSONATE_SERVICE_ACCOUNT=$GOOGLE_IMPERSONATE_SERVICE_ACCOUNT
terraform init && terraform plan   # expected: No changes
```

## Findings (imported as-is, fix in a later PR)

- `user:chris@simplifymy.cloud` holds basic role `roles/owner` on this project

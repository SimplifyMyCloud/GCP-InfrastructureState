# gcp-projects/smc-prod/smc-prod-bbmrc

Terraform for project **`smc-prod-bbmrc`** in folder `smc-prod` (`386439801809`): the project itself and every in-project service (APIs, storage, DNS, Firebase, App Engine, monitoring, ...).

| | |
| --- | --- |
| GCP node | project **`smc-prod-bbmrc`** in folder `smc-prod` (`386439801809`) |
| Terraform state | `gs://smc-ops-tf-state/terraform/state/foundation/gcp-projects/smc-prod/smc-prod-bbmrc/default.tfstate` |
| Imported | 2026-11-01/02 from the live Org, 24 resources, zero-diff plan |

## Resources

| Terraform type | Count |
| --- | --- |
| `google_project` | 1 |
| `google_project_service` | 23 |

## Files

| File | What it holds |
| --- | --- |
| `gcp_projects_smc_prod_bbmrc_apis.tf` | enabled APIs |
| `gcp_projects_smc_prod_bbmrc_gcs_backend.tf` | this directory's state location (hardcoded) |
| `gcp_projects_smc_prod_bbmrc_project.tf` | the project |
| `gcp_provider.tf` | symlink to the repo-root `gcp_provider.tf` (Terraform + provider versions) |

Each resource's `import {}` block sits right under it. After the first apply they are no-ops, kept as a record of where each resource came from.

## Run it

```bash
cd foundation/gcp-projects/smc-prod/smc-prod-bbmrc
export GOOGLE_IMPERSONATE_SERVICE_ACCOUNT=smc-tf-foundation-sa@smc-ops.iam.gserviceaccount.com
export GOOGLE_BACKEND_IMPERSONATE_SERVICE_ACCOUNT=$GOOGLE_IMPERSONATE_SERVICE_ACCOUNT
terraform init && terraform plan   # expected: No changes
```

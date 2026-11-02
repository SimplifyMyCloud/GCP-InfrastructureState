# gcp-projects/smc-prod/smc-prod-psmtherapy

Terraform for project **`smc-prod-psmtherapy`** in folder `smc-prod` (`386439801809`): the project itself and every in-project service (APIs, storage, DNS, Firebase, App Engine, monitoring, ...).

| | |
| --- | --- |
| GCP node | project **`smc-prod-psmtherapy`** in folder `smc-prod` (`386439801809`) |
| Terraform state | `gs://smc-ops-tf-state/terraform/state/foundation/gcp-projects/smc-prod/smc-prod-psmtherapy/default.tfstate` |
| Imported | 2026-11-01/02 from the live Org, 50 resources, zero-diff plan |

## Resources

| Terraform type | Count |
| --- | --- |
| `google_apikeys_key` | 1 |
| `google_dns_managed_zone` | 1 |
| `google_dns_record_set` | 8 |
| `google_firebase_project` | 1 |
| `google_firebase_web_app` | 2 |
| `google_identity_platform_config` | 1 |
| `google_project` | 1 |
| `google_project_service` | 35 |

## Files

| File | What it holds |
| --- | --- |
| `gcp_projects_smc_prod_psmtherapy_apikeys.tf` | API keys |
| `gcp_projects_smc_prod_psmtherapy_apis.tf` | enabled APIs |
| `gcp_projects_smc_prod_psmtherapy_dns.tf` | Cloud DNS zones and records |
| `gcp_projects_smc_prod_psmtherapy_firebase.tf` | Firebase, Firestore and security rules |
| `gcp_projects_smc_prod_psmtherapy_gcs_backend.tf` | this directory's state location (hardcoded) |
| `gcp_projects_smc_prod_psmtherapy_other.tf` | other resources |
| `gcp_projects_smc_prod_psmtherapy_project.tf` | the project |
| `gcp_provider.tf` | symlink to the repo-root `gcp_provider.tf` (Terraform + provider versions) |

Each resource's `import {}` block sits right under it. After the first apply they are no-ops, kept as a record of where each resource came from.

## Run it

```bash
cd foundation/gcp-projects/smc-prod/smc-prod-psmtherapy
export GOOGLE_IMPERSONATE_SERVICE_ACCOUNT=smc-tf-foundation-sa@smc-ops.iam.gserviceaccount.com
export GOOGLE_BACKEND_IMPERSONATE_SERVICE_ACCOUNT=$GOOGLE_IMPERSONATE_SERVICE_ACCOUNT
terraform init && terraform plan   # expected: No changes
```

## Seen in GCP but not managed here

| Asset type | Count | Why |
| --- | --- | --- |
| Config | 1 | no Terraform mapping yet |
| ResourceRecordSet | 1 | SOA record is owned by Cloud DNS |

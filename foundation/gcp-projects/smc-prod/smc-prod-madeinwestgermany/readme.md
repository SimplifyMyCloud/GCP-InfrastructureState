# gcp-projects/smc-prod/smc-prod-madeinwestgermany

Terraform for project **`smc-prod-madeinwestgermany`** in folder `smc-prod` (`386439801809`): the project itself and every in-project service (APIs, storage, DNS, Firebase, App Engine, monitoring, ...).

| | |
| --- | --- |
| GCP node | project **`smc-prod-madeinwestgermany`** in folder `smc-prod` (`386439801809`) |
| Terraform state | `gs://smc-ops-tf-state/terraform/state/foundation/gcp-projects/smc-prod/smc-prod-madeinwestgermany/default.tfstate` |
| Imported | 2026-11-01/02 from the live Org, 73 resources, zero-diff plan |

## Resources

| Terraform type | Count |
| --- | --- |
| `google_apikeys_key` | 2 |
| `google_app_engine_application` | 2 |
| `google_cloudbuild_trigger` | 1 |
| `google_dns_managed_zone` | 2 |
| `google_dns_record_set` | 12 |
| `google_firebase_project` | 1 |
| `google_firebase_web_app` | 1 |
| `google_firebaserules_release` | 1 |
| `google_firebaserules_ruleset` | 1 |
| `google_project` | 1 |
| `google_project_service` | 45 |
| `google_storage_bucket` | 4 |

## Files

| File | What it holds |
| --- | --- |
| `gcp_projects_smc_prod_madeinwestgermany_apikeys.tf` | API keys |
| `gcp_projects_smc_prod_madeinwestgermany_apis.tf` | enabled APIs |
| `gcp_projects_smc_prod_madeinwestgermany_appengine.tf` | App Engine application |
| `gcp_projects_smc_prod_madeinwestgermany_cloudbuild.tf` | Cloud Build |
| `gcp_projects_smc_prod_madeinwestgermany_dns.tf` | Cloud DNS zones and records |
| `gcp_projects_smc_prod_madeinwestgermany_firebase.tf` | Firebase, Firestore and security rules |
| `gcp_projects_smc_prod_madeinwestgermany_gcs_backend.tf` | this directory's state location (hardcoded) |
| `gcp_projects_smc_prod_madeinwestgermany_project.tf` | the project |
| `gcp_projects_smc_prod_madeinwestgermany_storage.tf` | GCS buckets |
| `gcp_provider.tf` | symlink to the repo-root `gcp_provider.tf` (Terraform + provider versions) |

Each resource's `import {}` block sits right under it. After the first apply they are no-ops, kept as a record of where each resource came from.

## Run it

```bash
cd foundation/gcp-projects/smc-prod/smc-prod-madeinwestgermany
export GOOGLE_IMPERSONATE_SERVICE_ACCOUNT=smc-tf-foundation-sa@smc-ops.iam.gserviceaccount.com
export GOOGLE_BACKEND_IMPERSONATE_SERVICE_ACCOUNT=$GOOGLE_IMPERSONATE_SERVICE_ACCOUNT
terraform init && terraform plan   # expected: No changes
```

## Seen in GCP but not managed here

| Asset type | Count | Why |
| --- | --- | --- |
| Database | 1 | Firestore API is DISABLED on this project; cannot read the database without enabling it |
| ResourceRecordSet | 2 | SOA record is owned by Cloud DNS |

## Findings (imported as-is, fix in a later PR)

- API key "Server key (auto created by Firebase)" has **no restrictions**

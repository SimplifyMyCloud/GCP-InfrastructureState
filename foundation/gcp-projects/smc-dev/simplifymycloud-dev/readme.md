# gcp-projects/smc-dev/simplifymycloud-dev

Terraform for project **`simplifymycloud-dev`** in folder `smc-dev` (`922883963214`): the project itself and every in-project service (APIs, storage, DNS, Firebase, App Engine, monitoring, ...).

| | |
| --- | --- |
| GCP node | project **`simplifymycloud-dev`** in folder `smc-dev` (`922883963214`) |
| Terraform state | `gs://smc-ops-tf-state/terraform/state/foundation/gcp-projects/smc-dev/simplifymycloud-dev/default.tfstate` |
| Imported | 2026-11-01/02 from the live Org, 194 resources, zero-diff plan |

## Resources

| Terraform type | Count |
| --- | --- |
| `google_apikeys_key` | 2 |
| `google_app_engine_application` | 1 |
| `google_artifact_registry_repository` | 4 |
| `google_bigquery_dataset` | 2 |
| `google_bigquery_table` | 8 |
| `google_cloudbuild_trigger` | 1 |
| `google_compute_instance_template` | 1 |
| `google_firebase_project` | 1 |
| `google_firebaserules_release` | 1 |
| `google_firebaserules_ruleset` | 3 |
| `google_firestore_database` | 1 |
| `google_kms_crypto_key` | 8 |
| `google_kms_key_ring` | 7 |
| `google_monitoring_alert_policy` | 4 |
| `google_monitoring_dashboard` | 2 |
| `google_monitoring_notification_channel` | 1 |
| `google_network_management_connectivity_test` | 3 |
| `google_project` | 1 |
| `google_project_service` | 117 |
| `google_pubsub_topic` | 5 |
| `google_storage_bucket` | 21 |

## Files

| File | What it holds |
| --- | --- |
| `gcp_projects_simplifymycloud_dev_apikeys.tf` | API keys |
| `gcp_projects_simplifymycloud_dev_apis.tf` | enabled APIs |
| `gcp_projects_simplifymycloud_dev_appengine.tf` | App Engine application |
| `gcp_projects_simplifymycloud_dev_artifact_registry.tf` | Artifact Registry |
| `gcp_projects_simplifymycloud_dev_bigquery.tf` | BigQuery |
| `gcp_projects_simplifymycloud_dev_cloudbuild.tf` | Cloud Build |
| `gcp_projects_simplifymycloud_dev_firebase.tf` | Firebase, Firestore and security rules |
| `gcp_projects_simplifymycloud_dev_gcs_backend.tf` | this directory's state location (hardcoded) |
| `gcp_projects_simplifymycloud_dev_kms.tf` | Cloud KMS |
| `gcp_projects_simplifymycloud_dev_monitoring.tf` | monitoring: dashboards, alerts, channels, log metrics |
| `gcp_projects_simplifymycloud_dev_other.tf` | other resources |
| `gcp_projects_simplifymycloud_dev_project.tf` | the project |
| `gcp_projects_simplifymycloud_dev_pubsub.tf` | Pub/Sub |
| `gcp_projects_simplifymycloud_dev_storage.tf` | GCS buckets |
| `gcp_provider.tf` | symlink to the repo-root `gcp_provider.tf` (Terraform + provider versions) |

Each resource's `import {}` block sits right under it. After the first apply they are no-ops, kept as a record of where each resource came from.

## Run it

```bash
cd foundation/gcp-projects/smc-dev/simplifymycloud-dev
export GOOGLE_IMPERSONATE_SERVICE_ACCOUNT=smc-tf-foundation-sa@smc-ops.iam.gserviceaccount.com
export GOOGLE_BACKEND_IMPERSONATE_SERVICE_ACCOUNT=$GOOGLE_IMPERSONATE_SERVICE_ACCOUNT
terraform init && terraform plan   # expected: No changes
```

## Seen in GCP but not managed here

| Asset type | Count | Why |
| --- | --- | --- |
| ConnectivityTest | 3 | no Terraform mapping yet |
| CustomJob | 2 | no Terraform mapping yet |
| Dashboard | 1 | built-in Console homepage dashboard; not visible to the API |
| InstanceTemplate | 1 | no Terraform mapping yet |
| Namespace | 1 | no Terraform mapping yet |
| Notebook | 1 | no Terraform mapping yet |
| OSPolicyAssignment | 7 | no Terraform mapping yet |
| SavedQuery | 1 | no Terraform mapping yet |
| ScanConfig | 1 | no Terraform mapping yet |
| SslCertificate | 1 | no Terraform mapping yet |

## Findings (imported as-is, fix in a later PR)

- API key "Server key (auto created by Firebase)" has **no restrictions**

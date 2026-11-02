<!-- hand-written -->
# gcp-projects / smc-ops / smc-ops

The **smc-ops** project: the SRE/operations project that holds the Terraform state bucket, the Terraform service accounts, and the smc-dev log bucket. This directory owns the project itself and every in-project service. IAM lives in [`iam/smc-ops/smc-ops/`](../../../iam/smc-ops/smc-ops/), and log buckets and sinks in [`logging/smc-ops/smc-ops/`](../../../logging/smc-ops/smc-ops/).

| | |
| --- | --- |
| Project ID / number | `smc-ops` / `328135394383` |
| Folder | `smc-ops` (`714502724732`) |
| Billing | `000000-000002-6D3BF8` (simplifymycloud-billing-main) |
| Terraform state | `gs://smc-ops-tf-state/terraform/state/foundation/gcp-projects/smc-ops/smc-ops/default.tfstate` |
| Imported | 2026-11-01, 33 resources; 33 management APIs added since |

## What's in here

| File | Owns |
| --- | --- |
| `gcp_projects_smc_ops.tf` | `google_project.smc_ops` (`deletion_policy = "PREVENT"`) |
| `gcp_projects_smc_ops_apis.tf` | enabled APIs in two hardcoded lists: the 25 found at import, plus 33 **management APIs** added because calls made as `smc-tf-foundation-sa` bill quota to smc-ops |
| `gcp_projects_smc_ops_storage.tf` | `gs://smc-ops-tf-state`, the bucket holding **every** state file in the repo (`prevent_destroy`) |
| `gcp_projects_smc_ops_monitoring.tf` | 3 security log-metrics, 2 alert policies, 1 email notification channel |
| `gcp_projects_smc_ops_gcs_backend.tf` | this directory's state location (hardcoded) |
| `gcp_provider.tf` | symlink to the repo-root `gcp_provider.tf` |

Each resource's `import {}` block sits right below it. Once the first apply has imported everything, those blocks are no-ops. They stay in the code as a record of where each resource came from.

## Run it

```bash
cd foundation/gcp-projects/smc-ops/smc-ops
terraform init
terraform plan     # expected: No changes (after the first apply)
```

## Gotchas

- **Never add `project = "smc-ops"` to the state bucket.** The import records `project` as null, so setting it makes Terraform plan to *destroy and recreate* the bucket.
- Alert-policy import IDs must be `"<project> projects/<project>/alertPolicies/<id>"`. The bare name fails because the shared provider sets no default project.

## Findings (imported as-is, fix later)

- The security log-metrics only see logs that land in **smc-ops**. They don't cover the whole org.
- `custom-role-change` has a metric but no alert policy.
- The `smc-dev-env-logging` bucket keeps logs for only **3 days** (see `logging/`).

<!-- hand-written -->
# iam / smc-ops / smc-ops

IAM for the **smc-ops** project: its service accounts and its project-level IAM bindings. The project itself is in [`gcp-projects/smc-ops/smc-ops/`](../../../gcp-projects/smc-ops/smc-ops/).

| | |
| --- | --- |
| Terraform state | `gs://smc-ops-tf-state/terraform/state/foundation/iam/smc-ops/smc-ops/default.tfstate` |
| Imported | 2026-11-01, 9 resources + 1 new grant, zero-diff plan |
| Style | `google_project_iam_member`: one resource per role + member (additive) |

## What's in here

| File | Owns |
| --- | --- |
| `iam_smc_ops_service_accounts.tf` | `smc-tf-foundation-sa` (the new dedicated Terraform SA) and `smc-ops-tf-org-admin` (pre-existing), plus who may act as them: chris@ is `serviceAccountTokenCreator` on `smc-tf-foundation-sa` (new, enables impersonation) and `serviceAccountAdmin`/`serviceAccountUser` on `smc-ops-tf-org-admin` (imported) |
| `iam_smc_ops_project.tf` | 5 project IAM bindings, including 1 with an IAM condition |
| `iam_smc_ops_gcs_backend.tf` | this directory's state location |
| `gcp_provider.tf` | symlink to the repo-root `gcp_provider.tf` |

## Bindings

| Role | Member | Note |
| --- | --- | --- |
| `roles/owner` | `user:chris@simplifymy.cloud` | |
| `roles/resourcemanager.organizationAdmin` | `smc-ops-tf-org-admin` SA | ⚠️ see findings |
| `roles/logging.bucketWriter` | smc-dev folder sink writer | conditional: only the `smc-dev-env-logging` bucket |
| `roles/cloudaicompanion.serviceAgent` | Google service agent | Google-managed |
| `roles/cloudsecuritycompliance.serviceAgent` | Google service agent | Google-managed |

Being additive means Terraform manages these bindings and nothing else on the policy. A binding added by hand later **won't show up in `plan`**. It shows up in the audit log and in a fresh `gcloud projects get-iam-policy`.

## Findings (imported as-is, fix later)

- **`smc-ops-tf-org-admin` holds org admin and has 2 user-managed keys** (`2603638549a0…`, `6b59a9c6ae62…`). It overlaps with the new `smc-tf-foundation-sa`. Recommend retiring it once the new SA is live: delete the keys, then the binding, then the SA.
- `smc-tf-foundation-sa` holds **temporary broad org roles** (owner, organizationAdmin, ...; see `iam/gcp-org/`) until it is switched to read-only.

<!-- hand-written -->
# iam / smc-ops / smc-ops

IAM for the **smc-ops** project: its service accounts and its project-level IAM bindings. The project itself is in [`gcp-projects/smc-ops/smc-ops/`](../../../gcp-projects/smc-ops/smc-ops/).

| | |
| --- | --- |
| Terraform state | `gs://smc-ops-tf-state/terraform/state/foundation/iam/smc-ops/smc-ops/default.tfstate` |
| Imported | 2026-11-01, 9 resources, zero-diff plan; since then 3 new grants (chris@ tokenCreator, state-bucket objectAdmin, log-archive objectCreator) and 1 removed (org-admin binding) |
| Style | `google_project_iam_member`: one resource per role + member (additive) |

## What's in here

| File | Owns |
| --- | --- |
| `iam_smc_ops_service_accounts.tf` | `smc-tf-foundation-sa` (the new dedicated Terraform SA) and `smc-ops-tf-org-admin` (pre-existing), plus who may act as them: chris@ is `serviceAccountTokenCreator` on `smc-tf-foundation-sa` (new, enables impersonation) and `serviceAccountAdmin`/`serviceAccountUser` on `smc-ops-tf-org-admin` (imported) |
| `iam_smc_ops_project.tf` | 4 project IAM bindings, including 1 with an IAM condition |
| `iam_smc_ops_state_bucket.tf` | `storage.objectAdmin` for `smc-tf-foundation-sa` on `gs://smc-ops-tf-state` (new 2026-11-02): the plan-only SA still has to write state-lock objects |
| `iam_smc_ops_log_archive_bucket.tf` | `storage.objectCreator` on `gs://smc-ops-log-archive` for the org sink's writer identity `service-org-933250405420@gcp-sa-logging` (new 2026-11-02) |
| `iam_smc_ops_gcs_backend.tf` | this directory's state location |
| `gcp_provider.tf` | symlink to the repo-root `gcp_provider.tf` |

## Bindings

| Role | Member | Note |
| --- | --- | --- |
| `roles/owner` | `user:chris@simplifymy.cloud` | |
| `roles/logging.bucketWriter` | smc-dev folder sink writer | conditional: only the `smc-dev-env-logging` bucket |
| `roles/cloudaicompanion.serviceAgent` | Google service agent | Google-managed |
| `roles/cloudsecuritycompliance.serviceAgent` | Google service agent | Google-managed |

Being additive means Terraform manages these bindings and nothing else on the policy. A binding added by hand later **won't show up in `plan`**. It shows up in the audit log and in a fresh `gcloud projects get-iam-policy`.

## Findings (imported as-is, fix later)

- **`smc-ops-tf-org-admin` is being retired.** Stage 1 done 2026-11-02: its `organizationAdmin` binding is removed, the SA is **disabled** (`disabled = true`), and its one user-managed key (`2603638549a0…`, from 2020) is disabled. Its other key is Google-managed (auto-rotating). Stage 2, on or after **2026-12-02**: delete the key, then remove the SA and its two chris@ grants in a change window.
- ✅ Fixed 2026-11-02: `smc-tf-foundation-sa` is now **plan-only** at the Org (read roles in `iam/gcp-org/`); its only write is objects in the state bucket. It gets write roles only during a change window (see `foundation/readme.md`).

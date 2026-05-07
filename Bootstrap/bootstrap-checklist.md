# Bootstrap Checklist

Pilot's pre-flight. One pass, top to bottom. Every box ticked before moving to the next phase. The verbose form of each step lives in `bootstrap-playbook.md`.

---

## Phase 0 — Pre-flight

- [ ] GCP Cloud Shell open
- [ ] Captured `TF_VAR_ORG_ID` from `gcloud organizations list`
- [ ] Captured `TF_VAR_BILLING_ACCOUNT` from `gcloud billing accounts list`
- [ ] Exported `TF_VAR_GENESIS_ADMIN`, `TF_VAR_REGION`, `TF_VAR_ZONE`
- [ ] `gcloud config get-value account` returns the genesis admin email

---

## Phase 1 — Baseline GCP Org policies

- [ ] `compute.requireOsLogin` enforced
- [ ] `iam.disableServiceAccountKeyCreation` enforced
- [ ] `compute.skipDefaultNetworkCreation` enforced

---

## Phase 2 — Temporary genesis admin elevations

- [ ] `roles/resourcemanager.folderCreator` granted
- [ ] `roles/resourcemanager.projectCreator` granted
- [ ] `roles/billing.user` granted
- [ ] `roles/iam.serviceAccountAdmin` granted
- [ ] `roles/serviceusage.serviceUsageAdmin` granted

---

## Phase 3 — `iq9`, `ops`, `iq9-bootstrap`, `iq9-bootstrap-sa`

- [ ] `iq9` folder created — `IQ9_FOLDER` exported
- [ ] `ops` folder created — `IQ9_OPS_FOLDER` exported
- [ ] `iq9-bootstrap` project created
- [ ] Billing linked to `iq9-bootstrap`
- [ ] APIs enabled on `iq9-bootstrap` (cloudresourcemanager, cloudbilling, iam, iamcredentials, serviceusage, storage, compute, logging)
- [ ] `iq9-bootstrap-sa` service account created — `BOOTSTRAP_SA` exported
- [ ] Org-level roles granted to `iq9-bootstrap-sa`
- [ ] Genesis admin granted `roles/iam.serviceAccountTokenCreator` on `iq9-bootstrap-sa`
- [ ] `IMPERSONATE` env var set; remaining commands run with impersonation

---

## Phase 4 — `iq9-ops-iac`, `iq9-tf-foundation-sa`, `gs://iq9-iac-ops-tf-state-bucket`, `iq9-tf-runner`

- [ ] `iq9-ops-iac` project created (impersonating bootstrap SA)
- [ ] Billing linked to `iq9-ops-iac`
- [ ] APIs enabled on `iq9-ops-iac` (cloudresourcemanager, cloudbilling, iam, iamcredentials, serviceusage, storage, compute, oslogin, logging)
- [ ] `iq9-tf-foundation-sa` created — `FOUNDATION_SA` exported
- [ ] **Folder-scoped** roles granted to `iq9-tf-foundation-sa` on `iq9` folder (NOT org-level)
- [ ] `iq9-tf-foundation-sa` granted `roles/billing.user` directly on the billing account (NOT folder-scoped — billing accounts live outside the resource hierarchy, so folder bindings are a no-op. Run by the genesis admin, since bootstrap SA lacks `billing.admin` to call `setIamPolicy`)
- [ ] `iq9-bootstrap-sa` granted `roles/iam.serviceAccountUser` on `iq9-tf-foundation-sa` (so it can attach the SA to the runner VM)
- [ ] `iq9-tf-foundation-sa` granted `roles/iam.roleAdmin` at `iq9-ops-iac` project scope (project-only role; not folder-supported. Lets foundation TF manage custom IAM roles)
- [ ] `gs://iq9-iac-ops-tf-state-bucket` created — uniform bucket-level access + public access prevention
- [ ] Versioning enabled on `gs://iq9-iac-ops-tf-state-bucket`
- [ ] `iq9-tf-foundation-sa` granted `roles/storage.objectAdmin` on `gs://iq9-iac-ops-tf-state-bucket`
- [ ] `iq9-ops-iac-vpc` VPC created (custom mode, bootstrap-temporary)
- [ ] `iq9-ops-iac-subnet` subnet created with Private Google Access ON
- [ ] `iq9-ops-iac-allow-iap-ssh` firewall rule created (IAP CIDR → tcp:22)
- [ ] `iq9-ops-iac-router` Cloud Router created
- [ ] `iq9-ops-iac-nat` Cloud NAT created (auto-allocate IPs, all subnet ranges)
- [ ] `iq9-tf-runner` GCE VM created — Debian 12, foundation SA attached, OS Login on, no public IP, attached to bootstrap-temporary subnet
- [ ] SSH'd into runner via IAP; Terraform installed; `terraform -version` returns `~> 1.10`

---

## Phase 5 — `logs`, `iq9-logging-warehouse`, archive bucket, iq9 folder log sink

- [ ] `logs` folder created — `IQ9_LOG_FOLDER` exported
- [ ] `iq9-logging-warehouse` project created
- [ ] Billing linked to `iq9-logging-warehouse`
- [ ] APIs enabled on `iq9-logging-warehouse` (storage, logging)
- [ ] `gs://iq9-logging-warehouse` created — `ARCHIVE` storage class, uniform access, public access prevention
- [ ] Retention period set to **180 days**
- [ ] ⏸ Retention lock **DEFERRED** — leave commented in playbook until end-to-end is verified
- [ ] Lifecycle rule applied — delete objects at age 180 days
- [ ] `iq9-log-sink` created at `iq9` folder level with `--include-children`, no filter
- [ ] Sink writer-identity SA captured into `SINK_WRITER_SA`
- [ ] `SINK_WRITER_SA` granted `roles/storage.objectCreator` on `gs://iq9-logging-warehouse`
- [ ] Verified logs landing in bucket (5+ minute delay; check Cloud Logging UI or `gcloud storage ls gs://iq9-logging-warehouse/`)
- [ ] (Later, after end-to-end verified) Retention policy LOCKED — one-way, confirmed with `y`

---

## Phase 6 — De-privilege the genesis admin

- [ ] `roles/resourcemanager.folderCreator` removed
- [ ] `roles/resourcemanager.projectCreator` removed
- [ ] `roles/billing.user` removed
- [ ] `roles/iam.serviceAccountAdmin` removed
- [ ] `roles/serviceusage.serviceUsageAdmin` removed
- [ ] GCP Super Admin passwords moved offline / to physical vault — two-person retrieval

---

## Phase 7 — Hand off to the Foundation Layer

- [ ] SSH'd into `iq9-tf-runner` via IAP
- [ ] Cloned `GCP-InfrastructureState` repo on the VM
- [ ] Foundation directories applied in dependency order (see `foundation/README.md`)
- [ ] All `terraform apply` runs succeeded — zero diff on a re-plan

---

## Phase 8 — Archive the bootstrap

- [ ] `iq9-bootstrap-sa` deleted
- [ ] Org-level role bindings for `iq9-bootstrap-sa` removed
- [ ] `iq9-bootstrap` project deleted
- [ ] Project shows `DELETE_REQUESTED` in `gcloud projects list --filter="state:DELETE_REQUESTED"`

---

✅ **Bootstrap complete. Every change to the GCP Org from this point on is a Terraform PR.**

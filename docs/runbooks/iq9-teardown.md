# Runbook — iq9 teardown

> ✅ **Completed 2026-11-01.** Kept as a record. The iq9 estate is gone, and the 10 leftover `iq9-bootstrap-sa` org grants were removed by Terraform (`foundation/iam/gcp-org/`).

**Goal:** remove every `iq9` resource from the `simplifymy.cloud` GCP Org (933250405420) so the Org matches git again, now that the repo describes the `smc` estate.

**Who runs it:** a human with Org owner (Chris). Every step is destructive and irreversible. Run them in order, one at a time, and check each step before moving on.

**Why order matters:** every iq9 Terraform state lives in `gs://iq9-iac-ops-tf-state-bucket`, which lives in `iq9-ops-iac`. That project is deleted **last**. If it goes first, Terraform loses its state and the rest becomes a manual click-delete.

---

## 0. Pre-flight

The iq9 Terraform code is gone from `HEAD`. Tear down from the last commit that still has it, **`c79f3ed`** (tag `iq9-final`):

```bash
git worktree add ../iq9-final iq9-final   # or: c79f3ed
cd ../iq9-final
gcloud auth application-default login \
  --impersonate-service-account=iq9-tf-foundation-sa@iq9-ops-iac.iam.gserviceaccount.com
```

Check the estate matches what this runbook expects (captured read-only on 2026-11-01):

| Folder (under `iq9` 147640766174) | Projects |
| --- | --- |
| `ops` 340182878863 | `iq9-ops-iac`, `iq9-bootstrap` |
| `logs` 473370836814 | `iq9-logging-warehouse` |
| `dev` 696735621171 | `iq9-gcp-dev-yamato` |
| `sandbox` 754288056256 | — |
| `prod` 804834447320 | — |

Terraform states in `gs://iq9-iac-ops-tf-state-bucket/terraform/state/`: `foundation/{gcp-folders, gcp-projects/yamato/dev, networks/bakery, networks/yamato/dev}` and `service/yamato/dev/{artifact-registry, cloudrun, cloudsql, frontdoor, logging}`. `foundation/logging/*` was never applied, so it has no state.

> ⚠️ **Data loss.** This deletes the yamato Cloud SQL database, the Artifact Registry images, and `gs://iq9-logging-warehouse`. That bucket holds the bootstrap's audit trail under a 180-day **unlocked** retention policy. Export anything you want to keep first.

---

## 1. Service Layer — `service/yamato/dev/*` (reverse dependency order)

For each root, in **this** order:

| # | Root | Note |
| --- | --- | --- |
| 1 | `service/yamato/dev/logging` | alerts/metrics reference Cloud Run + SQL |
| 2 | `service/yamato/dev/frontdoor` | LB, Cloud Armor, IAP → Cloud Run NEGs |
| 3 | `service/yamato/dev/cloudrun` | set `deletion_protection = false` in `terraform.tfvars`, `apply`, then destroy |
| 4 | `service/yamato/dev/cloudsql` | set `deletion_protection = false` in `terraform.tfvars`, `apply`, then destroy |
| 5 | `service/yamato/dev/artifact-registry` | deletes the yamato images |

```bash
cd service/yamato/dev/<root>
terraform init
terraform plan -destroy        # read it: only iq9 resources in iq9-gcp-dev-yamato
terraform destroy
```

**Verify:** `gcloud run services list --project=iq9-gcp-dev-yamato` and `gcloud sql instances list --project=iq9-gcp-dev-yamato` both come back empty.

---

## 2. Foundation Layer — networks

| # | Root | Note |
| --- | --- | --- |
| 6 | `foundation/networks/yamato/dev` | The PSA peering has `deletion_policy = "ABANDON"`, so Terraform drops it from state without deleting it. Cloud SQL is gone by now, so delete it by hand afterwards: `gcloud services vpc-peerings delete --service=servicenetworking.googleapis.com --network=iq9-vpc-dev-yamato --project=iq9-gcp-dev-yamato` |
| 7 | `foundation/networks/bakery` | The live VPC has **no subnet** (drift). `destroy` may report the subnet already gone; that's expected. |

```bash
cd foundation/networks/<root> && terraform init && terraform destroy
```

---

## 3. Foundation Layer — projects and folders

| # | Root | Note |
| --- | --- | --- |
| 8 | `foundation/gcp-projects/yamato/dev` | Edit `deletion_policy = "PREVENT"` → `"DELETE"`, `terraform apply`, then `terraform destroy`. The project goes into its 30-day pending-deletion window. |

**9. Bootstrap-created projects (not in Terraform):**

```bash
# stop the folder sink first so nothing more lands in the warehouse
gcloud logging sinks delete iq9-log-sink --folder=147640766174
gcloud projects delete iq9-logging-warehouse
gcloud projects delete iq9-bootstrap
```

**10. Folders.** `foundation/gcp-folders` can only destroy empty folders, and projects pending deletion still count as children for up to 30 days. Either wait out the window, or `gcloud projects delete` them early and move the folder destroy to the end:

```bash
cd foundation/gcp-folders && terraform init && terraform destroy   # ops, logs, sandbox, dev, prod
```

`ops` still contains `iq9-ops-iac` at this point, so that one folder destroy **fails**. That's expected; finish it in step 12.

---

## 4. Org-level iq9 leftovers

**11.** Remove the `iq9-bootstrap-sa` org IAM grants. The SA is gone with its project, but the bindings stay behind as `deleted:serviceAccount:...` until removed:

```bash
for r in roles/billing.user roles/compute.admin roles/iam.serviceAccountAdmin \
         roles/iam.serviceAccountTokenCreator roles/logging.admin roles/logging.configWriter \
         roles/resourcemanager.folderAdmin roles/resourcemanager.projectCreator \
         roles/serviceusage.serviceUsageAdmin roles/storage.admin; do
  gcloud organizations remove-iam-policy-binding 933250405420 --role="$r" \
    --member='deleted:serviceAccount:iq9-bootstrap-sa@iq9-bootstrap.iam.gserviceaccount.com?uid=<UID>' --condition=None
done
```

Get the exact `deleted:` member string, including its `uid`, from `gcloud organizations get-iam-policy 933250405420`.

---

## 5. Last — the state bucket's project

**12.** Only after steps 1–11 are verified:

```bash
gcloud storage cp -r gs://iq9-iac-ops-tf-state-bucket ./iq9-final-state-backup   # optional, keep offline
gcloud projects delete iq9-ops-iac
# after it and the other projects leave pending-deletion (≤30 days):
gcloud resource-manager folders delete 340182878863   # ops (if step 10 left it)
gcloud resource-manager folders delete 147640766174   # iq9 top folder
```

---

## 6. Outside GCP — the `iq9.io` domain

**13.** Admin console → Account → Domains → remove `iq9.io` as a secondary domain. Users and groups on `@iq9.io` have to be removed or renamed first. Delete the `iq9.io` DNS records (`yamato-dev.iq9.io`) at the registrar.

---

## Done when

```bash
gcloud resource-manager folders list --organization=933250405420   # no iq9
gcloud projects list --filter='projectId:iq9-*'                     # empty (or only DELETE_REQUESTED)
gcloud organizations get-iam-policy 933250405420 | grep -i iq9      # empty
git worktree remove ../iq9-final
```

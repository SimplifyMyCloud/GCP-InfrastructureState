# Foundation Layer — GCP Folders

The five environment folders that hang off the `iq9` top-level folder. This is the most rarely-changed Terraform state in the entire repo — folders are effectively permanent once created.

## Folder model

| Folder | Purpose | How it enters TF state |
| --- | --- | --- |
| `ops` | SRE domain — iac, observability, bakery | `terraform import` (bootstrap-created) |
| `logs` | Log warehouse — cold archive | `terraform import` (bootstrap-created) |
| `sandbox` | Per-engineer playgrounds | `terraform apply` |
| `dev` | Application dev (with `test` sub-env project) | `terraform apply` |
| `prod` | Production (with `stage` sub-env project) | `terraform apply` |

Every parent is hardcoded as `folders/147640766174` — the bootstrap-created `iq9` folder under organization `933250405420` (simplifymy.cloud). No variables.

## Files in this directory

| File | Purpose |
| --- | --- |
| `gcp_folders.tf` | All 5 folder resources, hardcoded |
| `gcp_folders_gcs_backend.tf` | TF state config — `gs://iq9-iac-ops-tf-state-bucket/terraform/state/foundation/gcp-folders/` |
| `gcp_provider.tf` | Soft link to repo-root `gcp_provider.tf` (terraform/provider version pins) |
| `readme.md` | This file |

## First-time setup

The two bootstrap-created folders must be imported before the first `apply`. Folder `display_name` is unique per parent, so without import Terraform would try to create duplicates and fail.

```bash
cd foundation/gcp-folders/

terraform init

terraform import google_folder.ops    folders/340182878863
terraform import google_folder.logs   folders/473370836814

terraform plan   # should show only sandbox, dev, prod as new
terraform apply
```

## Subsequent runs

```bash
cd foundation/gcp-folders/
terraform init
terraform plan   # should be a no-op once the layer is in steady state
```

## Why one TF state for all five folders

Folders are the most rarely-changed resources in the entire org and the dependency graph between them is trivial (siblings, no cross-refs). Bundling all five into a single state keeps the foundation footprint small and the blast radius of any future change localised to a single state file. As we move up the stack into projects, networks, and the Service Layer, state granularity increases.

## Change-control bar

Foundation Layer — minimum 3 PR approvals from the foundation reviewers group. A folder addition is an exception to the steady-state expectation; a folder deletion is essentially never approved.

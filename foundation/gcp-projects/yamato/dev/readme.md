# Foundation Layer — yamato / dev

The GCP project that hosts the dev environment of the `yamato` application — and the project's API enablement (a foundation-layer responsibility).

For the broader design philosophy — hardcoded values, state granularity, and change-control posture — see [`docs/infrastructurestate.md`](../../../../docs/infrastructurestate.md).

## What this state owns

One resource: `google_project.yamato_dev`. Project ID `iq9-gcp-dev-yamato`, parented to the `dev` folder, billed against the iq9 billing account, deletion-protected, and tagged with `env=dev` / `app=yamato` labels. `auto_create_network` is off — the default VPC is a sprawl of auto-mode subnets across every region, and we'd rather have a clean slate for `foundation/networks/yamato/dev/` to fill in.

API enablement lives here too — see `gcp_projects_yamato_dev_apis.tf`. Turning on a project's APIs is a foundation-layer responsibility (in a hardened split-identity model the Service-layer TF SA can't enable APIs), so the Service Layer assumes the APIs it needs are already on. No application *services* are provisioned here — the network state and the Service Layer do that.

## Hardcoded values

| Field | Value | Source |
| --- | --- | --- |
| `folder_id` | `696735621171` | dev folder, child of iq9 (created by `foundation/gcp-folders/`) |
| `billing_account` | `000000-000002-6D3BF8` | iq9 billing account, attached during bootstrap |
| `project_id` | `iq9-gcp-dev-yamato` | per `docs/naming-convention.md` (`{base}-gcp-{env}-{app}`) |

## Files in this directory

| File | Purpose |
| --- | --- |
| `gcp_projects_yamato_dev.tf` | The `google_project` resource |
| `gcp_projects_yamato_dev_apis.tf` | All `google_project_service` API enables for this project |
| `gcp_projects_yamato_dev_gcs_backend.tf` | TF state at `gs://iq9-iac-ops-tf-state-bucket/terraform/state/foundation/gcp-projects/yamato/dev/` |
| `gcp_provider.tf` | Soft link to repo-root `gcp_provider.tf` (terraform / provider version pins) |
| `readme.md` | This file |

## First-time setup

The project is brand new — no `terraform import` is required.

```bash
cd foundation/gcp-projects/yamato/dev/

terraform init

terraform plan   # should show one resource to create: google_project.yamato_dev
terraform apply  # creates iq9-gcp-dev-yamato
```

After the apply, verify from gcloud:

```bash
gcloud projects describe iq9-gcp-dev-yamato \
  --format='table(projectId, parent.id, lifecycleState, labels)'
```

Expected: `parent.id` is `696735621171`, `lifecycleState` is `ACTIVE`, labels include `env=dev` and `app=yamato`.

## Subsequent runs

```bash
cd foundation/gcp-projects/yamato/dev/
terraform init
terraform plan   # steady state — should report "No changes."
```

If a `plan` ever shows drift on this state, something has changed by hand and the audit log is the next stop.

## What comes next

Once this project (and its APIs) exist, the next foundation state — [`foundation/networks/yamato/dev/`](../../../networks/yamato/dev/) — creates the VPC, subnet, and PSA peering (the APIs it needs are already enabled here). After that, the Service Layer (Cloud SQL, Cloud Run, the front door, logging) populates the project with the services that run the yamato app.

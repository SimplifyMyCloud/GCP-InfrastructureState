# Foundation Layer — yamato / dev

The empty GCP project that hosts the dev environment of the `yamato` application.

For the broader design philosophy — hardcoded values, state granularity, and change-control posture — see [`docs/infrastructurestate.md`](../../../../docs/infrastructurestate.md).

## What this state owns

One resource: `google_project.yamato_dev`. Project ID `iq9-gcp-dev-yamato`, parented to the `dev` folder, billed against the iq9 billing account, deletion-protected, and tagged with `env=dev` / `app=yamato` labels. `auto_create_network` is off — the default VPC is a sprawl of auto-mode subnets across every region, and we'd rather have a clean slate for `foundation/gcp-networks/yamato/dev/` to fill in.

No APIs are enabled here. No services are provisioned here. The project is a shell; the next foundation state (gcp-networks) and the eventual Service Layer states populate it.

## Hardcoded values

| Field | Value | Source |
| --- | --- | --- |
| `folder_id` | `696735621171` | dev folder, child of iq9 (created by `foundation/gcp-folders/`) |
| `billing_account` | `000000-000002-6D3BF8` | iq9 billing account, attached during bootstrap |
| `project_id` | `iq9-gcp-dev-yamato` | per `docs/naming-convention.md` (`{base}-gcp-{env}-{app}`) |

## Files in this directory

| File | Purpose |
| --- | --- |
| `gcp_projects_yamato_dev.tf` | The single `google_project` resource |
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

Once this project exists, the next foundation state — [`foundation/gcp-networks/yamato/dev/`](../../../gcp-networks/yamato/dev/) — enables `compute` + `servicenetworking` inside it and creates the VPC, subnet, Cloud Router, Cloud NAT, IAP-SSH firewall rule, and PSA range. After that, the Service Layer (Cloud SQL, Cloud Run) populates the project with services that run the yamato app.

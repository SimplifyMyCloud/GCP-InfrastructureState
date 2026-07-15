# Foundation Layer — GCP Projects

The empty GCP project skeletons that hold every cloud service in this org. Each project is parented to one of the environment folders managed by [`../gcp-folders/`](../gcp-folders/), billed against the iq9 billing account, and tagged with `env` and `app` labels.

For the broader design philosophy — hardcoded values, state granularity, and change-control posture — see [`../../docs/infrastructurestate.md`](../../docs/infrastructurestate.md).

## Discipline

This layer creates **empty projects only**. No APIs are enabled, no networks are built, no service accounts are minted, no cloud services are provisioned. A `terraform apply` here produces a project shell that does literally nothing until another state populates it.

That discipline matters because:

- **API enablement is a security surface.** An enabled API is callable by anything in the project that holds the right IAM. Enabling APIs that aren't in use widens the blast radius for compromised credentials. Each downstream state enables only the APIs it actually uses.
- **Foundation is rare-change, downstream is frequent-change.** Putting a Cloud Run service in the project state means every Cloud Run version bump touches the foundation. Keeping foundation thin keeps the foundation reviewer queue short and the project resource itself unchanged for years at a time.
- **Layered teardown is safer.** When a service is retired, its state is destroyed; the project shell stays. When a project is retired, the folder hierarchy stays. Each layer can be torn down independently of what's above it.

What goes here: `google_project`, `auto_create_network = false`, `deletion_policy = "PREVENT"`, `env`/`app` labels, parent folder ID. That's all.

What does **not** go here: `google_project_service` (APIs), `google_compute_network` (VPCs), `google_service_account`, `google_project_iam_*` bindings, anything else.

## Layout

One directory per app, one Terraform state per project. New apps start as siblings — `foundation/gcp-projects/{app}/{env}/` — and never touch existing app states.

```
foundation/gcp-projects/
├── readme.md                    (this file)
└── yamato/                      (Star Blazers ships/characters/planets codex)
    ├── readme.md
    ├── dev/                     (state #1 — iq9-gcp-dev-yamato)
    ├── test/                    (pending — iq9-gcp-dev-yamato-test, parents to dev folder)
    ├── stage/                   (pending — iq9-gcp-prod-yamato-stage, parents to prod folder)
    └── prod/                    (pending — iq9-gcp-prod-yamato)
```

`test` and `stage` are sub-environments by folder hierarchy but live as peer state directories so each project's TF gets isolated blast radius. The folder hierarchy is the IAM/policy boundary; the state hierarchy is the change-management boundary. They don't have to match — and here they don't.

## Currently managed

| App | Description | States |
| --- | --- | --- |
| [`yamato/`](./yamato/) | Ships/characters/planets codex (Go + Cloud SQL + Cloud Run) | `dev/` (live), `test`/`stage`/`prod` pending |

## Adding a new app

The shape is identical for every app:

```
foundation/gcp-projects/{app}/
├── readme.md                   (app overview, mermaid diagram, env status table)
└── {env}/
    ├── gcp_projects_{app}_{env}.tf            (one google_project, hardcoded)
    ├── gcp_projects_{app}_{env}_gcs_backend.tf (prefix: foundation/gcp-projects/{app}/{env}/)
    ├── gcp_provider.tf                         (symlink to repo-root gcp_provider.tf)
    └── readme.md
```

Constants across every app/env: `auto_create_network = false`, `deletion_policy = "PREVENT"`, labels `env=<env>` + `app=<app>`, project_id `iq9-gcp-{env}-{app}` (or `iq9-gcp-{env}-{app}-{subenv}` for test/stage). Hardcoded folder IDs and billing account match the values documented in `gcp-folders/readme.md` and the bootstrap playbook.

# Service Layer — yamato / modules

The **reusable Terraform modules** that define the *shape* of each yamato service.
Per-environment roots (e.g. [`../dev/`](../dev/)) instantiate these with
environment-specific variables, so the same definition serves dev, test, stage,
and prod without copy-paste.

This split is the Service-Layer convention: variables + modules belong here (the
shape repeats across environments), unlike the Foundation Layer which hardcodes
everything. See [`docs/infrastructurestate.md`](../../../docs/infrastructurestate.md).

## Modules

| Module | Focus / desired state |
| --- | --- |
| [`artifact-registry/`](./artifact-registry/) | A Docker Artifact Registry repository + the image-pipeline APIs. |
| [`cloudsql/`](./cloudsql/) | A private-IP Postgres instance, its database, app user, and the password in Secret Manager. |
| [`cloudrun/`](./cloudrun/) | A Cloud Run service, its runtime service account, and the Serverless VPC connector. |
| [`frontdoor/`](./frontdoor/) | A global external HTTPS load balancer with IAP, fronting a Cloud Run service. |

## Conventions for every module here

- Declares `required_providers` in `versions.tf` but **no `provider` block** —
  provider config lives in the consuming root (the symlinked `gcp_provider.tf`).
- Declares **no `backend`** — state is owned by the per-env root.
- Takes `project_id` (and other identity/region values) as variables; never
  hardcodes an environment.
- `variables.tf` = inputs, `outputs.tf` = values the root re-exports or feeds to
  the next state.

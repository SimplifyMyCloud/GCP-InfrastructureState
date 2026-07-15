# Service Layer

The Service Layer hosts the GCP cloud-native services that applications run on —
Cloud Run, Cloud SQL, Artifact Registry, load balancing, Secret Manager, and the
like. It sits above the [Foundation Layer](../foundation/) (which it depends on)
and below the App Layer (the application code that runs on these services, which
is deliberately **not** managed by Terraform).

For the design philosophy behind layering, state granularity, and change-control,
see [`docs/infrastructurestate.md`](../docs/infrastructurestate.md).

## How the Service Layer differs from the Foundation Layer

| | Foundation Layer | Service Layer |
| --- | --- | --- |
| Values | hardcoded, no variables | **variables + modules** |
| Change cadence | rarely (org-shape changes) | often (developers iterate) |
| Review bar | minimum 3 approvals | 2 approvals |
| Posture | "Fort Knox" perimeter | developer velocity |

Variables and modules belong here precisely because the *same shape* repeats
across environments — the thing the Foundation Layer never has.

## Structure: shared modules + thin per-environment roots

Each application gets a `modules/` tree (the reusable service definitions) and one
**dedicated directory per environment**. Each environment directory is a thin root
that instantiates the modules with environment-specific variables and owns its own
Terraform state. Environments are **never** collapsed into one state via workspaces
or var-file switching — one dedicated git directory and one state per environment.

```
service/<app>/
├── modules/
│   ├── <service>/            reusable shape: variables.tf, <service>.tf, outputs.tf, versions.tf
│   └── ...
└── <env>/                    the environment's dedicated directory
    ├── <service>/            thin root: main.tf (module call), terraform.tfvars,
    │                          <service>_gcs_backend.tf, gcp_provider.tf (symlink), readme.md
    └── ...
```

Each `<env>/<service>/` directory is its own state (its own GCS backend prefix),
so a change to one service in one environment never widens the blast radius to
another service or another environment.

## Provider & auth

[`service/gcp_provider.tf`](./gcp_provider.tf) is the single provider/version
definition for the whole Service Layer, soft-linked into every environment-root
directory. Identity is resolved at runtime by Application Default Credentials — no
service-account email or key is pinned in any `*.tf` file.

## Apps

| App | Description |
| --- | --- |
| [`yamato/`](./yamato/) | Star Blazers fact wiki — Cloud Run (Go) + Cloud SQL Postgres, behind an IAP-gated external HTTPS load balancer |

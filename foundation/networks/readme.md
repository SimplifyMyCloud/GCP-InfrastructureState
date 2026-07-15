# Foundation Layer — GCP Networks

The VPCs, subnets, and Private Service Access plumbing that every cloud service in this org runs on top of. Each project gets its own VPC (one project, one VPC) — no Shared VPC, no host/service split.

For the broader design philosophy — hardcoded values, state granularity, and change-control posture — see [`../../docs/infrastructurestate.md`](../../docs/infrastructurestate.md).

## Discipline

This layer creates **per-project networks only**. The VPC and its supporting plumbing (subnet, PSA range, service-networking peering) live here. APIs needed by network resources (`compute`, `servicenetworking`) are enabled here too — same rule as everywhere in foundation: each state enables only the APIs it actually uses.

What goes here: `google_compute_network`, `google_compute_subnetwork`, `google_compute_global_address` (PSA ranges), `google_service_networking_connection`, plus the two `google_project_service` resources for the APIs above.

What does **not** go here: Cloud NAT / Cloud Router (deferred — only created when a workload actually needs egress IP control), firewall rules (deferred — added when there's a workload to firewall, currently nothing in dev needs them), Serverless VPC Access connectors (Service Layer — these are Cloud-Run-specific), Cloud SQL / Cloud Run / GKE clusters / anything else (Service Layer or Application Layer).

## Layout

One directory per app, one Terraform state per VPC. Each app's network tree mirrors the project tree at `foundation/gcp-projects/{app}/`.

```
foundation/networks/
├── readme.md                  (this file)
└── yamato/                    (Star Blazers ships/characters/planets codex)
    ├── readme.md
    ├── dev/                   (state #1 — iq9-vpc-dev-yamato)
    ├── test/                  (pending)
    ├── stage/                 (pending)
    └── prod/                  (pending — will likely revisit Shared VPC at prod scale)
```

## Currently managed

| App | VPCs |
| --- | --- |
| [`yamato/`](./yamato/) | `dev` (live), `test`/`stage`/`prod` pending |

## Adding a new app

The shape is identical for every app:

```
foundation/networks/{app}/
├── readme.md                                    (app overview, env status, CIDR plan)
└── {env}/
    ├── networks_{app}_{env}.tf              (APIs + VPC + subnet + PSA + peering)
    ├── networks_{app}_{env}_gcs_backend.tf  (prefix: foundation/networks/{app}/{env}/)
    ├── gcp_provider.tf                          (symlink to repo-root)
    └── readme.md
```

Network constants across every app/env: VPC is custom-mode (`auto_create_subnetworks = false`), routing is `REGIONAL`, subnet has `private_ip_google_access = true`, default routes are preserved, peering `deletion_policy = "ABANDON"`. CIDR ranges are non-overlapping across environments within an app so future inter-env VPC peering stays an option.

## Apply order

`foundation/networks/{app}/{env}/` depends on `foundation/gcp-projects/{app}/{env}/` having been applied first (the project must exist before TF can enable APIs and create resources in it). Beyond that, network states are independent of each other — `yamato/dev/` and a hypothetical second app's network can apply in any order.

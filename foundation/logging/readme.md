# Foundation Layer — Logging

The org-wide **cold log archive**: every log the organization emits, captured raw
into cheap GCS ARCHIVE buckets, partitioned by category. Comprehensive, dumb, cheap.

This is **deliberately separate from observability**. Live debugging, dashboards,
metrics, and per-app querying live elsewhere — each project's `_Default` bucket and
the Service Layer's own logging (see `service/yamato/dev/logging/` for this app).
This layer never diverts or suppresses those; it only mirrors to immutable archive.

## Layering

- **Foundation (here):** org-wide, captures **everything** raw into cheap archive.
- **Service layer (per app):** custom performance + security logging, owned by each
  app's dev/SRE team.

## Two states

| State | Owns | Apply order |
| --- | --- | --- |
| [`log-warehouse/`](./log-warehouse/) | `iq9-log-warehouse-01` project + three ARCHIVE buckets (`iq9-log-audit`, `iq9-log-security`, `iq9-log-archive`) | **1st** |
| [`log-sinks/`](./log-sinks/) | Three org-level aggregated sinks (one per bucket) + their writer-identity IAM grants | **2nd** |

Warehouse first — the sink state's bucket IAM bindings reference the buckets by name.

## Categories (partitioned — union = everything, no overlap)

| Bucket | Captures |
| --- | --- |
| `iq9-log-audit` | Admin Activity + System Event (the change/admin trail) |
| `iq9-log-security` | Data Access + Policy Denied + Access Transparency |
| `iq9-log-archive` | Everything else (app/infra/general catch-all) |

## Design decisions (2026-05-20)

- **Destination:** GCS ARCHIVE only — retention, not querying.
- **Retention:** 365-day lifecycle delete on all three buckets.
- **Scope:** capture everything org-wide, partitioned into the three categories.
- **Data Access audit logs:** left at GCP defaults org-wide (Admin Activity is always
  on; Data Access stays off). Per-app teams opt in for their own project if needed —
  yamato does, in its Service Layer.

## Required permissions

Applying `log-sinks` needs, at the **organization** scope (`933250405420`):
`roles/logging.configWriter` + `roles/resourcemanager.organizationViewer`.

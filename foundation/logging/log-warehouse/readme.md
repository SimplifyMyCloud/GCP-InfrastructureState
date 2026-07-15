# Foundation Layer — Logging — Log Warehouse

The destinations for the org-wide log sinks: one project holding three GCS ARCHIVE
buckets. Apply this **before** [`../log-sinks/`](../log-sinks/).

## What this state owns

- `google_project.log_warehouse` — `iq9-log-warehouse-01`, parented to the `logs`
  folder (`473370836814`), `deletion_policy = PREVENT`, `auto_create_network = false`.
- `google_project_service.storage` — `storage.googleapis.com`.
- Three buckets, all `ARCHIVE` / `us-west1` / uniform bucket-level access / public
  access prevention enforced / `force_destroy = false` / 365-day lifecycle delete:

  | Bucket | Category |
  | --- | --- |
  | `iq9-log-audit` | admin/system change trail |
  | `iq9-log-security` | access / denial / data-access |
  | `iq9-log-archive` | everything else (catch-all) |

A dedicated project keeps the archive's IAM surface isolated, and `deletion_policy =
PREVENT` guards the whole thing.

## Hardcoded values

| Field | Value |
| --- | --- |
| `project_id` | `iq9-log-warehouse-01` |
| `folder_id` | `473370836814` (the `logs` folder) |
| `billing_account` | `000000-000002-6D3BF8` |
| bucket `location` | `us-west1` |
| `storage_class` | `ARCHIVE` |
| lifecycle `age` | `365` |

## First-time setup

```bash
cd foundation/logging/log-warehouse/
terraform init
terraform plan    # project, storage API, 3 buckets
terraform apply
```

Then apply [`../log-sinks/`](../log-sinks/).

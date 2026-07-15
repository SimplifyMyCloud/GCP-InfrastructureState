# Foundation Layer — Logging — Org Log Sinks

Three organization-level aggregated sinks that copy logs from every project in the
org into the cold-archive buckets created by [`../log-warehouse/`](../log-warehouse/).
Apply this **after** the warehouse.

## What this state owns

Three `google_logging_organization_sink` (org `933250405420`, `include_children`,
`unique_writer_identity`) + a `google_storage_bucket_iam_member` per sink granting
its writer identity `roles/storage.objectCreator` on the destination bucket (without
which a sink delivers nothing):

| Sink | Filter | Destination |
| --- | --- | --- |
| `iq9-org-sink-audit` | `activity` + `system_event` | `iq9-log-audit` |
| `iq9-org-sink-security` | `data_access` + `policy` + `access_transparency` | `iq9-log-security` |
| `iq9-org-sink-archive` | `NOT` (any of the above) | `iq9-log-archive` |

The filters are mutually exclusive, so the three together capture **everything** with
no duplication and no gaps.

## Required org-level permissions

The applying identity needs, at the **organization** scope (`933250405420`):
`roles/logging.configWriter` and `roles/resourcemanager.organizationViewer`.

## First-time setup

```bash
# Apply ../log-warehouse/ first so the buckets exist.
cd foundation/logging/log-sinks/
terraform init
terraform plan    # 3 org sinks + 3 bucket IAM members
terraform apply
```

Verify a sink and its writer identity:

```bash
gcloud logging sinks describe iq9-org-sink-audit \
  --organization=933250405420 \
  --format='value(name, destination, writerIdentity)'
```

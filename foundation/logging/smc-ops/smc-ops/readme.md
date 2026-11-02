<!-- hand-written -->
# logging / smc-ops / smc-ops

Log buckets and project log sinks inside the **smc-ops** project.

| | |
| --- | --- |
| Terraform state | `gs://smc-ops-tf-state/terraform/state/foundation/logging/smc-ops/smc-ops/default.tfstate` |
| Imported | 2026-11-01, 4 resources, zero-diff plan |

## Log flow

```
smc-dev folder (all projects)  ── smc-dev-env-log-sink ──►  smc-dev-env-logging   us-west1 · 3 days · Log Analytics
smc-ops project                ── _Required sink ────────►  _Required bucket      400 days · locked by Google
                               └─ _Default sink ─────────►  _Default bucket       30 days
```

The `smc-dev-env-log-sink` sink itself is owned by `logging/smc-dev/`. Its permission to write here is in [`iam/smc-ops/smc-ops/`](../../../iam/smc-ops/smc-ops/).

## What's in here

| File | Owns |
| --- | --- |
| `logging_smc_ops.tf` | `smc-dev-env-logging` bucket, `_Default` bucket config, `_Default` + `_Required` sinks |
| `logging_smc_ops_gcs_backend.tf` | this directory's state location |
| `gcp_provider.tf` | symlink to the repo-root `gcp_provider.tf` |

`_Default`/`_Required` are Google's built-in sinks and buckets. They carry `prevent_destroy` so a stray `terraform destroy` can't break project logging. The `_Required` *bucket* is locked by Google and can't be managed, so only its sink is here.

## Findings (imported as-is, fix later)

- `smc-dev-env-logging` keeps the whole smc-dev folder's logs for **3 days**. That's too short for incident review.

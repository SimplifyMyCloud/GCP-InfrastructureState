<!-- hand-written -->
# foundation/logging

Where logs go. `logging/gcp-org/` and `logging/<env>/` hold org- and folder-level sinks; `logging/<env>/<project>/` holds each project's log buckets and sinks. Google's built-in `_Default` / `_Required` sinks are imported with `prevent_destroy` so git shows the whole flow.

Custom routing (both added or changed 2026-11-02):

```
every folder + project ── smc-org-log-archive (org sink, no filter) ──► gs://smc-ops-log-archive   Archive class · 365 days · GCS files
smc-dev folder         ── smc-dev-env-log-sink (folder sink) ───────► smc-dev-env-logging      30 days · Log Analytics (searchable)
each project           ── built-in _Required / _Default ─────────────► its own buckets          400 / 30 days
```

Neither custom sink intercepts, so every project still keeps its own `_Required`/`_Default` copies. Search recent logs in each project's Logs Explorer (or `smc-dev-env-logging` for dev); the archive is the long-term record, read by downloading objects.

State for any directory below: `gs://smc-ops-tf-state/terraform/state/foundation/logging/<same path>/default.tfstate`.

| Directory | Terraform for |
| --- | --- |
| [`smc-prod/`](smc-prod/) | the `smc-prod` folder itself |
| [`smc-ops/`](smc-ops/) | the `smc-ops` folder itself |
| [`smc-dev/`](smc-dev/) | the `smc-dev` folder itself |
| [`gcp-org/`](gcp-org/) | the Org |
| [`smc-dev/simplifymycloud-dev/`](smc-dev/simplifymycloud-dev/) | project `simplifymycloud-dev` |
| [`smc-ops/smc-ops/`](smc-ops/smc-ops/) | project `smc-ops` |
| [`smc-prod/smc-dental-knox/`](smc-prod/smc-dental-knox/) | project `smc-dental-knox` |
| [`smc-prod/smc-prod-bbmrc/`](smc-prod/smc-prod-bbmrc/) | project `smc-prod-bbmrc` |
| [`smc-prod/smc-prod-bigbarkozspeedshop/`](smc-prod/smc-prod-bigbarkozspeedshop/) | project `smc-prod-bigbarkozspeedshop` |
| [`smc-prod/smc-prod-caballerosflyingclub/`](smc-prod/smc-prod-caballerosflyingclub/) | project `smc-prod-caballerosflyingclub` |
| [`smc-prod/smc-prod-madeinwestgermany/`](smc-prod/smc-prod-madeinwestgermany/) | project `smc-prod-madeinwestgermany` |
| [`smc-prod/smc-prod-olympic-flying-club/`](smc-prod/smc-prod-olympic-flying-club/) | project `smc-prod-olympic-flying-club` |
| [`smc-prod/smc-prod-psmtherapy/`](smc-prod/smc-prod-psmtherapy/) | project `smc-prod-psmtherapy` |
| [`smc-prod/smc-prod-simplifymycloud/`](smc-prod/smc-prod-simplifymycloud/) | project `smc-prod-simplifymycloud` |
| [`smc-prod/smc-prod-trilliumhiring/`](smc-prod/smc-prod-trilliumhiring/) | project `smc-prod-trilliumhiring` |

Back to the [Foundation guide](../readme.md).

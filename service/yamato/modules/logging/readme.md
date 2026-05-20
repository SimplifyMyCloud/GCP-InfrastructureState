# Service Layer — module: logging

The per-app **performance + security logging** for yamato. This is Service-Layer,
app-owned observability — distinct from the Foundation `logging` layer, which is the
org-wide cold archive. Reusable shape; instantiated per environment from a thin root
(e.g. `service/yamato/dev/logging/`).

## What it builds

**Performance**
- Log-based metric `yamato/app_errors` (ERROR-severity app logs).
- Alert policies: Cloud Run **p95 latency**, Cloud Run **5xx rate**, Cloud SQL **CPU**,
  and **app error volume** — all to one email channel.
- A Cloud Monitoring **dashboard**: request rate by class, p95 latency, SQL CPU, and
  the security metrics.

**Layers of security logging**
1. **Data Access audit logs** enabled on the app project for `cloudsql` +
   `secretmanager` (foundation leaves these off org-wide; the app opts in).
2. A dedicated **Log Analytics bucket** (`yamato-app-logs`) + sink capturing the
   app's Cloud Run, load-balancer, and data-access logs — queryable, app-scoped
   retention.
3. Log-based metrics + alerts: `yamato/secret_access` (AccessSecretVersion spikes)
   and `yamato/iap_denied` (front-door 403s).

## Inputs

See `variables.tf`. Required: `project_id`, `run_service_name`, `sql_instance_name`,
`notification_email`. Thresholds (`latency_threshold_ms`, `error_5xx_threshold`,
`sql_cpu_threshold`, `app_error_threshold`, `secret_access_threshold`) and
`app_log_retention_days` have sensible defaults — **tune after first traffic**.

## Notes / caveats

- Alert filters and thresholds are best-effort defaults; run `terraform plan` and
  validate against real metric streams, then tune.
- `yamato/iap_denied` counts LB 403s as a proxy for IAP denials.
- `yamato/secret_access` depends on Data Access audit logs (enabled here).
- The app-log sink's writer identity is granted `roles/logging.bucketWriter` at the
  project to deliver into the Log Analytics bucket.

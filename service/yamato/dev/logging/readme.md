# Service Layer — yamato / dev / logging

The dev environment's **performance + security logging** for the yamato app —
app-owned observability, separate from the Foundation org-wide cold archive. Thin
root that instantiates [`../../modules/logging`](../../modules/logging/) with dev values.

## What this state owns

Via the module: Data Access audit config (Cloud SQL + Secret Manager), a dedicated
`yamato-app-logs` Log Analytics bucket + sink, log-based metrics (`yamato/app_errors`,
`yamato/secret_access`, `yamato/iap_denied`), five alert policies (p95 latency, 5xx
rate, Cloud SQL CPU, app errors, secret-access spike), an email notification channel,
and a Monitoring dashboard.

## Values (`terraform.tfvars`)

| Variable | Value |
| --- | --- |
| `project_id` | `iq9-gcp-dev-yamato` |
| `region` | `us-west1` |
| `run_service_name` | `iq9-run-dev-yamato` |
| `sql_instance_name` | `yamato-dev` |
| `notification_email` | `chris@simplifymy.cloud` |

## Apply

Apply **after** `cloudrun`, `cloudsql`, and `frontdoor` exist (the metrics/alerts
reference the Cloud Run service, Cloud SQL instance, and LB).

```bash
cd service/yamato/dev/logging/
terraform init
terraform plan    # validate the alert filters/thresholds against real metric streams
terraform apply
```

Thresholds default to sensible dev values — tune in the module variables after the
first real traffic. Confirm the email notification channel (Google sends a
verification email to `chris@simplifymy.cloud`).

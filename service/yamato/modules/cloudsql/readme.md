# Module — cloudsql

**Focus:** a Postgres instance reachable only over private IP, its application
database and user, and the user's generated password stored in Secret Manager.

**Desired state**
- `sqladmin.googleapis.com` and `secretmanager.googleapis.com` enabled (`disable_on_destroy = false`).
- `google_sql_database_instance` — **private IP only** (`ipv4_enabled = false`),
  attached to the given VPC via the PSA peering (created by the Foundation network
  state). Defaults: Postgres 16, `db-f1-micro`, ZONAL, SSD with autoresize, daily
  backups (PITR off), deletion protection on.
- `google_sql_database` (the app DB) and `google_sql_user` (built-in/password auth).
- `random_password` → `google_secret_manager_secret` + version. This module does
  **not** grant secret access; the consumer (Cloud Run) grants its own SA.

## Inputs (key)

| Variable | Required | Purpose |
| --- | --- | --- |
| `project_id`, `region` | yes | Where the instance lives |
| `network_id` | yes | Full URI of the VPC for private IP |
| `instance_name` | yes | Deterministic instance name (no random suffix; ~7-day reuse caveat) |
| `password_secret_id` | yes | Secret Manager secret ID for the password |
| `database_name`, `db_user` | no | Default `yamato` / `yamato_app` |
| `database_version`, `tier`, `edition`, `availability_type`, `disk_*`, `backup_start_time`, `deletion_protection`, `labels` | no | Sizing/posture overrides |

## Outputs

`instance_name`, `connection_name` (`project:region:instance`), `private_ip_address`,
`database_name`, `db_user`, `password_secret_id`.

Consumed by [`../../dev/cloudsql/`](../../dev/cloudsql/).

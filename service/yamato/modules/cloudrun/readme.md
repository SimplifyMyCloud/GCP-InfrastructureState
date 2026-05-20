# Module — cloudrun

**Focus:** a Cloud Run service that runs the app, its dedicated least-privilege
runtime service account, and the Serverless VPC Access connector that lets it
reach Cloud SQL over private IP.

**Desired state**
- `run.googleapis.com` and `vpcaccess.googleapis.com` enabled (`disable_on_destroy = false`).
- `google_vpc_access_connector` on a /28 outside the workload subnet.
- `google_service_account` (runtime identity) granted `roles/cloudsql.client`
  (project) and `roles/secretmanager.secretAccessor` on the DB password secret.
- `google_cloud_run_v2_service` — ingress locked to the LB
  (`INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER`), connector egress
  `PRIVATE_RANGES_ONLY`, DB params as env vars and `DB_PASS` from Secret Manager.
  `container_image` defaults to `cloudrun/hello` until the real image exists.
- `run.invoker` for `invoker_members` (default `allUsers` — safe because ingress
  is LB-only and IAP enforces identity at the front door).

## Inputs (key)

| Variable | Required | Purpose |
| --- | --- | --- |
| `project_id`, `region` | yes | Where the service/connector live |
| `network_name`, `connector_name`, `connector_cidr` | yes | The connector into the VPC |
| `service_name`, `service_account_id` | yes | Service + runtime SA names |
| `container_image` | no | Image to run (placeholder default) |
| `db_connection_name`, `db_name`, `db_user`, `password_secret_id` | yes | DB wiring |
| `ingress`, `vpc_egress`, `min/max_instances`, `cpu/memory_limit`, `deletion_protection`, `invoker_members`, `labels` | no | Posture/sizing overrides |

## Outputs

`service_name`, `service_uri` (LB-only), `runtime_service_account_email`, `connector_id`.

Consumed by [`../../dev/cloudrun/`](../../dev/cloudrun/).

# Module — cloudrun

**Focus:** two Cloud Run services that run the same app image — a public one and an
IAP-gated one — plus their shared, least-privilege runtime service account. Both
reach Cloud SQL over private IP via **Direct VPC egress**.

**Desired state**
- `google_service_account` (shared runtime identity) granted `roles/cloudsql.client`
  (project) and `roles/secretmanager.secretAccessor` on the DB password secret.
- `google_cloud_run_v2_service` **×2** — `this` (public, `var.service_name`) and
  `wiki` (IAP-gated, `var.wiki_service_name`). Identical config: ingress locked to
  the LB (`INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER`), Direct VPC egress onto
  `var.subnet_name` with `vpc_egress` `PRIVATE_RANGES_ONLY`, DB params as env vars
  and `DB_PASS` from Secret Manager.
- `run.invoker` for `invoker_members` (default `allUsers`) on **each** service —
  safe because ingress is LB-only and IAP enforces identity at the front door.

**Two services, not one:** IAP enabled on an LB backend attaches to the underlying
Cloud Run *service*, so a single shared service leaks IAP onto the public path.
Separate services scope IAP to the wiki only. (Root readme has the full story.)

**Direct VPC egress, not a connector:** the services attach straight to the app
subnet — no Serverless VPC Access connector, which is incompatible with the enforced
`compute.requireOsLogin` org policy.

**App owns the image:** each service carries
`lifecycle { ignore_changes = [template[0].containers[0].image] }`, so
`container_image` only seeds the first create and Terraform never reverts an App-Layer
deploy. See [`docs/infrastructurestate.md`](../../../../docs/infrastructurestate.md).

> APIs (`run`, `vpcaccess`) are enabled by the foundation project state, not here.

## Inputs (key)

| Variable | Required | Purpose |
| --- | --- | --- |
| `project_id`, `region` | yes | Where the services live |
| `network_name`, `subnet_name` | yes | The app VPC + subnet for Direct VPC egress |
| `service_name`, `wiki_service_name` | yes | Public + IAP-gated service names |
| `service_account_id` | yes | Runtime SA local part |
| `container_image` | no | Seeds first create only (placeholder default) |
| `db_connection_name`, `db_name`, `db_user`, `password_secret_id` | yes | DB wiring |
| `ingress`, `vpc_egress`, `min/max_instances`, `cpu/memory_limit`, `deletion_protection`, `invoker_members`, `labels` | no | Posture/sizing overrides |

## Outputs

`service_name` (public), `wiki_service_name` (IAP-gated), `service_uri` (LB-only),
`runtime_service_account_email`.

Consumed by [`../../dev/cloudrun/`](../../dev/cloudrun/).

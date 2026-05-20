# Service Layer — yamato / dev / cloudrun

The Cloud Run service that runs the yamato wiki in dev, its runtime service
account, and the Serverless VPC Access connector that bridges it to Cloud SQL.

## What this state owns

- `run.googleapis.com` and `vpcaccess.googleapis.com` enabled on `iq9-gcp-dev-yamato`.
- `google_vpc_access_connector` `iq9-conn-dev-yamato` on `10.10.16.0/28` (the /28 the
  network state reserved, outside the workload subnet).
- `google_service_account` `iq9-yamato-dev-run` — the runtime identity, granted
  `roles/cloudsql.client` (project) and `roles/secretmanager.secretAccessor` on
  the DB password secret.
- `google_cloud_run_v2_service` `iq9-run-dev-yamato` — ingress locked to the LB,
  egress PRIVATE_RANGES_ONLY through the connector, DB params as env vars and
  `DB_PASS` injected from Secret Manager.
- `run.invoker` for `allUsers` (see security note).

## Variables (`terraform.tfvars`)

| Variable | Value |
| --- | --- |
| `project_id` | `iq9-gcp-dev-yamato` |
| `network_name` | `iq9-vpc-dev-yamato` |
| `connector_name` / `connector_cidr` | `iq9-conn-dev-yamato` / `10.10.16.0/28` |
| `service_name` | `iq9-run-dev-yamato` |
| `service_account_id` | `iq9-yamato-dev-run` |
| `container_image` | `cloudrun/hello` placeholder → flip to the AR image |
| `db_connection_name` | `iq9-gcp-dev-yamato:us-west1:yamato-dev` |
| `db_name` / `db_user` | `yamato` / `yamato_app` |
| `password_secret_id` | `yamato-dev-db-password` |

## The placeholder image (chicken-and-egg)

Cloud Run needs an image, but the app is built *after* the infra. So
`container_image` defaults to GCP's `cloudrun/hello`. The service stands up and is
reachable through the front door immediately. Once the App Layer image is built
and pushed to Artifact Registry, change `container_image` to:

```
us-west1-docker.pkg.dev/iq9-gcp-dev-yamato/yamato/yamato:<tag>
```

and re-apply — that's the only change needed to go live.

## How the app reaches the database

The container gets `INSTANCE_CONNECTION_NAME`, `DB_NAME`, `DB_USER`, and `DB_PASS`
(from Secret Manager). The Go app uses the Cloud SQL connector over the **private**
path: traffic to Cloud SQL's private IP is pulled into the VPC by the connector
(egress PRIVATE_RANGES_ONLY), while public egress goes direct.

## Security note — `run.invoker = allUsers`

`ingress = INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER` means the `*.run.app` URL is
**not** publicly reachable — only the external HTTPS LB can route to the service.
IAP at the LB enforces identity (`@iq9.io` only). So `allUsers` on `run.invoker`
does not expose the app; it just lets the LB invoke it. If org policy
(`iam.allowedPolicyMemberDomains`) forbids `allUsers`, set `invoker_members` to a
narrower principal.

## Prerequisites & order

1. [`../cloudsql/`](../cloudsql/) applied (provides the DB, secret, connection name).
2. The Foundation network state (provides the VPC and the reserved /28).

```bash
cd service/yamato/dev/cloudrun/
terraform init
terraform plan
terraform apply
```

## What comes next

[`../frontdoor/`](../frontdoor/) puts the external HTTPS LB + IAP in front of this
service and routes the public landing page vs the IAP-gated wiki.

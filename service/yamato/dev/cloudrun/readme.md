# Service Layer — yamato / dev / cloudrun

The two Cloud Run services that run the yamato wiki in dev — a public one and an
IAP-gated one — their shared least-privilege runtime service account, and the
Direct VPC egress that bridges them to Cloud SQL over private IP.

## What this state owns

- `google_service_account` `iq9-yamato-dev-run` — the shared runtime identity,
  granted `roles/cloudsql.client` (project) and `roles/secretmanager.secretAccessor`
  on the DB password secret. Nothing else today; the live NOC dashboard at
  `/wiki/noc` adds a need for `roles/logging.viewer` and `roles/monitoring.viewer`
  on this SA — see [`docs/noc.md`](../../../../docs/noc.md) for the rationale and
  the module path the bindings belong on.
- `google_cloud_run_v2_service` `iq9-run-dev-yamato` — the **public** service
  (serves `/`, `/static/*`, `/healthz`).
- `google_cloud_run_v2_service` `iq9-run-dev-yamato-wiki` — the **IAP-gated**
  service (serves `/wiki`, `/wiki/*`).
- `run.invoker` for `allUsers` on **each** service (see security note).

Both services run the **same image**, with the same env wiring, same runtime SA,
and the same Direct VPC egress. Ingress on both is locked to the LB.

> APIs (`run`, `vpcaccess`) are **not** enabled here — they're owned by the
> foundation project state, [`foundation/gcp-projects/yamato/dev/`](../../../../foundation/gcp-projects/yamato/dev/).
> In a hardened split-identity model the Service-Layer Terraform SA has no
> api-enable permission; the Service Layer assumes the APIs are already on.

## Why two services, not one

IAP is enabled per LB **backend**, but it attaches to the underlying Cloud Run
**service**, not to the URL path. A single service shared by a public backend and
an IAP backend therefore leaks IAP onto the public path — intermittent ~70% `403`s
at the Google front end, *not* logged by the LB. Splitting into two services scopes
IAP cleanly to the wiki service (`/wiki`) and leaves the public service open. This
was confirmed the hard way; don't collapse them back into one.

## How the app reaches the database — Direct VPC egress

Each service attaches **directly to the app subnet** (`network_interfaces` on the
`vpc_access` block) with egress `PRIVATE_RANGES_ONLY`: only RFC1918 traffic (Cloud
SQL's private IP) is pulled into the VPC, while public egress goes direct. This
replaces the old Serverless VPC Access **connector**, which is incompatible with
the enforced `compute.requireOsLogin` org policy (the connector's managed instances
fail to come up). The container gets `INSTANCE_CONNECTION_NAME`, `DB_NAME`,
`DB_USER`, and `DB_PASS` (from Secret Manager) and dials Cloud SQL with the Go
connector over the private path.

## Variables (`terraform.tfvars`)

| Variable | Value |
| --- | --- |
| `project_id` | `iq9-gcp-dev-yamato` |
| `region` | `us-west1` |
| `network_name` / `subnet_name` | `iq9-vpc-dev-yamato` / `iq9-subnet-dev-yamato` |
| `service_name` | `iq9-run-dev-yamato` (public) |
| `wiki_service_name` | `iq9-run-dev-yamato-wiki` (IAP-gated) |
| `service_account_id` | `iq9-yamato-dev-run` |
| `container_image` | seeds first create only — see deploy note below |
| `db_connection_name` | `iq9-gcp-dev-yamato:us-west1:yamato-dev` |
| `db_name` / `db_user` | `yamato` / `yamato_app` |
| `password_secret_id` | `yamato-dev-db-password` |

## App versions deploy via gcloud — never Terraform

Both services carry `lifecycle { ignore_changes = [template[0].containers[0].image] }`.
Terraform manages everything about the services **except** the running image:
`container_image` only seeds the first create (defaults to GCP's `cloudrun/hello`
so the service stands up before the App Layer exists). After that, the App Layer is
the sole authority over app versions:

```bash
# build + push (Cloud Build)
gcloud builds submit app/yamato --project=iq9-gcp-dev-yamato \
  --config=app/yamato/cloudbuild.yaml
# roll BOTH services (App-Layer action, not Terraform)
gcloud run services update iq9-run-dev-yamato      --project=iq9-gcp-dev-yamato --region=us-west1 --image=<img>
gcloud run services update iq9-run-dev-yamato-wiki --project=iq9-gcp-dev-yamato --region=us-west1 --image=<img>
```

A later `terraform apply` here will **not** revert those deploys. This is the
deliberate Service-Layer / App-Layer wall — see
[`docs/infrastructurestate.md`](../../../../docs/infrastructurestate.md).

## Security note — `run.invoker = allUsers`

`ingress = INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER` means the `*.run.app` URLs are
**not** publicly reachable — only the external HTTPS LB can route to the services.
IAP at the LB enforces identity (`@iq9.io` only) on the wiki service. So `allUsers`
on `run.invoker` does not expose the apps; it just lets the LB invoke them. If org
policy (`iam.allowedPolicyMemberDomains`) forbids `allUsers`, set `invoker_members`
to a narrower principal.

## Prerequisites & order

1. [`../cloudsql/`](../cloudsql/) applied (provides the DB, secret, connection name).
2. The Foundation network state (provides the VPC + app subnet).
3. The Foundation project state (APIs already enabled).

```bash
cd service/yamato/dev/cloudrun/
terraform init
terraform plan
terraform apply
```

## What comes next

[`../frontdoor/`](../frontdoor/) puts the external HTTPS LB + IAP in front of these
services: two serverless NEGs (one per service), public landing vs IAP-gated wiki.

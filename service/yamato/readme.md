# Service Layer — yamato

The Service Layer for **yamato**, a wiki of facts from the *Star Blazers* anime
(aka Space Battleship Yamato). A small Go web app reads from Cloud SQL Postgres
and is served from Cloud Run, fronted by an external HTTPS load balancer with
Identity-Aware Proxy (IAP). A public, Star Blazers-themed landing page is open to
everyone; the wiki itself is gated by IAP to `@iq9.io` identities only.

The Go application code lives in the **App Layer** (not managed by Terraform). This
tree provisions only the GCP services the app runs on.

For the layer/structure conventions, see [`service/readme.md`](../readme.md). For
design philosophy, see [`docs/infrastructurestate.md`](../../docs/infrastructurestate.md).

## Foundation this builds on

yamato's Foundation Layer is already provisioned:

- Project `iq9-gcp-dev-yamato` — [`foundation/gcp-projects/yamato/dev/`](../../foundation/gcp-projects/yamato/dev/)
- VPC `iq9-vpc-dev-yamato`, subnet `10.10.0.0/20`, PSA range `10.20.0.0/20` peered to
  `servicenetworking` — [`foundation/gcp-networks/yamato/dev/`](../../foundation/gcp-networks/yamato/dev/)

This Service Layer consumes those by name. It does **not** modify them. Two address
ranges are pre-reserved by the network state for this layer to consume:

| Range | Consumed by |
| --- | --- |
| `10.20.0.0/20` (PSA) | Cloud SQL private IP |
| `10.10.16.0/28` | Serverless VPC Access connector (Cloud Run → VPC) |

## Services

| State | Owns |
| --- | --- |
| [`dev/artifact-registry/`](./dev/artifact-registry/) | Docker repo for the app image; Artifact Registry + Cloud Build APIs |
| [`dev/cloudsql/`](./dev/cloudsql/) | Postgres instance (private IP), database, app user, password in Secret Manager |
| [`dev/cloudrun/`](./dev/cloudrun/) | Serverless VPC connector, runtime SA, the Cloud Run service |
| [`dev/frontdoor/`](./dev/frontdoor/) | External HTTPS LB, managed cert, IAP, public landing + IAP-gated wiki routing |

`modules/` holds the reusable shape for each of the above; `dev/` is the dev
environment's dedicated roots. `test/`, `stage/`, and `prod/` will be added as
sibling directories under `service/yamato/` when those environments activate.

## Build order

Infrastructure is laid down first, the app second (per the project's build plan):

1. `dev/artifact-registry/` — so an image has somewhere to be pushed.
2. `dev/cloudsql/` — the database and its Secret Manager secret.
3. `dev/cloudrun/` — the connector, runtime SA, and the service. The container
   image is a **variable** with a placeholder default (`cloudrun/hello`) so the
   service stands up before the real app exists.
4. `dev/frontdoor/` — the LB + IAP front door.
5. App Layer: build the Go app, push the image to Artifact Registry, then flip the
   Cloud Run `container_image` variable to the real image.

## Conventions in every `dev/<service>/` root

- `main.tf` — instantiates `../../modules/<service>` with dev values
- `terraform.tfvars` — the dev environment's variable values (auto-loaded)
- `<service>_gcs_backend.tf` — state at `gs://iq9-iac-ops-tf-state-bucket/terraform/state/service/yamato/dev/<service>/`
- `gcp_provider.tf` — symlink to [`service/gcp_provider.tf`](../gcp_provider.tf)
- `readme.md` — what the state owns, hardcoded-vs-variable values, setup steps

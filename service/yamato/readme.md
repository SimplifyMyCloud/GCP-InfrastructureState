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
  `servicenetworking` — [`foundation/networks/yamato/dev/`](../../foundation/networks/yamato/dev/)

This Service Layer consumes those by name. It does **not** modify them.

| Range | Consumed by |
| --- | --- |
| `10.20.0.0/20` (PSA) | Cloud SQL private IP |
| subnet `10.10.0.0/20` | Cloud Run **Direct VPC egress** (services attach straight to the app subnet) |

> Cloud Run uses **Direct VPC egress** onto the app subnet — *not* a Serverless VPC
> Access connector, which is incompatible with the enforced `compute.requireOsLogin`
> org policy. The `10.10.16.0/28` the network state once reserved for a connector is
> no longer consumed.

## Services

| State | Owns |
| --- | --- |
| [`dev/artifact-registry/`](./dev/artifact-registry/) | Docker repo for the app image |
| [`dev/cloudsql/`](./dev/cloudsql/) | Postgres instance (private IP), database, app user, password in Secret Manager |
| [`dev/cloudrun/`](./dev/cloudrun/) | Two Cloud Run services (public + IAP-gated wiki), shared runtime SA, Direct VPC egress |
| [`dev/frontdoor/`](./dev/frontdoor/) | External HTTPS LB, managed cert, IAP; two NEGs → two services (public landing + IAP-gated wiki) |
| [`dev/logging/`](./dev/logging/) | Per-app performance + security logging: log-based metrics, alert policies, dashboard |

`modules/` holds the reusable shape for each of the above; `dev/` is the dev
environment's dedicated roots. `test/`, `stage/`, and `prod/` will be added as
sibling directories under `service/yamato/` when those environments activate.

## Build order

Infrastructure is laid down first, the app second (per the project's build plan):

1. `dev/artifact-registry/` — so an image has somewhere to be pushed.
2. `dev/cloudsql/` — the database and its Secret Manager secret.
3. `dev/cloudrun/` — the runtime SA and the two services (public + IAP wiki), on
   Direct VPC egress. The container image is a **variable** with a placeholder
   default (`cloudrun/hello`) so the services stand up before the real app exists;
   it only seeds the first create (see step 5).
4. `dev/frontdoor/` — the LB + IAP front door (two NEGs → the two services).
5. App Layer: build the Go app, push to Artifact Registry, then `gcloud run services
   update` **both** services onto the new image. The cloudrun state ignores the
   running image (`lifecycle ignore_changes`), so this is a pure App-Layer deploy —
   Terraform never reverts it. (`dev/logging/` can be applied any time after step 3.)

## Conventions in every `dev/<service>/` root

- `main.tf` — instantiates `../../modules/<service>` with dev values
- `terraform.tfvars` — the dev environment's variable values (auto-loaded)
- `<service>_gcs_backend.tf` — state at `gs://iq9-iac-ops-tf-state-bucket/terraform/state/service/yamato/dev/<service>/`
- `gcp_provider.tf` — symlink to [`service/gcp_provider.tf`](../gcp_provider.tf)
- `readme.md` — what the state owns, hardcoded-vs-variable values, setup steps

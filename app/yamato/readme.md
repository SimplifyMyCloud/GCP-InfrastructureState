# yamato — Application Layer

The Star Blazers wiki: a small Go web app served from Cloud Run, backed by the
private Cloud SQL Postgres instance. This is the **Application Layer** — it is
*not* Terraform. The infrastructure it runs on lives in `service/yamato/dev/`
(Cloud Run, Cloud SQL, Artifact Registry, the LB + IAP front door) and
`foundation/` (project + network).

## The front-door contract

The load balancer in `service/yamato/dev/frontdoor` splits one Cloud Run service
across two backends on the same serverless NEG:

| Path             | Backend | IAP        | Served by this app          |
|------------------|---------|------------|-----------------------------|
| `/`              | public  | no         | Star Blazers landing page   |
| `/static/*`      | public  | no         | CSS / theme assets          |
| `/healthz`       | public  | no         | DB-aware health check       |
| `/wiki`, `/wiki/*` | wiki  | **yes**    | wiki index + articles       |

**The app must keep all protected content under `/wiki`** — IAP only covers that
prefix. Anything outside it is public. The app itself does no auth; IAP at the LB
enforces `domain:iq9.io`. Under `/wiki` the app reads the IAP-asserted identity
from the `X-Goog-Authenticated-User-Email` header only to greet the user.

## Database

Connection comes entirely from env vars injected by the Cloud Run module:

| Env                        | Value (dev)                                  |
|----------------------------|----------------------------------------------|
| `INSTANCE_CONNECTION_NAME` | `iq9-gcp-dev-yamato:us-west1:yamato-dev`     |
| `DB_NAME`                  | `yamato`                                     |
| `DB_USER`                  | `yamato_app`                                 |
| `DB_PASS`                  | from Secret Manager `yamato-dev-db-password` |

The instance is **private-IP only**, so the app dials it through the Cloud SQL Go
connector with `WithPrivateIP()` (authorized by the runtime SA's
`roles/cloudsql.client`), not a public address. Because there is no convenient
out-of-band path to a private instance, the app is its own migrator:
`schema.sql` is embedded and applied idempotently on every startup. The seed uses
`ON CONFLICT DO UPDATE`, so `schema.sql` is the source of truth for article
content — redeploying refreshes it.

## Layout

```
main.go        server bootstrap + graceful shutdown
app.go         app struct, embeds (templates/static/schema), routing
db.go          Cloud SQL connector pool, schema apply, article queries
handlers.go    landing / wiki index / article / health, IAP identity
schema.sql     DDL + Star Blazers seed (embedded)
templates/     html/template pages (auto-escaped)
static/        style.css (space theme)
Dockerfile     multi-stage -> distroless static, nonroot
cloudbuild.yaml build + push to Artifact Registry
```

## Build & deploy

1. **Build + push the image** (Cloud Build):
   ```
   gcloud builds submit app/yamato \
     --project=iq9-gcp-dev-yamato \
     --config=app/yamato/cloudbuild.yaml
   ```
   Pushes `us-west1-docker.pkg.dev/iq9-gcp-dev-yamato/yamato/yamato:latest`
   (override the tag with `--substitutions=_TAG=v1`).

2. **Flip the Cloud Run image**: in
   `service/yamato/dev/cloudrun/terraform.tfvars`, change `container_image` off
   the `hello` placeholder to the pushed image, then re-apply the cloudrun state.

The infra must be applied first (artifact-registry → cloudsql → cloudrun →
frontdoor) so the Artifact Registry repo exists to receive the push.

## Local notes

`go build` / `go vet` work anywhere. The app cannot fully run locally without a
reachable Postgres (it requires the DB env and connects on startup); template and
rendering logic are pure and verifiable on the host.

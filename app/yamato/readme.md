# yamato — Application Layer

The Star Blazers wiki: a small Go web app served from Cloud Run, backed by the
private Cloud SQL Postgres instance. This is the **Application Layer** — it is
*not* Terraform. The infrastructure it runs on lives in `service/yamato/dev/`
(Cloud Run, Cloud SQL, Artifact Registry, the LB + IAP front door) and
`foundation/` (project + network).

## The front-door contract

The load balancer in `service/yamato/dev/frontdoor` routes to **two separate Cloud
Run services running this same image** — a public one and an IAP-gated one. (Two
services, not one: IAP enabled on a backend attaches to the underlying Cloud Run
*service*, so a single shared service would leak IAP onto the public path. See
that state's readme for the full story.)

| Path             | Backend | IAP        | Served by this app          |
|------------------|---------|------------|-----------------------------|
| `/`              | public service | no         | Star Blazers landing page   |
| `/static/*`      | public service | no         | CSS / theme / images        |
| `/healthz`       | public service | no         | DB-aware health check       |
| `/wiki`, `/wiki/*` | wiki service | **yes**    | wiki index + articles       |
| `/wiki/search`   | wiki service | **yes**    | full-text search (see [`docs/search.md`](../../docs/search.md)) |

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
db.go          Cloud SQL connector pool, schema apply, article queries,
               full-text search (plainto_tsquery + ts_rank + ts_headline)
handlers.go    landing / wiki index / article / search / health, IAP identity
schema.sql     DDL + Star Blazers seed (embedded); also the `tsv` column,
               GIN index, and trigger that power /wiki/search
templates/     html/template pages (auto-escaped) — includes search.html
static/        style.css (Star Blazers theme); img/ drop-in art (hero ship +
               crew avatars) with graceful fallbacks — see static/img/README.md
Dockerfile     multi-stage -> distroless static, nonroot
cloudbuild.yaml build + push to Artifact Registry
```

The landing page references `static/img/yamato.png` (hero) and
`static/img/crew/<slug>.jpg` (avatars). Both **fall back gracefully** — the hero to
an inline SVG battleship, each avatar to an initials badge — so the page looks
complete even with no images present. Drop in art you have the rights to (licensed
or owned); the built-in placeholders are original. Details in
[`static/img/README.md`](static/img/README.md).

## Build & deploy

1. **Build + push the image** (Cloud Build):
   ```
   gcloud builds submit app/yamato \
     --project=iq9-gcp-dev-yamato \
     --config=app/yamato/cloudbuild.yaml
   ```
   Pushes `us-west1-docker.pkg.dev/iq9-gcp-dev-yamato/yamato/yamato:latest`
   (override the tag with `--substitutions=_TAG=v1`).

2. **Roll both Cloud Run services onto the new image** — this is an App-Layer
   action, **not** Terraform:
   ```
   gcloud run services update iq9-run-dev-yamato \
     --project=iq9-gcp-dev-yamato --region=us-west1 \
     --image=us-west1-docker.pkg.dev/iq9-gcp-dev-yamato/yamato/yamato:latest
   gcloud run services update iq9-run-dev-yamato-wiki \
     --project=iq9-gcp-dev-yamato --region=us-west1 \
     --image=us-west1-docker.pkg.dev/iq9-gcp-dev-yamato/yamato/yamato:latest
   ```
   Both the public service and the IAP-gated wiki service run this image, so both
   get the roll. Each `update` cuts a new revision at 100% traffic.

**Why no Terraform here:** the cloudrun state pins
`lifecycle { ignore_changes = [...image] }` on both services, so Terraform never
touches the running version — `gcloud` (or CI) is the sole authority over app
deploys. The `container_image` variable only seeds the first create. This is the
deliberate Service-Layer / App-Layer wall; see
[`docs/infrastructurestate.md`](../../docs/infrastructurestate.md).

The infra must be applied first (artifact-registry → cloudsql → cloudrun →
frontdoor) so the Artifact Registry repo exists to receive the push.

## Local notes

`go build` / `go vet` work anywhere. The app cannot fully run locally without a
reachable Postgres (it requires the DB env and connects on startup); template and
rendering logic are pure and verifiable on the host.

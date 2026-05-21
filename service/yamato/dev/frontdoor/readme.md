# Service Layer — yamato / dev / frontdoor

The public front door: a global external Application Load Balancer that serves the
public Star Blazers landing page and gates the wiki behind Identity-Aware Proxy.

## What this state owns

- Global external IP `iq9-dev-yamato-ip` and managed SSL cert for `yamato-dev.iq9.io`.
  (`iap.googleapis.com` is enabled by the foundation project state, not here.)
- **Two** serverless NEGs, one per Cloud Run service:
  - `iq9-dev-yamato-neg-public` → `iq9-run-dev-yamato` (public).
  - `iq9-dev-yamato-wiki-neg` → `iq9-run-dev-yamato-wiki` (IAP-gated).
- Two backend services, each on its own NEG:
  - `iq9-dev-yamato-be-public` — **no IAP**, the default route (landing page).
  - `iq9-dev-yamato-be-wiki` — **IAP on**, the `/wiki` path.
- IAP enabled on the wiki backend with the **Google-managed OAuth client** (no
  brand/client resources — those depend on the IAP OAuth Admin API deprecated
  after July 2025), and `roles/iap.httpsResourceAccessor` granted to
  **`domain:iq9.io`** — only @iq9.io identities can log in.
- URL map, HTTPS proxy, port-443 forwarding rule, and a port-80 → HTTPS redirect.

## How the two surfaces work

```
yamato-dev.iq9.io/            → public backend (no IAP) → public NEG → public service  "/"
yamato-dev.iq9.io/wiki, /wiki/* → wiki backend  (IAP)   → wiki NEG   → wiki service    "/wiki/*"
```

Each backend routes to its **own** Cloud Run service through its own NEG. This split
is deliberate: IAP enabled on a backend attaches to the underlying Cloud Run
*service*, not to the URL path — so if both backends shared one service, IAP would
leak onto the public path (intermittent ~70% `403`s at the Google front end, not
logged by the LB). Two services scope IAP cleanly to `/wiki`. Clicking the landing
page's login button navigates to `/wiki`, which triggers the Google sign-in; only
`@iq9.io` users pass.

> **App contract:** the Cloud Run app must serve public content (landing, theme
> assets) at paths **outside** `/wiki`, and **all** protected content under
> `/wiki`. IAP only covers the `/wiki` prefix.

## Variables (`terraform.tfvars`)

| Variable | Value |
| --- | --- |
| `project_id` | `iq9-gcp-dev-yamato` |
| `name_prefix` | `iq9-dev-yamato` |
| `domain` | `yamato-dev.iq9.io` |
| `cloud_run_service_name` | `iq9-run-dev-yamato` (public NEG target) |
| `wiki_service_name` | `iq9-run-dev-yamato-wiki` (wiki NEG target) |
| `iap_members` | `["domain:iq9.io", "domain:simplifymy.cloud"]` |
| `iap_enabled` | `true` |

IAP uses the Google-managed OAuth client, so no support email / consent-screen
config is needed in Terraform. Setting `iap_enabled = false` removes IAP and its IAM
bindings (handy for isolating the public path during debugging).

## DNS is NOT managed here

`iq9.io` is not in this repo's Terraform. After `apply`, read the `load_balancer_ip`
output and create the A record wherever iq9.io is hosted:

```
yamato-dev.iq9.io.  A  <load_balancer_ip>
```

The managed certificate stays `PROVISIONING` until that record resolves to the LB
IP, then flips to `ACTIVE` (can take 15–60 min). Watch it:

```bash
gcloud compute ssl-certificates describe iq9-dev-yamato-cert \
  --project=iq9-gcp-dev-yamato --global \
  --format='value(managed.status)'
```

## Prerequisites & order

[`../cloudrun/`](../cloudrun/) must be applied first (the NEG targets that service).

```bash
cd service/yamato/dev/frontdoor/
terraform init
terraform plan
terraform apply
# then create the A record and wait for the cert to go ACTIVE
```

## Notes / decisions made

- **Public landing via the same Cloud Run app**, not a public GCS bucket — the org
  enforces public-access-prevention on buckets, so a second backend on the same
  service is the cleaner way to get a public surface.
- **One host, path-based routing** (`/wiki` gated) rather than two subdomains —
  keeps a single managed certificate and one A record.

Both are reasonable defaults; redirect here if you'd prefer a GCS landing or a
`wiki.` subdomain split.

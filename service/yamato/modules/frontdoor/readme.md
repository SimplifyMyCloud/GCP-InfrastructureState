# Module — frontdoor

**Focus:** a global external Application Load Balancer that fronts **two** Cloud Run
services, serving a public landing page and gating the wiki behind Identity-Aware
Proxy (IAP).

**Desired state**
- Global external IP + managed SSL certificate for `var.domain`.
  (`iap.googleapis.com` is enabled by the foundation project state, not here.)
- **Two serverless NEGs:** one → `var.cloud_run_service_name` (public), one →
  `var.wiki_service_name` (IAP-gated).
- **Two backend services, one per NEG:** `public` (no IAP, default route) and
  `wiki` (IAP on, the `var.wiki_path_prefix` route). Two services rather than one
  because IAP attaches to the underlying Cloud Run *service*; a shared service would
  leak IAP onto the public path. IAP uses the **Google-managed OAuth client**
  (`iap { enabled = var.iap_enabled }`) — not the deprecated
  `google_iap_brand`/`google_iap_client`.
- `roles/iap.httpsResourceAccessor` granted to `var.iap_members` (default `domain:iq9.io`).
- URL map (default → public, `/wiki*` → wiki), HTTPS target proxy, port-443
  forwarding rule, and an optional port-80 → HTTPS redirect.

> **App contract:** the Cloud Run app must serve public content outside
> `var.wiki_path_prefix` and all protected content under it — IAP only covers
> that prefix.

> **DNS:** not managed here. After apply, point `var.domain` at the
> `load_balancer_ip` output; the cert provisions once DNS resolves.

## Inputs (key)

| Variable | Required | Purpose |
| --- | --- | --- |
| `project_id`, `region` | yes | Project + Cloud Run region |
| `name_prefix` | yes | Prefix for all front-door resource names |
| `domain` | yes | Hostname for the managed cert |
| `cloud_run_service_name` | yes | Public service (public NEG target) |
| `wiki_service_name` | yes | IAP-gated service (wiki NEG target) |
| `wiki_path_prefix`, `iap_members`, `iap_enabled`, `enable_http_redirect` | no | Routing/access/redirect overrides |

## Outputs

`load_balancer_ip`, `managed_certificate_name`.

Consumed by [`../../dev/frontdoor/`](../../dev/frontdoor/).

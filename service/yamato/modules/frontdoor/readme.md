# Module — frontdoor

**Focus:** a global external Application Load Balancer that fronts a Cloud Run
service, serving a public landing page and gating the rest behind Identity-Aware
Proxy (IAP).

**Desired state**
- `iap.googleapis.com` enabled (`disable_on_destroy = false`).
- Global external IP + managed SSL certificate for `var.domain`.
- One serverless NEG → the Cloud Run service.
- **Two backend services on that one NEG:** `public` (no IAP, default route) and
  `wiki` (IAP on, the `var.wiki_path_prefix` route). IAP uses the **Google-managed
  OAuth client** (`iap { enabled = true }`) — not the deprecated
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
| `cloud_run_service_name` | yes | Service both backends route to |
| `wiki_path_prefix`, `iap_members`, `enable_http_redirect` | no | Routing/access/redirect overrides |

## Outputs

`load_balancer_ip`, `managed_certificate_name`.

Consumed by [`../../dev/frontdoor/`](../../dev/frontdoor/).

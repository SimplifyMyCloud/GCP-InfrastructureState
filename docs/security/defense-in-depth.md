# Defense in Depth — the layered vault

[← Security index](./readme.md)

IAP ([zero-trust-iap.md](./zero-trust-iap.md)) is the front door, but a door is not a vault.
The vault is the **stack of independent layers** below — every one of which an attacker must
defeat, in order, to reach anything of value. None of them do. This doc walks each layer:
what it is, what it stops, and exactly where it lives in this repo.

The attacker's path runs top to bottom; each layer is a wall.

```
                 Gamilas (internet)
                        │
   ┌────────────────────▼─────────────────────┐
   │ 1. Cloud Armor   — OWASP WAF + rate limit │  edge: blocks injection/scan payloads
   ├──────────────────────────────────────────┤
   │ 2. IAP           — identity at the LB     │  302 to Google login; no valid id, no app
   ├──────────────────────────────────────────┤
   │ 3. Locked ingress— LB-only to Cloud Run   │  run.app not public; no bypassing 1 & 2
   ├──────────────────────────────────────────┤
   │ 4. Least-priv SA — runtime identity       │  app can do almost nothing if owned
   ├──────────────────────────────────────────┤
   │ 5. Private SQL   — no public DB IP        │  DB unreachable except via the app's VPC path
   ├──────────────────────────────────────────┤
   │ 6. Secret Manager— no creds in image/env  │  DB password never on disk; scoped accessor
   ├──────────────────────────────────────────┤
   │ 7. Org policy    — guardrails             │  no SA keys, OS Login, no default-SA editor
   ├──────────────────────────────────────────┤
   │ 8. Logging+alerts— total visibility       │  every probe captured, alerted, archived
   └──────────────────────────────────────────┘
```

---

## 1. Cloud Armor — the edge WAF

**What:** a Cloud Armor security policy (`iq9-dev-yamato-armor`) attached to **both**
backend services, in **enforce** mode. Eight OWASP preconfigured WAF rules
(sqli, xss, lfi, rfi, rce, scanner-detection, protocol-attack, session-fixation) → `deny(403)`,
plus a per-source-IP **rate-limit ban** for the scan flood, plus Adaptive Protection (L7
DDoS). `log_level = VERBOSE`, so every block records the matched rule.

**Stops:** sqlmap/dalfox/nikto/nuclei payloads at the edge — *before* IAP, before the app.

**Lives in:** [service/yamato/modules/frontdoor/frontdoor.tf](../../service/yamato/modules/frontdoor/frontdoor.tf)
(`google_compute_security_policy.edge`), toggles in
[dev/frontdoor/terraform.tfvars](../../service/yamato/dev/frontdoor/terraform.tfvars).

> **Ordering gotcha (worth a slide):** Cloud Armor is **first-match-wins** by ascending
> priority. The catch-all rate-limit rule (match = all IPs) must sit at a *higher* priority
> number than the WAF deny rules (1000–1007), or it short-circuits every request to its
> "allow" conform-action and the WAF never runs. Ours is at 2000 — WAF first, rate-limit
> after, default-allow last.

## 2. IAP — identity at the load balancer

**What:** Identity-Aware Proxy on the wiki backend (Google-managed OAuth), allow-listed to
`domain:iq9.io` + `domain:simplifymy.cloud`. The URL map routes `/wiki*` and `/noc*` to
this IAP backend; everything else is the public landing.

**Stops:** any unauthenticated access to protected paths — the `302`. Full model in
[zero-trust-iap.md](./zero-trust-iap.md).

**Lives in:** [frontdoor.tf](../../service/yamato/modules/frontdoor/frontdoor.tf)
(`iap { enabled = true }` + `google_iap_web_backend_service_iam_member`).

## 3. Locked ingress — the LB is the only way in

**What:** both Cloud Run services run with `ingress = internal-and-cloud-load-balancing`.
The `*.run.app` URLs are not publicly routable.

**Stops:** the bypass — an attacker cannot skip Cloud Armor + IAP by hitting the Cloud Run
URL directly. Layers 1 and 2 are unskippable because of this layer.

**Lives in:** [service/yamato/modules/cloudrun/cloudrun.tf](../../service/yamato/modules/cloudrun/cloudrun.tf).

## 4. Least-privilege runtime service account

**What:** a dedicated runtime SA for the Cloud Run services holding **only**
`roles/cloudsql.client` and accessor on **one** secret. Nothing else — no project roles, no
`actAs`, no `setIamPolicy`.

**Stops:** the blast radius of an app compromise or a stolen runtime token. Even if an
attacker fully owns the running container (or lifts its metadata token), the identity they
inherit can open a DB connection and read one secret — and that's the entire universe of
what they can do. This is what makes [Act 2](./red-team-playbook.md) a dead end.

**Lives in:** [cloudrun.tf](../../service/yamato/modules/cloudrun/cloudrun.tf)
(`google_service_account.runtime` + its two narrow bindings).

## 5. Private-IP Cloud SQL

**What:** Postgres with **private IP only**, reached over Private Service Access peering;
the app connects via **Direct VPC egress** onto the app subnet. No public IP exists.

**Stops:** direct database attack. From the internet (or the attacker's box) the DB simply
isn't routable — a connection attempt just times out. SQLi is already blocked at layer 1,
and even a hypothetical query runs as the least-priv DB user.

**Lives in:** [service/yamato/dev/cloudsql](../../service/yamato/dev/cloudsql/) +
PSA range in [foundation/networks/yamato/dev](../../foundation/networks/yamato/dev/).

## 6. Secret Manager — no credentials on disk

**What:** the DB password lives in Secret Manager, injected to the container as a secret
env var at runtime; the accessor binding is scoped to the runtime SA only. The password is
never baked into the image, the Terraform, or plain env.

**Stops:** credential theft from the image/repo/state, and over-broad secret access. Access
to the secret is itself audit-logged (layer 8) and feeds the `secret_access` metric/alert.

**Lives in:** [cloudsql](../../service/yamato/dev/cloudsql/) (secret) +
[cloudrun.tf](../../service/yamato/modules/cloudrun/cloudrun.tf) (scoped accessor).

## 7. Org policy — the guardrails

Org-wide constraints that close whole classes of attack by default:

| Org policy | Effect |
| --- | --- |
| `iam.disableServiceAccountKeyCreation` | No exportable SA keys exist anywhere — auth is always short-lived tokens. Kills the "leaked key" path at the root. |
| `compute.requireOsLogin` | SSH to VMs is gated by IAM/OS Login, not static keys. |
| `iam.automaticIamGrantsForDefaultServiceAccounts` | (Default-enforced for orgs created ≥ 2024-05-03) the Compute default SA is **not** auto-granted Editor — no god-mode default identity. |
| `compute.vmExternalIpAccess` (inherited) | Constrains which VMs may have public IPs. |

**Lives in:** enforced org-wide; the auth/identity model is documented in
[gcp_provider.tf](../../gcp_provider.tf). These are why the bakery build VMs run with no
public IP (egress via Cloud NAT, SSH via IAP) — see
[foundation/networks/bakery](../../foundation/networks/bakery/).

## 8. Logging, metrics, alerting — total visibility

**What:** every layer above is *observed*:

- **Data Access audit logs** on Cloud SQL + Secret Manager (the app project opts itself in).
- **Log-based metrics:** `app_errors`, `secret_access`, `iap_denied`, `cloud_armor_blocked`,
  `denied_api_calls`, `sa_token_mints`, `sa_key_create_attempts`.
- **Two dashboards:** performance & security, and the **attack-view** board.
- **Alert policies → email** on every security signal (Armor blocks, denied API calls, SA
  token mints, secret-access spikes, …).
- A dedicated **Log Analytics bucket** for app-scoped, queryable retention.

**Plus the org-wide cold-archive sink** ([foundation/logging](../../foundation/logging/)):
GCS-only, **365-day** retention of audit + security logs for the *entire org* — immutable
and out of reach of anything the attacker can touch in the project. They cannot scrub what
they cannot reach.

**Lives in:** [service/yamato/dev/logging](../../service/yamato/dev/logging/) (per-app) +
[foundation/logging](../../foundation/logging/) (org sink). Surfaced on the
[NOC](./readme.md#the-noc).

---

## The point

An attacker doesn't face *a* wall — they face **eight**, in series, each independent. To
reach the database they'd have to beat Cloud Armor **and** IAP **and** find the locked-away
backend **and** escalate a least-privilege identity **and** route to a private-only DB
**and** pull a scoped secret **and** evade org-policy guardrails — all while every step is
logged, alerted, and archived. That's the vault.

## See also

- [zero-trust-iap.md](./zero-trust-iap.md) — the front door (layers 2–3) in depth
- [red-team-playbook.md](./red-team-playbook.md) — watching the layers hold, live

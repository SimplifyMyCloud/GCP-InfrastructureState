# Red-Team Playbook — the Gamilas demo

[← Security index](./readme.md)

This is the script for proving the [Fort Knox claim](./readme.md#the-one-claim-made-un-hecklable)
live: we play the **Gamilas Empire**, throw a real red-team arsenal at the Yamato, and watch
GCP stop, log, and alert on every move. Two acts, one per half of the claim.

The attacker is a baked image — see
[foundation/gce-bakery/gamilas-redteam](../../foundation/gce-bakery/gamilas-redteam/) for the
Packer recipe (nmap, ZAP, nuclei, sqlmap, ScoutSuite, Prowler, the GCP IAM-privesc set, …)
and the two profile scripts. Watch it all on the [NOC](./readme.md#the-noc) and the
**attack-view dashboard**.

> **Authorized testing only.** This runs against infrastructure we own. The profile scripts
> refuse to run without `AUTHORIZED=yes` and an explicit `TARGET_HOST`.

## Setup (before the demo)

1. Confirm Cloud Armor is in **enforce** and the WAF rules fire (sensitivity may need to be
   above 1 — verify a hand payload returns `403`). See
   [defense-in-depth.md §1](./defense-in-depth.md#1-cloud-armor--the-edge-waf).
2. Project the **NOC** (`/noc`) and the **attack-view dashboard** on the wall. They sit flat.
3. Deploy a gamilas VM (DigitalOcean droplet for the external vantage; a GCP VM for the
   insider/metadata vantage).

## Act 1 — Unauthenticated external attacker (no creds)

> _Proves: nobody penetrates IAP._

Run from the DigitalOcean droplet (true "outside GCP"):

```bash
export AUTHORIZED=yes TARGET_HOST=yamato-dev.iq9.io
/opt/gamilas/profiles/unauth-scan.sh
```

| Gamilas move | GCP wall | Where it shows on the NOC |
| --- | --- | --- |
| Port/service scan (nmap) | Only 443 answers; no public VM/DB IPs | LB request logs |
| Directory/content brute (ffuf/feroxbuster) | Public path is a static page; nothing to find | Cloud Armor blocks / 4xx |
| SQLi / XSS payloads (sqlmap/dalfox) | **Cloud Armor WAF → `403`**, by named rule | Cloud Armor blocks |
| Scanner sweep (nikto/nuclei) | Scanner-detection rule + the scan flood **rate-limit ban** | Cloud Armor blocks |
| Hit `/wiki` or `/noc` | **IAP → `302`** to Google login, before the app | Front-door 403s |

**The beat:** the attacker can *see* everything (it's on the internet) and gets *nowhere*.
The dashboard's "Cloud Armor blocks" and "front-door denials" tiles light up; the email
alerts fire. Nothing reaches the app.

## Act 2 — Insider with stolen credentials

> _Proves: a stolen key is worthless._

The only way "past" IAP is a valid identity, so we hand the attacker one — a phished
`@iq9.io` session and/or a leaked token — and let them loose from a GCP VM:

```bash
export AUTHORIZED=yes TARGET_HOST=yamato-dev.iq9.io
export STOLEN_IAP_COOKIE='GCP_IAAP_AUTH_TOKEN=...'   # optional phished session
export STOLEN_SA_KEY=/path/to/leaked-sa.json         # optional leaked key
/opt/gamilas/profiles/authed-scan.sh
```

| Gamilas move | GCP wall | Where it shows on the NOC |
| --- | --- | --- |
| Reuse phished wiki session | Valid session grants app **read** only — zero infra rights | (IAP logs) |
| SQL-inject the wiki app | Parameterized queries; runtime SA = `cloudsql.client` only | Denied API calls / app logs |
| Connect to the DB directly | **Private-IP Cloud SQL** — unroutable; connection times out | (VPC flow logs) |
| Steal token from the metadata server | Token inherits **only** the least-priv SA's roles | — (then every use below is logged) |
| Use a leaked SA key | Org policy **disables SA key creation** — keyless by design | Denied API calls |
| Enumerate (ScoutSuite/Prowler/gcp_scanner) | Recon is itself audited — every list/get is an event | Denied API calls + audit logs |
| **Service-account takeover** (actAs / setIamPolicy) | Least privilege + org policy → every escalation refused | **Denied API calls**, **SA token mints** |
| Bucket brute (GCPBucketBrute) | Buckets private, uniform access, no `allUsers` | Data-access audit logs |

**The beat:** the attacker is a *legitimate authenticated identity* — and still hits a wall
at every turn. The blast radius is one read-only DB role. Meanwhile the "denied API calls"
and "SA token mints" tiles spike and the alerts land in `chris@simplifymy.cloud`.

## The closing slide

Everything both acts generated flows to:

- **Per-app detection** — log-based metrics, alert policies, and the dashboards in
  [service/yamato/dev/logging](../../service/yamato/dev/logging/) (alerts fire on the attack).
- **Org-wide capture** — the immutable **cold-archive sink**
  ([foundation/logging](../../foundation/logging/)): GCS-only, 365-day retention of audit +
  security logs for the whole org. The Gamilas can't scrub what they can't reach.

> Find-everything, break-nothing. IAP can't be broken; a stolen key is worthless; and the
> entire assault was logged, alerted, and archived. **The Yamato holds.**

## See also

- [readme.md](./readme.md) — the claim and the layer map
- [zero-trust-iap.md](./zero-trust-iap.md) — why Act 1 ends at the `302`
- [defense-in-depth.md](./defense-in-depth.md) — the walls Act 2 keeps hitting
- [gamilas-redteam recipe](../../foundation/gce-bakery/gamilas-redteam/) — the attacker toolkit + profiles

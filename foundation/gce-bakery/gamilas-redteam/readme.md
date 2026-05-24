# gamilas-redteam — the attacker's box

> The **Gamilas Empire** lays siege to the **Yamato**. They bring every weapon a real red
> team brings against a webapp. They get nowhere — and GCP records every shot. **The
> defense begins.**

This recipe bakes **one** Ubuntu 22.04 attacker image, **two ways**:

- a **GCP image** (`googlecompute`) — the "insider already on GCP" vantage, and the box
  that can rob its own metadata server in Profile 2; and
- a **DigitalOcean snapshot** (`digitalocean`) — the "cold external attacker from outside
  GCP" vantage for Profile 1.

Same base, same scripts → identical toolset on both clouds. You then deploy it and run two
attack **profiles** against the yamato wiki, narrating each GCP control as it stops the
attack and logs it. It is a presentation engine for GCP defense-in-depth.

---

## What's on the box

| Tier | Tools |
| --- | --- |
| Recon (`10`) | nmap, masscan, naabu, dnsrecon, dnsx, subfinder, amass, httpx, whatweb, testssl.sh |
| Web app (`20`) | OWASP ZAP, nikto, nuclei (+templates), sqlmap, dalfox, wfuzz, ffuf, feroxbuster, gobuster, dirb, wpscan |
| GCP / cloud (`30`) | google-cloud-cli, ScoutSuite, Prowler, Google `gcp_scanner`, Rhino GCP-IAM-Privilege-Escalation, GCPBucketBrute, postgresql-client |
| Creds / wordlists (`40`) | hydra, medusa, john, hashcat, SecLists, rockyou |

Provisioner order is `00-base → 10 → 20 → 30 → 40 → (stage profiles) → 99-cleanup`.

---

## Build

```bash
cd foundation/gce-bakery/gamilas-redteam
packer init .
packer fmt .
packer validate -var "gcp_project_id=iq9-gcp-ops-01" .

# Build BOTH clouds (DO token via env, never committed):
export PKR_VAR_do_api_token=dop_v1_xxxxx
packer build -var "gcp_project_id=iq9-gcp-ops-01" .

# …or just one cloud:
packer build -only="gamilas-redteam.googlecompute.gamilas"  -var "gcp_project_id=iq9-gcp-ops-01" .
packer build -only="gamilas-redteam.digitalocean.gamilas"  .   # needs PKR_VAR_do_api_token
```

Artifacts: a private GCE image `iq9-img-gamilas-redteam-<ts>` (family `iq9-redteam`) and a
DO snapshot of the same name. IDs are written to `manifest.json`.

> **OS Login note:** this org enforces `compute.requireOsLogin`. Keep `gcp_use_os_login=true`
> (default) and build as a principal with `roles/compute.osAdminLogin` +
> `roles/iam.serviceAccountUser`, **or** bake in a project where the policy is relaxed for
> the bakery. The DO build is unaffected (root login).

---

## Deploy the demo VMs

- **DigitalOcean (external attacker):** create a droplet from the snapshot
  (`doctl compute droplet create gamilas --image <snapshot-id> --region fra1 --size s-2vcpu-4gb`).
- **GCP (insider attacker):** Service-Layer Terraform (or `gcloud compute instances create
  gamilas --image-family iq9-redteam`). To exercise the metadata-theft beat in Profile 2,
  attach a service account so there's a token to steal — ideally a **least-privilege** one,
  which is the whole point.

---

## Run the two profiles

Both are staged on the image at `/opt/gamilas/profiles/`. Both **refuse to run** without
`AUTHORIZED=yes` + a `TARGET_HOST` — a deliberate seatbelt for an authorized-testing tool.

```bash
export AUTHORIZED=yes TARGET_HOST=yamato-dev.iq9.io

# Profile 1 — unauthenticated external attacker (run from the DO droplet):
/opt/gamilas/profiles/unauth-scan.sh

# Profile 2 — stolen-credential insider (run from the GCP VM):
export STOLEN_IAP_COOKIE='GCP_IAAP_AUTH_TOKEN=...'   # optional phished session
export STOLEN_SA_KEY=/home/packer/leaked-sa.json     # optional leaked key
/opt/gamilas/profiles/authed-scan.sh
```

Each run drops timestamped evidence (tool output + a narrated `run.log`) in
`/var/log/gamilas/<profile>-<ts>/` — your presentation exhibit.

---

## The presentation: attack → GCP defense → where it's logged

This is the story the profiles tell on screen. Map it to the yamato infra in
[`service/yamato/dev/`](../../../service/yamato/dev/) and the Foundation controls.

### Profile 1 — unauthenticated (only the rock-solid static page is reachable)

| Gamilas attack | GCP wall that stops it | Where it's captured |
| --- | --- | --- |
| Port/service scan | No public IPs on Cloud Run or Cloud SQL; only the global HTTPS LB answers (443) | LB request logs → Cloud Logging |
| TLS downgrade / strip | Google-managed cert, modern TLS only | LB / SSL policy logs |
| Directory & content brute | Public `/` is a **static** page; nothing to find | Cloud Armor + LB request logs (and rate-limit on the noise) |
| Hit the `/wiki` app | **IAP** returns 302 → Google login *before* Cloud Run is reached | IAP / LB logs |
| nikto / nuclei / ZAP | Minimal static attack surface by design | LB request logs |

### Profile 2 — stolen credentials (insider kill-chain)

| Gamilas attack | GCP wall that stops it | Where it's captured |
| --- | --- | --- |
| Reuse phished wiki session | IAP validates server-side; a valid session grants app **read** only, **zero** infra rights | IAP logs |
| SQL injection on wiki | Parameterised queries; runtime SA holds only `roles/cloudsql.client` | App logs + Cloud SQL logs |
| Connect to the DB directly | Cloud SQL is **private-IP only**, reachable solely via Direct VPC egress from the app SA — connect times out | VPC Flow Logs |
| Read the DB password | Password is in **Secret Manager**, not the image; accessor scoped to the runtime SA | Secret Manager audit logs |
| Steal token from metadata server | Token inherits **only** the attached SA's (least-privilege) roles | — (then every use below is logged) |
| Leaked SA key | Org policy `iam.disableServiceAccountKeyCreation` kills key creation at the root | Org policy + IAM audit logs |
| Enumerate with gcp_scanner / ScoutSuite | Recon itself is audited — every list/get is an event | Cloud Audit Logs → **org cold-archive sink** |
| Service-account **takeover** (actAs / setIamPolicy / deploy-as) | Least privilege + org IAM constraints slam every escalation door; blast radius = one DB role | IAM audit logs + per-app **alert policies** |
| GCS bucket brute | Buckets are private, uniform bucket-level access, no `allUsers` | Data-access audit logs |
| Online brute-force at `/wiki` | IAP = Google login + MFA, no app password to guess; Cloud Armor rate-limits | IAP + Cloud Armor logs |

### The closing slide

Everything above flows to:

- **Per-app detection** — log-based metrics, **alert policies**, and a dashboard in
  [`service/yamato/dev/logging/`](../../../service/yamato/dev/) (alerts fire on the attack).
- **Org-wide capture** — the immutable **cold-archive log sink**
  ([`foundation/logging/`](../../../foundation/logging/)): GCS-only, **365-day** retention,
  audit + security logs for the whole org. The Gamilas can't scrub what they can't reach.

> Foothold → full compromise was blocked at **every** layer — IAP at the door, private-IP
> DB, secrets out of band, least-privilege SAs, org policies on escalation — and the entire
> assault was **logged, alerted, and archived**. The Yamato holds.

---

## Authorization & safety

This image and these scripts are for testing **infrastructure you own or are explicitly
engaged to test**. The profiles enforce `AUTHORIZED=yes` + an explicit `TARGET_HOST`, default
to the yamato dev host, and write a full evidence trail. Do not point them at third-party
systems. Tear down the demo VMs (and DO snapshot, if temporary) when the presentation is
done; the GCP image is a long-lived, labelled, auditable Foundation artifact.

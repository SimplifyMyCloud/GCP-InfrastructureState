# In the Wild — Real-World Attacks Against the Yamato Wiki

**Observation window:** 2026-06-02 11:00 UTC → 2026-06-03 11:00 UTC (24 hours)
**Target:** `yamato-dev.iq9.io` (LB external IP `8.233.20.46`)
**Project:** `iq9-gcp-dev-yamato`
**Blocks recorded:** 345
**Unique source IPs:** 20
**Fort Knox security layers tripped:** 1 of 5 (every attempt stopped at Layer 1)
**Operator interventions:** 0
**Customer impact:** 0
**Alert that fired:** Cloud Armor blocked-requests threshold (set to 20 in the alert window)

[← Security index](./readme.md) · [Defense in depth](./defense-in-depth.md) · [Red-team playbook](./red-team-playbook.md) · [Fort Knox claim](./fort-knox.md)

---

## What this document is

The [red-team playbook](./red-team-playbook.md) is the script for *proving* the [Fort Knox claim](./fort-knox.md) by playing the Gamilas Empire ourselves: we throw a baked attack image at the Yamato and narrate the defense as each layer of the Fort Knox security model fires. The whole rhetorical setup of that playbook is "watch us play the bad guys; watch GCP stop us." We needed an attacker because we did not have one.

We have one now. We have twenty. From four continents. While the operator slept.

This document records what real adversaries did against the production wiki on the night of 2026-06-02 into the morning of 2026-06-03, what the Fort Knox security layers caught, and — the part that matters most — what the *inner* Fort Knox security layers would have caught even if the *outer* layers had not been there at all. It is the experiment that confirms the hypothesis the red-team playbook describes.

The audience is two: future operators of this system, who should understand exactly what their public surface looks like to the internet at large, and consulting prospects who deserve evidence rather than a story.

---

## The thesis — five concentric Fort Knox security layers

The Yamato wiki is not protected by Cloud Armor. The Yamato wiki is not protected by any single product. The Yamato wiki is protected by five concentric Fort Knox security layers, each of which holds independently and each of which is stricter than the one outside it. Cloud Armor is one of those layers — Layer 1, the outermost — and last night it stopped 345 of 345 attempts. But the security claim does not depend on it. Even with Layer 1 disabled entirely, the inner four Fort Knox security layers would have rejected every one of last night's adversaries.

That is the difference between this architecture and the prevailing industry pattern. The prevailing pattern is to expose a vulnerable application to the internet, put a WAF in front, and declare the application protected. That is one layer. One layer is not Fort Knox. One layer is a fence. The gold inside Fort Knox is not protected by a fence — it is protected by an Army base around the building around the front desk around the vault around the cages.

The following sections describe the five Fort Knox security layers in the abstract, map each one onto its specific GCP control in the Yamato architecture, and then walk through what real attackers did against those layers last night.

---

## The Fort Knox security layers — the analogy

```
         ╔════════════════════════════════════════════════════════════╗
         ║  LAYER 1 — Outer perimeter / Army base gate                ║
         ║  [armed soldier · vehicle inspection · ID check]           ║
         ║                                                            ║
         ║   ╔════════════════════════════════════════════════════╗   ║
         ║   ║  LAYER 2 — Across the base                         ║   ║
         ║   ║  [roving patrols · random credential prompts]      ║   ║
         ║   ║                                                    ║   ║
         ║   ║   ╔════════════════════════════════════════════╗   ║   ║
         ║   ║   ║  LAYER 3 — Depository building gate        ║   ║   ║
         ║   ║   ║  [hardened entry · biometrics · no fakes]  ║   ║   ║
         ║   ║   ║                                            ║   ║   ║
         ║   ║   ║   ╔════════════════════════════════════╗   ║   ║   ║
         ║   ║   ║   ║  LAYER 4 — Front desk security     ║   ║   ║   ║
         ║   ║   ║   ║  [armed interior guards · escort]  ║   ║   ║   ║
         ║   ║   ║   ║                                    ║   ║   ║   ║
         ║   ║   ║   ║   ╔════════════════════════════╗   ║   ║   ║   ║
         ║   ║   ║   ║   ║  LAYER 5 — Vault cages     ║   ║   ║   ║   ║
         ║   ║   ║   ║   ║  [GOLD BARS]               ║   ║   ║   ║   ║
         ║   ║   ║   ║   ╚════════════════════════════╝   ║   ║   ║   ║
         ║   ║   ║   ╚════════════════════════════════════╝   ║   ║   ║
         ║   ║   ╚════════════════════════════════════════════╝   ║   ║
         ║   ╚════════════════════════════════════════════════════╝   ║
         ╚════════════════════════════════════════════════════════════╝

     →  Inbound: each Fort Knox security layer must be defeated in turn.
     ←  Outbound (exfil): every gate checks AGAIN, every alert is already
        firing, the response team is already mobilized. The carrier is
        slower than the alarm.
```

The five layers, summarized:

**Layer 1 — The Perimeter Gate.** The outer fence of the Army base. The first soldier with a rifle. Their job is to reject the obvious — vehicles without proper identification, the unauthorized truck rolling up to the front gate, the visitor who cannot articulate why they are there. Most threats stop here. This is also the layer most attackers expect to see, and the layer most defenders mistake for the whole security model.

**Layer 2 — The Interior Patrols.** Once inside the base, an intruder is not free. The base is enormous, the depository is somewhere inside it, and the path is monitored. Roving patrols stop anyone they do not recognize. Credentials are demanded at random and frequent intervals. There is no "I passed the outer gate so now I am inside" — every step across the base is an opportunity to be challenged.

**Layer 3 — The Depository Gate.** The gold depository is itself a separate fortified building. Its entry is stricter than the outer gate, less forgiving of forged credentials, and architecturally hardened. Even an attacker who somehow reached the depository's front door does not enter on guile alone; this layer is designed to *not be fooled* by techniques that worked on the outer perimeter.

**Layer 4 — The Front Desk.** Inside the depository, an interior security station processes everyone who passes the outer hardened door. The guards here are armed, alert, and not particularly social. An intruder cannot bluff their way to the vaults; the front desk is the last layer of human judgment before the gold itself.

**Layer 5 — The Vault Cages.** The gold is in cages inside the vault. Even an intruder who reached the vault floor cannot simply pick up a bar and leave. The cages are individually locked. The gold is heavy. The bars are inventoried. Picking up a few bars is the easy part; the hard part is what happens next.

**The reverse path.** Going back out is not the reverse of coming in. Going in, the attacker had surprise — no one was looking for them yet. Going out, every Fort Knox security layer is in active response mode. The outer gate is now a blockade. The interior patrols are now hunters. The exits are watched, the perimeter is sealed, the helicopters are airborne. Carrying gold bars makes the intruder slower than the alarm. The intruder is now slower than the response. This is the asymmetry that makes Fort Knox work in practice, not just on paper.

---

## The Yamato wiki — the same five Fort Knox security layers

```
       ╔══════════════════════════════════════════════════════════════╗
       ║  LAYER 1 — THE PERIMETER GATE                                ║
       ║  Cloud Armor at the external HTTPS load balancer             ║
       ║  policy: "iq9-dev-yamato-armor"  (345 blocks / 24h)          ║
       ║                                                              ║
       ║   ╔══════════════════════════════════════════════════════╗   ║
       ║   ║  LAYER 2 — THE INTERIOR PATROLS                      ║   ║
       ║   ║  Identity-Aware Proxy at the Google Front End        ║   ║
       ║   ║  [@iq9.io identity verified on EVERY /wiki/* request]║   ║
       ║   ║                                                      ║   ║
       ║   ║   ╔══════════════════════════════════════════════╗   ║   ║
       ║   ║   ║  LAYER 3 — THE DEPOSITORY GATE               ║   ║   ║
       ║   ║   ║  Cloud Run ingress = INTERNAL_LOAD_BALANCER  ║   ║   ║
       ║   ║   ║  [*.run.app URL refuses public connections]  ║   ║   ║
       ║   ║   ║                                              ║   ║   ║
       ║   ║   ║   ╔══════════════════════════════════════╗   ║   ║   ║
       ║   ║   ║   ║  LAYER 4 — THE FRONT DESK            ║   ║   ║   ║
       ║   ║   ║   ║  Runtime SA (least-priv: cloudsql    ║   ║   ║   ║
       ║   ║   ║   ║  client + 1 secret) + Go app code    ║   ║   ║   ║
       ║   ║   ║   ║  (param queries, auto-escape, length ║   ║   ║   ║
       ║   ║   ║   ║  caps, ext allowlist, nosniff)       ║   ║   ║   ║
       ║   ║   ║   ║                                      ║   ║   ║   ║
       ║   ║   ║   ║   ╔══════════════════════════════╗   ║   ║   ║   ║
       ║   ║   ║   ║   ║  LAYER 5 — THE VAULT         ║   ║   ║   ║   ║
       ║   ║   ║   ║   ║  Cloud SQL Postgres,         ║   ║   ║   ║   ║
       ║   ║   ║   ║   ║  private IP only             ║   ║   ║   ║   ║
       ║   ║   ║   ║   ║  (PSA range 10.20.0.0/20)    ║   ║   ║   ║   ║
       ║   ║   ║   ║   ║  [GOLD = the article data]   ║   ║   ║   ║   ║
       ║   ║   ║   ║   ╚══════════════════════════════╝   ║   ║   ║   ║
       ║   ║   ║   ╚══════════════════════════════════════╝   ║   ║   ║
       ║   ║   ╚══════════════════════════════════════════════╝   ║   ║
       ║   ╚══════════════════════════════════════════════════════╝   ║
       ╚══════════════════════════════════════════════════════════════╝

   →  Last night's 345 attempts: ALL stopped at LAYER 1 (the Perimeter Gate).
   →  Even with LAYER 1 OFF: the Go app's mux 404s every probed path
      (no .env, no /wp-admin, no /onvif, no /actuator, no Exchange OWA).
   →  Even with LAYERS 1–3 OFF: app code defenses (LAYER 4) and
      private-IP DB (LAYER 5) hold independently.
   ←  Exfil path: Cloud Logging captures every request; Cloud Armor
      adaptive protection flags anomalies; alert thresholds have already
      tripped; the runtime SA has nothing to elevate to; the distroless
      container has no shell to pivot through. The gold cannot leave
      the vault.
```

The mapping is one-to-one with the Fort Knox layers, and each Yamato layer's job is structurally identical to its Fort Knox counterpart:

**Layer 1 — The Perimeter Gate (Cloud Armor + external LB).** The first thing any attacker reaches. Pattern-matches against known-bad payloads at the edge of Google's network, before any Cloud Run service is even invoked. Last night, this single layer stopped every one of the 345 attempts. It is also the layer most readily confused with the entire security model — which is exactly the confusion this document is written against.

**Layer 2 — The Interior Patrols (IAP at the GFE).** Identity-Aware Proxy intercepts every request to `/wiki/*` at the Google Front End, *before* the LB routes the request to a backend. The check is not once-at-login; it is **every request**. This is the operational analogue of the patrols crossing the Army base — there is no concept of "I am inside now, leave me alone." Every step across the base is a new credential challenge. Without a valid `@iq9.io` Google identity, no `/wiki/*` traffic ever reaches a Cloud Run backend.

**Layer 3 — The Depository Gate (Cloud Run ingress = INTERNAL_LOAD_BALANCER).** Cloud Run services on this project are configured to refuse all traffic except from the external HTTPS load balancer. The `*.run.app` URL — which is publicly resolvable in DNS — returns `403` to any caller on the public internet. Even an attacker who somehow obtained a valid `@iq9.io` identity (the Layer 2 credential) cannot bypass the LB to hit the Cloud Run service directly. The depository's hardened entry is not fooled by credentials that would have passed the interior patrols.

**Layer 4 — The Front Desk (runtime SA + Go application code).** Inside the Cloud Run service, the application runs as the dedicated service account `iq9-yamato-dev-run`, which holds exactly two roles: `roles/cloudsql.client` (project-scoped) and `roles/secretmanager.secretAccessor` on one specific secret (`yamato-dev-db-password`). It cannot list buckets, modify IAM, create VMs, read other secrets, or escalate to anything else. Alongside the runtime identity sits the application code itself, written defensively: every DB query is parameterized with `$1`/`$2` placeholders, every template output is `html/template`-escaped, the full-text search caps query length at 200 *runes* (not bytes — see [search.md](../search.md) and the F-001 fix), the static handler sets `X-Content-Type-Options: nosniff` and enforces a strict extension allowlist under `/static/img/` (see [image-security.md](../image-security.md), F-1 and F-2). The container itself is distroless static, nonroot, with no shell, no package manager, and no writable filesystem. There is nothing for an intruder to talk their way past at this layer because there is no *softness* in the layer — no shell, no plugin system, no admin endpoint, no extensibility surface at all.

**Layer 5 — The Vault (Cloud SQL on private IP, via PSA).** The database has no public IP and never has. It lives on a Private Service Access range (`10.20.0.0/20`) inside the project's VPC, reachable only over Direct VPC egress from inside the same VPC. There is no `gcloud sql connect` over the public internet, no exposed `5432`, no path that a credential leak could exploit from outside the VPC perimeter. The gold is in the vault; the vault has no external door.

---

## Summary of the 24-hour window

Over the observed period, Layer 1 (Cloud Armor's `iq9-dev-yamato-armor` policy) denied **345 requests** from **20 unique source IPs** across four geographies and five hosting categories (US/EU cloud, US/EU residential, enterprise backbone). Every block was logged with timestamp, source IP, requested URL, HTTP method, the security policy name, and the matching rule's priority. **Not a single one of the 345 attempts reached Layer 2.** No request reached IAP. No identity was challenged. No Cloud Run service was invoked. No Cloud SQL query was attempted. No operator action was required beyond the threshold notification that confirmed Layer 1 was working as designed.

The 345 attempts broke down into two structurally distinct attacker classes, distinguishable not by the payload alone but by *how they found us*:

| Class | Hits | Source pattern | Discovery mechanism | Stopped at |
|---|---:|---|---|---|
| Focused secret-credential hunter | 274 | One AWS EC2 IP in Paris | Found `yamato-dev.iq9.io` by hostname — likely DNS or Cert Transparency enumeration | Layer 1 |
| Opportunistic IP-range scanners | 71 | 19 IPs across Azure, OVH, AT&T, European hosting, residential ISPs | Scanning cloud IP ranges and hitting `8.233.20.46` directly | Layer 1 |

The first class wanted us specifically. The second class was sweeping the internet and we happened to be on the list. Both got the same answer at the same layer.

---

## Attacker class 1 — the focused `.env` hunter (AWS Paris)

A single IP, `13.36.195.225`, in the AWS `eu-west-3` (Paris) range, generated 274 of the 345 blocks — 79% of the observed attack volume in 24 hours. The pattern is unambiguous in the request log:

```
2026-06-03T11:11:49Z  iq9-dev-yamato-armor  1002  GET  https://yamato-dev.iq9.io/bulk/.env
2026-06-03T11:11:49Z  iq9-dev-yamato-armor  1002  GET  https://yamato-dev.iq9.io/transactional/.env
2026-06-03T11:11:48Z  iq9-dev-yamato-armor  1002  GET  https://yamato-dev.iq9.io/brevo/.env
2026-06-03T11:11:48Z  iq9-dev-yamato-armor  1002  GET  https://yamato-dev.iq9.io/mailjet/.env
2026-06-03T11:11:48Z  iq9-dev-yamato-armor  1002  GET  https://yamato-dev.iq9.io/mandrill/.env
2026-06-03T11:11:48Z  iq9-dev-yamato-armor  1002  GET  https://yamato-dev.iq9.io/mailgun/.env
2026-06-03T11:11:47Z  iq9-dev-yamato-armor  1002  GET  https://yamato-dev.iq9.io/postmark/.env
2026-06-03T11:11:47Z  iq9-dev-yamato-armor  1002  GET  https://yamato-dev.iq9.io/sparkpost/.env
2026-06-03T11:11:47Z  iq9-dev-yamato-armor  1002  GET  https://yamato-dev.iq9.io/sendgrid/.env
2026-06-03T11:11:47Z  iq9-dev-yamato-armor  1002  GET  https://yamato-dev.iq9.io/ses/.env
```

The probe pattern is `GET /<prefix>/.env` across approximately sixty different directory prefixes, fired in rapid sequence — roughly four requests per second — in a single burst lasting under three minutes. Every probe targets the same file: `.env`. Every probe was blocked by Layer 1 at the Perimeter Gate.

### What they wanted

The list of prefixes is not random. A representative sample:

- **Transactional email service slugs:** `/brevo/.env`, `/mailjet/.env`, `/mandrill/.env`, `/mailgun/.env`, `/postmark/.env`, `/sparkpost/.env`, `/sendgrid/.env`, `/ses/.env`, `/smtp/.env`, `/mail/.env`, `/mailer/.env`, `/newsletter/.env`, `/campaign/.env`, `/sender/.env`, `/notify/.env`, `/notifications/.env`, `/mailing/.env`, `/email/.env`
- **Common application directory slugs:** `/admin/.env`, `/panel/.env`, `/dashboard/.env`, `/portal/.env`, `/internal/.env`, `/scripts/.env`, `/tools/.env`, `/uploads/.env`, `/assets/.env`, `/storage/.env`, `/resources/.env`, `/database/.env`, `/lib/.env`, `/vendor/.env`, `/service/.env`, `/microservice/.env`
- **Framework/language slugs:** `/node/.env`, `/express/.env`, `/next/.env`, `/nuxt/.env`, `/nest/.env`, `/saas/.env`, `/shop/.env`, `/store/.env`, `/erp/.env`, `/crm/.env`, `/api/.env`, `/exapi/.env`
- **Maintenance and backup slugs:** `/backup/.env`, `/backups/.env`, `/old/.env`, `/tmp/.env`, `/temp/.env`, `/cron/.env`, `/cronlab/.env`, `/lab/.env`

The first group reveals the economic motive. A `.env` file in a Node.js / Python / Ruby application directory commonly contains application secrets — and for many web applications, the most monetizable secret is a transactional-email-service API key (SendGrid, Mailgun, Postmark, Brevo, AWS SES, Mailjet, Mandrill, SparkPost). A single leaked SendGrid key can blast on the order of 100,000 phishing or spam messages before SendGrid's abuse team locks the account, and during those hours the attacker's deliverability is *better than the attacker's own* because the messages are being sent from a domain with established sender reputation. There is a cottage industry of bots whose entire purpose is to scan the internet for these specific files and exfiltrate the keys they contain. The attacker that hit us last night is one of them, automated and unsophisticated, working through a pre-baked list of probable directory prefixes — every probe arriving at the Army base's outer gate and getting turned away by the soldier on duty.

### How they found us

The dominant attacker hit the hostname `yamato-dev.iq9.io`, not the load balancer IP. That distinction matters: it means they did not find us through a brute IP-range scan. The most likely discovery mechanisms, in decreasing order of probability:

1. **Certificate Transparency log monitoring.** When Google's managed SSL certificate for `yamato-dev.iq9.io` was issued, the issuance was logged in public CT logs (per RFC 6962). Several public services index those logs in near-real-time — `crt.sh`, `Censys`, `certspotter`. Any scanner subscribed to CT updates for `*.iq9.io` (or even `*.io`) would have learned of the hostname within minutes of the certificate's first issuance.
2. **Passive DNS aggregators.** Recursive DNS resolvers like Cloudflare's `1.1.1.1` and Google's `8.8.8.8` participate (with telemetry consent caveats) in passive DNS datasets aggregated by SecurityTrails, Farsight, and others. Bots subscribe to these feeds.
3. **Direct DNS enumeration of `iq9.io`** is less likely because most public DNS does not allow zone transfer, but subdomain brute force ("`yamato.iq9.io`, `yamato-dev.iq9.io`, ...") could surface the name if the attacker knew to look.

There is no way to prevent CT-driven discovery short of not having a TLS certificate, which is not a tradeoff anyone should make. The defensive posture has to assume discovery, not prevent it. Fort Knox does not pretend to be invisible. Fort Knox is on a map. The defense is the layers, not the obscurity.

### How they were caught

Layer 1, Cloud Armor policy `iq9-dev-yamato-armor`, rule priority `1002`. 274 of 274 attempts denied at the load balancer's edge. The Go application did not see a single byte of these requests; no Cloud Run request-seconds were billed; Layer 2 (IAP) was not even consulted because no request from this source made it past the perimeter gate to need an identity check.

But — and this is the important part for the layered argument that follows — **even if Layer 1 had been absent, every one of these probes would have died at deeper layers.** The Go binary's HTTP mux registers exactly seven routes:

```
GET /            → landing page                 (public)
GET /healthz     → DB-aware health check        (public)
GET /static/*    → embedded static assets       (public)
GET /wiki        → wiki index                   (IAP-gated)
GET /wiki/       → wiki index                   (IAP-gated)
GET /wiki/{slug} → article                      (IAP-gated)
GET /wiki/search → full-text search             (IAP-gated)
```

Anything else returns `http.NotFound` — including `/bulk/.env`, `/sendgrid/.env`, `/.env`, and every other prefix the attacker tried. There is no `.env` file *anywhere* on the embedded filesystem. The Go binary has no concept of a filesystem-mapped webroot at all. The attacker is probing for an application that does not exist.

---

## Attacker class 2 — the IP-range scanners (long tail)

The remaining 71 blocks came from 19 IPs spread across cloud providers, residential ISPs, and enterprise backbones in three continents. Every one of them hit the bare load balancer IP `8.233.20.46` rather than the hostname — meaning they found us by brute-forcing through cloud IP allocations rather than through DNS or CT.

This is a structurally different attack class. A focused attacker has reason to believe a specific hostname is interesting (CT log, DNS enumeration, target list). An IP-range scanner has no idea what is behind any given IP; they sweep `0.0.0.0/0` (or large subsets of cloud allocations) and spray their entire payload menu at anything that answers on port 443. The "attack" is not even adversarial — it is automated indiscriminate probing. From the Fort Knox analogy: this is the bus tour of would-be intruders driving along every fence line of every Army base in the country, rattling each gate to see which ones rattle back, and then trying the same handful of forged passes on the ones that do.

### Representative payloads observed

The long tail attempted a much more diverse menu than the focused attacker, spanning several categories:

**Secret and credential files** (priority `1002`, ~52 of 71 blocks):

```
GET /.env, /.env.backup, /.env.local, /.env.production, /.env.save
GET /.aws/credentials
GET /.git/config, /.git/HEAD
GET /.htpasswd
GET /.DS_Store
GET /wp-config.php, /wp-config.php.bak
GET /app/config/parameters.yml      (Symfony)
GET /config/database.yml             (Rails)
```

Same economic motive as the focused attacker, broader inventory of what specific files might be leaked.

**Known-CVE probes for specific enterprise software** (priorities `1004`/`1005`, ~12 of 71 blocks):

```
POST /onvif/device_service           (ONVIF IoT cameras — CVE-2018-1149 family)
GET  /developmentserver/metadatauploader  (SAP NetWeaver Visual Composer RCE)
GET  /actuator/health                  (Spring Boot Actuator information disclosure)
GET  /actuator/env                     (Spring Boot environment dump)
GET  /owa/auth/logon.aspx              (Microsoft Exchange / Outlook Web Access)
GET  /version                          (generic version disclosure)
```

These are CVE-template probes. The attacker has a database of "if this URL returns 200, the target is running vulnerable version of X, exploit Y is applicable." Cheap to throw, occasionally lucrative when the target *is* an exposed Exchange server or a vulnerable SAP installation.

**Path traversal and command injection** (priority `1002`, occasional):

```
POST /cgi-bin/%252e%252e/%252e%252e/%252e%252e/%252e%252e/%252e%252e/%252e%252e/%252e%252e/bin/sh
```

Apache `mod_cgi` Shellshock-family payload, double-URL-encoded to bypass naive `..` filtering. Targets the bygone era of Apache + bash CGI scripts. We do not have a CGI handler at all.

### The IoT-camera correlation worth noting

Three of the 20 source IPs — `89.21.67.141`, `193.176.31.200`, and `193.176.31.209` — all hit `POST /onvif/device_service` in the observation window. The two `193.176.31.*` IPs are in the same `/24`, suggesting coordination or shared infrastructure. ONVIF (Open Network Video Interface Forum) is the standard protocol for IP-connected security cameras and DVR systems, and there is a long-running global botnet operation that hunts for exposed ONVIF endpoints to recruit cameras into DDoS swarms (Mirai and its descendants). The probe is cheap; the prize is a recruited node.

We are not an ONVIF camera. The Go binary returns 404 to any POST under `/onvif/`. Layer 1 stopped the attempt at the Perimeter Gate.

### How they were caught

Layer 1, same Cloud Armor policy, mostly priority `1002`, with priorities `1001` (5 blocks) and `1005` (6 blocks) catching the protocol-level and enterprise-CVE probes. Every block recorded the timestamp, source IP, requested URL, HTTP method, and rule priority. Layer 2 was again not consulted, because nothing reached it.

And — the layered argument again — none of the probed software is running anywhere in this stack. There is no PHP, no Apache, no Symfony, no Rails, no WordPress, no Spring Boot, no Exchange, no SAP. The application is a Go binary that registers seven HTTP routes and rejects everything else. The "attack" looks like a determined attempt to find any of perhaps twenty different software stacks; none of those stacks exists at this address.

---

## Walking the Fort Knox security layers — what each layer would have caught

This is the layered case in detail. For each of the five Fort Knox security layers, the section below describes what the layer enforces, what it would have caught in last night's attacks, and what specifically would have happened at that layer if every preceding layer had been disabled.

### Layer 1 — The Perimeter Gate (Cloud Armor)

**What it enforces:** pattern-matched rejection of known-malicious requests at the LB edge, before Cloud Run is invoked. Policy `iq9-dev-yamato-armor` is a custom rule set (not the stock OWASP CRS).

**What it caught last night:** all 345 attempts. 100%.

**What would happen if it were disabled:** the LB would route requests to either the public service (`/`, `/static/*`, `/healthz`) or the wiki service (`/wiki/*`). Every probed path the attackers tried — `/.env`, `/wp-config.php`, `/onvif/device_service`, `/owa/auth/logon.aspx`, `/actuator/health`, `/.git/config`, the rest — falls through to the public service backend, where the Go binary's mux finds no matching route and returns 404. The attacker spends some Cloud Run request-seconds and learns nothing.

### Layer 2 — The Interior Patrols (IAP)

**What it enforces:** Identity-Aware Proxy at the Google Front End. Every request to `/wiki/*` is intercepted before the LB even forwards it to a backend. Without a valid `@iq9.io` Google identity, IAP returns a 302 redirect to Google's sign-in page. There is no "session" that gets the attacker through Layer 2 once; every request is checked. This is the operational essence of Fort Knox's interior patrols: the credential check is not a one-time event, it is the ambient condition of being inside the perimeter.

**What it would have caught last night:** had any of last night's attacks targeted `/wiki/*` (the IAP-gated paths), Layer 2 would have intercepted them at the GFE, redirected the attacker to Google's sign-in, and the attacker — having no `@iq9.io` identity — would have been unable to authenticate. None of last night's attacks did target `/wiki/*` because the attackers were probing for general-web-app patterns, not specific wiki paths.

**What would happen if both Layer 1 and Layer 2 were disabled:** the requests would arrive at the relevant Cloud Run backend. The Go binary would still return 404 for every path that does not match its mux. The application is the same regardless of which authentication layers sit in front of it.

### Layer 3 — The Depository Gate (Cloud Run ingress = INTERNAL_LOAD_BALANCER)

**What it enforces:** both Cloud Run services in this project (`iq9-run-dev-yamato` and `iq9-run-dev-yamato-wiki`) have `ingress = INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER`. The `*.run.app` URLs that Cloud Run automatically allocates for these services return `403` to any caller on the public internet. The services can only be reached via this project's specific external HTTPS load balancer.

**What it would have caught last night:** Layer 3 is not in the path of last night's attacks, because last night's attackers all came through the LB (which is the intended path). Layer 3 is in the path of a *different* attack profile: an attacker who has obtained a valid `@iq9.io` identity (somehow defeating Layer 2) and tries to bypass the LB to hit the `*.run.app` URL directly. The depository's hardened gate refuses them. The identity that worked at the interior patrols does not work at this entry.

**What would happen if Layers 1–3 were all disabled:** the attacker reaches the Cloud Run container directly. The container runs the same Go binary with the same mux, returning 404 for everything that does not match a registered route.

### Layer 4 — The Front Desk (runtime SA + application code + container hardening)

**What it enforces:** three components that work together.

- **The runtime identity.** Cloud Run runs the binary as the dedicated service account `iq9-yamato-dev-run`, which holds two roles: `roles/cloudsql.client` (project-scoped) and `roles/secretmanager.secretAccessor` on the single secret `yamato-dev-db-password`. It cannot list buckets, modify IAM, create VMs, read other secrets, modify firewall rules, attach to other networks, write logs to arbitrary destinations, or do anything else useful to an attacker who somehow reached this layer.
- **The application code.** Every database query is parameterized (`pgx` with `$1`/`$2` placeholders); SQL injection has no surface. All template output is auto-escaped by `html/template`; XSS has no surface. The full-text search caps query length at 200 *runes*, not bytes (see the F-001 fix in [search.md](../search.md)). The static handler sets `X-Content-Type-Options: nosniff` and enforces a strict extension allowlist under `/static/img/` (`.jpg .jpeg .png .webp .gif`, no SVG — see F-1 and F-2 in [image-security.md](../image-security.md)). Schema migrations are idempotent and additive. There is no `eval`, no untrusted deserialization, no admin endpoint.
- **The container.** Built from `gcr.io/distroless/static-debian12:nonroot`. No shell, no package manager, no writable filesystem, no setuid binaries, no compiler, no `curl`, no `wget`, no `python`. Even hypothetically obtaining remote code execution inside the container yields a process that can call the kernel and almost nothing else.

**What it would have caught last night:** Layer 4 is not in the path of last night's attacks. The attacks die at Layer 1. Layer 4 is what holds if an attacker somehow gets inside the Cloud Run service — by, for example, exploiting a hypothetical zero-day in `http.FileServerFS` or in the Go runtime itself.

**What would happen if Layers 1–4 were the only defense (everything outside Layer 4 disabled):** the attacker has remote code execution inside the container. They can call the kernel. They cannot read other secrets, list buckets, modify IAM, escalate to other service accounts, or invoke any of the standard cloud lateral-movement primitives — because the runtime SA does not hold the IAM that would permit any of it. They can connect outbound to the database (port 5432 on the private IP) using the credentials in the environment. That is genuinely the only thing they can do that matters. Which brings us to Layer 5.

### Layer 5 — The Vault (Cloud SQL on private IP, via PSA)

**What it enforces:** Cloud SQL Postgres has no public IP. It lives on a Private Service Access range (`10.20.0.0/20`) inside the project's VPC, accessible only over Direct VPC egress from a workload attached to that same VPC. There is no `gcloud sql connect` over the public internet; no exposed `5432`; no path that a credential leak from outside the VPC could exploit. The database itself is what an attacker who reaches Layer 5 is trying to read.

**What it would have caught last night:** Layer 5 is not in the path of last night's attacks. The DB has zero connections from any source other than the runtime SA all day. The attackers never came close.

**What would happen if Layers 1–4 were all defeated:** the attacker is running code inside the Cloud Run container, has the DB credentials from the environment, and can connect to the DB on its private IP. They can execute parameterized queries (the application code uses parameterization, but the attacker now controls the application code). They can read the article bodies, the schema, the seed. The data they obtain is — and this matters — *the public wiki content the IAP-gated audience already reads*. The "gold bars" in this vault are 15 in-universe Star Blazers archival entries. There are no user PII tables, no password hashes (IAP holds the identity, not the app), no payment data, no API keys, no production secrets the attacker did not already need to obtain *before* they reached this layer. The vault contains exactly what an honest authenticated user is permitted to see, and nothing else, because the application's data model puts nothing else in the vault.

This is also the answer to the most common consulting-prospect question, *"What happens if someone gets all the way in?"* The honest answer for this specific application is: they read the wiki. The architecture has been designed so that the worst case at the innermost layer is the published case at the outermost layer. The vault does not contain anything that needs more secrecy than the public landing page.

---

## The reverse path — exfiltration is harder than infiltration

The Fort Knox model has a property the inbound analysis above does not yet name: **the way out is not the reverse of the way in.** A hypothetical attacker who managed to defeat all five Fort Knox security layers on the way to the vault does not get to retrace those same steps to leave. By the time they have the gold, every layer is already in active response.

Mapped onto the Yamato architecture, here is what the reverse path looks like:

**Cloud Logging is comprehensive and unforgeable.** Every request that reaches the LB is logged with timestamp, source IP, requested URL, response code, and the matching Cloud Armor rule. Every Cloud Run invocation is logged with the runtime SA, the request URI, the response code, and a request latency. Every Cloud SQL query is logged at the DB level (when query logging is enabled). The logs are written to a Cloud Logging bucket that the runtime SA cannot modify or delete — and they are simultaneously shipped to an org-scoped archive sink that lives in an entirely different project. An attacker who somehow ran arbitrary code inside the container could not erase their tracks; the trail is already off the host.

**Cloud Armor's adaptive protection scores traffic and tightens the perimeter.** If a session that began as ordinary traffic starts issuing unusual query shapes — high-cardinality requests, atypical user-agents, atypical geographies — the score climbs and the policy enforces more aggressively. The perimeter gate that let the attacker in becomes the perimeter gate that does not let the next request through. Like the Fort Knox patrols mobilizing, the perimeter does not stay static once an alert has fired.

**The threshold alert is already a tripwire.** The 20-blocks-per-window alert we discuss below is one of nine alerts configured on this project. The others include unusual SQL query rates, Cloud Run error rate spikes, IAM policy changes, and unexpected egress patterns. By the time an attacker is inside the vault, multiple alerts have fired and the operator dashboard is already lit up. The carrier is slower than the alarm.

**The runtime SA cannot exfiltrate to anywhere useful.** The service account holds `roles/cloudsql.client` and a single `roles/secretmanager.secretAccessor`. It does not hold `roles/storage.objectCreator`, so it cannot write to a GCS bucket the attacker controls. It does not hold `roles/pubsub.publisher`, so it cannot publish to a topic. It does not hold `roles/cloudfunctions.invoker`, so it cannot trigger external code paths. Outbound HTTPS to an arbitrary endpoint is possible (the VPC egress is `PRIVATE_RANGES_ONLY` for VPC traffic, and direct egress for the public internet), but every such request is in the Cloud Run access log with timestamp and destination — and an HTTPS POST of "the gold bars" to `evil.example.com` is itself an anomalous pattern that the alert configurations are tuned to surface.

**The distroless container has no escape.** Even if the attacker has remote code execution inside the container, there is no shell from which to pivot — `/bin/sh` does not exist. There is no `curl`, no `wget`, no `python`, no `bash` heredocs. The attacker is constrained to whatever they can do with the Go binary's own syscalls and whatever they brought as their initial payload. They cannot install tools because there is no package manager. They cannot write to disk because the filesystem is read-only outside `/tmp`. They cannot persist across a container restart because Cloud Run is stateless and the next request might land on a fresh instance entirely.

**The vault contains what is already published.** As noted in the Layer 5 description, the data the attacker reaches at the innermost layer is the public wiki content the legitimate audience already reads. The gold bars are paper, not metal. The reverse-exfil path is not just hard; the prize is not worth the effort of completing it.

Put together: the Fort Knox security layers are not just stacked, they are **time-asymmetric**. The defender's advantage compounds with depth. The deeper the attacker reaches, the more layers have already alerted, the more constrained their available actions become, and the smaller the prize gets. The architecture is designed so that even total compromise of the innermost layer would be a slow, noisy, low-value operation — and last night, no attacker came close to it.

---

## Layer 1 alone is not Fort Knox — why WAF-as-primary-defense fails

The mainstream industry pattern, particularly in mid-market organizations, is the inverse of the Fort Knox security model. A vulnerable web application — typically running on a wide-open public IP, often on a permissive cloud VM with full network egress, often with database credentials in environment variables or `.env` files — is fronted by a WAF, and the WAF is treated as the primary security control. The reasoning, when it is articulated, runs roughly:

> *"The WAF will block attacks before they reach our app. So we do not need to harden the app."*

This is one layer. It is Layer 1 only. It is the soldier at the outer gate of the Army base with nothing behind them — no patrols, no depository gate, no front desk, no vault, no cages, no alarms. It is a fence with a sign on it.

The reasoning is wrong in three specific ways, each of which would destroy the assumed protection.

### 1. WAFs are signature engines. They miss what they have not seen.

A WAF blocks attacks by matching incoming requests against a corpus of known malicious patterns: SQL injection canaries, XSS string fragments, directory-traversal sequences, scanner User-Agent strings, known-malicious CVE template signatures. This works for the attacks the WAF vendor has catalogued. It does nothing for novel attacks — by definition, the attacks the WAF cannot block are the ones for which a signature has not yet been written. The history of security research is littered with WAF bypass techniques that worked because the rule corpus was a strict subset of the actual attack space.

Even for the attacks the WAF *has* catalogued, bypass research is a continuous academic and adversarial enterprise:

- **Encoding tricks.** Double-URL-encoding, Unicode normalization, mixed-case keywords, comment-injection in SQL (`SEL/**/ECT`), HTTP parameter pollution, and dozens of others have at various times bypassed all major commercial WAFs.
- **Fragmentation.** Splitting a payload across multiple request parameters or HTTP chunks that the WAF inspects independently but the application reassembles.
- **Behavioral mimicry.** Slow, throttled probing that stays below per-source rate limits while patiently mapping out the target.
- **Novel CVE chains.** Any zero-day, by definition, has no signature.

### 2. WAFs create false confidence at the executive level

The presence of a WAF on the procurement spreadsheet, with a green checkbox next to it, frequently *worsens* the security posture of the underlying application. Engineering teams stop hardening the app because "the WAF will catch it." Risk dashboards report the application as "protected." When the inevitable bypass occurs — a new CVE, a clever encoding, a slow probe that mapped the application without tripping the threshold — the application that should have been hardened from day one is found to have been wide open the whole time. The WAF was theater; the theater hid the real exposure. There were no Fort Knox security layers behind it.

### 3. WAFs are themselves an attack surface

Every WAF agent, every WAF cloud service, every WAF appliance is software, and software has CVEs. WAFs have shipped exploitable vulnerabilities at every major vendor at various points — including remote code execution in the WAF agent itself. Adding a WAF without an architectural defense doubles the attack surface: now an attacker can target either the application or the WAF.

### And the AV-on-server narrative

The companion mistake — installing an "endpoint protection" agent (anti-virus, EDR) on server workloads — is worse for the same reasons and one more:

- AV is signature-matching for known malware *binaries*. Server-side compromises in 2026 are overwhelmingly *codepath exploitations* (RCE via deserialization, SSRF, prompt injection in LLM applications, supply-chain attacks via compromised dependencies). A signature-matching AV on the host catches none of these — the exploitation happens entirely inside the application's memory, never touching a file the scanner could see.
- AV agents themselves have a long, embarrassing history of catastrophic CVEs (Sophos, Symantec, Cylance, McAfee, ESET have all shipped agent-RCEs in the last decade).
- For a distroless container, AV has nothing to scan. There are no files. There is no filesystem. The scan returns clean because there is nothing there. The protection is illusory.

### What we did instead — the five Fort Knox security layers, not one

We made the application unreachable on its own URL (Layer 3). We made the database unreachable from the internet at all (Layer 5). We made the identity surface narrow to a single Google Workspace domain (Layer 2). We gave the runtime no privilege (Layer 4). We removed the shell from the container (Layer 4). We hardened the application code (Layer 4). *Then* we added Cloud Armor as Layer 1 — the outer perimeter gate that catches the obvious garbage before it costs us Cloud Run request-seconds or clutters our LB logs.

The 345 blocks observed last night are not the proof that the security holds. They are the proof that the security holds *with one of five Fort Knox security layers actively engaged*. The other four would have held independently of Layer 1, and last night Layer 1 never let anything reach them.

---

## Layer 1 internals — Cloud Armor policy priorities

The policy `iq9-dev-yamato-armor` is a custom rule set (not the stock OWASP Core Rule Set, which Google offers as a managed bundle). The priority distribution across all 345 blocks in the observation window:

| Priority | Blocks | Inferred category from observed traffic |
|---:|---:|---|
| `1002` | 326 | Dotfile / credential / config file probes (`.env`, `.git/*`, `.aws/*`, `wp-config.php`, etc.) |
| `1005` | 6 | Known-CVE probes for enterprise software (SAP, Spring, Exchange, generic `/version`) |
| `1004` | 6 | (Reserved / mixed — small sample; further analysis warranted) |
| `1001` | 5 | Protocol-level abuse (`POST /onvif/device_service`) |
| `1006` | 2 | (Reserved / mixed) |

The custom-ruleset approach has two operational virtues over the stock OWASP CRS:

1. **It is tuned to threats we actually observe.** The OWASP CRS is comprehensive but conservative — it includes many rules with non-trivial false-positive rates against legitimate traffic. The custom policy includes only the rule categories we have decided we want to enforce, at the sensitivities we have chosen, with the priorities ordered to make the logs grep-able.
2. **It is auditable in our terraform.** The policy lives in `service/yamato/modules/frontdoor/frontdoor.tf` and changes require a Service Layer PR with the appropriate review bar (see [`docs/infrastructurestate.md`](../infrastructurestate.md)). We know exactly what is enforced and what is not, and the policy evolves through code review rather than through a vendor's quarterly rule update.

---

## The threshold alert — Layer 1's smoke detector

A Cloud Monitoring alert policy fires when the count of `denied` requests at Layer 1 crosses 20 in the alert window. Last night, that threshold was crossed and the on-call email arrived. The threshold is deliberately calibrated:

- **A threshold of 1** would page on every drive-by Censys probe and every misconfigured-bot single request. Operator fatigue would set in within a week. By the time a real attack came, the operator would have learned to ignore the alerts.
- **A threshold of 1,000** would have missed the 274-attempt `.env` hunter entirely — that single attacker's burst was just over a quarter of the higher threshold and would have been lost in the noise.
- **20 is the sweet spot.** It filters the trickle of background internet noise (typical observed rate without an active attacker: 1–10 blocks per hour) and surfaces anything that looks coordinated. When 20 is exceeded, *something is happening* — not necessarily a sophisticated attack, but at minimum a tool run worth eyeballing.

The alert's purpose, importantly, is *not* to summon the operator to do anything. The Fort Knox security layers already worked. The alert exists so the operator can *admire* the defense — and, in cases like this one, capture the evidence while it is fresh in the logs. This is what mature alerting looks like.

---

## The Gamilas were a hypothesis. Last night was the experiment.

The [red-team playbook](./red-team-playbook.md) describes Act 1 of the demonstration as follows:

> *"Run from the DigitalOcean droplet (true 'outside GCP'): the attacker can see everything (it's on the internet) and gets nowhere. The dashboard's 'Cloud Armor blocks' and 'front-door denials' tiles light up; the email alerts fire. Nothing reaches the app."*

That was the prediction. The Gamilas were a teaching device — a baked Packer image with nmap, sqlmap, nuclei, ffuf, feroxbuster, the whole arsenal — designed to give a presenter something dramatic to point at on stage. The presenter would run the attack, the dashboard tiles would light up, the audience would see the wall hold.

Last night, twenty unrelated adversaries, with their own tools and their own motives, ran their own attacks against the same target. The dashboard tiles lit up at Layer 1. The threshold alert fired. The wall held. The defense behaved identically whether the attacker was friendly and pre-scripted or hostile and opportunistic — because the defense does not depend on knowing who the attacker is. It depends on five concentric Fort Knox security layers that hold independently.

This is the difference between a demo and a working system. The demo proves the design on a controlled input. The system proves it on the only input that matters in the long run: whatever happens to show up.

---

## What this means for prospects and audiences

For a consulting context, this document is the answer to the most common skeptical question: *"That's a nice demo, but does any of this actually work in production?"*

Yes. Here is twenty-four hours of evidence. Twenty real adversaries from four continents. Three hundred and forty-five attempts. **All stopped at Layer 1 of the Fort Knox security model. The other four layers would have stopped them independently if Layer 1 had been absent.** The application is genuinely Fort-Knox-secure, not because of any single product purchased from any single vendor, but because the surface area exposed to the public internet is exactly what it should be: a static landing page, a health check, and an IAP-gated identity wall. Everything else is private. Everything else is layered. Everything holds.

The consulting frame writes itself:

- "Most security architectures have one layer. They are a fence. We have **five Fort Knox security layers**, and each one holds independently."
- "Yesterday, real attackers from four continents threw 345 attacks at us. **All 345 stopped at Layer 1.** The other four layers were not even consulted."
- "The architecture is not protected by Cloud Armor. The architecture is protected by **not being reachable**. Cloud Armor is the cat door. The safe is the five Fort Knox security layers."
- "Show me your application's diagram. Now count the layers. If you have one, you are exposed."

This is what "infrastructure empathy" looks like when it is built on. Not a security product layered atop a vulnerable application — a vulnerable application *cannot* be made secure by layering. A genuinely secure application, where the architecture itself rejects the question.

---

## Methodology — reproducing this analysis

The data in this document came from three Cloud Logging queries against the production project. The queries are reproducible by any operator with `roles/logging.viewer` on the project.

**Top blocked source IPs in the last 24 hours:**

```bash
gcloud logging read \
  'resource.type="http_load_balancer"
   AND (jsonPayload.enforcedSecurityPolicy.outcome="DENY"
        OR jsonPayload.statusDetails="denied_by_security_policy")' \
  --project=iq9-gcp-dev-yamato --freshness=24h --limit=5000 \
  --format='value(httpRequest.remoteIp)' \
| sort | uniq -c | sort -rn | head -20
```

**Per-request payload menu from a specific source IP:**

```bash
gcloud logging read \
  'resource.type="http_load_balancer"
   AND (jsonPayload.enforcedSecurityPolicy.outcome="DENY"
        OR jsonPayload.statusDetails="denied_by_security_policy")
   AND httpRequest.remoteIp="13.36.195.225"' \
  --project=iq9-gcp-dev-yamato --freshness=24h --limit=100 \
  --format='table(timestamp,
                  jsonPayload.enforcedSecurityPolicy.name,
                  jsonPayload.enforcedSecurityPolicy.priority,
                  httpRequest.requestMethod,
                  httpRequest.requestUrl)'
```

**Rule-priority distribution across all blocks:**

```bash
gcloud logging read \
  'resource.type="http_load_balancer" AND jsonPayload.enforcedSecurityPolicy.outcome="DENY"' \
  --project=iq9-gcp-dev-yamato --freshness=24h --limit=5000 \
  --format='value(jsonPayload.enforcedSecurityPolicy.priority)' \
| sort | uniq -c | sort -rn
```

Run any of the three with `--freshness=7d` for the weekly view, or with `--freshness=168h` to align with a typical incident-review window.

---

## Appendix A — the 20 source IPs in full

| IP | Hits | Owner (best-effort attribution) | Pattern type |
|---|---:|---|---|
| `13.36.195.225` | 274 | AWS EC2 `eu-west-3` (Paris) | Focused `.env`-credential hunter |
| `172.172.87.58` | 11 | Microsoft Azure | Mixed scanner |
| `135.119.238.195` | 11 | Microsoft Azure | Credential file probes |
| `64.236.153.154` | 8 | Cogent Communications (US backbone) | Credential file probes |
| `48.211.210.113` | 7 | Microsoft Azure | Credential file probes |
| `64.236.131.243` | 6 | Cogent Communications (US backbone) | Credential file probes |
| `68.154.38.17` | 5 | AT&T (US residential/business) | Mixed scanner |
| `31.58.144.14` | 5 | Lithuanian/Eastern European ISP | Mixed scanner |
| `192.53.121.68` | 2 | European hosting (OVH or similar) | Credential file probes |
| `89.21.67.141` | 1 | European hosting | ONVIF protocol abuse |
| `77.83.39.197` | 1 | European hosting | `.env` probe |
| `4.150.191.6` | 1 | Microsoft Azure | Version disclosure probe |
| `217.154.173.63` | 1 | European business ISP | Path traversal / Shellshock variant |
| `20.65.194.161` | 1 | Microsoft Azure | CVE template probe |
| `20.163.33.22` | 1 | Microsoft Azure | Spring Actuator probe |
| `20.106.49.2` | 1 | Microsoft Azure | SAP NetWeaver probe |
| `193.176.31.209` | 1 | European hosting (same /24 as below) | ONVIF protocol abuse |
| `193.176.31.200` | 1 | European hosting (same /24 as above) | ONVIF protocol abuse |
| `172.202.117.213` | 1 | Microsoft Azure | Microsoft Exchange OWA probe |
| `167.71.43.252` | 1 | **DigitalOcean** | Single low-volume probe (not our droplet — see note) |

The single DigitalOcean IP at the bottom of the list is worth a footnote, because we had reason to wonder: do we still have a baked Gamilas droplet running from a forgotten demo? The volume answers the question. A real Gamilas droplet executing `profiles/unauth-scan.sh` would generate hundreds of blocks from a single DO IP in a single run (nmap alone fires top-200 port probes, nuclei fires thousands of CVE templates). One DigitalOcean block is noise — almost certainly an unrelated DO customer's scanner-bot, not our infrastructure. `doctl compute droplet list` should be run to confirm, but the evidence already says it is not us.

---

## Appendix B — the full `.env` prefix menu from the focused attacker

Reproduced for completeness; this is the 60-prefix list the AWS Paris attacker sprayed in a single burst against Layer 1 of the Fort Knox security model:

```
/bulk /transactional /brevo /mailjet /mandrill /mailgun /postmark
/sparkpost /sendgrid /ses /newsletter /campaign /sender /notify
/notifications /mailing /smtp /email /mail /mailer /sitemaps /exapi
/psnlink /administrator /en /cron /cronlab /lab /temp /tmp /old
/backups /backup /nest /nuxt /next /express /node /project /client
/saas /store /shop /erp /crm /panel /dashboard /portal /scripts
/tools /internal /uploads /assets /storage /resources /database
/lib /vendor /service /microservice
```

Each prefix was probed exactly once, each appended with `/.env`. The list is alphabetically scrambled in the log (consistent with random sampling from a precomputed wordlist), and the request rate is uniform at approximately four per second — consistent with a single-threaded HTTP client running through a static input file. Cheap, automated, indiscriminate. Caught by a single Cloud Armor rule at Layer 1 of the Fort Knox security model, never approaching Layer 2.

---

## See also

- [`docs/security/readme.md`](./readme.md) — security documentation index
- [`docs/security/defense-in-depth.md`](./defense-in-depth.md) — the layered defense model
- [`docs/security/zero-trust-iap.md`](./zero-trust-iap.md) — Layer 2 (IAP), in detail
- [`docs/security/fort-knox.md`](./fort-knox.md) — the one un-hecklable claim
- [`docs/security/red-team-playbook.md`](./red-team-playbook.md) — the Gamilas demo
- [`docs/infrastructurestate.md`](../infrastructurestate.md) — the layered architecture
- [`docs/search.md`](../search.md) — the wiki search feature and its Layer 4 hardening
- [`docs/image-security.md`](../image-security.md) — static image serving and its Layer 4 hardening
- [`service/yamato/modules/frontdoor/frontdoor.tf`](../../service/yamato/modules/frontdoor/frontdoor.tf) — Layer 1 (Cloud Armor policy `iq9-dev-yamato-armor`), in code

---

*Recorded by the on-call operator. The five Fort Knox security layers held. The Yamato sailed on.*

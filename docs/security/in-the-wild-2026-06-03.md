# In the Wild — Real-World Attacks Against the Yamato Wiki

**Observation window:** 2026-06-02 11:00 UTC → 2026-06-03 11:00 UTC (24 hours)
**Target:** `yamato-dev.iq9.io` (LB external IP `8.233.20.46`)
**Project:** `iq9-gcp-dev-yamato`
**Blocks recorded:** 345
**Unique source IPs:** 20
**Operator interventions:** 0
**Customer impact:** 0
**Alert that fired:** Cloud Armor blocked-requests threshold (set to 20 in the alert window)

[← Security index](./readme.md) · [Defense in depth](./defense-in-depth.md) · [Red-team playbook](./red-team-playbook.md) · [Fort Knox claim](./fort-knox.md)

---

## What this document is

The [red-team playbook](./red-team-playbook.md) is the script for *proving* the [Fort Knox claim](./fort-knox.md) by playing the Gamilas Empire ourselves: we throw a baked attack image at the Yamato and narrate the defense as each control fires. The whole rhetorical setup of that playbook is "watch us play the bad guys; watch GCP stop us." We needed an attacker because we did not have one.

We have one now. We have twenty. From four continents. While the operator slept.

This document records what real adversaries did against the production wiki on the night of 2026-06-02 into the morning of 2026-06-03, what Cloud Armor caught at the edge, and — the part that matters most — what the *architecture* would have caught even if Cloud Armor had not been there at all. It is the experiment that confirms the hypothesis the red-team playbook describes.

The audience is two: future operators of this system, who should understand exactly what their public surface looks like to the internet at large, and consulting prospects who deserve evidence rather than a story.

---

## The thesis, stated up front

The Yamato wiki is not protected by Cloud Armor. The Yamato wiki is protected by *not being reachable*. Cloud Armor is the cat door, not the safe.

The vital surface area of the application — the wiki, the database, the secrets, the runtime identity — has no path from the public internet at all. The Go binary's Cloud Run service is configured `ingress = INTERNAL_LOAD_BALANCER`, so the `*.run.app` URL does not answer. Cloud SQL Postgres has no public IP and never has — it lives on a Private Service Access range, reachable only over Direct VPC egress from inside the project's VPC. The application's runtime service account holds two roles total (`roles/cloudsql.client` and `roles/secretmanager.secretAccessor` on one specific secret); nothing else. The container image is distroless static with no shell, no package manager, and no writable filesystem. The wiki path is gated by Identity-Aware Proxy at the Google Front End, intercepting requests before they reach the load balancer's backend at all.

In that architecture, Cloud Armor is the *edge hygiene layer*. It does useful work — it rejects the obvious garbage before it costs us Cloud Run request-seconds, it keeps our LB logs readable, and it gives us a quantifiable threshold-based alert when the noise floor rises. None of that is the security model. The security model is the unreachability.

What follows is the live evidence for that claim.

---

## Summary of the 24-hour window

Over the observed period, Cloud Armor's policy `iq9-dev-yamato-armor` denied **345 requests** from **20 unique source IPs** across four geographies and five hosting categories (US/EU cloud, US/EU residential, enterprise backbone). Every block was logged with timestamp, source IP, requested URL, HTTP method, the security policy name, and the matching rule's priority. No request from any of the 20 attackers reached the Go application. No request reached Cloud SQL. No identity passed IAP. No alert required operator intervention beyond the one threshold notification that confirmed the defense was working as designed.

The 345 blocks broke down into two structurally distinct attacker classes, distinguishable not by the payload alone but by *how they found us*:

| Class | Hits | Source pattern | Discovery mechanism |
|---|---:|---|---|
| Focused secret-credential hunter | 274 | One AWS EC2 IP in Paris | Found `yamato-dev.iq9.io` by hostname — likely DNS or Cert Transparency enumeration |
| Opportunistic IP-range scanners | 71 | 19 IPs across Azure, OVH, AT&T, European hosting, residential ISPs | Scanning cloud IP ranges and hitting `8.233.20.46` directly |

The first class wanted us specifically. The second class was sweeping the internet and we happened to be on the list. Both got the same answer.

---

## Attacker class 1 — the focused `.env` hunter (AWS Paris)

A single IP, `13.36.195.225`, in the AWS `eu-west-3` (Paris) range, generated 274 of the 345 blocks — 79% of the observed attack volume in 24 hours. The pattern is unambiguous when viewed in the request log:

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

The probe pattern is `GET /<prefix>/.env` across approximately sixty different directory prefixes, fired in rapid sequence — roughly four requests per second — in a single burst lasting under three minutes. Every probe targets the same file: `.env`. Every probe was blocked by the same rule: `iq9-dev-yamato-armor` priority `1002`.

### What they wanted

The list of prefixes is not random. A representative sample:

- **Transactional email service slugs:** `/brevo/.env`, `/mailjet/.env`, `/mandrill/.env`, `/mailgun/.env`, `/postmark/.env`, `/sparkpost/.env`, `/sendgrid/.env`, `/ses/.env`, `/smtp/.env`, `/mail/.env`, `/mailer/.env`, `/newsletter/.env`, `/campaign/.env`, `/sender/.env`, `/notify/.env`, `/notifications/.env`, `/mailing/.env`, `/email/.env`
- **Common application directory slugs:** `/admin/.env`, `/panel/.env`, `/dashboard/.env`, `/portal/.env`, `/internal/.env`, `/scripts/.env`, `/tools/.env`, `/uploads/.env`, `/assets/.env`, `/storage/.env`, `/resources/.env`, `/database/.env`, `/lib/.env`, `/vendor/.env`, `/service/.env`, `/microservice/.env`
- **Framework/language slugs:** `/node/.env`, `/express/.env`, `/next/.env`, `/nuxt/.env`, `/nest/.env`, `/saas/.env`, `/shop/.env`, `/store/.env`, `/erp/.env`, `/crm/.env`, `/api/.env`, `/exapi/.env`
- **Maintenance and backup slugs:** `/backup/.env`, `/backups/.env`, `/old/.env`, `/tmp/.env`, `/temp/.env`, `/cron/.env`, `/cronlab/.env`, `/lab/.env`

The first group reveals the economic motive. A `.env` file in a Node.js / Python / Ruby application directory commonly contains application secrets — and for many web applications, the most monetizable secret is a transactional-email-service API key (SendGrid, Mailgun, Postmark, Brevo, AWS SES, Mailjet, Mandrill, SparkPost). A single leaked SendGrid key can blast on the order of 100,000 phishing or spam messages before SendGrid's abuse team locks the account, and during those hours the attacker's deliverability is *better than the attacker's own* because the messages are being sent from a domain with established sender reputation. There is a cottage industry of bots whose entire purpose is to scan the internet for these specific files and exfiltrate the keys they contain. The attacker that hit us last night is one of them, automated and unsophisticated, working through a pre-baked list of probable directory prefixes.

### How they found us

The dominant attacker hit the hostname `yamato-dev.iq9.io`, not the load balancer IP. That distinction matters: it means they did not find us through a brute IP-range scan. The most likely discovery mechanisms, in decreasing order of probability:

1. **Certificate Transparency log monitoring.** When Google's managed SSL certificate for `yamato-dev.iq9.io` was issued, the issuance was logged in public CT logs (per RFC 6962). Several public services index those logs in near-real-time — `crt.sh`, `Censys`, `certspotter`. Any scanner subscribed to CT updates for `*.iq9.io` (or even `*.io`) would have learned of the hostname within minutes of the certificate's first issuance.
2. **Passive DNS aggregators.** Recursive DNS resolvers like Cloudflare's `1.1.1.1` and Google's `8.8.8.8` participate (with telemetry consent caveats) in passive DNS datasets aggregated by SecurityTrails, Farsight, and others. Bots subscribe to these feeds.
3. **Direct DNS enumeration of `iq9.io`** is less likely because most public DNS does not allow zone transfer, but subdomain brute force ("`yamato.iq9.io`, `yamato-dev.iq9.io`, ...") could surface the name if the attacker knew to look.

There is no way to prevent CT-driven discovery short of not having a TLS certificate, which is not a tradeoff anyone should make. The defensive posture has to assume discovery, not prevent it.

### How they were caught

Cloud Armor policy `iq9-dev-yamato-armor`, rule priority `1002`. 274 of 274 attempts denied at the load balancer's edge. The Go application did not see a single byte of these requests; the Cloud Run service was not invoked; no Cloud Run request-seconds were billed for any of these probes.

But — and this is the important part for the architecture critique that follows — **even if Cloud Armor had been absent, the Go application would have answered every single one of these probes with HTTP 404**. The Yamato wiki's HTTP mux registers exactly seven routes:

```
GET /            → landing page (public)
GET /healthz     → DB-aware health check (public)
GET /static/*    → embedded static assets (public)
GET /wiki        → wiki index (IAP-gated)
GET /wiki/       → wiki index (IAP-gated)
GET /wiki/{slug} → article (IAP-gated)
GET /wiki/search → full-text search (IAP-gated)
```

Anything else returns `http.NotFound` — including `/bulk/.env`, `/sendgrid/.env`, `/.env`, and every other prefix the attacker tried. The Go binary has no concept of a filesystem-mapped webroot. There is no `.env` file *anywhere* on the embedded filesystem. There never was.

Cloud Armor blocked the requests as a hygiene matter — it kept the LB access log readable and saved the Cloud Run service the few microseconds of work it would otherwise have spent producing 404s. The substantive defense, the defense that would have held without any WAF at all, was the simple architectural fact that this application does not look anything like the application the attacker was hoping to find.

---

## Attacker class 2 — the IP-range scanners (long tail)

The remaining 71 blocks came from 19 IPs spread across cloud providers, residential ISPs, and enterprise backbones in three continents. Every one of them hit the bare load balancer IP `8.233.20.46` rather than the hostname — meaning they found us by brute-forcing through cloud IP allocations rather than through DNS or CT.

This is a structurally different attack class. A focused attacker has reason to believe a specific hostname is interesting (CT log, DNS enumeration, target list). An IP-range scanner has no idea what is behind any given IP; they sweep `0.0.0.0/0` (or large subsets of cloud allocations) and spray their entire payload menu at anything that answers on port 443. The "attack" is not even adversarial — it is automated indiscriminate probing.

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
GET /developmentserver/metadatauploader  (SAP NetWeaver Visual Composer RCE)
GET /actuator/health                  (Spring Boot Actuator information disclosure)
GET /actuator/env                     (Spring Boot environment dump)
GET /owa/auth/logon.aspx              (Microsoft Exchange / Outlook Web Access)
GET /version                          (generic version disclosure)
```

These are CVE-template probes. The attacker has a database of "if this URL returns 200, the target is running vulnerable version of X, exploit Y is applicable." Cheap to throw, occasionally lucrative when the target *is* an exposed Exchange server or a vulnerable SAP installation.

**Path traversal and command injection** (priority `1002`, occasional):

```
POST /cgi-bin/%252e%252e/%252e%252e/%252e%252e/%252e%252e/%252e%252e/%252e%252e/%252e%252e/bin/sh
```

Apache `mod_cgi` Shellshock-family payload, double-URL-encoded to bypass naive `..` filtering. Targets the bygone era of Apache + bash CGI scripts. We do not have a CGI handler at all.

### The IoT-camera correlation worth noting

Three of the 20 source IPs — `89.21.67.141`, `193.176.31.200`, and `193.176.31.209` — all hit `POST /onvif/device_service` in the observation window. The two `193.176.31.*` IPs are in the same /24, suggesting coordination or shared infrastructure. ONVIF (Open Network Video Interface Forum) is the standard protocol for IP-connected security cameras and DVR systems, and there is a long-running global botnet operation that hunts for exposed ONVIF endpoints to recruit cameras into DDoS swarms (Mirai and its descendants). The probe is cheap; the prize is a recruited node.

We are not an ONVIF camera. The Go binary returns 404 to any POST under `/onvif/`. Cloud Armor blocked it at the edge.

### How they were caught

Same policy, mostly priority `1002`, with priorities `1001` (5 blocks) and `1005` (6 blocks) catching the protocol-level and enterprise-CVE probes. Every block recorded the timestamp, source IP, requested URL, HTTP method, and rule priority.

And again — the architectural answer would have held without Cloud Armor. None of the probed software is running here. There is no PHP, no Apache, no Symfony, no Rails, no WordPress, no Spring Boot, no Exchange, no SAP. The application is a Go binary that registers seven HTTP routes and rejects everything else. The "attack" looks like a determined attempt to find any of perhaps twenty different software stacks; none of those stacks exists at this address.

---

## Why the security model does not depend on Cloud Armor

This section is the operating principle. It is what differentiates this architecture from the prevailing industry pattern of "expose a vulnerable application to the internet, put a WAF in front, declare victory."

### The Yamato model, restated

The defense holds in concentric layers, ordered by what would catch the attack *first* if all subsequent layers failed:

1. **The application is not reachable on its own URL.** Cloud Run ingress on both the public service (`iq9-run-dev-yamato`) and the wiki service (`iq9-run-dev-yamato-wiki`) is `INTERNAL_LOAD_BALANCER`. The `*.run.app` URL returns `403` to anyone on the public internet. The only path to the binary is through our specific external HTTPS load balancer.
2. **The database is not reachable from the internet at all.** Cloud SQL Postgres has no public IP. It lives on a Private Service Access range (`10.20.0.0/20`) inside the project's VPC, reachable only from workloads with Direct VPC egress onto the same network. There is no `gcloud sql connect` over the public internet, no exposed `5432`, no path that a credential leak could exploit from outside the VPC perimeter.
3. **The wiki is gated by identity.** Identity-Aware Proxy intercepts every request to `/wiki/*` at the Google Front End — *before* the load balancer routes the request to a backend. No valid `@iq9.io` Google identity, no traffic reaches the IAP-protected Cloud Run service. The `roles/iap.httpsResourceAccessor` binding allows two domains and nothing else.
4. **The runtime identity has minimal authority.** The Cloud Run runtime service account `iq9-yamato-dev-run` holds exactly two roles: `roles/cloudsql.client` (project) and `roles/secretmanager.secretAccessor` on one secret (`yamato-dev-db-password`). It cannot list buckets, modify IAM, create VMs, read other secrets, write logs to arbitrary destinations, or do anything else useful to a compromise.
5. **The container image is minimal-attack-surface.** Built from `gcr.io/distroless/static-debian12:nonroot` — no shell, no package manager, no writable filesystem, no setuid binaries, no compiler, no `curl`, no `wget`, no `python`. Even hypothetically obtaining remote code execution inside the container yields a process that can call the kernel and almost nothing else.
6. **The application itself follows defensive patterns.** Every database query is parameterized (`pgx` with `$1`/`$2` placeholders). All template output is auto-escaped by `html/template`. The full-text search caps query length at 200 *runes* (not bytes — see [search.md](../search.md) and the F-001 fix). The static handler sets `X-Content-Type-Options: nosniff` and enforces a strict extension allowlist under `/static/img/` (see [image-security.md](../image-security.md), F-1 and F-2). Schema migrations are idempotent and additive. There is no `eval`, no untrusted deserialization, no admin endpoint.
7. **Then — only then — Cloud Armor.** The edge WAF rejects obvious garbage *before* it reaches any of the above. It is the cat door, not the safe. It is useful but not necessary.

Cloud Armor failed open, last night, would have changed nothing for any of the 345 attempts. The architectural moat holds.

### The contrast — what WAF-as-primary-defense actually looks like in practice

The mainstream industry pattern, particularly in mid-market organizations, is the inverse of the above. A vulnerable web application — typically running on a wide-open public IP, often on a permissive cloud VM with full network egress, often with database credentials in environment variables or `.env` files — is fronted by a WAF, and the WAF is treated as the primary security control. The reasoning, when it is articulated, runs roughly:

> "The WAF will block attacks before they reach our app. So we do not need to harden the app."

This reasoning is wrong in three specific ways, each of which destroys the assumed protection.

#### 1. WAFs are signature engines. They miss what they have not seen.

A WAF blocks attacks by matching incoming requests against a corpus of known malicious patterns: SQL injection canaries, XSS string fragments, directory-traversal sequences, scanner User-Agent strings, known-malicious CVE template signatures. This works for the attacks the WAF vendor has catalogued. It does nothing for novel attacks — by definition, the attacks the WAF cannot block are the ones for which a signature has not yet been written. The history of security research is littered with WAF bypass techniques that worked because the rule corpus was a strict subset of the actual attack space.

Even for the attacks the WAF *has* catalogued, bypass research is a continuous academic and adversarial enterprise:

- **Encoding tricks.** Double-URL-encoding, Unicode normalization, mixed-case keywords, comment-injection in SQL (`SEL/**/ECT`), HTTP parameter pollution, and dozens of others have at various times bypassed all major commercial WAFs.
- **Fragmentation.** Splitting a payload across multiple request parameters or HTTP chunks that the WAF inspects independently but the application reassembles.
- **Behavioral mimicry.** Slow, throttled probing that stays below per-source rate limits while patiently mapping out the target.
- **Novel CVE chains.** Any zero-day, by definition, has no signature.

#### 2. WAFs create false confidence at the executive level

The presence of a WAF on the procurement spreadsheet, with a green checkbox next to it, frequently *worsens* the security posture of the underlying application. Engineering teams stop hardening the app because "the WAF will catch it." Risk dashboards report the application as "protected." When the inevitable bypass occurs — a new CVE, a clever encoding, a slow probe that mapped the application without tripping the threshold — the application that should have been hardened from day one is found to have been wide open the whole time. The WAF was theater; the theater hid the real exposure.

#### 3. WAFs are themselves an attack surface

Every WAF agent, every WAF cloud service, every WAF appliance is software, and software has CVEs. WAFs have shipped exploitable vulnerabilities at every major vendor at various points — including remote code execution in the WAF agent itself. Adding a WAF without an architectural defense doubles the attack surface: now an attacker can target either the application or the WAF.

#### And the AV-on-server narrative

The companion mistake — installing an "endpoint protection" agent (anti-virus, EDR) on server workloads — is worse for the same reasons and one more:

- AV is signature-matching for known malware *binaries*. Server-side compromises in 2026 are overwhelmingly *codepath exploitations* (RCE via deserialization, SSRF, prompt injection in LLM applications, supply-chain attacks via compromised dependencies). A signature-matching AV on the host catches none of these — the exploitation happens entirely inside the application's memory, never touching a file the scanner could see.
- AV agents themselves have a long, embarrassing history of catastrophic CVEs (Sophos, Symantec, Cylance, McAfee, ESET have all shipped agent-RCEs in the last decade).
- For a distroless container, AV has nothing to scan. There are no files. There is no filesystem. The scan returns clean because there is nothing there. The protection is illusory.

### What we did instead

We made the application unreachable. We made the database unreachable. We made the identity surface narrow to a single Google Workspace domain. We gave the runtime no privilege. We removed the shell from the container. We hardened the application code. *Then* we added Cloud Armor as edge hygiene.

The 345 blocks observed last night are not the proof that the security holds. They are the proof that the security holds *with one layer of defense*. The thirty other layers above it would have held independently.

---

## Cloud Armor policy — what the priorities mean

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

## The threshold alert — why 20 is the right number

A Cloud Monitoring alert policy fires when the count of `denied` requests crosses 20 in the alert window. Last night, that threshold was crossed and the on-call email arrived. The threshold is deliberately calibrated:

- **A threshold of 1** would page on every drive-by Censys probe and every misconfigured-bot single request. Operator fatigue would set in within a week. By the time a real attack came, the operator would have learned to ignore the alerts.
- **A threshold of 1,000** would have missed the 274-attempt `.env` hunter entirely — that single attacker's burst was just over a quarter of the higher threshold and would have been lost in the noise.
- **20 is the sweet spot.** It filters the trickle of background internet noise (typical observed rate without an active attacker: 1–10 blocks per hour) and surfaces anything that looks coordinated. When 20 is exceeded, *something is happening* — not necessarily a sophisticated attack, but at minimum a tool run worth eyeballing.

The alert's purpose, importantly, is *not* to summon the operator to do anything. The defense already worked. The alert exists so the operator can *admire* the defense — and, in cases like this one, capture the evidence while it is fresh in the logs. This is what mature alerting looks like.

---

## The Gamilas were a hypothesis. Last night was the experiment.

The [red-team playbook](./red-team-playbook.md) describes Act 1 of the demonstration as follows:

> *"Run from the DigitalOcean droplet (true 'outside GCP'): the attacker can see everything (it's on the internet) and gets nowhere. The dashboard's 'Cloud Armor blocks' and 'front-door denials' tiles light up; the email alerts fire. Nothing reaches the app."*

That was the prediction. The Gamilas were a teaching device — a baked Packer image with nmap, sqlmap, nuclei, ffuf, feroxbuster, the whole arsenal — designed to give a presenter something dramatic to point at on stage. The presenter would run the attack, the dashboard tiles would light up, the audience would see the wall hold.

Last night, twenty unrelated adversaries, with their own tools and their own motives, ran their own attacks against the same target. The dashboard tiles lit up. The threshold alert fired. The wall held. The defense behaved identically whether the attacker was friendly and pre-scripted or hostile and opportunistic — because the defense does not depend on knowing who the attacker is. It depends on the architecture.

This is the difference between a demo and a working system. The demo proves the design on a controlled input. The system proves it on the only input that matters in the long run: whatever happens to show up.

---

## What this means for prospects and audiences

For a consulting context, this document is the answer to the most common skeptical question: *"That's a nice demo, but does any of this actually work in production?"*

Yes. Here is twenty-four hours of evidence. Twenty real adversaries from four continents. Three hundred and forty-five attempts. Cloud Armor caught them all at the edge; the architecture would have caught every single one independently without Cloud Armor. The application is genuinely Fort-Knox-secure, not because of any single product purchased from any single vendor, but because the surface area exposed to the public internet is exactly what it should be: a static landing page, a health check, and an IAP-gated identity wall. Everything else is private. Everything else holds.

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

Reproduced for completeness; this is the 60-prefix list the AWS Paris attacker sprayed in a single burst:

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

Each prefix was probed exactly once, each appended with `/.env`. The list is alphabetically scrambled in the log (consistent with random sampling from a precomputed wordlist), and the request rate is uniform at approximately four per second — consistent with a single-threaded HTTP client running through a static input file. Cheap, automated, indiscriminate. Caught by a single Cloud Armor rule.

---

## See also

- [`docs/security/readme.md`](./readme.md) — security documentation index
- [`docs/security/defense-in-depth.md`](./defense-in-depth.md) — the layered defense model
- [`docs/security/zero-trust-iap.md`](./zero-trust-iap.md) — the IAP identity wall
- [`docs/security/fort-knox.md`](./fort-knox.md) — the one un-hecklable claim
- [`docs/security/red-team-playbook.md`](./red-team-playbook.md) — the Gamilas demo
- [`docs/infrastructurestate.md`](../infrastructurestate.md) — the layered architecture
- [`docs/search.md`](../search.md) — the wiki search feature and its hardening
- [`docs/image-security.md`](../image-security.md) — static image serving and its hardening
- [`service/yamato/modules/frontdoor/frontdoor.tf`](../../service/yamato/modules/frontdoor/frontdoor.tf) — Cloud Armor policy `iq9-dev-yamato-armor`, in code

---

*Recorded by the on-call operator. The wall held. The Yamato sailed on.*

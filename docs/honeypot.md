# Honeypot Tripwires — Layer 0 Lure on the Public Service

Six deliberately enticing endpoints that exist solely to identify, fingerprint, and track the attackers who probe us. The honeypots are *not* a defense in the same sense as Cloud Armor or IAP — they are an intelligence-collection surface that sits **outside** the perimeter gate, captures the data Cloud Armor's DENY logs cannot, and feeds a new tile on the [`/wiki/noc` dashboard](./noc.md). The naming follows the architecture: the [Fort Knox claim](./security/fort-knox.md) walks Layers 1 through 5; the honeypots are **Layer 0** — the lure outside the fence.

This document is the *why* and the *how*: what the honeypots are, where they sit in the Fort Knox model, the request lifecycle, the six paths and their fake content, the structured log shape the NOC tile depends on, the security posture, the open issues a reviewer flagged that did not block the ship, and how to add a seventh path the day a new attacker class arrives.

## What this is

A bot scanning the internet for `/admin`, `/backup.sql`, `/phpmyadmin`, and the rest of the classic-exposed-software menu hits the Yamato wiki's public load balancer at `https://yamato-dev.iq9.io/<one of six paths>`. Cloud Armor lets the request through because the URL itself does not match a WAF signature — these paths are *bait*, not exploits. The request lands on the public Cloud Run service `iq9-run-dev-yamato`, the Go mux dispatches it to a shared honeypot handler, the handler emits **one** structured Cloud Logging entry with the attacker's IP, user-agent, request body prefix, and the path they probed, and returns a small believable fake 200 made entirely of obviously-synthetic placeholders.

The visible payoff is a new tile on the live NOC dashboard — *Tripwire hits · 24h* — showing the total honeypot hit count over the last day plus the top three paths attackers tried. The operational payoff is the structured-log stream itself: `jsonPayload.tripwire=true` in Cloud Logging captures every probe with the attacker context Cloud Armor does not record, so a future analysis (or `/wiki/noc/history`, or an email-on-first-hit-from-a-new-IP alert) can sit on top of the same data without changing the app.

The honeypots do not defend anything. They do not block attackers, they do not slow them down, they do not rate-limit them, they do not raise their cost. Attackers who probe `/admin` get a fake login form and disappear into their next 100,000 targets. What we get back is the data — *who* tried us, *what* they sent, and *what they were running when they sent it.* That is the intelligence, and that is what the Fort Knox model did not previously have.

## The Fort Knox layer placement — Layer 0

The [in-the-wild evidence from 2026-06-03](./security/in-the-wild-2026-06-03.md) names five concentric Fort Knox security layers — Cloud Armor at the perimeter, IAP across the base, locked Cloud Run ingress at the depository gate, the least-privilege runtime SA + hardened Go app at the front desk, and private-IP Cloud SQL at the vault. The honeypots are not one of those five. The five layers all *defend*; the honeypots collect intelligence on attackers who have not yet challenged a single one of them.

Place the honeypots in the Fort Knox analogy this way: **a few unattended boxes left in the parking lot outside the perimeter fence, each labelled "TICKETS" or "PAYROLL FILES — DO NOT TOUCH."** Anyone who tries to open one of those boxes never gets near the fence, never gets near the base, never gets near the depository. But the parking lot has cameras, and we know exactly who tries which box, in what order, with what tools. That intelligence does not protect the gold — but it tells us who is casing the place, and that is its own kind of operational value.

Concretely:

- **Layer 0 — the lure (this document).** Honeypot endpoints on the public Cloud Run service. Intelligence collection. Outside the perimeter gate.
- **Layer 1 — Cloud Armor at the LB.** Pattern-based WAF blocks at the edge. 345 blocks in the [observation window](./security/in-the-wild-2026-06-03.md).
- **Layer 2 — IAP at the GFE.** `@iq9.io` identity required on every `/wiki/*` request.
- **Layer 3 — Cloud Run ingress = INTERNAL_LOAD_BALANCER.** `*.run.app` URLs refuse public callers.
- **Layer 4 — Runtime SA + Go app code.** Least privilege, parameterized queries, auto-escape, length caps, allowlists.
- **Layer 5 — Cloud SQL on private IP.** No external door to the vault.

Two things follow from the placement.

First, **Layer 0 does not replace any of Layers 1–5.** A honeypot hit and a Cloud Armor DENY are distinct events on the same request stream. Cloud Armor's DENY at the LB stops the truly hostile payloads (sqli, command-injection, traversal) before they reach the app; the honeypots accept the *cosmetically* hostile paths (the bait paths) and convert them into telemetry. Cloud Armor blocks `GET /.env`. The honeypot lets `GET /admin` through and records the attacker who tried it. Different events, different layers.

Second, **the honeypots only see what gets past Layer 1.** A probe that matches a Cloud Armor WAF rule gets DENY'd at the edge and never reaches the Go handler, so it never produces a tripwire log line. The [in-the-wild evidence](./security/in-the-wild-2026-06-03.md) showed 345 such DENYs in 24 hours; none of them would appear on the tripwire tile. The tile and the existing *Edge blocks* tile are complementary views of the same incoming probe traffic — Cloud Armor handles the payload-pattern probes, the honeypots handle the bait-path probes, and the operator reads both tiles together to see the full picture.

## The consulting frame

> *We don't just block attackers — we identify, fingerprint, and track them.*

That is the sentence the honeypots add to the Fort Knox pitch. The existing pitch ends at "every block you see on this page was caught at Layer 1; we have four more layers behind it." The tripwire tile lets it continue: "and for the bots whose probes Cloud Armor does not match — the ones rattling the parking-lot boxes — we know their IP, their tool, and the exact payload they tried, in real time." Open `/wiki/noc` in front of a prospect; point at the *Tripwire hits · 24h* tile; the supporting paths and counts are right there.

The framing matters because operations security is usually pitched as a binary — *we blocked them* — and binaries are easy for a sharp prospect to heckle. *"Are you sure you blocked all of them?"* The intelligence frame is harder to heckle. *We blocked the ones we recognised, we recorded the ones we didn't, and we can show you both lists.* That answer is more honest, and a more honest security pitch is — counterintuitively — a more confident one.

## Architecture — one tripwire hit, end to end

Two request paths meet at the tripwire tile: the attacker probing the public service, and the operator viewing the dashboard. Both are sketched here.

### Attacker path

```
GET https://yamato-dev.iq9.io/admin             (or any of the six paths)
        |
        v
External HTTPS LB        service/yamato/dev/frontdoor
        |  url_map default backend → public Cloud Run service
        |  (NOT the /wiki/* path rule — the honeypots live outside IAP)
        v
Cloud Armor policy       iq9-dev-yamato-armor          [Layer 1]
        |  pattern-based WAF: sqli/xss/lfi/rfi/rce/scannerdetection/
        |  protocolattack/sessionfixation. None of the six honeypot
        |  paths matches a signature at the dev sensitivity, so the
        |  request passes through.
        v
Cloud Run service        iq9-run-dev-yamato            [public; no IAP]
        |  ingress = INTERNAL_LOAD_BALANCER (Layer 3 still holds —
        |  *.run.app refuses; only the LB can invoke)
        v
stdlib ServeMux          app/yamato/app.go             [Layer 4]
        |  honeypotPaths() registers /admin, /backup.sql, /api/v1/users,
        |  /server-status, /phpmyadmin, /console — all on the PUBLIC
        |  mux, all dispatch to a.handleHoneypot.
        v
handleHoneypot           app/yamato/honeypot.go
        |  1. logTripwire(r): one slog.JSONHandler entry to stderr
        |     with severity=NOTICE, tripwire=true, path, method,
        |     remote_ip, user_agent, body_truncated.
        |  2. write the canned fake 200 from honeypotResponses[path]
        |     with Server: fake-honey/0.0 and Cache-Control: no-store.
        v
Cloud Run lifts the stderr JSON line into jsonPayload  [Cloud Logging]
        |  every top-level slog key becomes a jsonPayload.<key> field.
        v
HTTP 200 with believable fake body back to the attacker
```

### Operator path

```
GET https://yamato-dev.iq9.io/wiki/noc          (operator dashboard)
        |
        v  (Layer 1) Cloud Armor → (Layer 2) IAP → (Layer 3) Cloud Run
        v
handleNOCDashboard       app/yamato/noc_dashboard.go
        |  fans out FOUR independent goroutines, each with a 6s timeout:
        |    scan24h           ← Cloud Armor DENY events (existing)
        |    scan1hCount       ← Cloud Armor DENY counts (existing)
        |    fetchAlertTile    ← Cloud Monitoring alert policies (existing)
        |    scanTripwire      ← honeypot hits (NEW)
        v
scanTripwire(ctx, projectID, now, "iq9-run-dev-yamato")
        |  logadmin.Entries with filter:
        |    resource.type="cloud_run_revision"
        |    AND resource.labels.service_name="iq9-run-dev-yamato"
        |    AND jsonPayload.tripwire=true
        |    AND timestamp>="<RFC3339 of (now - 24h)>"
        |  capped at nocEntryCap=3000 entries, NewestFirst.
        |  Returns (total int64, paths map[string]int64).
        v
nocTripwireTile{Total, Rows=top3(paths), Available, Empty}
        v
templates/noc_dashboard.html renders the gold-accented tile
```

The pattern is identical to the three pre-existing NOC fan-outs — same client (`logadmin`), same `nocEntryCap`, same `nocAPITimeout`, same per-tile fallback on error, same Application Default Credentials path (the runtime SA `iq9-yamato-dev-run` was already granted `roles/logging.viewer` for the existing scans, so no IAM change was needed for the new one). The new tile shares the page's degrades-rather-than-500s contract: a Cloud Logging outage paints the tile *"Cloud Logging unavailable — retry on next refresh"* and the rest of the page renders normally.

## The six paths

Each path returns a small (<2 KiB) believable fake 200 with a Content-Type that matches what the named software would actually serve. The hard `<2 KiB` cap is enforced at startup via an `init()` panic in `honeypot.go`, so no future maintainer can silently grow a lure beyond the budget.

| Path | Content-Type | What the fake looks like |
| --- | --- | --- |
| `/admin` | `text/html` | A generic "Admin Login" form posting to `/admin/login`, footer `build host.example · v0.0.0-FAKE-HONEY`. |
| `/backup.sql` | `text/plain` | An obvious `mysqldump 10.13` header against `Database: iq9-fake-honey`, one `users` table DDL, two rows with email `fake-user-N@host.example` and `api_key` of the form `AKIA0000000FAKEHONEYN`. |
| `/api/v1/users` | `application/json` | A two-element `users` array with the same `fake-user-N` / `AKIA0000000FAKEHONEYN` shape as the SQL dump, plus `count` and `next` siblings. JSON validity is verified at startup. |
| `/server-status` | `text/plain` | Apache `server-status` page formatted exactly like the real thing — `Apache/0.0.0 (FAKE-HONEY)`, server uptime 0 minutes, all counters at zero, full scoreboard key. |
| `/phpmyadmin` | `text/html` | A Verdana-styled phpMyAdmin login with `pma_username` / `pma_password` / `pma_servername=host.example` fields and footer `phpMyAdmin 0.0.0-FAKE-HONEY`. |
| `/console` | `text/html` | A green-on-black "Management Console" form posting to `/console/auth` with `user` / `token` fields. |

The developer verified against the Cloud Armor policy in `service/yamato/modules/frontdoor/frontdoor.tf` (lines 33-42 + 81-118) that none of these paths are caught by an existing priority rule at the dev WAF sensitivity. The policy is built entirely from Google's preconfigured WAF rule families (`sqli-v33-stable`, `xss-v33-stable`, `lfi-v33-stable`, `rfi-v33-stable`, `rce-v33-stable`, `scannerdetection-v33-stable`, `protocolattack-v33-stable`, `sessionfixation-v33-stable`) plus a per-IP rate-based ban at priority 2000 and a default allow at the bottom. The WAF rules match on **payload/header patterns** (SQL syntax, JS sinks, traversal sequences, scanner UAs), not URL paths. At the dev sensitivity (`waf_sensitivity=1`) all six paths pass through unimpeded. See **F-001** in *Known issues* below for the sensitivity-bump caveat — two of the six paths are on the CRS scanner-detection list at paranoia level 2+, and a future environment that raises sensitivity would intercept them at the edge.

## The fake content principle

Every value in every fake response is obviously synthetic. The bait is the *shape* of the response (a believable Apache `server-status`, a believable `mysqldump` header, a believable phpMyAdmin login form), never the content (no real key, no real project ID, no real SA email, no real hostname). A pen-tester or future operator who pastes any value from a tripwire response into the real GCP console gets a clean miss — and that is the contract.

The convention, codified in `honeypot.go`:

- Hostnames are `host.example`. RFC 6761 reserves the `.example` TLD for exactly this purpose; it will never resolve to anything real.
- Project IDs and database names are `iq9-fake-honey`. The `fake-honey` segment is a deliberate sentinel; no real iq9 project has it.
- API keys mimic AWS access-key format (`AKIA...`) but use the all-zero prefix `AKIA0000000FAKEHONEY1` / `AKIA0000000FAKEHONEY2` — visibly fake, structurally a 20-character access-key shape so attackers' regex scanners do pick them up.
- Version strings are `0.0.0-FAKE-HONEY` (with variations like `FAKE-HONEY` in build strings). No real software ships at version 0.0.0.
- IPs are `0.0.0.0`.

A reader extending the honeypots — adding a `/wp-login.php` or a `/.env` lure — should reach for the same sentinels. If a future fake needs an email address, it is `something@host.example`. If it needs a port, it is `0`. If it needs a session token, it is `FAKE-HONEY-...`. The convention is uniform on purpose, so a future reader of either a leaked fake response or a `gcloud logging read` of the tripwire stream sees the bait at a glance.

The Tester verified the convention holds across the current six responses: `grep` for `iq9-gcp-`, `yamato-dev.iq9.io`, `@iq9.io`, the LB IP `8.233.20.46`, `us-west1`, and `@.iam.gserviceaccount.com` across `honeypot.go` returns zero matches. Only the `iq9-fake-honey`, `host.example`, `AKIA0000000FAKEHONEY1/2`, `FAKE-HONEY`, and `0.0.0.0` placeholders appear.

## The log shape

Every honeypot hit produces exactly one structured JSON log line on the public service's stderr. Cloud Run lifts each top-level JSON key into the corresponding `jsonPayload.*` field in Cloud Logging, so the NOC tile's filter `jsonPayload.tripwire=true` matches every honeypot entry and nothing else. A representative entry, captured from a synthetic `sqlmap` POST in development:

```json
{
  "time": "2026-06-03T16:12:58.446167Z",
  "level": "INFO",
  "msg": "honeypot tripwire",
  "severity": "NOTICE",
  "tripwire": true,
  "path": "/admin",
  "method": "POST",
  "remote_ip": "203.0.113.42",
  "user_agent": "Mozilla/5.0 (compatible; sqlmap/1.7-stable; http://sqlmap.org)",
  "body_truncated": "u=admin&p=' OR 1=1 --"
}
```

The fields, by purpose:

- `severity: "NOTICE"` — Cloud Logging promotes this to the entry-level severity, overriding slog's `level: "INFO"` inference. NOTICE places tripwire entries in their own bucket between INFO (noise) and WARNING (operator-actionable), which is the right reading: a tripwire hit is interesting but not, on its own, a page-worthy event.
- `tripwire: true` — the discriminator. The NOC tile filters on this exact predicate; a future tile or log-based metric can do the same.
- `path` — the URL path the attacker hit, as `r.URL.Path` reads it from the mux. The top-3 breakdown on the NOC tile aggregates over this field.
- `method` — `GET`, `POST`, `HEAD`, `PROPFIND`, or any other verb. The mux deliberately registers without a method prefix so unusual verbs (which bots use to fingerprint deployed software) are also captured.
- `remote_ip` — the attacker's IP, read from the first comma-separated token of `X-Forwarded-For` (which the Google HTTPS LB rewrites to put the verified client first) with `r.RemoteAddr` fallback for local `go run`. Trustworthy in production; the LB cannot be bypassed because the Cloud Run ingress is `INTERNAL_LOAD_BALANCER`.
- `user_agent` — the bot's reported UA. `sqlmap`, `nuclei`, `Go-http-client/1.1`, `Mozilla/5.0`, the lot. A high-quality fingerprint for clustering related probes.
- `body_truncated` — the first 1024 bytes of the request body, captured via `io.LimitReader`. Names the payload family — SQL-injection one-liner, JNDI string, base64-wrapped reverse shell, plain `username=&password=`.

Two structural choices worth naming.

**Structured JSON, not free text.** The NOC tile's filter is `jsonPayload.tripwire=true` — a sharp, type-aware predicate that Cloud Logging can index. A free-text `log.Println("honeypot hit on " + path)` would force the tile to substring-match against the message body, which is brittle (any future log line that happened to contain the word "honeypot" would match) and slow (Cloud Logging cannot index arbitrary substrings the way it indexes structured field equality). Structured JSON is also forward-compatible: when a future iteration adds a `geo_country` field or an `attacker_class` cluster ID, the tile keeps working without a filter change.

**The log records the request, never the response.** What we want to study is what the attacker *tried* — their payload, their tool, their target — not what we *lied about* in the response. The canned fake body is constant per path; logging it would add noise without adding information. The Developer named this explicitly in the package comment, and it is the contract any future log-shape change should preserve.

## The NOC tile

The new tile is *Tripwire hits · 24h*, registered to the right of *Top WAF rule priorities · 24h* in the dashboard grid (see [`docs/noc.md`](./noc.md) for the full tile catalogue). Its shape:

- **Headline.** The total count of honeypot hits in the last 24 hours, in the same large numeric style the *Edge blocks* tile uses. The number gets a gold "hot" accent (`.t-num-trip`) when greater than zero, so a quiet day reads as a calm `0` and an active day visibly lights up.
- **Top 3 paths.** Below the headline, an ordered list of the top three probed honeypot paths with per-path hit counts. The list uses the existing `.t-list` + `.t-key-mono` styling so attacker-controlled-looking path strings render in a monospace face consistent with the other top-N tiles. Three is the right cardinality because there are six paths total; a top-5 would be redundant.
- **Empty state.** *"No tripwires sprung in the last 24h."* No goose-egg next to an empty list; the operator sees that the scan succeeded and there was simply nothing to count. Quiet days are the common case and the tile should look composed when one happens.
- **Error state.** *"Cloud Logging unavailable — retry on next refresh."* Same fallback string the other Cloud Logging tiles use, so the operator's diagnostic intuition transfers — see [`docs/noc.md`'s operational notes](./noc.md#operational-notes) for what to check first when the message persists.

The Cloud Logging filter the tile runs, reproduced verbatim so an operator can paste it into Logs Explorer when a tile reading looks wrong:

```
resource.type="cloud_run_revision"
AND resource.labels.service_name="iq9-run-dev-yamato"
AND jsonPayload.tripwire=true
AND timestamp>="<RFC3339 of (now - 24h)>"
```

The service name is parameterised via `HONEYPOT_SERVICE_NAME` (env var, defaulting to `iq9-run-dev-yamato`) so a future test/stage environment can re-point the tile at a different public service without a code change. The 24-hour window matches the existing 24h scans for symmetry; a future history page can widen the window or aggregate across days.

## Security posture

Four properties hold the surface.

**The honeypot routes live on the PUBLIC service only.** They are registered in `app.go`'s `routes()` between the public landing handler and the `/wiki/*` block — every path comes from the same `honeypotPaths()` source-of-truth slice that the response menu uses. The LB's url_map routes `/wiki` and `/wiki/*` to the IAP-gated backend; the honeypot paths are not under `/wiki`, so they land on the public-service backend, which is not IAP-gated by design. That is what we want — IAP would 302 the attacker to Google's login before a single byte of payload reached the honeypot. The mux ordering note in [`docs/noc.md`](./noc.md#architecture--one-request-end-to-end) applies here too: Go 1.22's ServeMux gives literal-segment patterns precedence over wildcards, so a hypothetical future `/wiki/admin` would route to the wiki handler regardless of registration order, and the literal `/admin` honeypot can never accidentally shadow a real wiki article.

**Fake response content cannot leak real data.** The fake-content principle, codified by convention and verified by the Tester. Future maintainers extending the honeypots inherit the convention by reading `honeypot.go`'s comments and the existing six entries.

**The log line cannot be forged via attacker-controlled headers.** `slog.JSONHandler` JSON-escapes every string field, so an attacker sending `User-Agent: "ignored","fake_field":"injected"` produces a `user_agent` field whose value is the literal string with the embedded quotes escaped — never a sibling `fake_field` on the same entry. The Tester verified this with a newline + injected-JSON payload in a synthetic test; the slog output kept the attacker payload entirely inside the string value.

**The handler is read-only and resource-bounded.** Each request reads at most 1024 bytes of body via `io.LimitReader`, logs once, writes a canned response of at most 2048 bytes, and returns. No DB call, no external API call, no file write. The 1024-byte body cap is the only knob and it caps the largest possible log entry; a sustained probe campaign cannot exhaust memory or fill Cloud Logging quota at a rate the existing per-IP rate-based ban (priority 2000 in the Cloud Armor policy) does not already cover. See **F-003** in *Known issues* for the related observation that the rate-limit ban can sink the tripwire signal under aggressive single-IP probing — desirable from a Layer 1 perspective, an undercount from the tile's perspective.

## What honeypots are NOT

Worth making explicit, because the framing is easy to over-claim:

- **Honeypots are not a defense layer.** They do not block, slow, rate-limit, or otherwise impede attackers. An attacker who hits `/admin` gets a fake 200 and moves on. The five Fort Knox layers are what stop the actual attacks; the honeypots tell us who the attackers were.
- **Honeypots are not a replacement for Cloud Armor.** Cloud Armor's job — pattern-based WAF at the edge — is unchanged. The honeypots complement it by capturing the bait-path probes Cloud Armor lets through (because the URL itself is harmless), not by replacing the payload-pattern matching that Cloud Armor does.
- **Honeypots are not bait you can trust.** If an attacker ever submits credentials, an API key, or any other "real-looking" value to a tripwire, treat that value as **compromised**. It was bait — but the moment the attacker touched it, they treated it as theirs. Anything sent *to* a honeypot is now an unsafe input.
- **Honeypots are not "always legal everywhere."** Running unauthenticated honeypots on your own infrastructure is generally permissible in the jurisdictions iq9 operates in (the attacker initiates the connection; we serve a synthetic response; no entrapment), but the doc should not be silent on the question. If you are operating in a jurisdiction with stronger anti-deception or computer-misuse rules, or if you ever consider serving fake content that resembles a real third party's product (we do not; the fakes are deliberately generic), get legal review before extending the honeypots beyond the current shape.

## Known issues

These were flagged by the Tester against the commit that introduced the honeypots (`fc57969`). None of them block the demo; the build passes, the routes register, no real data leaks, the tile renders. Severity tags are the reviewer's. The first one is operationally meaningful before any environment promotion past dev; the others are documentation and quality concerns.

- **F-001 (medium, security)** — *Honeypot path survival depends on `waf_sensitivity=1`; bumping the sensitivity silently 403s `/phpmyadmin` and `/server-status` at the edge.* The Cloud Armor policy at `service/yamato/modules/frontdoor/frontdoor.tf` is built from preconfigured WAF rule families with no path-based deny expressions. The `scannerdetection-v33-stable` family, however, contains ModSecurity CRS rule 913120, which matches `REQUEST_FILENAME` against a list of well-known scanner-target paths (`/server-status`, `/phpmyadmin`, `/manager/`, …). Rule 913120 sits at CRS paranoia level 2, so it only fires when `waf_sensitivity >= 2`. The dev tfvars default is 1 (`modules/frontdoor/variables.tf:81`), and `service/yamato/dev/frontdoor/` does not override it — so at dev sensitivity the developer's pass-through claim holds. **But if any future environment bumps the sensitivity to 2 for tighter coverage, `/phpmyadmin` and `/server-status` will start getting 403'd by Cloud Armor before they reach the Go handler — the tripwire tile for those paths goes silent in production with no code-level indication why.** The other four honeypot paths (`/admin`, `/backup.sql`, `/api/v1/users`, `/console`) are not on the CRS 913120 fixed list and remain safe at any sensitivity. Recommended fix: at the environment promotion that raises sensitivity, swap the two affected paths for ones CRS does not target by filename (`/.env`, `/wp-login.php`, `/api/v2/keys` are still safe at PL2 — verify against the CRS rule set first), or add a Cloud Armor exception allow-listing the honeypot paths at a priority lower than `1005`. — `app/yamato/honeypot.go`.

- **F-002 (low, quality)** — *Comment in `logTripwire` describes a `honeypotBodyCap+1` read that does not match the actual code.* `honeypot.go:87-90` says *"LimitReader caps the read at honeypotBodyCap+1 so we can tell whether the body was actually truncated, but we never keep more than honeypotBodyCap bytes in memory,"* but the code is `io.ReadAll(io.LimitReader(r.Body, honeypotBodyCap))` — no `+1` anywhere and no truncation-detection logic. The captured body is `min(actual_length, 1024)` bytes and the caller cannot distinguish a 1024-byte body from a 1 MB body. Pure comment-vs-code drift; especially misleading because the field is called `body_truncated`, which strongly implies the truncation bit is recorded somewhere. Recommended fix: either replace the comment with the truth (*"longer bodies are silently truncated to that prefix"*) or actually read `honeypotBodyCap+1` and emit a `body_was_truncated: true` field when the read returned exactly that many bytes. — `app/yamato/honeypot.go:87`.

- **F-003 (low, functional)** — *Rate-limit ban at 100 req/60s/IP can sink the tripwire signal when a single attacker probes aggressively.* Cloud Armor's rate-based ban (`service/yamato/modules/frontdoor/frontdoor.tf:81-102`) triggers at 100 requests/60s per source IP across all paths, then bans the IP for 300s. An aggressive scanner (ffuf default 40 threads, sqlmap forking, nuclei across many templates) easily exceeds 100 req/min and trips the ban; once banned, that IP's honeypot probes get 429'd at the edge and never reach the Go app. **The tripwire tile undercounts exactly the noisiest attackers** — the ones the demo most wants to showcase. The tradeoff is correct behaviour (we *want* to ban scan floods at Layer 1), but it should not be silent in the operator-facing surface. Cross-reference: an attacker accounted for in *Top probed URLs* (the existing Cloud Armor DENY tile) but absent from *Tripwire hits* is the expected signal of a banned scanner. — `app/yamato/noc_dashboard.go:336`.

- **F-004 (info, quality)** — *slog also writes top-level `level:"INFO"` alongside the explicit `severity:"NOTICE"`.* slog's JSONHandler emits its own `time`, `level`, and `msg` keys; the developer adds an explicit `severity` field which Cloud Logging correctly promotes to the entry-level severity (the `tripwire` entries do show up at NOTICE in the log explorer). However, `jsonPayload.level=INFO` is still present as a noise field, and a future reader querying `jsonPayload.severity=NOTICE` will get every tripwire while a careless query for `jsonPayload.level=NOTICE` will return zero results. Same hazard for `msg:"honeypot tripwire"` — a future maintainer changing the slog message string would silently break any log-based metric querying `msg`. Pure quality concern; the canonical filter is `jsonPayload.tripwire=true` and the extra fields are inert. — `app/yamato/honeypot.go:99`.

- **F-005 (info, quality)** — *Single-file 320-line `honeypot.go` mixes routing, response menu, response sizing `init()`, and request logging.* The current shape (route enumeration, shared handler, structured logger, response menu, startup-time invariant checker) is consistent with the rest of the app's flat package layout and well under the "needs splitting" threshold. Worth flagging only because the canned response bodies (~100 lines of HTML/SQL/JSON literal) are noise to anyone reviewing handler logic, and a future maintainer adding a path will edit the path slice, the response map, and possibly the `init()` — three coupled changes. Optional future cleanup: extract the response menu to `honeypot_responses.go` or embed each lure from a `templates/honeypot/*.{html,sql,json}` file via `//go:embed`. Not blocking. — `app/yamato/honeypot.go:121`.

## Future extensions

Intentionally out of scope for the first ship; named here so the next person who wants one knows where to look.

- **Cloud Armor exception that lures the high-value paths in too.** The brief explicitly deferred path-based Cloud Armor changes. The natural follow-up is a Cloud Armor exception rule (priority < 1000, action `allow`) that whitelists a curated list of bait paths — `/.env`, `/wp-config.php`, `/.git/config`, `/onvif/device_service` — so the [in-the-wild evidence](./security/in-the-wild-2026-06-03.md)'s 345 daily Cloud Armor DENYs become 345 daily tripwire hits with full attacker context instead. The cost is a careful audit that the chosen paths cannot, in any future code change, accidentally reach a real handler that does something dangerous; the value is a 10x increase in attacker telemetry from probes Layer 1 currently drops.
- **Honeytoken AWS canary tokens that ping when used externally.** The current `AKIA0000000FAKEHONEY1/2` placeholders are designed to be obviously fake. A canary-token variant would mint a *real but inert* AWS access key (via Thinkst Canary or an in-house equivalent), embed it in the fake responses, and configure CloudTrail to alert when the key is ever used. An attacker who scrapes the key from a `/backup.sql` response and tries it gets discovered the moment they make their first AWS API call. Higher value than the current fakes; requires an external AWS account and a notification pipe.
- **Slack/email alert on the first hit from a new source IP.** The current alerting envelope (9 policies, see the Alert policies tile) does not cover tripwire entries. A log-based metric on `jsonPayload.tripwire=true AND timestamp>="<1h ago>"` plus a Cloud Monitoring threshold of `0 > threshold over 1h` would generate a quiet, useful alert any time a previously-unseen IP rattles the bait — without the per-request noise a hit-by-hit alert would produce.
- **Coordinated decoy hostname.** A second LB-fronted hostname like `api-internal.yamato-dev.iq9.io` that is not in any CT log (issued with a wildcard) but is reachable by direct IP scan, with its own honeypot menu pre-loaded. Distinguishes CT-driven attackers from IP-range scanners (the two classes [in-the-wild §Attacker class 1 vs 2](./security/in-the-wild-2026-06-03.md#attacker-class-1--the-focused-env-hunter-aws-paris) named) without inferring from `Host:` headers.
- **Geo enrichment.** A free GeoIP lookup on `remote_ip` per tripwire hit, surfaced as a sixth column on the tile and a tooltip-overlay world map. The data is already collected; the missing piece is an embedded MaxMind GeoLite2 country DB (~6 MB). The Cloud Armor DENY tile has the same gap and the same follow-up; doing both at once is the right shape.

## Operational notes

A few things worth knowing for the day a tile looks wrong or a new honeypot needs adding.

**Adding a new honeypot path.** Three edits, all in `app/yamato/honeypot.go`:

1. Append the path to the slice returned by `honeypotPaths()`. Keep the ordering note in mind — group conceptually so a startup-log grep stays readable.
2. Add an entry to `honeypotResponses` with a Content-Type and a `<2 KiB` body that follows the fake-content principle above (`host.example`, `iq9-fake-honey`, `0.0.0.0`, `FAKE-HONEY`).
3. Build: `go vet ./app/yamato && go build ./app/yamato`. The `init()` in `honeypot.go` enforces three invariants at startup — every entry in `honeypotPaths()` has a corresponding `honeypotResponses` entry, no response body exceeds 2 KiB, every `application/json` response parses cleanly. A mismatch panics the container at boot, which is the right failure mode: better a hard fail at deploy than a silent 404 in production.

The route registers automatically because `app.go`'s `routes()` iterates `honeypotPaths()`; no second edit there.

**Verifying a new path isn't already caught by Cloud Armor.** Before adding a path, grep the WAF rule families currently in `service/yamato/modules/frontdoor/frontdoor.tf` and cross-reference the path against Google's preconfigured rule descriptions. The current policy uses eight rule families at priorities 1000–1007 plus the rate-based ban at 2000. Of those, `scannerdetection-v33-stable` is the only one that contains a path-based filename list (CRS rule 913120 — see F-001 above); the others match payload/header patterns and do not look at the URL path. A bare path probe (no exploit body, no suspicious header) is therefore safe against all rule families except scannerdetection at PL2+. If the new path is on the CRS 913120 list, swap it for an off-list variant before shipping.

**Reading raw tripwire logs.** When the NOC tile shows something surprising, paste the filter into Cloud Logging directly:

```bash
gcloud logging read \
  'resource.type="cloud_run_revision"
   AND resource.labels.service_name="iq9-run-dev-yamato"
   AND jsonPayload.tripwire=true' \
  --project=iq9-gcp-dev-yamato --freshness=24h --limit=200 \
  --format='value(timestamp,jsonPayload.path,jsonPayload.remote_ip,jsonPayload.user_agent)'
```

The required IAM is the same `roles/logging.viewer` the rest of the NOC dashboard uses; the runtime SA `iq9-yamato-dev-run` already holds it from the prior NOC ship. A local operator running `gcloud` against the project needs the role on their own user account or impersonation through the SA. The structured fields (`jsonPayload.path`, `jsonPayload.remote_ip`, `jsonPayload.user_agent`, `jsonPayload.body_truncated`, `jsonPayload.method`) are all top-level under `jsonPayload` and queryable individually — narrowing to a single attacker IP, a single path, or a single UA family is one extra `AND` clause.

**Demo flow from a shell.** From any machine on the public internet:

```bash
curl https://yamato-dev.iq9.io/admin
curl https://yamato-dev.iq9.io/backup.sql
curl -X POST -d "u=admin&p=' OR 1=1 --" https://yamato-dev.iq9.io/admin
```

Each returns a believable fake 200 with `Server: fake-honey/0.0`. Within ~10 seconds (Cloud Logging indexing latency), the entries are queryable. Refresh `/wiki/noc` — the *Tripwire hits · 24h* tile shows the count climbing and the operator's IP and User-Agent contribute to the next 24-hour aggregation.

## Files at a glance

| File | Role |
| --- | --- |
| `app/yamato/honeypot.go` | The package: `honeypotPaths()` source of truth, `handleHoneypot` shared handler, `logTripwire` structured-log emitter, `honeypotResponses` canned-response map, startup-time `init()` invariant checker. |
| `app/yamato/app.go` | Route registration: the `for _, p := range honeypotPaths()` loop in `routes()` between the public landing routes and the `/wiki/*` IAP-gated routes. |
| `app/yamato/noc_dashboard.go` | The fourth fan-out goroutine `scanTripwire`, the `nocTripwireFilter` Cloud Logging filter, the `nocTripwireTile` page-data struct, the `extractTripwirePath` payload walker. |
| `app/yamato/templates/noc_dashboard.html` | The new tile markup (the *Tripwire hits · 24h* article) and the empty/error template branches. |
| `app/yamato/static/style.css` | The `.k-tripwire`, `.t-num-trip` styling — gold-accented to match the lure metaphor. |
| `service/yamato/modules/frontdoor/frontdoor.tf` | Unchanged. The Cloud Armor policy is referenced for the WAF-sensitivity analysis (F-001) but the honeypot ship did not touch Terraform. |

## See also

- [`docs/noc.md`](./noc.md) — the live NOC dashboard; the *Tripwire hits · 24h* tile is part of that page and shares its lifecycle, IAM, and fallback semantics.
- [`docs/security/in-the-wild-2026-06-03.md`](./security/in-the-wild-2026-06-03.md) — the 24-hour observation that motivates Layer 0; the honeypots fill the per-attacker-context gap Cloud Armor's DENY logs leave.
- [`docs/security/fort-knox.md`](./security/fort-knox.md) — the five-layer claim Layer 0 sits *outside*; the honeypots add to the pitch without replacing any of Layers 1–5.
- [`docs/security/red-team-playbook.md`](./security/red-team-playbook.md) — the two-act Gamilas demo scaffolding the honeypots extend; a future Act 3 could narrate a tripwire hit alongside the Cloud Armor DENY.
- `app/yamato/honeypot.go` — the source of truth for the route list, the response menu, and the log shape.
- `app/yamato/noc_dashboard.go` — `scanTripwire` and `nocTripwireFilter` for the tile-feeding scan.

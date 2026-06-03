# NOC Dashboard — `/wiki/noc`

The live view of GCP defense activity on the Yamato wiki. This is the page that turns the [Fort Knox claim](./security/fort-knox.md) into something a prospect can stare at: an IAP-gated dashboard, served as part of the wiki, that pulls Cloud Armor blocks, honeypot tripwire hits, and alert-policy state from the Cloud Logging and Cloud Monitoring APIs at request time and renders them as six tiles that refresh every 30 seconds. No slides, no narration, no recorded video — the dashboard is the evidence, and it updates while the prospect is still looking at it.

This document is the *why* and the *how*: what the page is, the request lifecycle, the queries that feed each tile, the security posture, the IAM the user still needs to grant, and the open issues a reviewer flagged that did not block the ship. The code lives in the **Application Layer** (Go on Cloud Run); no Terraform was touched to add the route — but two new IAM bindings on the runtime SA *are* required for the tiles to populate, and those are called out below.

## What this page is

A signed-in `@iq9.io` operator (or a consulting prospect sitting next to one) opens `https://yamato-dev.iq9.io/wiki/noc`. IAP intercepts at the Google Front End, demands an identity, lets a verified `@iq9.io` Google account through, and hands the request to the wiki Cloud Run service. The Go binary's mux registers `GET /wiki/noc` and dispatches to `handleNOCDashboard`, which fans out four independent API calls in parallel — three against Cloud Logging (the 24h and 1h Cloud Armor DENY windows, plus a 24h honeypot-tripwire scan on the public Cloud Run service) and one against Cloud Monitoring (for the live state of the project's alert policies). When all four return (or time out, or fail), the handler assembles a `nocPageData` struct and renders `templates/noc_dashboard.html`. A `<meta http-equiv="refresh" content="30">` in the page head causes the browser to reload every 30 seconds, so the operator never has to touch the page to see the next minute's blocks.

Six tiles:

| Tile | What it shows |
| --- | --- |
| **Edge blocks · 1h / 24h** | Two big numbers — Cloud Armor DENY count in the last hour and the last 24 hours. |
| **Top source IPs · 24h** | Top 5 attacker IPs (with their per-IP block counts) over the last 24h. |
| **Top probed URLs · 24h** | Top 5 paths attackers tried to reach (`/wp-config.php`, `/.env`, `/onvif/device_service`, the usual menu). |
| **Top WAF rule priorities · 24h** | Top 5 Cloud Armor policy priorities firing — which rule categories are doing the work. |
| **Tripwire hits · 24h** | Total honeypot hits in the last 24h plus the top 3 probed bait paths. The Layer 0 lure on the public service — see [`docs/honeypot.md`](./honeypot.md) for the full story. |
| **Alert policies · live state** | The 9 (project-wide; see Known issues F-007) alert policies, each with enabled/disabled, severity, and last-mutation timestamp; disabled or invalid policies float to the top with a red dot. |

The page exists as a sibling of `/wiki` rather than as a standalone surface for one reason: IAP scoping is enforced at the LB by the `/wiki` and `/wiki/*` path rule (`service/yamato/modules/frontdoor/frontdoor.tf`), and putting the dashboard at `/wiki/noc` inherits that gate by virtue of the prefix. No new IAP backend, no new path rule, no new url_map entry — just one more route on the wiki Cloud Run service's existing mux.

> **Not to be confused with `/noc`.** The existing `/noc` page (`handleNOC`, `templates/noc.html`) is a *launcher* — a grid of deep-links into Cloud Console dashboards, the Cloud Armor policy view, and pre-filtered Logs Explorer queries. `/noc` sends you off-platform to look at GCP's own UIs. `/wiki/noc` is the **live view in our own theme** — the data is pulled and rendered inside the wiki itself, so the prospect never sees a Google login or a Cloud Console chrome. Both pages are IAP-gated; they coexist.

## The consulting frame

Open `https://yamato-dev.iq9.io/wiki/noc` in front of a prospect. Sign in with `@iq9.io`. The five tiles populate from live Cloud Logging data — last night's `.env` hunters from AWS Paris are right there in the Top source IPs tile, the 60-prefix probe menu is right there in the Top URLs tile, the priority distribution (`1002` dominant, `1001` / `1004` / `1005` / `1006` in the tail) is right there in the Top WAF priorities tile, and the 9 alert policies are right there in the bottom strip with green dots if they are healthy.

The dashboard is the live operationalization of [in-the-wild-2026-06-03.md](./security/in-the-wild-2026-06-03.md). That document is the *recorded* evidence — twenty real adversaries, 345 blocks, all stopped at Layer 1. The NOC is the *live* evidence — the same numbers, the same shape, refreshed every 30 seconds against the same Cloud Logging data the in-the-wild analysis came from. A prospect who reads the in-the-wild doc sees that the architecture held last night. A prospect who looks at `/wiki/noc` sees that it is holding right now.

The Fort Knox security layers cited by the page:

- The blocks the **Edge blocks** and **Top source IPs** / **URLs** / **priorities** tiles show all happened at **Layer 1 — Cloud Armor at the external HTTPS load balancer** ([in-the-wild §Layer 1](./security/in-the-wild-2026-06-03.md#layer-1--the-perimeter-gate-cloud-armor)).
- The fact that the prospect had to sign in with `@iq9.io` to even see the page is **Layer 2 — IAP at the Google Front End**.
- The Cloud Run service serving the page is **Layer 3 — `INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER`** (the `*.run.app` URL refuses everyone; only the LB can invoke).
- The Go binary's mux registers seven routes and 404s everything else; the dashboard handler runs as the least-privilege runtime SA — that is **Layer 4**.
- The Cloud SQL Postgres on private IP that the wiki proper reads from — the gold — is **Layer 5**, and the NOC dashboard does not touch it. The NOC reads logs about defense layers; it does not read the data those layers defend.

The narrative writes itself: *"every block you see on this page was caught at Layer 1. We have four more layers behind it. None of them were even consulted last night."*

## Architecture — one request, end to end

```
GET https://yamato-dev.iq9.io/wiki/noc
        |
        v
External HTTPS LB        service/yamato/dev/frontdoor
        |  url_map path_matcher "main"
        |  path_rule paths = ["/wiki", "/wiki/*"]  -> wiki backend
        v
Cloud Armor policy       iq9-dev-yamato-armor          [Layer 1]
        |
        v
IAP                      domain:iq9.io                  [Layer 2]
        |  injects X-Goog-Authenticated-User-Email
        v
Cloud Run service        iq9-run-dev-yamato-wiki        [Layer 3]
        |  ingress = INTERNAL_LOAD_BALANCER
        v
stdlib ServeMux          app/yamato/app.go              [Layer 4]
        |  mux.HandleFunc("GET /wiki/noc", a.handleNOCDashboard)
        v
handleNOCDashboard       app/yamato/noc_dashboard.go
        |  fan out 4 goroutines, each with a 6s context.WithTimeout
        v
   +----+-------------------+-------------------------+----------------------+
   |                        |                         |                      |
   v                        v                         v                      v
scan24h                  scan1hCount               fetchAlertTile          scanTripwire
logadmin.Entries         logadmin.Entries          monitoring.              logadmin.Entries
24h DENY scan, capped    1h DENY count, capped     ListAlertPolicies        24h tripwire scan,
at nocEntryCap=3000      at nocEntryCap=3000       all project alert        capped at
   |                        |                      policies (DisplayName,   nocEntryCap=3000,
   |                        |                      Enabled, Severity,       jsonPayload.tripwire
   |                        |                      MutationRecord)          =true on public svc
   |                        |                         |                      |
   +----+-------------------+-------------------------+----------------------+
        |
        v  wg.Wait()
        v
nocPageData assembled (race-clean — each goroutine wrote only to its
                       own pre-declared local; assembly is sequential)
        |
        v
a.render("noc_dashboard.html", data)   html/template auto-escape
        |
        v
HTML response back through Cloud Run -> IAP -> LB -> browser
        |
        v
<meta http-equiv="refresh" content="30">  → browser reloads in 30s
```

Two things about that picture worth naming.

**The mux ordering is not a precedence trick — it is documented Go behavior.** `app.go` registers `GET /wiki/noc` before `GET /wiki/{slug}` in the route table, but ordering does not matter: Go 1.22's net/http mux gives literal-segment patterns precedence over wildcard patterns. `/wiki/noc` always matches the literal route first, never the wildcard. The same property is what makes `/wiki/search` work — see [`docs/search.md`](./search.md).

**Authentication is Application Default Credentials, against the existing runtime SA.** No new service account, no JSON key, no explicit auth wiring. On Cloud Run, ADC resolves to the runtime SA `iq9-yamato-dev-run` (provisioned in `service/yamato/modules/cloudrun/cloudrun.tf`); the `logadmin` and `monitoring` clients pick it up from the metadata server transparently. The same SA already dials Cloud SQL through `cloudsqlconn` in `db.go`, so the auth path is identical.

## The tiles, one by one

Each tile has the same contract: a Cloud Logging or Cloud Monitoring query, a client-side aggregation, an Available flag, an Empty flag (where applicable), an Error string, and a template branch for each of (available + populated), (available + empty), (unavailable). The handler never returns 500 because of an API failure — every tile is allowed to degrade on its own.

### Edge blocks · 1h / 24h

**What it shows.** Two big numbers side by side: Cloud Armor DENY count in the last hour, Cloud Armor DENY count in the last 24 hours. The 1h number gets a "hot" colour class when it is greater than zero so a live probe burst is visually distinct from a quiet hour.

**What feeds it.** Two independent Cloud Logging queries (the 24h scan and the 1h scan, both produced by `nocBlockedFilter(since)` with different `since` values). They run in parallel goroutines so a slow window does not delay the other.

**Empty state.** Both numbers render as `0` with no "hot" class; the operator-visible "1h / last 24h" subtitles still anchor the tile.

**Error state.** When both scans fail, the template short-circuits the tile to *"Logs unavailable — retry on next refresh."* When one scan succeeds and the other fails, the tile renders with whichever number is real — see **F-001** in Known issues for the visual contradiction this currently produces.

### Top source IPs · 24h

**What it shows.** Top 5 source IPs from the last 24h of Cloud Armor DENY events, sorted descending by block count, with the per-IP count next to each row.

**What feeds it.** The same 24h scan as the counts tile. The handler aggregates client-side into a `map[string]int64` keyed by `httpRequest.remoteIp`, then `topTile()` sorts and truncates to 5.

**Empty state.** *"No activity in the last 24h."*

**Error state.** Whatever message the 24h scan returned, surfaced as a `t-empty` paragraph in place of the list.

**Note.** Provider attribution (AWS, Azure, OVH, etc.) is **not** done here — it would require a reverse-DNS or WHOIS call per IP and that does not fit the per-request budget. The in-the-wild doc captured attribution by hand (`Appendix A`); the live tile shows only the IP. Operators who want attribution one-click into Cloud Console via `/noc` or run a WHOIS by hand.

### Top probed URLs · 24h

**What it shows.** Top 5 URL paths attackers tried to reach, with counts. `canonicalPath` strips the host/scheme and truncates anything over 120 characters with an ellipsis, so a command-injection payload that is several hundred characters long does not blow out the tile layout.

**What feeds it.** Same 24h scan, aggregated into a separate `map[string]int64` keyed by `canonicalPath(e.HTTPRequest.Request.URL)`.

**Empty state.** *"No activity in the last 24h."*

**Error state.** Same fallback as Top source IPs.

### Top WAF rule priorities · 24h

**What it shows.** Top 5 Cloud Armor policy priorities firing — `priority 1002` for credential-file probes, `priority 1001` for protocol-level abuse, etc. (See the priority distribution table in [in-the-wild §Layer 1 internals](./security/in-the-wild-2026-06-03.md#layer-1-internals--cloud-armor-policy-priorities) for what each priority catches in the current `iq9-dev-yamato-armor` policy.)

**What feeds it.** Same 24h scan; `extractPriority` walks the `jsonPayload.enforcedSecurityPolicy.priority` field defensively (the `logadmin` client unmarshals JSON payloads into nested `map[string]any`, and any type along the chain might be missing — the helper returns `""` on anything malformed and the count is skipped rather than panicking).

**Empty state.** *"No activity in the last 24h."*

**Error state.** Same fallback as the other top-N tiles.

### Tripwire hits · 24h

**What it shows.** The total number of honeypot tripwire hits on the *public* Cloud Run service over the last 24 hours, plus the top 3 probed bait paths. The headline number lights up with a gold "hot" class when greater than zero so an active probe day reads visibly distinct from a quiet day. This is the Layer 0 lure surface; the [full story is in `docs/honeypot.md`](./honeypot.md).

**What feeds it.** A fourth Cloud Logging scan in the fan-out, against the public service `iq9-run-dev-yamato`, filtering on `jsonPayload.tripwire=true`. The 6 honeypot routes registered in `app/yamato/honeypot.go` each emit one structured log entry per hit (see honeypot.md for the field shape); `scanTripwire` aggregates those entries by `jsonPayload.path` and feeds the tile a `(Total, Rows=top3)` payload. Same `nocEntryCap=3000` cap as the other scans, same per-call 6s timeout.

**Empty state.** *"No tripwires sprung in the last 24h."*

**Error state.** *"Cloud Logging unavailable — retry on next refresh."*

**Read together with the *Edge blocks* and *Top probed URLs* tiles.** A probe that matches a Cloud Armor WAF signature gets DENY'd at the edge and lands in *Edge blocks* + *Top probed URLs*. A probe that hits a bait path (which is not, on its own, a WAF signature) passes through Cloud Armor, lands on the public service, and lands in *Tripwire hits*. The two tiles are complementary views of the same incoming probe traffic — different layers, different events, both real. See [honeypot.md → *The Fort Knox layer placement*](./honeypot.md#the-fort-knox-layer-placement--layer-0) for the layered argument, and **F-003** in *Known issues* over there for the rate-limit-ban interaction that biases the tripwire count low on heavy single-IP probing days.

### Alert policies · live state

**What it shows.** Every alert policy in the project, one row each, with a coloured dot (green = healthy enabled, red = disabled or invalid), display name, `enabled` / `DISABLED` state, and the timestamp of the policy's last mutation. Disabled / RED rows float to the top so a problem catches the prospect's eye first; the remaining rows sort alphabetically.

**What feeds it.** A single Cloud Monitoring v3 `ListAlertPolicies` call against `projects/<projectID>`. The handler reads `DisplayName`, `Enabled.Value`, `Validity.Code` (treated as healthy if zero, RED otherwise), and `MutationRecord.MutateTime` (formatted as `YYYY-MM-DD HH:MM UTC`).

**Empty state.** *"No alert policies configured on this project."*

**Error state.** *"Monitoring API unavailable — alert state cannot be read."*

**The signal limitation.** The Monitoring v3 Go SDK does not expose live *incident* state — there is no `Incidents.List` to ask "is this policy firing right now?" So the dashboard surfaces what it can: enabled/disabled, validity, last mutation. The contract is set up so a future incidents lookup can swap in without changing the template — `Severity` already has an `AMBER` branch that nothing currently produces, and the template knows how to colour it. When the SDK grows the call, only `fetchAlertTile` needs to change.

## Data freshness

The page refreshes every 30 seconds via `<meta http-equiv="refresh" content="30">` in the template head. Each refresh is a fresh request, a fresh fan-out of three API calls, and a fresh render. The "as of" timestamp at the top of the page is the server time of *this* render — printed as `YYYY-MM-DD HH:MM:SS UTC` so the prospect can see that the dashboard is live, not a cached screenshot.

Thirty seconds is the right interval for a consulting demo. Faster (5s, WebSocket push) would burn Cloud Logging quota and serve no narrative — a prospect needs a few seconds to read each tile before the page refreshes anyway. Slower (5m) would make the dashboard feel static. Meta-refresh, with no JavaScript framework on the page, is also the lowest-complexity implementation that meets the brief — and lower complexity is itself a security property at Layer 4.

There is a small data-freshness caveat worth naming. The 1h number measures `now() - 1h`, but Cloud Logging indexes the LB request logs with a short delay (typically seconds, occasionally tens of seconds under heavy traffic). On a quiet day this is invisible; under a synthetic burst the very-newest events may not appear in the 1h tile for a refresh or two. This is the way Cloud Logging works; there is no way to defeat it from the client.

## Security posture

Four properties hold the dashboard surface.

**IAP scoping is enforced at the LB, not in the app.** The url_map's path rule routes `/wiki` and `/wiki/*` to the IAP-gated backend service (`service/yamato/modules/frontdoor/frontdoor.tf` — the `path_rule` around line 274 — same rule that gates `/wiki/search`). `/wiki/noc` is a child of that prefix, so it inherits the gate without a separate IAP backend configuration. A request from an unauthenticated browser is intercepted at the GFE; `handleNOCDashboard` is only ever invoked for a verified `@iq9.io` identity. This is **non-negotiable** in the brief and structurally enforced by the LB path-rule, not by an in-app check.

**Runtime SA auth via ADC, no new service account.** The Cloud Logging and Cloud Monitoring clients are constructed without explicit credentials; on Cloud Run they pick up the runtime SA `iq9-yamato-dev-run` from the metadata server. There is no new SA, no JSON key, no `GOOGLE_APPLICATION_CREDENTIALS` file. The same identity that dials Cloud SQL also reads logs and alert policies. This is the brief's hard constraint, and it is also how the Layer 4 least-privilege argument keeps working — the SA can read logs and list alert policies, and nothing else.

**Per-call timeouts and per-tile fallbacks.** Every Cloud Logging and Cloud Monitoring call is wrapped in a 6-second `context.WithTimeout` (the constant `nocAPITimeout`). The three calls fan out in parallel; the handler joins after `wg.Wait()`. A hung or failing API drains its own 6 seconds and produces an error; the handler converts that into a per-tile fallback message and the page still renders. The page **never** 500s on a logging outage — a key brief requirement and verified in the Tester's pass.

**Template auto-escaping over attacker-controlled fields.** Every string the dashboard renders that derives from log payloads — source IP, URL path, WAF priority, alert policy display name — is rendered through Go's `html/template` `{{.Field}}` interpolation, which auto-escapes `<`, `>`, `&`, `"`, `'`. There are no `template.HTML` casts anywhere in `noc_dashboard.go`. Classic HTML injection from a log-derived field is structurally closed. (See **F-002** in Known issues for the residual sub-issue around C0 control characters and BiDi-format Unicode, which auto-escape does not address.)

## IAM dependency the user needs to apply

This is the **one thing that is not yet wired up.** The runtime SA `iq9-yamato-dev-run` currently holds `roles/cloudsql.client` (project) and `roles/secretmanager.secretAccessor` on one secret. To populate the dashboard tiles, two more project-scoped roles are required:

| Role | Why it is needed |
| --- | --- |
| `roles/logging.viewer` | The 24h and 1h Cloud Armor DENY scans (counts, top IPs, top URLs, top priorities) all go through `logadmin.Client.Entries` against the LB request logs. |
| `roles/monitoring.viewer` | The alert-policy state tile uses `monitoring.AlertPolicyClient.ListAlertPolicies` against the project. |

The wiring lives in `service/yamato/modules/cloudrun/cloudrun.tf` — the module that owns the runtime SA — alongside the existing `google_project_iam_member.cloudsql_client` resource at lines 30–34. Two new `google_project_iam_member` resources, each binding the role to `serviceAccount:${google_service_account.runtime.email}`. The dev state at `service/yamato/dev/cloudrun/` does not need any direct change; it picks up the new module resources on its next `terraform apply`.

**This Terraform change has not been applied as part of this pipeline.** It is a Service Layer change and the user applies it separately under the [Service Layer's normal review bar](./infrastructurestate.md#change-control-posture) (two reviewer approvals from the platform team). Until the roles are granted, the handler renders but every API-backed tile shows its fallback: *"Logs unavailable — retry on next refresh"* / *"Monitoring API unavailable — alert state cannot be read."* The page itself never 500s on missing IAM. After `terraform apply`, the next page refresh — 30 seconds at most — populates the tiles from live data.

## Cloud Logging filters used by the dashboard

Reproduced verbatim so any operator can run the same queries by hand if a tile looks wrong. Both filters are identical in shape to the canonical filter in [in-the-wild-2026-06-03.md §Methodology](./security/in-the-wild-2026-06-03.md#methodology--reproducing-this-analysis); only the freshness window differs. `<RFC3339-since>` is `time.Now().UTC().Add(-24h)` or `Add(-1h)` formatted per RFC 3339.

**24h scan — feeds the 24h counts, top-5 IPs, top-5 URLs, top-5 priorities. PageSize cap 3000.**

```
resource.type="http_load_balancer"
AND (jsonPayload.enforcedSecurityPolicy.outcome="DENY"
     OR jsonPayload.statusDetails="denied_by_security_policy")
AND timestamp>="<RFC3339 of (now - 24h)>"
```

**1h scan — feeds the 1h half of the counts tile only. PageSize cap 3000.**

```
resource.type="http_load_balancer"
AND (jsonPayload.enforcedSecurityPolicy.outcome="DENY"
     OR jsonPayload.statusDetails="denied_by_security_policy")
AND timestamp>="<RFC3339 of (now - 1h)>"
```

To run either by hand (with the runtime SA's `roles/logging.viewer` once granted, or with your own `roles/logging.viewer` on the project):

```bash
gcloud logging read \
  'resource.type="http_load_balancer"
   AND (jsonPayload.enforcedSecurityPolicy.outcome="DENY"
        OR jsonPayload.statusDetails="denied_by_security_policy")' \
  --project=iq9-gcp-dev-yamato --freshness=24h --limit=3000 \
  --format='value(httpRequest.remoteIp,httpRequest.requestUrl,jsonPayload.enforcedSecurityPolicy.priority)'
```

The OR-arm with `statusDetails="denied_by_security_policy"` catches the legacy field shape that some log entries surface instead of the nested `enforcedSecurityPolicy.outcome`. Both shapes occur in the wild; the OR-arm makes the filter robust against both.

## Edge cases handled

The brief's quality bar requires the page to render cleanly under a range of less-than-happy conditions. Each is named explicitly here so an operator looking at a degraded tile can recognise what they are seeing.

- **Empty response (quiet day).** `topTile()` flags the tile `Empty: true` and the template renders *"No activity in the last 24h."* No goose-egg next to an empty list; the operator sees that the API call succeeded and there was simply nothing to count.
- **Cloud Logging API timeout.** The per-call 6-second `context.WithTimeout` expires; the scan returns a `context.DeadlineExceeded` error wrapped by `scan24h` or `scan1hCount`; the handler converts the error to *"Cloud Logging unavailable — retry on next refresh"* and renders the page without that tile.
- **Cloud Logging API error.** Any non-timeout error (permission denied, project not found, transient 5xx) is treated the same way as a timeout — fallback message, page renders.
- **Cloud Monitoring API timeout / error.** Same shape: `fetchAlertTile` returns an error; `data.Alerts` gets the `Monitoring API unavailable` fallback; the rest of the page renders normally.
- **Busy day exceeding the aggregation cap.** Each scan is capped at `nocEntryCap = 3000` log entries. On a typical day with ~345 blocks/24h (per the in-the-wild observation), the scan is exact. On a much louder day, the top-N tiles are exact within the most recent 3000 events — accurate ranking but not a complete inventory. This sampling caveat is documented in the code comment on `nocEntryCap` and is acceptable per the brief's aggregation-budget guidance. (See **F-005** in Known issues for the related concern about the 1h count under attack volume.)
- **All three calls fail simultaneously.** Each tile renders its fallback message; the page header (project, "as of" timestamp, "live" badge, refresh interval) still renders correctly. The operator sees a fully-formatted page with five "unavailable" tiles, which is itself a useful diagnostic — the page is alive, the APIs are not.
- **One scan succeeds and the other errors (1h vs 24h).** The two halves of the counts tile come from independent scans, so this case is real. Today the template renders the half that errored as its zero default (`0 last 24h` next to `42 last 1h`), which is misleading. See **F-001** in Known issues.

## Operational notes

A few things worth knowing for the operator on the day a tile starts looking wrong.

**A tile reads "Logs unavailable" persistently.** Almost always an IAM problem on the runtime SA — `roles/logging.viewer` was not granted (the most common cause on a first deploy; see "IAM dependency" above), or it was revoked. Quick check: `gcloud projects get-iam-policy iq9-gcp-dev-yamato --flatten="bindings[].members" --filter="bindings.members:iq9-yamato-dev-run@*" --format='value(bindings.role)'` should list both `roles/logging.viewer` and `roles/monitoring.viewer` alongside the existing `roles/cloudsql.client`. The underlying gRPC error is **not** currently surfaced in Cloud Run logs (see **F-004** in Known issues), so the IAM check is the first place to look rather than the tenth.

**The alert-policies tile shows policies you do not recognise.** The tile lists *every* policy in the project, not just Yamato's nine (see **F-007** in Known issues). If the project picks up a non-Yamato policy in the future, it will appear here. Filtering by a known display-name prefix is the obvious fix; today, accept the project-wide listing.

**The "as of" timestamp is more than ~60 seconds old.** Either the browser stopped refreshing (the user disabled `<meta refresh>`, the tab is throttled by the OS, or the network is down) or one of the goroutines is sitting at its 6-second deadline. The latter shows up as a fallback message on the affected tile; the former shows up as a wholly stale page with no refresh indicator. Cmd-R always reloads.

**The dashboard does not modify Cloud Armor or the alert policies.** It is read-only by construction; the runtime SA only ever needs `*.viewer` roles. Any change to the Cloud Armor policy or the alert configurations happens through the Service Layer Terraform (`service/yamato/modules/frontdoor/` for the WAF, `service/yamato/dev/logging/` for the alerts) and the standard review bar.

## Known issues

These were flagged in review against the commit that introduced the dashboard. They are documented here so they do not get lost. None of them block the demo; the page renders, IAP gates, and the brief's quality bars are met. Severity tags are the reviewer's.

- **F-001 (medium, functional)** — *Counts tile silently shows 0 when one window (1h or 24h) errored.* When the 1h scan succeeds and the 24h scan errors (or vice versa), `data.Counts.Available` is set to true and the template renders both halves of `t-twin` unconditionally — so the failed side prints as `0` instead of as the promised em-dash. On a busy day where the 24h scan times out but the 1h scan succeeds, the operator sees `42 last 1h` next to `0 last 24h` and `.Counts.Error` rendered as a small note below. Code comment at `noc_dashboard.go:238-239` promises an em-dash; template does not actually render one. Recommended fix is per-side availability flags (e.g. `Last1hAvailable` / `Last24hAvailable`) and a template branch on each cell. — `app/yamato/noc_dashboard.go:240`.

- **F-002 (low, security)** — *Log-derived strings rendered without control-character / Unicode-spoofing sanitization.* Auto-escape closes classic HTML injection from log-derived fields (verified — no `template.HTML` casts anywhere in `noc_dashboard.go`). It does not strip C0 control characters (`\r`, `\n`, `\t`) or visually-deceptive Unicode (U+202E RIGHT-TO-LEFT OVERRIDE, U+200E LRM, U+200B ZWSP, U+2028 LS, U+2029 PS). An attacker who probes a path containing a U+202E (URL-encoded as `%E2%80%AE`) and triggers a Cloud Armor DENY can land a reversed-looking path onto the operator dashboard for the next viewer of `/wiki/noc`. Severity is low because IAP scopes the audience to `@iq9.io` and the dashboard is in-house ops — but the operator-dashboard log-forging vector is real. Recommended fix: in `canonicalPath` (and analogously for `RemoteIP` in the IPs tile), apply a `strings.Map` that rejects `unicode.IsControl` runes plus an explicit blocklist of BiDi-format runes, replacing each with U+FFFD or stripping outright. Apply after the length truncation so the truncated label is also sanitised. — `app/yamato/noc_dashboard.go:353`.

- **F-003 (low, quality)** — *Cloud Logging / Monitoring clients constructed per request — connection setup churn.* `scan24h`, `scan1hCount`, and `fetchAlertTile` each call `logadmin.NewClient` or `monitoring.NewAlertPolicyClient` on every request, then `defer Close()`. With the 30-second meta-refresh, a single open browser tab causes ~360 client constructions/hour (3 per refresh × 120 refreshes/hour). Each construction triggers a gRPC dial and an ADC token fetch (cached after first call, but still mutex-checked). Wasteful and adds latency to a per-request budget that is already tight (15s Cloud Run, 6s per call). Recommended fix: add `logadmin *logadmin.Client` and `monAlert *monitoring.AlertPolicyClient` fields to `type app`, initialize lazily in `newApp` (or behind `sync.Once`), close in `(*app).Close()`, pass the clients into the scan functions rather than constructing them inside. The per-call timeouts can remain (they wrap only the `Entries` / `ListAlertPolicies` call, not the client construction). — `app/yamato/noc_dashboard.go:266`.

- **F-004 (low, quality)** — *API errors not logged on the server side — operators cannot diagnose why a tile fell back.* When `scan24Err` / `scan1hErr` / `alertErr` come back non-nil, the handler converts them to a generic user-visible "unavailable" message and rendering proceeds. The original error is never `log.Printf`'d. An operator looking at Cloud Run request logs sees a 200, but cannot tell whether the underlying cause was a missing IAM role, a gRPC deadline, a 404 project, or a transient 5xx. This makes the IAM-dependency callout above harder to verify on the deploy that follows the `terraform apply` — until the roles are granted, every tile silently falls back with no diagnostic trail. Recommended fix: at each fallback branch (`noc_dashboard.go:223`, `:240`, `:250`), call `log.Printf("noc dashboard: <tile>: %v", err)` before assigning the user-visible message. Keep the user-visible message generic; the log gives operators the real cause. — `app/yamato/noc_dashboard.go:222`.

- **F-005 (low, functional)** — *`scan1hCount` silently caps at 3000 — undercounts on very loud hours.* The 1h count path uses the same `nocEntryCap = 3000` cap as the 24h scan. On a probe storm producing >3000 DENYs in a single hour, the 1h tile saturates at `3000` with no visual indication that the count is capped. The 24h cap is documented and acceptable (top-N within the sampled window per the brief); the 1h cap on a SUM-only query is technically wasteful (you only need the count, not the entries) and misleading at high volume. The 1h tile is the **headline number for an active-attack demo** — undercounting it under attack is exactly when accuracy matters most. Recommended fix, in increasing order of effort: (a) bump the 1h cap well above expected peak hourly volume; (b) surface a "cap reached" flag on the tile so the operator sees `>3000 last 1h` rather than `3000`; (c) switch the 1h count to Cloud Monitoring's `logging.googleapis.com/log_entry_count` metric, which aggregates server-side and supports the same filter. — `app/yamato/noc_dashboard.go:320`.

- **F-006 (info, quality)** — *Hardcoded fallback project ID in shipped binary.* `nocProjectID` returns `getenv("GCP_PROJECT", "iq9-gcp-dev-yamato")`. On Cloud Run `GCP_PROJECT` is set, so the fallback fires only for local `go run`. That is an explicit and documented design choice — `handleNOC` (the launcher) uses the same pattern at `handlers.go:143`, so this is at most a consistency item. The defect-shaped concern is hypothetical: if a future env (test/stage/prod) ever forgets to set `GCP_PROJECT`, this handler will silently query the dev project from a non-dev container — surfacing as "wrong data" rather than as a clear startup failure. Worth knowing; not worth a fix today. — `app/yamato/noc_dashboard.go:59`.

- **F-007 (info, quality)** — *Alert tile lists ALL project policies, not just Yamato's nine.* `fetchAlertTile` calls `ListAlertPolicies` with `Name: "projects/" + projectID` and renders every returned policy. The dev project `iq9-gcp-dev-yamato` presumably contains only Yamato policies today, so the tile is accurate now. If/when the project picks up policies from other services, they will appear on the dashboard. Low risk in current single-tenant dev project; flagged for visibility. Recommended fix when it bites: filter on a known display-name prefix that the Service Layer's alerting module assigns to Yamato policies, or accept the project-wide listing and update this doc to say so. — `app/yamato/noc_dashboard.go:446`.

## Future extensions

Intentionally out of scope for the first ship; named here so the next person who wants one can find the obvious extension point.

- **World map of source IPs.** A small SVG world overlay with dots scaled by per-country block count, driven by a free GeoIP lookup on each IP. The data is already collected by `scan24h`'s `ips` map; the missing piece is a GeoIP lookup table embedded into the binary (MaxMind's GeoLite2 country database is ~6MB and updates monthly).
- **Historical analytics / charts over time.** A `/wiki/noc/history` route showing blocks-per-hour for the last 7 days as a bar chart. Either drive it from Cloud Monitoring's `logging.googleapis.com/log_entry_count` metric (aggregated server-side, cheap) or from a daily snapshot table written by a Cloud Scheduler + Cloud Function.
- **Per-rule drill-down pages.** A `/wiki/noc/priority/<N>` page that drills into a specific Cloud Armor priority — what the rule pattern is, recent matching requests, the same in-the-wild commentary the security docs already carry. Requires the rule description as a static table mapped from the policy ID.
- **WebSocket / SSE push.** Meta-refresh is structurally simpler and meets the brief; SSE is the obvious upgrade for an operator with the page open all shift. Worth the complexity only if the 30-second refresh interval starts feeling stale, which it does not today.
- **Live incident state on the alert tile.** As noted under the alert-policies tile, the Monitoring v3 Go SDK currently does not expose firing incidents. When it does, swap `fetchAlertTile`'s severity heuristic for a real "is this policy firing right now?" lookup and the AMBER branch the template already supports starts producing output.

## Files at a glance

| File | Role |
| --- | --- |
| `app/yamato/noc_dashboard.go` | `handleNOCDashboard`, the four fan-out scans (including `scanTripwire`), the aggregation helpers, the alert-tile fetcher, the page-data struct. |
| `app/yamato/honeypot.go` | The Layer 0 lure routes and `logTripwire` log emitter that produce the entries the tripwire tile aggregates over. See [`docs/honeypot.md`](./honeypot.md). |
| `app/yamato/app.go` | Route registration: `mux.HandleFunc("GET /wiki/noc", a.handleNOCDashboard)` between `/wiki/search` and `/wiki/{slug}`; the public-service honeypot routes are registered in the same `routes()` method just above. |
| `app/yamato/templates/noc_dashboard.html` | The six tiles, the meta-refresh, the empty/error template branches, the alert-policy row formatting. |
| `app/yamato/static/style.css` | `.noc-dash`, `.noc-dash-grid`, `.noc-dash-tile`, `.t-twin`, `.t-list`, `.t-alerts`, `.noc-alert-{red,amber,green}`, `.k-tripwire`, `.t-num-trip` — uses the existing Star Blazers theme tokens. |
| `app/yamato/go.mod` / `go.sum` | New direct deps: `cloud.google.com/go/logging`, `cloud.google.com/go/monitoring`, `google.golang.org/api` (promoted from indirect for `iterator`). |
| `service/yamato/modules/cloudrun/cloudrun.tf` | Where the two new `google_project_iam_member` resources will go when the user applies the IAM change — `roles/logging.viewer` and `roles/monitoring.viewer` on the runtime SA. **Not yet applied.** |
| `service/yamato/modules/frontdoor/frontdoor.tf` | url_map `path_rule` for `/wiki` + `/wiki/*` — gates `/wiki/noc` via IAP by prefix. Unchanged by this feature. |

## See also

- [`docs/honeypot.md`](./honeypot.md) — the Layer 0 honeypot tripwires that feed the *Tripwire hits · 24h* tile; the lure surface outside the Fort Knox perimeter gate.
- [`docs/security/in-the-wild-2026-06-03.md`](./security/in-the-wild-2026-06-03.md) — the recorded evidence the live dashboard operationalizes; same Cloud Logging filter, same priority distribution.
- [`docs/security/fort-knox.md`](./security/fort-knox.md) — the five-layer claim the dashboard is the live view of.
- [`docs/security/defense-in-depth.md`](./security/defense-in-depth.md) — the layered defense model the tiles visualise per layer.
- [`docs/search.md`](./search.md) — the other recent `/wiki/*` handler, with the same IAP-by-prefix posture and the same Layer 4 disposition.
- [`docs/infrastructurestate.md`](./infrastructurestate.md) — the Service / Application Layer boundary that explains why the dashboard is an App-Layer change with **one** Service-Layer IAM dependency that the user applies separately.
- `app/yamato/noc_dashboard.go` — the handler and the three scan functions.
- `app/yamato/templates/noc_dashboard.html` — the template.
- The existing `/noc` launcher at `app/yamato/handlers.go` (`handleNOC`) — the Cloud Console deep-linker page; unrelated to and unchanged by this feature.

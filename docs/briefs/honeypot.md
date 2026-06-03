Use the multi-agent playbook.

Feature: Honeypot tripwire endpoints on the public service plus a
NOC dashboard tile showing tripwire hits, designed to catch the bot
probes Cloud Armor doesn't already block at Layer 1.

Why / who it's for: The in-the-wild evidence (docs/security/in-the-wild-
2026-06-03.md) shows ~345 probes/day blocked at Cloud Armor's edge,
but Cloud Armor's reporting doesn't capture rich per-attacker telemetry
(user-agent strings, request bodies, full payloads). Honeypots fill
that gap with paths Cloud Armor lets through. Adds a "Layer 0 lure"
to the Fort Knox story: "We don't just block attackers — we identify,
fingerprint, and track them." Visible payoff: a new tile on /wiki/noc
showing live tripwire hits.

In scope:
- 6 honeypot HTTP routes on the PUBLIC Cloud Run service (NOT under
  /wiki — these must NOT be IAP-gated). Suggested:
    /admin, /backup.sql, /api/v1/users, /server-status,
    /phpmyadmin, /console
  The Developer should grep service/yamato/modules/frontdoor/frontdoor.tf
  for the Cloud Armor policy expressions and confirm none of the chosen
  paths are already caught by an existing priority rule. If a chosen
  path IS caught, swap it for an alternate from this list and document
  the swap in the design summary.
- Each path returns a believable, structurally-correct fake 200 with
  OBVIOUSLY FAKE VALUES (no real keys, project IDs, SA emails, or
  hostnames). Example: /api/v1/users returns a tiny JSON array with
  "fake-user-1" / "fake-user-2"; /server-status returns Apache-styled
  fake stats with synthetic numbers. Each response is small (<2KB).
- Each request emits ONE structured Cloud Logging entry with:
    severity=NOTICE, jsonPayload.tripwire=true,
    jsonPayload.path, jsonPayload.remote_ip,
    jsonPayload.user_agent, jsonPayload.method,
    jsonPayload.body_truncated (first 1KB of request body)
- New NOC tile (add to existing /wiki/noc): "Tripwire hits — 24h"
  showing total count plus top 3 paths hit. Same Cloud Logging API
  pattern as the existing tiles, filter is jsonPayload.tripwire=true.

Out of scope:
- Cloud Armor policy changes (deferred to a follow-up if needed)
- Per-attacker state tracking, session correlation, rate limiting on
  honeypot hits (let everything through; we want maximum data)
- Email/Slack alerting beyond the existing 9 alert policies
- Honeytoken creds monitored externally (e.g., AWS canary tokens)
- Adding routes to the WIKI service

Constraints / quality bar:
- Honeypot routes register on the PUBLIC service mux only. NEVER
  under /wiki. Reading app.go's routes() shows the existing split —
  the public routes are /, /healthz, /static/* — add the honeypots
  alongside, before any wildcard catch-all.
- Honeypot routes MUST NOT shadow real routes (/, /static/*, /healthz,
  /wiki/*).
- Fake response content MUST contain NO real:
    project IDs, SA emails, IP addresses, hostnames, internal paths,
    secrets, keys, or configuration values
  Use obvious placeholders (e.g. "AKIA0000000FAKEHONEY", project
  "iq9-fake-honey", host "host.example"). If a future attacker pastes
  the values into a real GCP console, nothing should match.
- Log entries MUST be structured JSON (slog or zerolog or stdlib
  with a small marshaler) — NOT free-text. The NOC tile depends on
  filtering jsonPayload.tripwire=true cleanly.
- The log line MUST NOT include the response we sent — only the
  REQUEST. We're logging what the attacker tried, not what we lied
  about.
- Build clean (go vet, go build, templates parse including any new
  data shape for the NOC tile).

Demo flow: from a shell, curl https://yamato-dev.iq9.io/admin and
https://yamato-dev.iq9.io/backup.sql — each returns a believable
fake 200. Open Cloud Logging filtered to jsonPayload.tripwire=true:
the entries appear immediately. Refresh /wiki/noc — the new tile
shows the count climbing and your IP/UA on the top-paths breakdown.
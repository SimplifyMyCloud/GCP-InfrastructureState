Use the multi-agent playbook.

Feature: A live NOC dashboard for the Yamato wiki at /wiki/noc,
showing Cloud Armor and IAP defense activity in real time, pulled
from Cloud Logging API.

Why / who it's for: This is the centerpiece of the consulting demo.
A prospect should be able to look at this page and immediately see
the Fort Knox defense layers working against real adversaries —
no slides, no narration, just live evidence. Visual clarity matters
more than feature breadth.

In scope:
- A /wiki/noc page (IAP-gated, under /wiki, follows existing wiki theme)
- Tile: blocks in the last 1h / 24h
- Tile: top 5 source IPs (with provider attribution if cheap)
- Tile: top 5 probed URLs
- Tile: top WAF rule priorities firing
- Tile: status of the 9 alert policies (green/yellow/red)
- All data pulled from Cloud Logging API using the runtime SA
- Auto-refresh every 30s (meta refresh tag is fine; no JS framework)

Out of scope:
- World map of source IPs (next feature)
- Historical analytics / charts over time
- Per-rule drill-down pages
- WebSocket / SSE push (meta refresh suffices)
- Modifying Cloud Armor rules or alert policies

Constraints / quality bar:
- Must render cleanly with EMPTY Cloud Logging response (e.g., quiet day)
- Must NOT crash or block if Cloud Logging API times out — show a
  fallback state ("logs unavailable, try again") and keep rendering
- IAP gating is non-negotiable; /wiki/noc must NEVER be reachable
  without an @iq9.io identity
- The Cloud Logging API call must use the existing runtime SA — do
  NOT introduce a new service account
- The runtime SA may need roles/logging.viewer added; if so, document
  it in the Writer's doc but flag it for the user (Terraform change
  required, not done by this pipeline)

Demo flow: open https://yamato-dev.iq9.io/wiki/noc in front of a
prospect, log in with @iq9.io, watch the tiles populate from live
Cloud Logging data showing real overnight attacks blocked.
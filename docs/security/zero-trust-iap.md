# Zero Trust & IAP — identity is the perimeter

[← Security index](./readme.md)

The old model put a wall around the network: get inside the VPN and you're trusted. That
model fails the moment one credential, one device, or one forgotten firewall rule leaks.
The yamato platform uses the opposite model — **BeyondCorp / zero trust** — where there is
no trusted network. Access is granted by **identity** (and optionally device posture),
checked on **every request**, no matter where it comes from.

That's why we can put the wiki and the NOC on the public internet without flinching.

## The `302` — the whole thesis in one status code

Hit `https://yamato-dev.iq9.io/wiki` (or `/noc`) without being signed in and you get:

```
HTTP/2 302
location: https://accounts.google.com/...   (Google sign-in)
```

The important part is **where that decision is made**: at the **load balancer's edge, by
Identity-Aware Proxy**, *before the request is ever forwarded to Cloud Run*. The
application never sees an unauthenticated request. From the app's own source
([app/yamato/main.go](../../app/yamato/main.go)):

> _"The app never enforces identity itself; IAP at the LB does."_

This is a profound property: **the gate lives in infrastructure, not in application code.**
A bug in the app cannot leak a protected page, because the app is never asked to make the
auth decision. Under `/wiki` and `/noc`, the app only *reads* the identity IAP already
verified (the `X-Goog-Authenticated-User-Email` header) — purely to say "signed in as you."

## Why "public internet + IAP" is genuinely safe

When an attacker attacks the login, they are **not** attacking Chris's auth code. IAP runs
on **Google Identity** — the same sign-in that protects billions of Gmail and Workspace
accounts, and the productized form of **BeyondCorp**, the model Google secures its own
internal corporate access with. So you inherit, for free:

- Google's account-takeover and suspicious-login detection
- MFA, security keys, and passkey support
- Brute-force and credential-stuffing defenses at Google scale

A red team does not brute-force that. Which is exactly what
[the playbook](./red-team-playbook.md)'s **Act 1** demonstrates: unauthenticated, you get
the `302` and nothing else.

## The part most people miss: locked ingress

IAP at the LB is only airtight because **the Cloud Run services cannot be reached around
the LB.** Both services are deployed with:

```
ingress = "internal-and-cloud-load-balancing"
```

(see [service/yamato/dev/cloudrun](../../service/yamato/dev/cloudrun/)). This means the
`*.run.app` URLs are **not publicly routable** — the *only* path to the app is **through**
the load balancer, where IAP (identity) **and** Cloud Armor (WAF + rate limit) both stand.

Without locked ingress, an attacker would simply skip the vault door and knock on the
`run.app` URL directly. So the real formula is:

> **IAP + locked backend ingress** — expose by *identity*, never by *network location*.

Take away the locked ingress and IAP becomes a front door on a house with no walls.

## What IAP does NOT do (and why that's correct)

IAP authenticates **identity**. It faithfully admits whoever proves they are an
allow-listed user. It does **not** stop a *legitimately authenticated* attacker holding a
**stolen** session — and it isn't supposed to. That is not a weakness in IAP; it's the
boundary of what authentication can do, and it's precisely the scenario
[Act 2](./red-team-playbook.md) is built around. The answer to stolen credentials is the
**layers behind IAP** ([defense-in-depth.md](./defense-in-depth.md)): a wiki-reader token
carries zero infrastructure rights, least-privilege service accounts and org policy block
every escalation, and the whole attempt is logged and alerted.

## Hardening the door further (recommended)

IAP is only as strong as the accounts on its allow-list. The allow-list here is
`domain:iq9.io` + `domain:simplifymy.cloud` (see
[frontdoor terraform.tfvars](../../service/yamato/dev/frontdoor/terraform.tfvars)), so the
strength of Act 1 ultimately rests on those identities being hard to phish:

1. **Phishing-resistant MFA — passkeys / security keys** enforced across both domains. This
   turns "phish a session" from *plausible* into *very hard*, and is the single biggest
   lever on Act 1's airtightness.
2. **Context-Aware Access (BeyondCorp Enterprise)** — layer device trust and/or location on
   top of identity, so even a stolen cookie from an unmanaged device is bounced. This is the
   step that begins to defend against the Act 2 stolen-credential case at the *door*, not
   just behind it.

The difference between these enabled and not is the difference between "Google-grade" and
"Google-grade **and** phishing-resistant."

## See also

- [defense-in-depth.md](./defense-in-depth.md) — the layers behind the door
- [red-team-playbook.md](./red-team-playbook.md) — proving both halves of the claim

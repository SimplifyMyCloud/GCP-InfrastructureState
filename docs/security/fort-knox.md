# The Fort Knox Model — the pitch

[← Security index](./readme.md)

> **Use this analogy in every security topic we pitch.** Business owners don't buy "IAP"
> or "least-privilege IAM" — they buy *"nobody walks out with my gold."* Fort Knox is how
> the technical truth lands with non-technical people protecting their digital assets from
> attack, brute force, and insiders.

![Fort Knox defense-in-depth — concentric GCP controls around your data](../diagrams/fort-knox-defense.svg)

## The story

Fort Knox doesn't protect the gold with *one* amazing wall. It protects it with **layers**:

- The **gold bars** sit inside a vault — and the vault has its **own cage** around the gold.
- The vault is inside a **depository building** with gates and guards.
- The building sits inside a **US Army tank base**.
- The base sits inside an **Army perimeter** — fences, gates, guards, guns.

To reach the gold you must penetrate **every** layer, in order. It's not impossible — but
**each layer slows you down**, and every delay gives the defenders time to escalate their
response. So even if you somehow reach a vault, you're caged at the gold; and the moment you
try to **walk out with the loot**, you're met with an overwhelming response.

That is exactly how this platform protects your data on Google Cloud.

## The mapping — Fort Knox → GCP → what it means for you

| Fort Knox layer | The guard's job | GCP control | What it means for your business |
| --- | --- | --- | --- |
| **Army perimeter** (fences, guards, guns) | Repel the obvious assault on sight | **Cloud Armor** — WAF + rate-limit ban + Adaptive Protection | Automated attacks, bots, and brute force are blocked at the edge — before they ever cost you |
| **Gates & guards** (ID checkpoint) | Nobody enters without proving who they are | **Identity-Aware Proxy** (the `302`) | Only *your* people get in — on the same login that guards Gmail and Google's own staff |
| **Sealed building** (one road in) | Every other door is bricked up | **Locked Cloud Run ingress** (LB-only) | There is no back door to sneak through; the guarded gate is the *only* way in |
| **Vault door** | Even inside, you can barely touch anything | **Least-privilege service account** | A breached app can't roam — it can do almost nothing |
| **Cage around the gold** | The gold is locked up *even inside the vault* | **Private-IP Cloud SQL + Secret Manager** | Your actual data has no public address, and your keys are never left lying around |
| **Watchtowers & alarms** | Every move watched; alarms in **and** out | **Logging + Alerts + NOC + 365-day archive** | You see attacks in real time, and stolen goods can't leave unnoticed |

## The two points that close the deal

**1. Every layer buys you response time.** A single wall either holds or it doesn't. Layers
turn a breach into a *slow, noisy* journey — and at each ring an alarm fires
([the NOC](./readme.md#the-noc) lights up, alerts hit the inbox). The defender is escalating
while the attacker is still digging. Time is the product depth buys you.

**2. You can get *in* — you can't get *out* with the loot.** This is the clincher for an
owner. Suppose an attacker beats the front and reaches the vault (in our world: they phished
a real login — [Act 2](./red-team-playbook.md)). They *still* lose, three ways:

- **There's barely any loot to grab** — least-privilege means the identity they hijacked can
  touch almost nothing (one read-only database role, one secret).
- **Every grab trips an alarm** — reading a secret, an over-broad API call, minting a token:
  each is audit-logged and alerted in real time.
- **The evidence is out of their reach** — logs stream to an immutable **365-day org-wide
  archive** they cannot delete. They can't scrub the camera footage.

> *"On Google Cloud, the question isn't just 'can they break in?' — it's 'can they break in,
> find anything worth taking, get it out, and erase the tapes?' The answer is no, no, no, and
> no."*

## The 60-second pitch (say it like this)

> "Think of your data as gold in Fort Knox. We don't bet everything on one wall. There's an
> armed perimeter that stops the mob at the fence — that's Google's Cloud Armor. There's a
> guarded gate where you prove who you are, the same ID check that protects every Gmail
> account on Earth — that's Identity-Aware Proxy. The building has just one guarded road in;
> every other door is sealed. Inside, the vault barely lets you touch anything, and the gold
> itself is in a locked cage with no public address. And the whole place is under watch —
> alarms when you come in, and alarms when you try to leave with anything. You can throw
> everything you've got at it, and you'll be slowed, seen, and stopped at every step. That's
> what 'secure on Google Cloud' actually means."

## See also

- [readme.md](./readme.md) — the index and the un-hecklable claim
- [zero-trust-iap.md](./zero-trust-iap.md) — the gate (IAP) in depth
- [defense-in-depth.md](./defense-in-depth.md) — every ring mapped to the repo
- [red-team-playbook.md](./red-team-playbook.md) — watching the gold stay put under live attack

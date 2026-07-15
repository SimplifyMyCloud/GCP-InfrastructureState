# Life of a Packet — the long form

*The book behind the deck.*

This is the extended prose companion to the *"Life of a Packet"* presentation ([`../deck.md`](../deck.md)). Where the slides land the beat, the chapters unpack the mechanism. Where the slides use a metaphor, the chapters cite the source.

The book is designed to be **readable standalone** — a prospect who never attends the live session should be able to work through the chapters at their own pace and walk away with the same mental model the workshop delivers. Each chapter corresponds to one paired-slide concept in the deck; each stands on its own.

## Table of Contents

| # | Chapter | Status |
|---|---|---|
| 1 | [The Trust Boundary Is Not the Network](./01-beyondcorp-premise.md) — Operation Aurora, BeyondCorp, and why cloud security starts with identity, not location | ✓ |
| 2 | [TLS Wrap on the Client](./02-tls-wrap-on-the-client.md) — the packet is opaque before it leaves the laptop; why port 443 does more work than it looks | ✓ |
| 3 | [GFE + DDoS Scrubbing](./03-gfe-ddos-scrubbing.md) — the outermost active defense; where volumetric attacks die (2.5 Tbps in 2020, 398M rps in 2023) and public internet ends | ✓ |
| 4 | [Google's Private Backbone](./04-google-private-backbone.md) — one million miles of fiber + 15 subsea cables + B4 SDN + ALTS/PSP encryption; why MUSCULAR (2013) taught Google that owning the fiber is not the same as trusting it | ✓ |
| 5 | [IAP Identity Check](./05-iap-identity-check.md) — OAuth/JWT + per-request IAM evaluation; the "session does not outlive the grant" property that makes revocation immediate | ✓ |
| 6 | [IAP Context Check (Context-Aware Access)](./06-iap-context-check.md) — device posture, network location, patch level; why stolen credentials without the matching device context are worthless; the "escort in the hallway" beat | ✓ |
| 7 | [VPC Firewall (`35.235.240.0/20`)](./07-vpc-firewall.md) — the belt-and-suspenders layer that holds independently of IAP; two gates, both required, and why independence is what makes defense-in-depth real | ✓ |
| 8 | [OS Login SSH Key Check](./08-os-login-ssh-key-check.md) — the innermost layer; sshd + OS Login as a second independent auth system alongside IAP; central identity as the source of truth for SSH access | ✓ |
| 9 | [Return Path](./09-return-path.md) — the bridge to the finale; same six hops reversed for legitimate users, but the exit is where the trap closes on anyone who was not supposed to be in | ✓ |
| 10 | [The APT Counterfactual](./10-apt-counterfactual.md) — assume the impossible: the attacker got in; now watch the reverse-flow defenses (Cloud Logging, adaptive protection, VPC egress + VPC SC, minimal SA, distroless, alerts) close the trap; the honest security guarantee that actually matters | ✓ |

## How to read

Sequentially, for the full argument — each chapter builds on the previous. Or jump to any single chapter — each stands alone, with its own historical citations, its own technical mechanism, and its own Fort Knox parallel bridging concrete-to-abstract for readers arriving cold.

## Relationship to the slide deck

Each chapter maps to **one paired-slide concept** in [`../deck.md`](../deck.md). The slide pair is the presentation's version — one technical slide, one Fort Knox parallel — designed for live delivery. The chapter is the written-out substance behind both slides, sized to be read.
